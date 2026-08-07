import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 备孕时间设置弹窗
class TimeSettingsSheet extends StatefulWidget {
  final Function(String? targetDate, String? pregnantDate) onSave;
  const TimeSettingsSheet({required this.onSave});

  @override
  State<TimeSettingsSheet> createState() => _TimeSettingsSheetState();
}

class _TimeSettingsSheetState extends State<TimeSettingsSheet> {
  String? _targetDate;
  String? _pregnantDate;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _targetDate = p.getString('beiyun_target_date');
        _pregnantDate = p.getString('beiyun_pregnant_date');
      });
    }
  }

  Future<void> _pickDate(String type) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final s = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (type == 'target') _targetDate = s;
        if (type == 'pregnant') _pregnantDate = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('备孕时间设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          _dateField('备孕目标起始日 *', _targetDate, () => _pickDate('target')),
          const SizedBox(height: 12),
          _dateField('确认怀孕日期（留空 = 尚未怀孕）', _pregnantDate, () => _pickDate('pregnant')),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '设置目标日后，系统会自动推算任务最晚完成日、日历事件与阶段状态；填写怀孕日期后进入怀孕期模式。',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF999999),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_targetDate == null && _pregnantDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请至少设置备孕目标日')),
                      );
                      return;
                    }
                    widget.onSave(_targetDate, _pregnantDate);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, String? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              value != null ? value : '点我选择日期',
              style: TextStyle(
                fontSize: 14,
                color: value != null ? const Color(0xFF333333) : const Color(0xFF999999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 主题切换弹窗
class ThemeSheet extends StatefulWidget {
  final Function(String preset, String? customColor) onSave;
  const ThemeSheet({required this.onSave});

  @override
  State<ThemeSheet> createState() => _ThemeSheetState();
}

class _ThemeSheetState extends State<ThemeSheet> {
  static const _themes = [
    ('sakura', '樱花粉', Color(0xFFE8638C)),
    ('mint', '薄荷绿', Color(0xFF4BA886)),
    ('sky', '天空蓝', Color(0xFF5A93C9)),
    ('sun', '暖阳橙', Color(0xFFE0A62B)),
    ('lavender', '薰衣草', Color(0xFF9678CF)),
  ];

  String _selected = 'sakura';
  Color _customColor = const Color(0xFFE8638C);

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selected = p.getString('beiyun_theme_preset') ?? 'sakura';
        final cc = p.getString('beiyun_custom_color');
        if (cc != null) {
          _customColor = Color(int.parse(cc.substring(1), radix: 16) | 0xFF000000);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('切换主题',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _themes.map((t) {
              final selected = _selected == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _selected = t.$1),
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: t.$3,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: const Color(0xFF333333), width: 3)
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(t.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF333333))),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('自定义主色（优先于预设）',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (_) => SimpleDialog(
                        title: const Text('选择颜色'),
                        children: [
                          Container(
                            width: 200, height: 100,
                            color: _customColor,
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, Colors.orange),
                            child: const Text('橙色'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, Colors.pink),
                            child: const Text('粉色'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, Colors.teal),
                            child: const Text('青色'),
                          ),
                        ],
                      ),
                    );
                    if (picked != null) setState(() => _customColor = picked);
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _customColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => setState(() => _customColor = const Color(0xFFE8638C)),
                child: const Text('清除自定义色', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final hex = '#${(_customColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
                widget.onSave(_selected, hex);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('保存主题'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 字体切换弹窗
class FontSheet extends StatefulWidget {
  final Function(String preset) onSave;
  const FontSheet({required this.onSave});

  @override
  State<FontSheet> createState() => _FontSheetState();
}

class _FontSheetState extends State<FontSheet> {
  static const _fonts = [
    ('rounded', '圆润可爱'),
    ('elegant', '正式优雅'),
    ('modern', '简约现代'),
  ];

  String _selected = 'rounded';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _selected = p.getString('beiyun_font_preset') ?? 'rounded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('切换字体',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _fonts.map((f) {
              final selected = _selected == f.$1;
              return GestureDetector(
                onTap: () => setState(() => _selected = f.$1),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFFF3E0) : const Color(0xFFFFFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? const Color(0xFFF5A623) : const Color(0xFFE0E0E0),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text('孕',
                            style: TextStyle(
                              fontSize: 26,
                              color: const Color(0xFF333333),
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(f.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF333333))),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '字体仅改变标题与数字的展示风格，不影响数据与配色。"圆润可爱"为默认字体。',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('保存字体'),
            ),
          ),
        ],
      ),
    );
  }
}