import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_extra.dart';

/// 营养打卡子页面 — 完整还原 Web 版
class SupplementPage extends StatefulWidget {
  const SupplementPage({super.key});

  @override
  State<SupplementPage> createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage> {
  // ── Colors ──
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color orange = Color(0xFFF5A623);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color textDark = Color(0xFF333333);
  static const Color textGray = Color(0xFF999999);
  static const Color greenBadge = Color(0xFF7ED321);

  // ── 预置营养品类 ──
  static const List<SupplementType> _defaultTypes = [
    SupplementType(name: '叶酸', emoji: '🌿', frequency: '每日1次'),
    SupplementType(name: '钙片', emoji: '🥛', frequency: '每日1次'),
    SupplementType(name: '维生素D', emoji: '☀️', frequency: '每日1次'),
    SupplementType(name: '铁剂', emoji: '💊', frequency: '每日1次'),
    SupplementType(name: 'DHA', emoji: '🐟', frequency: '每日1次'),
  ];

  // ── State ──
  List<SupplementLog> _todayLogs = [];
  List<SupplementType> _customTypes = [];
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = AppDatabase.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final allLogs = await db.getSupplementLogs();

    final todayLogs = allLogs.where((l) => l.date == today).toList();

    // 计算连续打卡天数
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      final ds = DateFormat('yyyy-MM-dd').format(d);
      if (allLogs.any((l) => l.date == ds && l.done)) {
        streak++;
      } else {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _todayLogs = todayLogs;
        _streak = streak;
        _loading = false;
      });
    }
  }

  bool _isChecked(String type) =>
      _todayLogs.any((l) => l.type == type && l.done);

  Future<void> _toggleSupplement(String type, bool checked) async {
    final db = AppDatabase.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (checked) {
      await db.addSupplementLog(SupplementLog(
        date: today,
        type: type,
        done: true,
      ));
    } else {
      final existing = _todayLogs.where((l) => l.type == type && l.done);
      for (final log in existing) {
        if (log.id != null) {
          await db.delete('supplement_logs',
              where: 'id = ?', whereArgs: [log.id]);
        }
      }
    }
    _loadData();
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String frequency = '每日1次';
    TimeOfDay? reminderTime;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('添加营养品',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: '营养品名称',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: InputDecoration(
                      labelText: '频率',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: '每日1次', child: Text('每日1次')),
                      DropdownMenuItem(value: '每日2次', child: Text('每日2次')),
                      DropdownMenuItem(value: '隔日1次', child: Text('隔日1次')),
                      DropdownMenuItem(value: '每周1次', child: Text('每周1次')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => frequency = v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: reminderTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => reminderTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD0D0D0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 18, color: textGray),
                          const SizedBox(width: 8),
                          Text(
                            reminderTime != null
                                ? '提醒时间: ${reminderTime!.format(context)}'
                                : '设置提醒时间（可选）',
                            style: TextStyle(
                              fontSize: 14,
                              color: reminderTime != null
                                  ? textDark
                                  : textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消',
                      style: TextStyle(color: textGray)),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _customTypes.add(SupplementType(
                          name: name,
                          emoji: '💊',
                          frequency: frequency,
                          reminderTime: reminderTime,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('添加',
                      style: TextStyle(
                          color: orange, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 所有类型（预置 + 自定义） ──
  List<SupplementType> get _allTypes => [..._defaultTypes, ..._customTypes];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr =
        '${today.month}月${today.day}日 · ${weekdays[today.weekday - 1]}';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('营养打卡',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textDark)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allTypes.isEmpty
              ? _buildEmptyState()
              : _buildBody(dateStr),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '暂无营养品项',
            style: TextStyle(
                fontSize: 16,
                color: textGray,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角 + 添加需要打卡的营养品',
            style: TextStyle(fontSize: 13, color: textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String dateStr) {
    final checkedCount = _defaultTypes
        .where((t) => _isChecked(t.name))
        .length;
    final total = _defaultTypes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
      child: Column(
        children: [
          // ── 日期摘要卡 ──
          _buildHeaderCard(dateStr, checkedCount, total),
          const SizedBox(height: 12),

          // ── 连续打卡 ──
          if (_streak > 0) _buildStreakCard(),
          if (_streak > 0) const SizedBox(height: 12),

          // ── 营养品列表 ──
          ..._allTypes.map((type) => _buildSupplementCard(type)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String dateStr, int checked, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 日期图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('📅', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark)),
                const SizedBox(height: 3),
                Text(
                  '今日已打卡: $checked/$total',
                  style: TextStyle(
                    fontSize: 13,
                    color: checked == total ? greenBadge : textGray,
                    fontWeight:
                        checked == total ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (checked == total)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: greenBadge.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: greenBadge),
                  SizedBox(width: 3),
                  Text('已完成',
                      style: TextStyle(
                          fontSize: 11,
                          color: greenBadge,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          const Text('连续打卡',
              style: TextStyle(fontSize: 14, color: textGray)),
          const SizedBox(width: 6),
          Text('$_streak 天',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: orange)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: textGray, size: 20),
        ],
      ),
    );
  }

  Widget _buildSupplementCard(SupplementType type) {
    final checked = _isChecked(type.name);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: checked ? lightOrange : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(type.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Name + frequency
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                const SizedBox(height: 2),
                Text(type.frequency,
                    style: const TextStyle(fontSize: 11, color: textGray)),
              ],
            ),
          ),
          // Check-in status
          if (checked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: greenBadge.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 13, color: greenBadge),
                  SizedBox(width: 3),
                  Text('已打卡',
                      style: TextStyle(
                          fontSize: 11,
                          color: greenBadge,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => _toggleSupplement(type.name, true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('打卡',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          // Toggle switch for completed items
          if (checked)
            Switch(
              value: true,
              onChanged: (v) => _toggleSupplement(type.name, v),
              activeColor: orange,
              activeTrackColor: lightOrange,
            ),
        ],
      ),
    );
  }
}

/// 营养品类型数据模型
class SupplementType {
  final String name;
  final String emoji;
  final String frequency;
  final TimeOfDay? reminderTime;

  const SupplementType({
    required this.name,
    this.emoji = '💊',
    this.frequency = '每日1次',
    this.reminderTime,
  });
}