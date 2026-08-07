import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/budget.dart';
import '../../models/todo.dart';
import '../../models/beiyun_extra.dart';
import '../../main.dart';

/// 工作台首页 — 聚合日历 + 三项目入口
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  List<BeiyunTask> _beiyunTasks = [];
  List<BudgetCategory> _budgetCats = [];
  List<BudgetRecord> _budgetRecords = [];
  List<TodoTask> _todoTasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = AppDatabase.instance;
    final tasks = await db.getBeiyunTasks();
    final cats = await db.getBudgetCategories();
    final records = await db.getBudgetRecords();
    final todos = await db.getTodoTasks();
    if (mounted) {
      setState(() {
        _beiyunTasks = tasks;
        _budgetCats = cats;
        _budgetRecords = records;
        _todoTasks = todos;
      });
    }
  }

  int _undoneBeiyun() => _beiyunTasks.where((t) => !t.done).length;
  int _undoneBudget() => _budgetCats.where((c) => !c.done).length;
  int _undoneTodo() => _todoTasks.where((t) => !t.done).length;

  /// 获取某天的所有事件（用于日历圆点）
  Map<String, List<dynamic>> _eventsForDay(DateTime day) {
    final ds = fmtDate(day);
    final result = <String, List<dynamic>>{
      'beiyun': [],
      'budget': [],
      'todo': [],
    };
    // 备孕：有 planDate 的任务
    result['beiyun'] = _beiyunTasks.where((t) => t.planDate == ds).toList();
    // 备婚：有当天记录的分类
    final hasRecords = _budgetRecords.where((r) => r.date == ds).isNotEmpty;
    if (hasRecords) result['budget'] = _budgetRecords.where((r) => r.date == ds).toList();
    // 事项：有 date 的任务
    result['todo'] = _todoTasks.where((t) => t.date == ds).toList();
    return result;
  }

  /// 判断某天是否有事件
  bool _hasEvent(DateTime day) {
    final ev = _eventsForDay(day);
    return ev['beiyun']!.isNotEmpty || ev['budget']!.isNotEmpty || ev['todo']!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ThemeProvider>();
    final p = prov.preset;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('工作台'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: p.pri),
            onPressed: () => ThemePickerSheet.show(context, p,
                onPick: (picked) => prov.setTheme(picked)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // 三项目入口卡
              _buildProjectCards(p),
              const SizedBox(height: 16),
              // 聚合日历
              _buildCalendar(p, prov),
              const SizedBox(height: 16),
              // 选中日详情
              _buildDayDetail(p),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCards(ThemePreset p) {
    return Row(
      children: [
        _projectCard(p, '👶', '备孕', _undoneBeiyun(), p.pri),
        const SizedBox(width: 10),
        _projectCard(p, '💍', '备婚', _undoneBudget(), p.accent),
        const SizedBox(width: 10),
        _projectCard(p, '☑️', '事项', _undoneTodo(), p.priDeep),
      ],
    );
  }

  Widget _projectCard(ThemePreset p, String icon, String label, int count, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8, height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      Text(label, style: TextStyle(color: p.ink2, fontSize: 11)),
                    ],
                  ),
                ),
                Text('$count', style: TextStyle(
                  color: p.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Baloo 2',
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemePreset p, ThemeProvider prov) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime(2024),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        calendarFormat: _format,
        onFormatChanged: (f) => setState(() => _format = f),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) => _focusedDay = focused,
        locale: 'zh_CN',
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: p.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: p.pri),
          rightChevronIcon: Icon(Icons.chevron_right, color: p.pri),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: p.pri.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: p.pri,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white),
          defaultTextStyle: TextStyle(color: p.ink),
          weekendTextStyle: TextStyle(color: p.ink.withValues(alpha: 0.6)),
          outsideTextStyle: TextStyle(color: p.ink2.withValues(alpha: 0.3)),
          markerDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        eventLoader: (day) {
          final ev = _eventsForDay(day);
          final markers = <Widget>[];
          if (ev['beiyun']!.isNotEmpty) {
            markers.add(Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: p.pri, shape: BoxShape.circle),
            ));
          }
          if (ev['budget']!.isNotEmpty) {
            markers.add(Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            ));
          }
          if (ev['todo']!.isNotEmpty) {
            markers.add(Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: p.priDeep, shape: BoxShape.circle),
            ));
          }
          return markers;
        },
      ),
    );
  }

  Widget _buildDayDetail(ThemePreset p) {
    final ds = fmtDate(_selectedDay);
    final ev = _eventsForDay(_selectedDay);
    final hasAny = ev['beiyun']!.isNotEmpty || ev['budget']!.isNotEmpty || ev['todo']!.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('M月d日 EEEE', 'zh_CN').format(_selectedDay),
                style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: p.pri.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${DateFormat('EEEE', 'zh_CN').format(_selectedDay)}',
                  style: TextStyle(color: p.pri, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAny)
            EmptyState(icon: '📅', text: '这天没有安排'),
          if (hasAny) ...[
            if (ev['budget']!.isNotEmpty) ...[
              _sectionHeader(p, '💍', '备婚'),
              ...(ev['budget'] as List<BudgetRecord>).map((r) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Text(r.categoryName, style: TextStyle(color: p.ink, fontSize: 14)),
                    const Spacer(),
                    Text('¥${fmtMoney(r.amount)}', style: TextStyle(color: p.pri, fontSize: 13)),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            if (ev['beiyun']!.isNotEmpty) ...[
              _sectionHeader(p, '👶', '备孕'),
              ...(ev['beiyun'] as List<BeiyunTask>).map((t) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                child: Text(t.title, style: TextStyle(color: p.ink, fontSize: 14)),
              )),
              const SizedBox(height: 8),
            ],
            if (ev['todo']!.isNotEmpty) ...[
              _sectionHeader(p, '☑️', '事项'),
              ...(ev['todo'] as List<TodoTask>).map((t) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18, color: t.done ? Colors.green : p.ink2),
                    const SizedBox(width: 8),
                    Text(t.title,
                        style: TextStyle(
                          color: t.done ? p.ink2 : p.ink,
                          decoration: t.done ? TextDecoration.lineThrough : null,
                        )),
                  ],
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemePreset p, String icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: p.ink2, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: p.line, thickness: 1)),
        ],
      ),
    );
  }
}