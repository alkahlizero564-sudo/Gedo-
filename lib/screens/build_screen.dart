import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';

// واجهة البناء: بناء APK للتطبيق الأول أو الثاني داخل التطبيق عبر GitHub Actions
// + توليد وتنفيذ SQL تلقائياً للربط عبر Supabase
class BuildScreen extends StatefulWidget {
  final AppProject project;
  final ApiKeys keys;
  const BuildScreen({super.key, required this.project, required this.keys});
  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  String status = '';
  double progress = 0;

  // SQL تلقائي للجدول والصلاحيات عند ربط التطبيقين عبر Supabase
  String generateSql(AppProject p) {
    if (!p.app2.linkedToFirstApp) return '';
    final t1 = (p.app1.name.isEmpty ? 'client' : p.app1.name)
        .replaceAll(' ', '_')
        .toLowerCase();
    final t2 = (p.app2.name.isEmpty ? 'admin' : p.app2.name)
        .replaceAll(' ', '_')
        .toLowerCase();
    return '''
-- تم توليده تلقائياً بواسطة Maher 🔗
create table if not exists ${t1}_data (
  id uuid primary key default gen_random_uuid(),
  payload jsonb not null default '{}',
  created_at timestamptz default now()
);
create table if not exists ${t2}_orders (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references ${t1}_data(id) on delete cascade,
  status text default 'pending',
  created_at timestamptz default now()
);
alter table ${t1}_data enable row level security;
alter table ${t2}_orders enable row level security;
create policy "clients read own data" on ${t1}_data
  for select using (auth.uid() = id);
create policy "admins full access" on ${t2}_orders
  for all using (auth.role() = 'authenticated');
''';
  }

