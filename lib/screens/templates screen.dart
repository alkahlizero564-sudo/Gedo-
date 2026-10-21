import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';
import 'preview_screen.dart' show WebViewPreview;

// قوالب UI/UX حقيقية — لتطبيق واحد وتطبيقين، مع معاينة قبل الاستخدام
class TemplatesScreen extends StatelessWidget {
  final AppProject project;
  const TemplatesScreen({super.key, required this.project});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎨 واجهة القوالب')),
      body: ListView.builder(
        itemCount: kTemplates.length,
        itemBuilder: (context, i) {
          final t = kTemplates[i];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: t.color,
                  child: Icon(Icons.apps, color: Colors.white)),
              title: Text(t.name),
              subtitle: Text(
                  '${t.description}\n'
                  '${t.dualApp ? "قالب لتطبيقين (عميل + إدارة)" : "قالب لتطبيق واحد"}',
                  style: TextStyle(
                      color:
                          t.dualApp ? Colors.deepOrange : Colors.green)),
              isThreeLine: true,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _previewTemplate(context, t),
                ),
                ElevatedButton(
                  child: const Text('استخدام'),
                  onPressed: () {
                    final app = project.app1;
                    app.htmlCode = t.html;
                    app.cssCode = t.css;
                    app.jsCode = t.js;
                    if (t.dualApp) {
                      project.app2.htmlCode = t.html;
                      project.app2.linkedToFirstApp = true;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تطبيق القالب: ${t.name} ✅')));
                  },
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _previewTemplate(BuildContext context, AppTemplate t) {
    final html =
        '<html><head><style>${t.css}</style></head><body>${t.html}'
        '<script>${t.js}</script></body></html>';
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => WebViewPreview(html: html, title: t.name)));
  }
}
