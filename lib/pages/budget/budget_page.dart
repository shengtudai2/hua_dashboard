import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../database/database_helper.dart';
import '../../models/budget.dart';

/// 备婚预算 — 婚礼倒计时 + 预算总览 + 分类管理 + 最近流水 + 近14天花销图
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<BudgetCategory> _cats = [];
  List<BudgetRecord> _records = [];
  DateTime? _weddingDate;
  bool _loading = true;

  static const _groups = ['拍摄准备', '婚礼当天', '备婚选品'];

  @override
  void initState() {
    super.initState();
    _ensureRedsTheme();
    _load();
  }

  /// 首次进入时默认切到喜庆红系
  void _ensureRedsTheme() {
    final prov = context.read<ThemeProvider>();
    if (prov.collectionId != 'REDS') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) prov.setTheme(RedsPresets.list[0]);
      });
    }
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final cats = await db.getBudgetCategories();
    final records = await db.getBudgetRecords();
    final prefs = await SharedPreferences.getInstance();
    final ws = prefs.getString('wedding_date');
    if (mounted) {
      setState(() {
        _cats = cats;
        _records = records;
        _weddingDate = ws == null ? null : parseDate(ws);
        _loading = false;
      });
    }
  }

  // ---------- 统计 ----------
  double get _totalBudget => _cats.fold(0, (s, c) => s + c.budget);
  double get _totalSpent => _cats.fold(0, (s, c) => s + c.spent);
  double get _remaining => _totalBudget - _totalSpent;
  int get _daysLeft =>
      _weddingDate == null ? 0 : diffDays(_weddingDate!, DateTime.now());

  // ---------- DatePicker ----------
  Future<void> _pickWeddingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: '选择婚礼日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wedding_date', fmtDate(picked));
    setState(() => _weddingDate = picked);
  }

  // ---------- 新增分类 ----------
  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    var group = _groups.first;
    final budgetCtrl = TextEditingController();
    final p = context.read<ThemeProvider>().preset;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新增预算分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '分类名称', hintText: '如：婚纱照')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: group,
                decoration: const InputDecoration(labelText: '分组'),
                items: _groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setSheet(() => group = v ?? group),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '预算金额'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final b = double.tryParse(budgetCtrl.text) ?? 0;
                    if (nameCtrl.text.trim().isEmpty) return;
                    AppDatabase.instance.addBudgetCategory(BudgetCategory(
                      name: nameCtrl.text.trim(), group: group, budget: b));
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) { _load(); }
  }

  // ---------- 分类流水 ----------
  Future<void> _showCategoryRecords(BudgetCategory cat) async {
    final p = context.read<ThemeProvider>().preset;
    final recs = _records.where((r) => r.categoryId == cat.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await showModalBottomSheet(
      context: context,
      backgroundColor: p.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${cat.icon} ${cat.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink)),
                const Spacer(),
                Text('已花 ¥${fmtMoney(cat.spent)}', style: TextStyle(color: p.pri, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text('预算 ¥${fmtMoney(cat.budget)}', style: TextStyle(color: p.ink2, fontSize: 13)),
              const SizedBox(height: 12),
              Expanded(
                child: recs.isEmpty
                    ? const EmptyState(icon: '🧾', text: '还没有流水记录')
                    : ListView.separated(
                        itemCount: recs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = recs[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Text(r.date, style: TextStyle(color: p.ink2, fontSize: 12)),
                            title: Text(r.note.isEmpty ? r.categoryName : r.note,
                                style: TextStyle(color: p.ink, fontSize: 14)),
                            trailing: Text('¥${fmtMoney(r.amount)}',
                                style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
                            onLongPress: () async {
                              await AppDatabase.instance.deleteBudgetRecord(r.id!);
                              _recomputeCategorySpent(cat);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _load();
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showRecordForm(cat); },
                  icon: const Icon(Icons.add),
                  label: const Text('记一笔'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 记录表单 ----------
  Future<void> _showRecordForm(BudgetCategory cat) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var date = DateTime.now();
    final p = context.read<ThemeProvider>().preset;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('记一笔 · ${cat.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '金额', prefixText: '¥ '),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx, initialDate: date,
                    firstDate: DateTime(2020), lastDate: DateTime(2035));
                  if (d != null) date = d;
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '日期'),
                  child: Text(fmtDate(date), style: TextStyle(color: p.ink)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: '备注（可选）')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text);
                    if (amt == null || amt <= 0) return;
                    Navigator.pop(ctx, true);
                    _saveRecord(cat, amt, fmtDate(date), noteCtrl.text.trim());
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _saveRecord(BudgetCategory cat, double amount, String date, String note) async {
    await AppDatabase.instance.addBudgetRecord(BudgetRecord(
      categoryId: cat.id!, categoryName: cat.name, amount: amount, date: date, note: note));
    await _recomputeCategorySpent(cat);
    _load();
  }

  Future<void> _recomputeCategorySpent(BudgetCategory cat) async {
    final db = AppDatabase.instance;
    final all = await db.getBudgetRecords();
    final recs = all.where((r) => r.categoryId == cat.id).toList();
    final sum = recs.fold(0.0, (s, r) => s + r.amount);
    final updated = BudgetCategory(
      id: cat.id, name: cat.name, group: cat.group,
      budget: cat.budget, spent: sum, pinned: cat.pinned, done: cat.done, icon: cat.icon);
    await db.updateBudgetCategory(updated);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ThemeProvider>();
    final p = prov.preset;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('备婚预算'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: p.pri),
            onPressed: () => ThemePickerSheet.show(context, p, onPick: (x) => prov.setTheme(x)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildOverview(p),
                  const SizedBox(height: 16),
                  _buildChart(p),
                  const SizedBox(height: 16),
                  _buildCategorySections(p),
                  const SizedBox(height: 16),
                  _buildRecentRecords(p),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // 1. 总览头
  Widget _buildOverview(ThemePreset p) {
    final ratio = _totalBudget <= 0 ? 0.0 : (_totalSpent / _totalBudget).clamp(0.0, 1.0);
    return HeroCard(
      preset: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 倒计时
          InkWell(
            onTap: _pickWeddingDate,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Expanded(
                  child: _weddingDate != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('距离婚礼还有', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('$_daysLeft',
                                style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800)),
                            Text('${fmtDate(_weddingDate!)} · 点击修改', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💍', style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: 6),
                            Text('点击设置婚礼日期，开始倒计时',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('总预算', _totalBudget),
              _statBox('已花', _totalSpent),
              _statBox('剩余', _remaining),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ratio, minHeight: 10,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Text('${(ratio * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }

  Widget _statBox(String label, double val) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text('¥${fmtMoney(val)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // 2. 近14天柱状图
  Widget _buildChart(ThemePreset p) {
    final now = DateTime.now();
    final days = List.generate(14, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 13 - i)));
    final dateToAmount = <String, double>{};
    for (final r in _records) {
      dateToAmount[r.date] = (dateToAmount[r.date] ?? 0) + r.amount;
    }
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < 14; i++) {
      final ds = fmtDate(days[i]);
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: dateToAmount[ds] ?? 0, color: p.pri, width: 8,
          borderRadius: BorderRadius.circular(3)),
      ]));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('近14天花销', style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (dateToAmount.values.fold(0.0, (a, b) => a > b ? a : b) * 1.2).clamp(1.0, 1e9),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= 14) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${days[i].day}', style: TextStyle(color: p.ink2, fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
                    '¥${fmtMoney(r.toY)}',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              barGroups: groups,
            )),
          ),
        ],
      ),
    );
  }

  // 3. 分类分组
  Widget _buildCategorySections(ThemePreset p) {
    if (_cats.isEmpty) {
      return AppCard(child: EmptyState(icon: '💰', text: '点击右下角 + 新建预算分类'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in _groups) ...[
          if (_cats.any((c) => c.group == g)) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(g, style: TextStyle(color: p.ink2, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            ..._cats.where((c) => c.group == g).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCategoryCard(p, c),
            )),
          ],
        ],
      ],
    );
  }

  Widget _buildCategoryCard(ThemePreset p, BudgetCategory c) {
    final ratio = c.budget <= 0 ? 0.0 : c.spent / c.budget;
    final Color barColor;
    if (ratio > 1.0) barColor = Colors.red;
    else if (ratio >= 0.8) barColor = Colors.orange;
    else barColor = Colors.green;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showCategoryRecords(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(c.icon.isEmpty ? '📌' : c.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(c.name,
                  style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w600,
                      decoration: c.done ? TextDecoration.lineThrough : null)),
            ),
            Text('¥${fmtMoney(c.spent)} / ¥${fmtMoney(c.budget)}',
                style: TextStyle(color: p.ink2, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: p.line,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // 4. 最近流水
  Widget _buildRecentRecords(ThemePreset p) {
    final recent = _records.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final top = recent.take(20).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近流水', style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('还没有流水，点分类记一笔吧', style: TextStyle(color: p.ink2, fontSize: 13))),
            )
          else
            ...top.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text('${r.icon()}', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.categoryName, style: TextStyle(color: p.ink, fontSize: 14)),
                    Text(r.date, style: TextStyle(color: p.ink2, fontSize: 11)),
                  ]),
                ),
                Text('¥${fmtMoney(r.amount)}', style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
              ]),
            )),
        ],
      ),
    );
  }
}

extension _CategoryIcon on BudgetRecord {
  String icon() {
    final c = _iconMap[categoryName];
    return c ?? '🧾';
  }
}

const _iconMap = <String, String>{
  '婚纱照': '📷', '婚宴': '🍽️', '婚戒': '💍', '礼服': '👗', '婚房布置': '🏠',
  '请柬': '💌', '蜜月': '✈️', '跟妆': '💄', '摄影摄像': '🎥', '甜品台': '🍰',
};