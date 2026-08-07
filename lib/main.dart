import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  // 初始化中文日期符号（否则 TableCalendar/DateFormat 的 zh_CN 会抛异常）
  try {
    await initializeDateFormatting('zh_CN', null);
  } catch (_) {/* 忽略，个别环境可能缺数据 */}

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
        child: const DaihuaApp(),
      ),
    );
  } catch (e) {
    final prefs = await SharedPreferences.getInstance();
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(
          preset: DopaminePresets.list[0],
          collectionId: 'DOPAMINE',
          fontStyle: 'rounded',
          prefs: prefs,
        ),
        child: const DaihuaApp(),
      ),
    );
  }
}

/// 品牌启动页
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
                  child: Text('代', style: TextStyle(fontSize: 44, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('代花时光', style: TextStyle(fontSize: 26, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700)),
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

class DaihuaApp extends StatelessWidget {
  const DaihuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final theme = AppTheme.build(themeProv.preset);
    final p = themeProv.preset;

    return MaterialApp(
      title: '代花时光',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: FloatingDecorLayer(
        floaters: p.floaters,
        child: const MainShell(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 漂浮粒子层
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
// 主外壳：侧边抽屉导航（匹配 Web 版左边缘把手）
// ═══════════════════════════════════════════════════════════════

/// 全局抽屉 Key，供各页面 AppBar 的汉堡按钮打开抽屉
final GlobalKey<ScaffoldState> appDrawerKey = GlobalKey<ScaffoldState>();

/// 每个页面 AppBar 的汉堡按钮 → 打开侧边抽屉
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().preset;
    return IconButton(
      icon: Icon(Icons.menu, color: p.pri),
      onPressed: () => appDrawerKey.currentState?.openDrawer(),
      tooltip: '应用切换',
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentPage = 0;

  final _pages = const [
    HomePage(),
    BeiyunPage(),
    BudgetPage(),
    TodoPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ThemeProvider>();
    final p = prov.preset;

    return Scaffold(
      key: appDrawerKey,
      backgroundColor: p.bg,
      drawer: _buildDrawer(context, prov, p),
      body: IndexedStack(index: _currentPage, children: _pages),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeProvider prov, ThemePreset p) {
    return Drawer(
      backgroundColor: p.card,
      child: SafeArea(
        child: Column(
          children: [
            // 品牌区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [p.heroA, p.heroB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('代花时光', style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ZCOOL KuaiLe',
                  )),
                  const SizedBox(height: 4),
                  Text('备孕 · 备婚 · 事项', style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 模块列表
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(context, 0, '🏠', '工作台', p),
                  _divider(p),
                  _drawerItem(context, 1, '👶', '备孕工作台', p),
                  _divider(p),
                  _drawerItem(context, 2, '💍', '备婚预算', p),
                  _divider(p),
                  _drawerItem(context, 3, '☑️', '事项管理', p),
                  _divider(p),
                  _drawerItem(context, 4, '⚙️', '设置', p),
                ],
              ),
            ),
            // 底部主题按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showThemePicker(context, prov),
                  icon: Icon(Icons.palette, size: 18, color: p.pri),
                  label: Text('切换主题', style: TextStyle(color: p.pri)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: p.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, int index, String emoji, String label, ThemePreset p) {
    final isSelected = _currentPage == index;
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: TextStyle(
        color: isSelected ? p.pri : p.ink,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 15,
      )),
      trailing: isSelected
          ? Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: p.pri, shape: BoxShape.circle),
            )
          : null,
      onTap: () {
        setState(() => _currentPage = index);
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _divider(ThemePreset p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: p.line),
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: prov.preset.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _ThemePickerContent(prov: prov),
      ),
    );
  }
}

class _ThemePickerContent extends StatelessWidget {
  final ThemeProvider prov;
  const _ThemePickerContent({required this.prov});

  @override
  Widget build(BuildContext context) {
    final p = prov.preset;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('氛围主题', style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('当前：${p.name}', style: TextStyle(color: p.ink2, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _themeCollection(context, 'DOPAMINE', '多巴胺系'),
                    const SizedBox(height: 16),
                    _themeCollection(context, 'REDS', '喜庆红系'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeCollection(BuildContext context, String id, String label) {
    final list = AppTheme.collections[id]!;
    final p = prov.preset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.ink2, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in list)
              GestureDetector(
                onTap: () {
                  prov.setTheme(preset);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: preset.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: preset.id == p.id ? preset.pri : preset.line,
                        width: preset.id == p.id ? 2.5 : 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [preset.heroA, preset.heroB]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(preset.decorChar ?? preset.name[0],
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(preset.name,
                          style: TextStyle(color: preset.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(preset.desc,
                          style: TextStyle(color: preset.ink2, fontSize: 10)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}