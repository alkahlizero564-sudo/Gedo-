import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models.dart';

// توليد التطبيق من وصف نصي 100% — عبر Gemini أو Claude
class AiScreen extends StatefulWidget {
  final AppProject project;
  final ApiKeys keys;
  const AiScreen({super.key, required this.project, required this.keys});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final descCtrl = TextEditingController();
  bool loading = false;
  String log = '';
  int target = 0; // 0 = التطبيق الأول، 1 = الثاني

  Future<String> generateWithGemini(String prompt) async {
    final key = widget.keys.geminiKeys[widget.keys.activeGeminiKey];
    if (key.isEmpty) throw 'أضف مفتاح Gemini أولاً من واجهة المفاتيح';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '${widget.keys.geminiModel}:generateContent?key=$key';
    final res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'parts': [{'text': prompt}]}
          ]
        }));
    if (res.statusCode != 200) throw 'Gemini: ${res.statusCode}';
    final data = jsonDecode(res.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  Future<String> generateWithClaude(String prompt) async {
    if (widget.keys.claudeKey.isEmpty) throw 'أضف مفتاح Claude أولاً';
    final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': widget.keys.claudeKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': widget.keys.claudeModel,
          'max_tokens': 4096,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }));
    if (res.statusCode != 200) throw 'Claude: ${res.statusCode}';
    final data = jsonDecode(res.body);
    return data['content'][0]['text'] as String;
  }

  Future<void> generate() async {
    setState(() {
      loading = true;
      log = '';
    });
    final app = target == 0 ? widget.project.app1 : widget.project.app2;
    final prompt =
        'أنت خبير تطوير تطبيقات. ابنِ تطبيق كامل بناءً على هذا الوصف:\n'
        '"${descCtrl.text}"\n'
        'أعد الناتج بهذا الشكل بالضبط:\nHTML: <الكود>\nCSS: <الكود>\n'
        'JS: <الكود>\n'
        'وشرح موجز بالعربية. التطبيق '
        '${target == 0 ? "الأول (العميل)" : "الثاني (الإدارة)"}'
        '${app.linkedToFirstApp && target == 1 ? " ومرتبط بالأول عبر Supabase" : ""}.';
    try {
      final out = await generateWithGemini(prompt);
      _parseOutput(out, app);
      setState(() => log = out);
    } catch (e) {
      try {
        final out = await generateWithClaude(prompt);
        _parseOutput(out, app);
        setState(() => log = out);
      } catch (e2) {
        setState(() => log = 'خطأ: $e2');
      }
    }
    setState(() => loading = false);
  }

  void _parseOutput(String out, AppSpec app) {
    final h = RegExp(r'HTML\s*:([\s\S]*?)(?=CSS\s*:)', caseSensitive: false);
    final c = RegExp(r'CSS\s*:([\s\S]*?)(?=JS\s*:)', caseSensitive: false);
    final j = RegExp(r'JS\s*:([\s\S]*?)(?=\n(Dart|Python|شرح)|$)',
        caseSensitive: false);
    if (h.hasMatch(out)) app.htmlCode = h.firstMatch(out)!.group(1)!.trim();
    if (c.hasMatch(out)) app.cssCode = c.firstMatch(out)!.group(1)!.trim();
    if (j.hasMatch(out)) app.jsCode = j.firstMatch(out)!.group(1)!.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🤖 بناء بالذكاء الاصطناعي')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('توليد التطبيق الأول')),
                    ButtonSegment(value: 1, label: Text('توليد التطبيق الثاني')),
                  ],
                  selected: {target},
                  onSelectionChanged: (s) => setState(() => target = s.first),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: widget.keys.geminiModel,
                  decoration: const InputDecoration(
                      labelText: 'نموذج Gemini', border: OutlineInputBorder()),
                  items: widget.keys.geminiModels
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => widget.keys.geminiModel = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'اكتب وصف التطبيق وسيتولاه الذكاء الاصطناعي 100%',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: تطبيق متجر الكتروني للملابس مع سلة شراء'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('ابنِ التطبيق بالذكاء الاصطناعي'),
                ),
                if (log.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(log, style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
    );
  }
}
