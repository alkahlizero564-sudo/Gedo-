import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';

// المعاينة الفورية: HTML/JS داخل WebView + Flutter عبر DartPad + Python عبر Piston
class PreviewScreen extends StatefulWidget {
  final AppProject project;
  const PreviewScreen({super.key, required this.project});
  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  int selected = 0;
  // 0 = HTML فوري، 1 = Flutter عبر DartPad، 2 = Python عبر Piston
  int mode = 0;
  String buildHtml(AppSpec app) =>
      '<html dir="rtl"><head><meta name="viewport" content="width=device-width,initial-scale=1">'
      '<style>${app.cssCode}</style></head><body>${app.htmlCode}'
      '<script>${app.jsCode}</script></body></html>';

  @override
  Widget build(BuildContext context) {
    final app = selected == 0 ? widget.project.app1 : widget.project.app2;
    return Scaffold(
      appBar: AppBar(title: const Text('👁️ واجهة المعاينة الفورية')),
      body: Column(children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('التطبيق الأول')),
            ButtonSegment(value: 1, label: Text('التطبيق الثاني')),
          ],
          selected: {selected},
          onSelectionChanged: (s) => setState(() => selected = s.first),
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('HTML/JS')),
            ButtonSegment(value: 1, label: Text('Flutter ▶')),
            ButtonSegment(value: 2, label: Text('Python ▶')),
          ],
          selected: {mode},
          onSelectionChanged: (s) => setState(() => mode = s.first),
        ),
        Expanded(
          child: mode == 0
              ? WebViewPreview(html: buildHtml(app), title: app.name)
              : mode == 1
                  ? FlutterPreview(dartCode: app.dartCode)
                  : PythonPreview(pythonCode: app.pythonCode),
        ),
      ]),
    );
  }
}

// معاينة Flutter — تشغيل كود Dart فورياً عبر DartPad الرسمي
class FlutterPreview extends StatefulWidget {
  final String dartCode;
  const FlutterPreview({super.key, required this.dartCode});
  @override
  State<FlutterPreview> createState() => _FlutterPreviewState();
}

class _FlutterPreviewState extends State<FlutterPreview> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final code = Uri.encodeComponent(widget.dartCode.isEmpty
        ? "import 'package:flutter/material.dart';\n"
            "void main() => runApp(MaterialApp(home: Scaffold(body: Center(child: Text('اكتب كود Flutter ليظهر هنا 🚀')))));"
        : widget.dartCode);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://dartpad.dev/?embed=true&code=$code'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة Flutter (تشغيل حقيقي)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load()),
        ],
      ),
      body: Column(children: [
        Expanded(child: WebViewWidget(controller: controller)),
        Container(
          width: double.infinity,
          color: Colors.deepPurple,
          padding: const EdgeInsets.all(10),
          child: const Text(
            '▶ DartPad يشغّل كود Flutter فعلياً في المتصفح — النتيجة تفاعلية 100%',
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }
}

// معاينة Python — تنفيذ كود Python فوراً عبر Piston API
class PythonPreview extends StatefulWidget {
  final String pythonCode;
  const PythonPreview({super.key, required this.pythonCode});
  @override
  State<PythonPreview> createState() => _PythonPreviewState();
}

class _PythonPreviewState extends State<PythonPreview> {
  String output = '';
  bool running = false;

  Future<void> runCode() async {
    final code = widget.pythonCode.isEmpty
        ? 'print("مرحباً! اكتب كود Python هنا ▶")'
        : widget.pythonCode;
    setState(() {
      running = true;
      output = '⏳ جاري التنفيذ…';
    });
    try {
      final res = await http.post(
        Uri.parse('https://emkc.org/api/v2/piston/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': 'python',
          'version': '3.10.0',
          'files': [{'content': code}],
        }),
      );
      final data = jsonDecode(res.body);
      final stdout = data['run']['stdout'] ?? '';
      final stderr = data['run']['stderr'] ?? '';
      setState(() {
        output = '';
        if (stdout.toString().isNotEmpty) output += '$stdout';
        if (stderr.toString().isNotEmpty) {
          output += output.isEmpty ? '' : '\n';
          output += '❌ $stderr';
        }
        if (output.isEmpty) output = '— لا مخرجات —';
      });
    } catch (e) {
      setState(() => output = 'خطأ في الاتصال: $e');
    }
    setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة Python (تنفيذ حقيقي)'),
        actions: [
          IconButton(
              icon: const Icon(Icons.play_arrow, size: 30),
              onPressed: running ? null : runCode),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: Colors.blueGrey,
          padding: const EdgeInsets.all(10),
          child: const Text(
            '▶ يتم تنفيذ كود Python فعلياً على خادم سحابي (Piston) وعرض الناتج فوراً',
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Text(
                output.isEmpty ? 'اضغط ▶ أعلى الشاشة لتنفيذ كود Python' : output,
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 14),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// WebView عام للمعاينة الفورية HTML/CSS/JS
class WebViewPreview extends StatelessWidget {
  final String html;
  final String title;
  const WebViewPreview({super.key, required this.html, required this.title});
  @override
  Widget build(BuildContext context) {
    late final controller = WebViewController()
      ..loadHtmlString(html)
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    return Scaffold(
      appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadHtmlString(html)),
          ]),
      body: WebViewWidget(controller: controller),
    );
  }
}
