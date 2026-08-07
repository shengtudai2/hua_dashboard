import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../widgets/web_widgets.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/budget.dart';
import '../../models/todo.dart';
import '../../main.dart';

/// 工作台首页 — 聚合日历 + 三项目入口（Web 设计系统）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  List<BeiyunTask> _tasks = [];
  List<BudgetCategory> _cats = [];
  List<BudgetRecord> _records = [];
  List<TodoTask> _todos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final tasks = await db.getBeiyunTasks();
    final cats = await db.getBudgetCategories();
    final records = await db.getBudgetRecords();
    final todos = await db.getTodoTasks();
    if (mounted) setState(() {
      _tasks = tasks; _cats = cats; _records = records; _todos = todos;
    });
  }

  int _undoBeiyun() => _tasks.where((t) => !t.done).length;
  int _undoCats() => _cats.where((c) => !c.done).length;
  int _undoTodos() => _todos.where((t) => !t.done).length;

  Map<String, List<dynamic>> _eventsForDay(DateTime day) {
    final ds = DateFormat('yyyy-MM-dd').format(day);
    return {
      'beiyun': _tasks.where((t) => t.planDate == ds).toList(),
      'budget': _records.where((r) => r.date == ds).toList(),
      'todo': _todos.where((t) => t.date == ds).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.bg,
      appBar: AppBar(
        backgroundColor: WebTheme.bg,
        elevation: 0,
        leading: const DrawerMenuButton(),
        title: const Text('工作台', style: TextStyle(
          fontFamily: 'ZCOOL KuaiLe', fontSize: 20, color: WebTheme.ink,
        )),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 26),
          child: Column(
            children: [
              _buildProjectCards(),
              const SizedBox(height: 4),
              WebStatsGrid(items: [
                WebStatItem('${_tasks.length + _todos.length}', '待办'),
                WebStatItem('$_undoBeiyun', '备孕'),
                WebStatItem('$_undoCats', '备婚'),
                WebStatItem('$_undoTodos', '事项'),
              ]),
              _buildCalendar(),
              _buildDayDetail(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCards() {
    return WebCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _projectCard('👶', '备孕', _undoBeiyun(), WebTheme.pri),
          const SizedBox(width: 10),
          _projectCard('💍', '备婚', _undoCats(), WebTheme.accent),
          const SizedBox(width: 10),
          _projectCard('☑️', '事项', _undoTodos(), WebTheme.evBlue),
        ],
      ),
    );
  }

  Widget _projectCard(String emoji, String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity, height: 4,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(label, style: const TextStyle(fontSize: 11, color: WebTheme.ink2)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(
            fontFamily: 'ZCOOL KuaiLe',
            fontSize: 26, fontWeight: FontWeight.w800, color: WebTheme.ink,
          )),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return WebCard(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime(2024),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        calendarFormat: _format,
        onFormatChanged: (f) => setState(() => _format = f),
        onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
        onPageChanged: (f) => _focusedDay = f,
        locale: 'zh_CN',
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextFormatter: (d, l) => '${d.year}年${d.month}月',
          titleTextStyle: const TextStyle(
            fontFamily: 'ZCOOL KuaiLe', fontSize: 17, fontWeight: FontWeight.w700, color: WebTheme.ink,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: WebTheme.priDeep),
          rightChevronIcon: const Icon(Icons.chevron_right, color: WebTheme.priDeep),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: WebTheme.priSoft, shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: WebTheme.pri, shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white),
          defaultTextStyle: const TextStyle(color: WebTheme.ink),
          weekendTextStyle: const TextStyle(color: WebTheme.ink2),
          outsideTextStyle: const TextStyle(color: WebTheme.ink2),
          markerDecoration: const BoxDecoration(color: Colors.transparent),
          markersMaxCount: 3,
        ),
        eventLoader: (day) {
          final ev = _eventsForDay(day);
          final r = <String>[];
          if (ev['beiyun']!.isNotEmpty) r.add('b');
          if (ev['budget']!.isNotEmpty) r.add('g');
          if (ev['todo']!.isNotEmpty) r.add('t');
          return r;
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (c, d, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: events.map((e) {
                Color dc;
                switch (e as String) {
                  case 'b': dc = WebTheme.pri;
                  case 'g': dc = WebTheme.accent;
                  case 't': dc = WebTheme.evBlue;
                  default: dc = WebTheme.line;
                }
                return Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: dc, shape: BoxShape.circle),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayDetail() {
    final ev = _eventsForDay(_selectedDay);
    final hasAny = ev['beiyun']!.isNotEmpty || ev['budget']!.isNotEmpty || ev['todo']!.isNotEmpty;

    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('M月d日', 'zh_CN').format(_selectedDay),
                  style: const TextStyle(
                    fontFamily: 'ZCOOL KuaiLe', fontSize: 16, fontWeight: FontWeight.w700, color: WebTheme.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WebTheme.priSoft, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('EEEE', 'zh_CN').format(_selectedDay),
                    style: const TextStyle(fontSize: 11, color: WebTheme.priDeep),
                  ),
                ),
              ],
            ),
          ),
          if (!hasAny)
            const WebEmptyState(icon: '📅', text: '这天没有安排'),
          if (ev['budget']!.isNotEmpty) ...[
            _sectionHeader('💍', '备婚'),
            ...(ev['budget'] as List<BudgetRecord>).map((r) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
              child: Row(
                children: [
                  Text(r.categoryName, style: const TextStyle(fontSize: 14, color: WebTheme.ink)),
                  const Spacer(),
                  Text('¥${r.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: WebTheme.priDeep)),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
          if (ev['beiyun']!.isNotEmpty) ...[
            _sectionHeader('👶', '备孕'),
            ...(ev['beiyun'] as List<BeiyunTask>).map((t) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
              child: Text(t.title, style: const TextStyle(fontSize: 14, color: WebTheme.ink)),
            )),
            const SizedBox(height: 8),
          ],
          if (ev['todo']!.isNotEmpty) ...[
            _sectionHeader('☑️', '事项'),
            ...(ev['todo'] as List<TodoTask>).map((t) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18, color: t.done ? WebTheme.accent : WebTheme.ink2),
                  const SizedBox(width: 8),
                  Text(t.title, style: TextStyle(
                    fontSize: 14, color: t.done ? WebTheme.ink2 : WebTheme.ink,
                    decoration: t.done ? TextDecoration.lineThrough : null,
                  )),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String emoji, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.ink2)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: WebTheme.line)),
        ],
      ),
    );
  }
}