import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';

// واجهة الإنشاء: التطبيق الأول وتحته التطبيق الثاني بنفس التفاصيل
class CreateScreen extends StatefulWidget {
  final AppProject project;
  const CreateScreen({super.key, required this.project});
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  Future<void> pickIcon(AppSpec app) async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => app.iconPath = f.path);
  }

  Widget appSection(AppSpec app, Color color, {bool isSecond = false}) => Card(
        margin: const EdgeInsets.all(12),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                    backgroundColor: color,
                    child: Text(isSecond ? '2' : '1',
                        style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Text(isSecond ? 'التطبيق الثاني' : 'التطبيق الأول',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'اسم التطبيق', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => app.name = v),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'اسم الحزمة (Package Name)',
                    border: OutlineInputBorder(),
                    hintText: 'com.maher.myapp'),
                onChanged: (v) => setState(() => app.packageName = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<AppPlatform>(
                initialValue: app.platform,
                decoration: const InputDecoration(
                    labelText: 'المنصة / اللغة', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: AppPlatform.web, child: Text('HTML / CSS / JS')),
                  DropdownMenuItem(
                      value: AppPlatform.flutter, child: Text('Flutter')),
                  DropdownMenuItem(
                      value: AppPlatform.python, child: Text('Python')),
                ],
                onChanged: (v) => setState(() => app.platform = v!),
              ),
              const SizedBox(height: 10),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () => pickIcon(app),
                  icon: const Icon(Icons.image),
                  label: const Text('اختر أيقونة من المعرض'),
                ),
                const SizedBox(width: 10),
                if (app.iconPath != null)
                  CircleAvatar(
                      backgroundImage: FileImage(File(app.iconPath!)),
                      radius: 24),
              ]),
              if (isSecond) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                      'التطبيق الثاني يقرأ كود التطبيق الأول (مثل العميل والإدارة)'),
                  subtitle: Text(app.linkedToFirstApp
                      ? 'مرتبط — سيتم إنشاء SQL وصلاحيات مشتركة تلقائياً'
                      : 'غير مرتبط — تطبيق مختلف تماماً'),
                  value: app.linkedToFirstApp,
                  onChanged: (v) => setState(() => app.linkedToFirstApp = v),
                ),
              ],
              const SizedBox(height: 10),
              ExpansionTile(
                title: Text('كود ${app.name.isEmpty ? "التطبيق" : app.name}'),
                children: [
                  _CodeField(
                      label: 'HTML',
                      value: app.htmlCode,
                      onChanged: (v) => app.htmlCode = v),
                  _CodeField(
                      label: 'CSS',
                      value: app.cssCode,
                      onChanged: (v) => app.cssCode = v),
                  _CodeField(
                      label: 'JavaScript',
                      value: app.jsCode,
                      onChanged: (v) => app.jsCode = v),
                  _CodeField(
                      label: 'Dart (Flutter)',
                      value: app.dartCode,
                      onChanged: (v) => app.dartCode = v),
                  _CodeField(
                      label: 'Python',
                      value: app.pythonCode,
                      onChanged: (v) => app.pythonCode = v),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🛠️ Maher — إنشاء التطبيقات')),
      body: ListView(children: [
        appSection(widget.project.app1, const Color(0xFF6C63FF)),
        appSection(widget.project.app2, const Color(0xFFFF6584), isSecond: true),
      ]),
    );
  }
}

class _CodeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _CodeField(
      {required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          maxLines: 5,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
          controller: TextEditingController(text: value),
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
