import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_extra.dart';

/// 生理周期子页面 — 周期事件列表
class CyclePage extends StatefulWidget {
  const CyclePage({super.key});

  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color pinkBg = Color(0xFFFFE4E9);
  static const Color orange = Color(0xFFF5A623);
  static const Color textGray = Color(0xFF999999);

  List<CycleEvent> _events = [];
  final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  static const Map<CycleEventType, String> _typeLabels = {
    CycleEventType.taboo: '禁忌',
    CycleEventType.period: '经期',
    CycleEventType.ovulation: '排卵',
    CycleEventType.fertile: '易孕',
    CycleEventType.release: '解禁',
    CycleEventType.due: '到期',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppDatabase.instance.getCycleEvents();
    if (mounted) {
      setState(() => _events = list);
    }
  }

  Future<void> _add() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final type = await showModalBottomSheet<CycleEventType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _typeLabels.entries
              .map((e) => ListTile(
                    title: Text(e.value),
                    onTap: () => Navigator.pop(ctx, e.key),
                  ))
              .toList(),
        ),
      ),
    );
    if (type == null) return;

    await AppDatabase.instance
        .addCycleEvent(CycleEvent(date: _fmt.format(picked), type: type));
    await _load();
  }

  Future<void> _delete(int id) async {
    await AppDatabase.instance.deleteCycleEvent(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('生理周期'),
      ),
      body: _events.isEmpty
          ? const Center(
              child: Text('暂无周期记录', style: TextStyle(color: textGray)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = _events[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: pinkBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.date, style: const TextStyle(fontSize: 15)),
                            if (e.note.isNotEmpty)
                              Text(e.note,
                                  style: const TextStyle(
                                      color: textGray, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(_typeLabels[e.type] ?? '未知',
                          style: const TextStyle(
                              color: orange, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _delete(e.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: orange,
        onPressed: _add,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}