import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models.dart';

// واجهة المفاتيح: GitHub / Supabase / Gemini (5 مفاتيح + النموذج) / Claude
class KeysScreen extends StatefulWidget {
  final ApiKeys keys;
  const KeysScreen({super.key, required this.keys});
  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  bool showKeys = false;

  Widget field(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        obscureText: !showKeys,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
              icon: Icon(showKeys ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => showKeys = !showKeys)),
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.keys;
    return Scaffold(
      appBar: AppBar(title: const Text('🔑 واجهة المفاتيح')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('GitHub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          field('GitHub Access Token', k.githubToken, (v) => k.githubToken = v),
          field('GitHub Project / Repo Ref', k.githubRepoRef,
              (v) => k.githubRepoRef = v),
          const Divider(height: 24),
          const Text('Supabase',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          field('Supabase Access Token', k.supabaseToken,
              (v) => k.supabaseToken = v),
          field('Supabase Project Ref', k.supabaseProjectRef,
              (v) => k.supabaseProjectRef = v),
          field('Supabase URL', k.supabaseUrl, (v) => k.supabaseUrl = v),
          field('Supabase Anon Key', k.supabaseAnonKey,
              (v) => k.supabaseAnonKey = v),
          const Divider(height: 24),
          const Text('Gemini API (5 مفاتيح + اختيار النموذج)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Radio<int>(
                    value: i,
                    groupValue: k.activeGeminiKey,
                    onChanged: (v) => setState(() => k.activeGeminiKey = v!)),
                Expanded(
                    child: field('Gemini API Key #${i + 1}', k.geminiKeys[i],
                        (v) => k.geminiKeys[i] = v)),
              ]),
            ),
          DropdownButtonFormField<String>(
            initialValue: k.geminiModel,
            decoration: const InputDecoration(
                labelText: 'اختر نموذج Gemini', border: OutlineInputBorder()),
            items: k.geminiModels
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => k.geminiModel = v!),
          ),
          const Divider(height: 24),
          const Text('Claude AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          field('Claude API Key', k.claudeKey, (v) => k.claudeKey = v),
          DropdownButtonFormField<String>(
            initialValue: k.claudeModel,
            decoration: const InputDecoration(
                labelText: 'اختر نموذج Claude', border: OutlineInputBorder()),
            items: k.claudeModels
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => k.claudeModel = v!),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _saveKeys(k),
            icon: const Icon(Icons.save),
            label: const Text('حفظ المفاتيح'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveKeys(ApiKeys k) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/maher_keys.json');
    await f.writeAsString(jsonEncode({
      'githubToken': k.githubToken,
      'githubRepoRef': k.githubRepoRef,
      'supabaseToken': k.supabaseToken,
      'supabaseProjectRef': k.supabaseProjectRef,
      'supabaseUrl': k.supabaseUrl,
      'supabaseAnonKey': k.supabaseAnonKey,
      'geminiKeys': k.geminiKeys,
      'activeGeminiKey': k.activeGeminiKey,
      'geminiModel': k.geminiModel,
      'claudeKey': k.claudeKey,
      'claudeModel': k.claudeModel,
    }));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المفاتيح محلياً 🔐')));
    }
  }
}
