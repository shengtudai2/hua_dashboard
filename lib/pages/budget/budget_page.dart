import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../widgets/web_widgets.dart';
import '../../database/database_helper.dart';
import '../../models/budget.dart';
import '../../main.dart';

/// 备婚预算 — 对应 Web 版备婚预算 App（Web 设计系统）
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  static const _groups = ['拍摄准备', '婚礼当天', '备婚选品'];

  List<BudgetCategory> _categories = [];
  List<BudgetRecord> _records = [];
  DateTime? _weddingDate;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ensureRedsTheme();
    _load();
  }

  /// 首次进入备婚预算：若非喜庆红系则切换到 RedsPresets.list[0]
  Future<void> _ensureRedsTheme() async {
    final prov = context.read<ThemeProvider>();
    final isRed = AppTheme.collections['REDS']?.any((e) => e.id == prov.preset.id) ?? false;
    if (!isRed) {
      prov.setTheme(RedsPresets.list[0]);
    }
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final cats = await db.getBudgetCategories();
    final recs = await db.getBudgetRecords();
    final prefs = await SharedPreferences.getInstance();
    final ds = prefs.getString('wedding_date');
    DateTime? wd;
    if (ds != null) {
      try {
        wd = DateTime.tryParse(ds);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _records = recs;
      _weddingDate = wd;
      _loaded = true;
    });
  }

  // ── 数据计算 ──
  double get _totalBudget => _categories.fold(0, (s, c) => s + c.budget);
  double get _totalSpent => _categories.fold(0, (s, c) => s + c.spent);
  double get _remaining => _totalBudget - _totalSpent;
  double get _progress {
    if (_totalBudget <= 0) return 0;
    return (_totalSpent / _totalBudget).clamp(0.0, 1.0);
  }

  int get _daysLeft {
    if (_weddingDate == null) return 0;
    final today = DateTime.now();
    final d = DateTime(_weddingDate!.year, _weddingDate!.month, _weddingDate!.day);
    final t = DateTime(today.year, today.month, today.day);
    return d.difference(t).inDays;
  }

  Color _ratioColor(double ratio) {
    if (ratio >= 1.0) return WebTheme.danger;
    if (ratio >= 0.8) return const Color(0xFFF09577); // 橙
    return WebTheme.accent; // 绿
  }

  // ── 设置婚礼日期 ──
  Future<void> _pickWeddingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wedding_date', DateFormat('yyyy-MM-dd').format(picked));
    setState(() => _weddingDate = picked);
  }

  // ── 新增分类 ──
  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String group = _groups.first;

    await WebBottomSheet.show(
      context,
      title: '新增分类',
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '保存',
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final budget = double.tryParse(budgetCtrl.text.trim()) ?? 0;
              final nav = Navigator.of(context);
              await AppDatabase.instance.addBudgetCategory(BudgetCategory(
                name: name,
                group: group,
                budget: budget > 0 ? budget : 0,
              ));
              if (nav.mounted) nav.pop();
              _load();
            },
          ),
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebFormField(
              label: '分类名称',
              required: true,
              child: WebInput(controller: nameCtrl, hint: '如：婚纱照'),
            ),
            WebFormField(
              label: '所属分组',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: WebTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WebTheme.line, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: group,
                    isExpanded: true,
                    dropdownColor: WebTheme.card,
                    items: _groups
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: const TextStyle(color: WebTheme.ink)),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => group = v!),
                  ),
                ),
              ),
            ),
            WebFormField(
              label: '预算金额',
              child: WebInput(
                controller: budgetCtrl,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 新增/查看流水 ──
  Future<void> _openCategory(BudgetCategory cat) async {
    final catRecords = _records.where((r) => r.categoryId == cat.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await WebBottomSheet.show(
      context,
      title: '${cat.name} · 花费',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (catRecords.isEmpty)
            const WebEmptyState(icon: '💸', text: '还没有流水记录')
          else
            ...catRecords.map((r) => _recordRow(r)),
          const SizedBox(height: 8),
          Center(
            child: WebGradientButton(
              label: '添加流水',
              icon: Icons.add,
              onPressed: () => _addRecord(cat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordRow(BudgetRecord r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¥ ${r.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WebTheme.ink)),
                if (r.note.isNotEmpty)
                  Text(r.note, style: const TextStyle(fontSize: 11, color: WebTheme.ink2)),
              ],
            ),
          ),
          Text(r.date, style: const TextStyle(fontSize: 11, color: WebTheme.ink2)),
        ],
      ),
    );
  }

  Future<void> _addRecord(BudgetCategory cat) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = DateTime.now();

    await WebBottomSheet.show(
      context,
      title: '添加流水 · ${cat.name}',
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '保存',
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              await AppDatabase.instance.addBudgetRecord(BudgetRecord(
                categoryId: cat.id!,
                categoryName: cat.name,
                amount: amount,
                date: DateFormat('yyyy-MM-dd').format(date),
                note: noteCtrl.text.trim(),
              ));
              // 更新分类已花费
              final updated = cat.copyWith(spent: cat.spent + amount);
              await AppDatabase.instance.updateBudgetCategory(updated);
              Navigator.pop(context);
              _load();
            },
          ),
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebFormField(
              label: '金额',
              required: true,
              child: WebInput(
                controller: amountCtrl,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            WebFormField(
              label: '日期',
              child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (d != null) setLocal(() => date = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: WebTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WebTheme.line, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(date),
                          style: const TextStyle(fontSize: 14, color: WebTheme.ink)),
                      const Icon(Icons.calendar_today, size: 15, color: WebTheme.ink2),
                    ],
                  ),
                ),
              ),
            ),
            WebFormField(
              label: '备注',
              child: WebInput(controller: noteCtrl, hint: '选填'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 长按切换完成 ──
  Future<void> _toggleDone(BudgetCategory cat) async {
    final updated = cat.copyWith(done: !cat.done);
    await AppDatabase.instance.updateBudgetCategory(updated);
    setState(() {
      final i = _categories.indexWhere((c) => c.id == cat.id);
      if (i >= 0) _categories[i] = updated;
    });
  }

  // ── 近 14 天图表 ──
  List<BarChartGroupData> _buildChartData() {
    final today = DateTime.now();
    final map = <String, double>{};
    for (final r in _records) {
      map[r.date] = (map[r.date] ?? 0) + r.amount;
    }
    final groups = <BarChartGroupData>[];
    for (int i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      groups.add(BarChartGroupData(x: 13 - i, barRods: [
        BarChartRodData(
          toY: map[key] ?? 0,
          color: WebTheme.pri,
          width: 9,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ]));
    }
    return groups;
  }

  Widget _buildChart() {
    final maxY = _records.fold<double>(0, (m, r) => m > r.amount ? m : r.amount);
    final top = maxY <= 0 ? 1.0 : (maxY * 1.2);
    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: top,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: top / 3,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: WebTheme.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i > 13) return const SizedBox.shrink();
                  final d = DateTime.now().subtract(Duration(days: 13 - i));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.month}/${d.day}',
                      style: const TextStyle(fontSize: 8.5, color: WebTheme.ink2),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: _buildChartData(),
        ),
      ),
    );
  }

  // ── 分类分组渲染 ──
  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const WebEmptyState(icon: '💍', text: '还没有预算分类，点击 + 开始');
    }
    final children = <Widget>[];
    for (final group in _groups) {
      final list = _categories.where((c) => c.group == group).toList();
      if (list.isEmpty) continue;
      children.add(WebPageTitle(title: group));
      children.addAll(list.map(_buildCategoryCard));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildCategoryCard(BudgetCategory cat) {
    final ratio = cat.budget > 0 ? cat.spent / cat.budget : (cat.spent > 0 ? 1.0 : 0.0);
    final color = _ratioColor(ratio);
    return GestureDetector(
      onLongPress: () => _toggleDone(cat),
      child: WebCard(
        onTap: () => _openCategory(cat),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cat.name, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: WebTheme.ink,
                  decoration: cat.done ? TextDecoration.lineThrough : null,
                )),
              ),
              if (cat.done)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check_circle, size: 16, color: WebTheme.accent),
                ),
              Text('¥${cat.spent.toStringAsFixed(0)} / ¥${cat.budget.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11.5, color: WebTheme.ink2)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.budget > 0 ? (cat.spent / cat.budget).clamp(0.0, 1.0) : 0,
              minHeight: 7,
              backgroundColor: WebTheme.bg2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── 最近流水 ──
  Widget _buildRecent() {
    final recent = _records.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final top = recent.take(20).toList();
    if (top.isEmpty) {
      return const WebEmptyState(icon: '🧾', text: '还没有流水记录');
    }
    return Column(
      children: [
        for (final r in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¥ ${r.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: WebTheme.ink),
                      ),
                      Text(r.categoryName + (r.note.isNotEmpty ? ' · ${r.note}' : ''),
                          style: const TextStyle(fontSize: 11, color: WebTheme.ink2)),
                    ],
                  ),
                ),
                Text(r.date, style: const TextStyle(fontSize: 11, color: WebTheme.ink2)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.bg,
      appBar: AppBar(
        backgroundColor: WebTheme.bg,
        elevation: 0,
        leading: const DrawerMenuButton(),
        title: const Text('备婚预算', style: TextStyle(
          fontFamily: 'ZCOOL KuaiLe', fontSize: 20, color: WebTheme.ink)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: WebTheme.heroB,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              children: [
                // 1. 婚礼倒计时
                WebHeroCard(
                  onTap: _pickWeddingDate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('距离婚礼还有', style: TextStyle(fontSize: 13, color: WebTheme.ink2)),
                      const SizedBox(height: 4),
                      Text(
                        '$_daysLeft',
                        style: const TextStyle(
                          fontFamily: 'ZCOOL KuaiLe', fontSize: 44, fontWeight: FontWeight.w900,
                          color: WebTheme.priDeep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _weddingDate == null
                            ? '点击设置婚礼日期'
                            : '婚礼日：${DateFormat('yyyy年M月d日').format(_weddingDate!)}',
                        style: const TextStyle(fontSize: 12, color: WebTheme.ink2),
                      ),
                    ],
                  ),
                ),

                // 2. 总览
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('预算总览', style: TextStyle(
                        fontFamily: 'ZCOOL KuaiLe', fontSize: 15, fontWeight: FontWeight.w700, color: WebTheme.ink)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _stat('总预算', _totalBudget),
                          _stat('已花费', _totalSpent),
                          _stat('剩余', _remaining),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 8,
                                backgroundColor: WebTheme.bg2,
                                valueColor: const AlwaysStoppedAnimation(WebTheme.pri),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${(_progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WebTheme.priDeep)),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. 近 14 天图表
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('近 14 天花费', style: TextStyle(
                        fontFamily: 'ZCOOL KuaiLe', fontSize: 15, fontWeight: FontWeight.w700, color: WebTheme.ink)),
                      const SizedBox(height: 12),
                      _buildChart(),
                    ],
                  ),
                ),

                // 4. 分类分组
                _buildCategories(),

                // 5. 最近流水
                const WebPageTitle(title: '最近流水'),
                WebCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildRecent(),
                ),
              ],
            )
          : const SizedBox(),
    );
  }

  Widget _stat(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text('¥${value.toStringAsFixed(0)}', style: const TextStyle(
            fontFamily: 'ZCOOL KuaiLe', fontSize: 17, fontWeight: FontWeight.w800, color: WebTheme.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: WebTheme.ink2)),
        ],
      ),
    );
  }
}