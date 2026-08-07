import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'database/database_helper.dart';
import 'pages/home/home_page.dart';
import 'pages/beiyun/beiyun_page.dart';
import 'pages/budget/budget_page.dart';
import 'pages/todo/todo_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 立即渲染品牌启动页，不阻塞首帧
  runApp(const Boo4Splash());

  // 后台初始化数据库 + 主题
  try {
    await AppDatabase.instance.database;
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString('theme_id') ?? 'sakura';
    final collectionId = prefs.getString('theme_collection') ?? 'DOPAMINE';
    final fontStyle = prefs.getString('font_style') ?? 'rounded';
    final end = _findPreset(themeId, collectionId) ?? DopaminePresets.list[0];

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(
          preset: end,
          collectionId: collectionId,
          fontStyle: fontStyle,
          prefs: prefs,
        ),
        child: const HuaTodoApp(),
      ),
    );
  } catch (e) {
    // 初始化失败也能进入主界面，数据懒加载
    final prefs = await SharedPreferences.getInstance();
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(
          preset: DopaminePresets.list[0],
          collectionId: 'DOPAMINE',
          fontStyle: 'rounded',
          prefs: prefs,
        ),
        child: const HuaTodoApp(),
      ),
    );
  }
}

/// 品牌启动页（初始化期间显示）
class Boo4Splash extends StatelessWidget {
  const Boo4Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF6F0FB),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC1A6F0), Color(0xFFF6C6E6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Text('花', style: TextStyle(fontSize: 44, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('花笺', style: TextStyle(fontSize: 26, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('备孕 · 备婚 · 事项', style: TextStyle(fontSize: 13, color: Color(0xFF9A8AB0))),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Color(0xFFB39DDB))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ThemePreset? _findPreset(String id, String collection) {
  for (final list in AppTheme.collections.values) {
    for (final p in list) {
      if (p.id == id) return p;
    }
  }
  return null;
}

class ThemeProvider extends ChangeNotifier {
  ThemePreset preset;
  String collectionId;
  String fontStyle;
  final SharedPreferences prefs;

  ThemeProvider({
    required this.preset,
    required this.collectionId,
    required this.fontStyle,
    required this.prefs,
  });

  void setTheme(ThemePreset p, {String? font}) {
    preset = p;
    if (font != null) fontStyle = font;
    collectionId = _findCollection(p);
    prefs.setString('theme_id', p.id);
    prefs.setString('theme_collection', collectionId);
    prefs.setString('font_style', fontStyle);
    notifyListeners();
  }

  String _findCollection(ThemePreset p) {
    for (final entry in AppTheme.collections.entries) {
      if (entry.value.any((e) => e.id == p.id)) return entry.key;
    }
    return 'DOPAMINE';
  }
}

class HuaTodoApp extends StatelessWidget {
  const HuaTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final theme = AppTheme.build(themeProv.preset);
    final p = themeProv.preset;

    return MaterialApp(
      title: '花笺',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: FloatingDecorLayer(
        floaters: p.floaters,
        child: const MainShell(),
      ),
    );
  }
}

/// 漂浮粒子层（氛围包装饰）
class FloatingDecorLayer extends StatefulWidget {
  final List<String> floaters;
  final Widget child;
  const FloatingDecorLayer({super.key, required this.child, this.floaters = const []});

  @override
  State<FloatingDecorLayer> createState() => _FloatingDecorLayerState();
}

class _FloatingDecorLayerState extends State<FloatingDecorLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  List<_FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _rebuildParticles();
  }

  @override
  void didUpdateWidget(FloatingDecorLayer old) {
    super.didUpdateWidget(old);
    if (old.floaters != widget.floaters) _rebuildParticles();
  }

  void _rebuildParticles() {
    _particles = List.generate(
      widget.floaters.isEmpty ? 0 : 8,
      (i) => _FloatingParticle(
        char: widget.floaters[i % widget.floaters.length],
        x: (i * 37 + 13) % 100 / 100,
        delay: (i * 1.1) % 14,
        size: 12.0 + (i % 5) * 3,
        opacity: 0.15 + (i % 4) * 0.06,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.floaters.isNotEmpty)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Stack(
                children: [
                  for (final p in _particles)
                    Positioned(
                      left: p.x * MediaQuery.of(context).size.width,
                      top: ((_ctrl.value * 1.0 + p.delay) % 1.0) *
                          MediaQuery.of(context).size.height,
                      child: Opacity(
                        opacity: p.opacity,
                        child: Text(p.char, style: TextStyle(fontSize: p.size)),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FloatingParticle {
  final String char;
  final double x;
  final double delay;
  final double size;
  final double opacity;
  _FloatingParticle({required this.char, required this.x, required this.delay, required this.size, required this.opacity});
}

/// 主外壳：底部导航 + 4 个 Tab
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final _pages = const [
    HomePage(),
    BeiyunPage(),
    BudgetPage(),
    TodoPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().preset;
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: p.card,
        selectedItemColor: p.pri,
        unselectedItemColor: p.ink2,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '工作台'),
          BottomNavigationBarItem(icon: Icon(Icons.child_care_outlined), activeIcon: Icon(Icons.child_care), label: '备孕'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_outlined), activeIcon: Icon(Icons.card_giftcard), label: '备婚'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_outlined), activeIcon: Icon(Icons.checklist), label: '事项'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}