import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_extra.dart';
import '../../widgets/common.dart';

/// 财务记账 sub-page.
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color orange = Color(0xFFF5A623);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color textDark = Color(0xFF333333);
  static const Color textGray = Color(0xFF999999);
  static const double _budget = 8000; // 总预算

  final List<BeiyunFinance> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppDatabase.instance.getBeiyunFinance();
    if (mounted) {
      setState(() {
        _records
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    }
  }

  double get _spent => _records.fold(0, (s, r) => s + r.amount);
  double get _remaining => _budget - _spent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('财务记账'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
        child: Column(
          children: [
            _buildBudgetCard(),
            const SizedBox(height: 12),
            _buildQuickAddCard(),
            const SizedBox(height: 12),
            _buildRecordList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── 1. 预算总览 ──
  Widget _buildBudgetCard() {
    final spentPct = _budget > 0 ? (_spent / _budget).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('备孕预算',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _budgetItem('总预算', '¥${fmtMoney(_budget)}'),
              _budgetItem('已花费', '¥${fmtMoney(_spent)}'),
              _budgetItem('剩余', '¥${fmtMoney(_remaining)}'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: spentPct,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text('已使用 ${(spentPct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _budgetItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── 2. 快速记账 ──
  Widget _buildQuickAddCard() {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_card, color: orange, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('快速记账',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark)),
                Text('记录备孕相关花费',
                    style: TextStyle(fontSize: 12, color: textGray)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _addRecord,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('记一笔',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. 记录列表 ──
  Widget _buildRecordList() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('记账明细',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('暂无记录，点击右下角记一笔',
                    style: TextStyle(fontSize: 13, color: textGray)),
              ),
            )
          else
            ..._records.map((r) => _recordTile(r)),
        ],
      ),
    );
  }

  Widget _recordTile(BeiyunFinance r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Text('¥',
                    style: TextStyle(color: orange, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.category,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                Text(
                  '${r.note.isEmpty ? '暂无备注' : r.note} · ${r.date}',
                  style: const TextStyle(fontSize: 12, color: textGray),
                ),
              ],
            ),
          ),
          Text('¥${fmtMoney(r.amount)}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: orange)),
        ],
      ),
    );
  }

  // ── 新增记录 ──
  Future<void> _addRecord() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: '一般');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记一笔'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '金额'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: '备注'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount <= 0) return;
              await AppDatabase.instance.addBeiyunFinance(BeiyunFinance(
                amount: amount,
                date: todayStr(),
                note: noteCtrl.text.trim(),
                category: categoryCtrl.text.trim().isEmpty ? '一般' : categoryCtrl.text.trim(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}