  Future<void> runAutoSql() async {
    final k = widget.keys;
    if (k.supabaseUrl.isEmpty || k.supabaseToken.isEmpty) {
      setState(() => status = '⚠️ أضف مفاتيح Supabase أولاً من واجهة المفاتيح');
      return;
    }
    final sql = generateSql(widget.project);
    if (sql.isEmpty) {
      setState(() =>
          status = 'التطبيق الثاني غير مرتبط بالأول — لا حاجة لـ SQL مشترك');
      return;
    }
    setState(() {
      status = 'جاري تنفيذ SQL تلقائياً…';
      progress = 0.3;
    });
    final res = await http.post(
      Uri.parse('${k.supabaseUrl}/rest/v1/rpc/exec_sql'),
      headers: {
        'apikey': k.supabaseAnonKey,
        'Authorization': 'Bearer ${k.supabaseToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': sql}),
    );
    setState(() {
      progress = 1;
      status = res.statusCode == 200
          ? 'تم إنشاء الجداول والصلاحيات تلقائياً ✅'
          : 'فشل التنفيذ: ${res.body}';
    });
  }

  Future<void> buildApp(AppSpec app) async {
    setState(() {
      status = 'بدء بناء "${app.name}"…';
      progress = 0.1;
    });

    // 1) تجهيز ملفات المشروع (HTML/CSS/JS + Dart + Python)
    final pubspec = 'name: ${app.packageName.split('.').last}\n'
        'description: ${app.name}\n'
        'publish_to: none\n'
        'environment:\n  sdk: ">=3.0.0 <4.0.0"\n'
        'dependencies:\n  flutter:\n    sdk: flutter\n';
    final files = <String, String>{
      'index.html':
          '<!DOCTYPE html><html><head><style>${app.cssCode}</style></head>'
          '<body>${app.htmlCode}<script>${app.jsCode}</script></body></html>',
      'main.py': app.pythonCode,
      'lib/main.dart': app.dartCode,
      'pubspec.yaml': pubspec,
      '.github/workflows/maher_build.yml': _workflowYaml(app),
    };
    setState(() {
      status = 'تجهيز الملفات…';
      progress = 0.2;
    });

    // 2) رفع الكود إلى GitHub عبر REST API (بدون فتح GitHub)
    final k = widget.keys;
    if (k.githubToken.isEmpty || k.githubRepoRef.isEmpty) {
      setState(() => status = '⚠️ أضف GitHub Token و Repo Ref أولاً');
      return;
    }
    final headers = {
      'Authorization': 'token ${k.githubToken}',
      'Accept': 'application/vnd.github+json',
    };
    final repoName = app.packageName.split('.').last;
    // إنشاء المستودع إن لم يكن موجوداً
    final exists = await http.get(
        Uri.parse('https://api.github.com/repos/${k.githubRepoRef}'),
        headers: headers);
    if (exists.statusCode == 404) {
      await http.post(Uri.parse('https://api.github.com/user/repos'),
          headers: headers,
          body: jsonEncode({'name': repoName, 'auto_init': true}));
    }
    for (final e in files.entries) {
      // جلب sha الحالي للملف إن وُجد (لتحديثه بدل إنشائه)
      String? sha;
      final cur = await http.get(
          Uri.parse(
              'https://api.github.com/repos/${k.githubRepoRef}/contents/${e.key}'),
          headers: headers);
      if (cur.statusCode == 200) sha = jsonDecode(cur.body)['sha'];
      await http.put(
        Uri.parse(
            'https://api.github.com/repos/${k.githubRepoRef}/contents/${e.key}'),
        headers: headers,
        body: jsonEncode({
          'message': 'Maher build: ${e.key}',
          'content': base64Encode(utf8.encode(e.value)),
          if (sha != null) 'sha': sha,
        }),
      );
    }
    setState(() {
      status = 'تم رفع الكود ✅ — جاري تشغيل البناء على GitHub Actions…';
      progress = 0.45;
    });

    // 3) تشغيل الـ workflow (بناء APK حقيقي داخل GitHub Actions)
    final dispatch = await http.post(
      Uri.parse(
          'https://api.github.com/repos/${k.githubRepoRef}/actions/workflows/maher_build.yml/dispatches'),
      headers: headers,
      body: jsonEncode({'ref': 'main'}),
    );
    if (dispatch.statusCode != 204) {
      setState(() => status = 'فشل تشغيل البناء: ${dispatch.body}');
      return;
    }

    // 4) مراقبة حالة البناء حتى الاكتمال
    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 5));
      final runs = await http.get(
          Uri.parse(
              'https://api.github.com/repos/${k.githubRepoRef}/actions/runs?per_page=5'),
          headers: headers);
      final list = jsonDecode(runs.body)['workflow_runs'] as List;
      if (list.isNotEmpty) {
        final run = list.first;
        final st = run['status'] as String;
        setState(() {
          progress = 0.45 + (i / 120) * 0.4;
          status = 'البناء جارٍ على GitHub Actions — $st';
        });
        if (st == 'completed') {
          if (run['conclusion'] != 'success') {
            setState(() => status = 'فشل البناء ❌ (${run['conclusion']})');
            return;
          }
          break;
        }
      }
    }

    // 5) تنزيل APK من إصدارات المستودع (Release)
    setState(() {
      status = 'اكتمل البناء ✅ — جاري تنزيل ملف APK…';
      progress = 0.9;
    });
    final rel = await http.get(
        Uri.parse(
            'https://api.github.com/repos/${k.githubRepoRef}/releases/latest'),
        headers: headers);
    String? apkUrl;
    if (rel.statusCode == 200) {
      final assets = jsonDecode(rel.body)['assets'] as List;
      for (final a in assets) {
        if ((a['name'] as String).endsWith('.apk')) {
          apkUrl = a['url'] as String;
        }
      }
    }
    if (apkUrl == null) {
      setState(() => status = 'لم يتم العثور على APK في الإصدارات ⚠️');
      return;
    }
    final apkRes = await http.get(Uri.parse(apkUrl), headers: {
      'Authorization': 'token ${k.githubToken}',
      'Accept': 'application/octet-stream',
    });
    final dir = await getApplicationDocumentsDirectory();
    final apkFile = File(
        '${dir.path}/${repoName}-${DateTime.now().millisecondsSinceEpoch}.apk');
    await apkFile.writeAsBytes(apkRes.bodyBytes);
    setState(() {
      progress = 1;
      status =
          'تم تنزيل APK جاهز للتثبيت ✅ ${(apkRes.bodyBytes.length / 1048576).toStringAsFixed(1)} MB';
    });

    // 6) مشاركة APK للتثبيت مباشرة
    await Share.shareXFiles([XFile(apkFile.path)],
        text: 'APK من Maher: ${app.name}');
  }

  // ---- سكربت البناء الذي يرفع تلقائياً على GitHub Actions ----
  String _workflowYaml(AppSpec app) => '''
name: Maher APK Build
on:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
      - run: flutter pub get
      - run: flutter build apk --release
      - name: Release APK
        uses: softprops/action-gh-release@v2
        with:
          tag_name: maher-build-\${{ github.run_number }}
          files: build/app/outputs/flutter-apk/app-release.apk
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
''';

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(title: const Text('📦 واجهة البناء')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildCard('التطبيق الأول: ${p.app1.name}', p.app1.platform.name,
              () => buildApp(p.app1)),
          _buildCard('التطبيق الثاني: ${p.app2.name}', p.app2.platform.name,
              () => buildApp(p.app2)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: runAutoSql,
            icon: const Icon(Icons.storage),
            label:
                const Text('ربط التطبيقين + إنشاء SQL والصلاحيات تلقائياً'),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(status, textAlign: TextAlign.center),
          if (p.app2.linkedToFirstApp) ...[
            const Divider(),
            const Text('SQL المولّد تلقائياً:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black87,
              child: Text(generateSql(p),
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, VoidCallback onBuild) =>
      Card(
        child: ListTile(
          leading: const Icon(Icons.android, size: 36),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('المنصة: $subtitle'),
          trailing:
              ElevatedButton(onPressed: onBuild, child: const Text('بناء APK')),
        ),
      );
}
