import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 漂浮装饰粒子层（氛围包的一部分）
class FloatersLayer extends StatefulWidget {
  final List<String> floaters;
  final Color? color;
  const FloatersLayer({super.key, this.floaters = const [], this.color});

  @override
  State<FloatersLayer> createState() => _FloatersLayerState();
}

class _FloatersLayerState extends State<FloatersLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Floater> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
    _particles = List.generate(
      widget.floaters.isEmpty ? 0 : 10,
      (i) => _Floater(
        char: widget.floaters[i % widget.floaters.length],
        x: (i * 37) % 100 / 100,
        delay: (i * 0.9) % 12,
        size: 14.0 + (i % 4) * 4,
        opacity: 0.25 + (i % 3) * 0.15,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.floaters.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              for (final p in _particles)
                Positioned(
                  left: p.x * 100,
                  top: ((_controller.value * 1 + p.delay) % 1) * 100,
                  child: Opacity(
                    opacity: p.opacity,
                    child: Text(p.char,
                        style: TextStyle(fontSize: p.size)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Floater {
  final String char;
  final double x;
  final double delay;
  final double size;
  final double opacity;
  _Floater({required this.char, required this.x, required this.delay, required this.size, required this.opacity});
}

/// 主题选择器（底部弹窗）
class ThemePickerSheet {
  static Future<void> show(BuildContext context, ThemePreset current,
      {required void Function(ThemePreset) onPick}) async {
    final selected = await showModalBottomSheet<ThemePreset>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThemeSheet(current: current),
    );
    if (selected != null) onPick(selected);
  }
}

class _ThemeSheet extends StatelessWidget {
  final ThemePreset current;
  const _ThemeSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final p = current;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    _collection(context, 'DOPAMINE', '多巴胺系'),
                    const SizedBox(height: 16),
                    _collection(context, 'REDS', '喜庆红系'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collection(BuildContext context, String id, String label) {
    final list = AppTheme.collections[id]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: current.ink2, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in list)
              GestureDetector(
                onTap: () => Navigator.pop(context, preset),
                child: Container(
                  width: 86,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: preset.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: preset.id == current.id ? preset.pri : preset.line,
                        width: preset.id == current.id ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [preset.heroA, preset.heroB]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(preset.decorChar ?? preset.name[0],
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(preset.name,
                          style: TextStyle(
                              color: preset.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
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

/// 通用大圆角卡片
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final card = color ?? Theme.of(context).cardColor;
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 渐变 hero 卡
class HeroCard extends StatelessWidget {
  final ThemePreset preset;
  final Widget child;
  const HeroCard({super.key, required this.preset, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [preset.heroA, preset.heroB]),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

/// 空状态
class EmptyState extends StatelessWidget {
  final String icon;
  final String text;
  const EmptyState({super.key, this.icon = '🌱', required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.black45, fontSize: 14)),
        ],
      ),
    );
  }
}

/// 数字格式化
String fmtMoney(num v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

/// 日期工具
String todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDate(String s) {
  try {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  } catch (_) {
    return null;
  }
}

int diffDays(DateTime a, DateTime b) {
  final da = DateTime(a.year, a.month, a.day);
  final db = DateTime(b.year, b.month, b.day);
  return da.difference(db).inDays;
}