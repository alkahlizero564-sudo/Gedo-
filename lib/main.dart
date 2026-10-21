import 'package:flutter/material.dart';
import 'models.dart';
import 'screens/create_screen.dart';
import 'screens/templates_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/keys_screen.dart';
import 'screens/build_screen.dart';

void main() => runApp(const MaherApp());

class MaherApp extends StatelessWidget {
  const MaherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maher — بناء التطبيقات بالذكاء الاصطناعي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final project = AppProject(
      AppSpec(name: 'تطبيق العميل'), AppSpec(name: 'تطبيق الإدارة'));
  final keys = ApiKeys();

  late final List<Widget> screens = [
    CreateScreen(project: project),
    TemplatesScreen(project: project),
    PreviewScreen(project: project),
    AiScreen(project: project, keys: keys),
    KeysScreen(keys: keys),
    BuildScreen(project: project, keys: keys),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.create), label: 'إنشاء'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'القوالب'),
          NavigationDestination(icon: Icon(Icons.play_circle), label: 'المعاينة'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'الذكاء'),
          NavigationDestination(icon: Icon(Icons.vpn_key), label: 'المفاتيح'),
          NavigationDestination(icon: Icon(Icons.build), label: 'البناء'),
        ],
      ),
    );
  }
}
