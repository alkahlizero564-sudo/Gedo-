import 'package:flutter/material.dart';

// ============================================================
// MODELS
// ============================================================
enum AppPlatform { web, flutter, python }

class AppSpec {
  String name;
  String packageName;
  AppPlatform platform;
  String? iconPath;
  String description;
  String htmlCode;
  String jsCode;
  String cssCode;
  String dartCode;
  String pythonCode;
  bool linkedToFirstApp; // true = التطبيق الثاني يقرأ كود الأول (عميل/إدارة)
  AppSpec({
    required this.name,
    this.packageName = 'com.example.app',
    this.platform = AppPlatform.flutter,
    this.iconPath,
    this.description = '',
    this.htmlCode = '<h1>مرحباً 👋</h1>',
    this.jsCode = 'console.log("Hello");',
    this.cssCode = 'body{font-family:sans-serif;padding:20px}',
    this.dartCode = '',
    this.pythonCode = '',
    this.linkedToFirstApp = false,
  });
}

class AppProject {
  final AppSpec app1;
  final AppSpec app2;
  AppProject(this.app1, this.app2);
}

class ApiKeys {
  // GitHub
  String githubToken = '';
  String githubRepoRef = '';
  // Supabase
  String supabaseToken = '';
  String supabaseProjectRef = '';
  String supabaseUrl = '';
  String supabaseAnonKey = '';
  // Gemini (5 مفاتيح)
  List<String> geminiKeys = ['', '', '', '', ''];
  int activeGeminiKey = 0;
  String geminiModel = 'gemini-2.0-flash';
  List<String> geminiModels = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.0-pro-exp',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
    'gemini-flash-latest',
    'gemini-pro-latest',
  ];
  // Claude
  String claudeKey = '';
  String claudeModel = 'claude-sonnet-4-5';
  List<String> claudeModels = [
    'claude-sonnet-4-5',
    'claude-opus-4-1',
    'claude-haiku-4-5',
    'claude-3-7-sonnet-latest',
    'claude-3-5-haiku-latest',
  ];
}

// ============================================================
// TEMPLATES — قوالب لتطبيق واحد وتطبيقين
// ============================================================
class AppTemplate {
  final String id;
  final String name;
  final String description;
  final bool dualApp; // true = قالب لتطبيقين (عميل + إدارة)
  final Color color;
  final String html;
  final String css;
  final String js;
  AppTemplate(this.id, this.name, this.description, this.dualApp, this.color,
      this.html, this.css, this.js);
}

final List<AppTemplate> kTemplates = [
  AppTemplate(
    'shop_single', 'متجر بسيط 🛍️', 'متجر منتجات بتطبيق واحد', false,
    const Color(0xFF6C63FF),
    '<div class="card"><h2>متجر الزهور</h2><p>تصفح المنتجات واطلب الآن</p><button onclick="buy()">اطلب الآن</button></div>',
    '.card{background:#fff;padding:24px;border-radius:16px;box-shadow:0 4px 20px rgba(0,0,0,.1);text-align:center;font-family:sans-serif}',
    'function buy(){alert("تم إرسال الطلب ✅")}',
  ),
  AppTemplate(
    'restaurant_dual', 'مطعم (عميل + إدارة) 🍕', 'طلب الطعام + لوحة إدارة الطلبات', true,
    const Color(0xFFFF6584),
    '<div class="screen"><h1>🍔 طلبك جاهز</h1><ul id="menu"></ul></div>',
    '.screen{font-family:sans-serif;padding:20px;background:#FFF5F7}',
    'const menu=["بيتزا","برجر","شاورما"];document.getElementById("menu").innerHTML=menu.map(m=>"<li>"+m+"</li>").join("")',
  ),
  AppTemplate(
    'delivery_dual', 'توصيل طلبات 🚚', 'عميل يتتبع طلبه + إدارة السائقين', true,
    const Color(0xFF2196F3),
    '<div class="track"><h2>تتبع طلبك</h2><div id="status">جاري التحضير…</div></div>',
    '.track{font-family:sans-serif;padding:24px;text-align:center}',
    'setTimeout(()=>document.getElementById("status").innerText="في الطريق إليك 🚗",2000)',
  ),
  AppTemplate(
    'school_dual', 'مدرسة (طالب + إدارة) 🎓', 'درجات الطالب + لوحة المعلم', true,
    const Color(0xFF4CAF50),
    '<div class="box"><h3>درجاتي</h3><p id="g">—</p></div>',
    '.box{font-family:sans-serif;padding:20px;background:#F1FFF4;border-radius:12px}',
    'document.getElementById("g").innerText="رياضيات: 95 | علوم: 88"',
  ),
  AppTemplate(
    'portfolio_single', 'بورتفوليو 👨‍💻', 'صفحة شخصية احترافية', false,
    const Color(0xFFFF9800),
    '<header><h1>ماهر</h1><p>مطور تطبيقات</p></header>',
    'header{background:linear-gradient(135deg,#FF9800,#FF5722);color:#fff;padding:60px 20px;font-family:sans-serif;text-align:center}',
    '',
  ),
  AppTemplate(
    'chat_dual', 'شات دعم 💬', 'عميل يراسل الدعم + إدارة الردود', true,
    const Color(0xFF9C27B0),
    '<div class="chat"><div class="msg">أهلاً! كيف نساعدك؟</div></div>',
    '.chat{padding:16px;font-family:sans-serif}.msg{background:#E8DAEF;padding:10px 14px;border-radius:12px;margin:4px 0}',
    '',
  ),
];
