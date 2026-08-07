import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../database/database_helper.dart';
import '../../models/todo.dart';
import '../../widgets/common.dart';
import '../../theme/app_theme.dart';

const _presetColors = [
  '#FFB74D', '#FF8A65', '#E57373', '#F06292',
  '#BA68C8', '#64B5F6', '#4DB6AC', '#81C784',
];
const _emojiList = ['📌', '📝', '📋', '✅', '🎯', '⭐', '❤️', '🔥', '💪',
  '📅', '🎉', '💡', '🏠', '🛒', '📚', '💼', '🏃', '🎨', '📷', '✈️'];

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TodoModule> _modules = [];
  List<TodoTask> _tasks = [];
  int? _filterModuleId;
  DateTime _calSelected = DateTime.now();
  DateTime _calFocused = DateTime.now();
  CalendarFormat _calFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = AppDatabase.instance;
    final modules = await db.getTodoModules();
    final tasks = await db.getTodoTasks();
    if (mounted) setState(() { _modules = modules; _tasks = tasks; });
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  List<TodoTask> _filteredTasks() {
    var list = _tasks.where((t) => _filterModuleId == null || t.moduleId == _filterModuleId).toList();
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.date != b.date) {
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      }
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return list;
  }

  int _taskCount(int modId) => _tasks.where((t) => t.moduleId == modId).length;
  int _completedToday() => _tasks.where((t) => t.done && t.date == todayStr()).length;

  int _weekDone() {
    final ws = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final we = ws.add(const Duration(days: 7));
    return _tasks.where((t) {
      if (t.date == null) return false;
      final d = parseDate(t.date!);
      return d != null && !d.isBefore(ws) && d.isBefore(we) && t.done;
    }).length;
  }

  int _weekTotal() {
    final ws = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final we = ws.add(const Duration(days: 7));
    return _tasks.where((t) {
      if (t.date == null) return false;
      final d = parseDate(t.date!);
      return d != null && !d.isBefore(ws) && d.isBefore(we);
    }).length;
  }

  Set<DateTime> _taskDateSet() {
    final s = <DateTime>{};
    for (final t in _tasks) {
      if (t.date == null) continue;
      final d = parseDate(t.date!);
      if (d != null) s.add(DateTime(d.year, d.month, d.day));
    }
    return s;
  }

  List<TodoTask> _tasksOnDay(DateTime day) {
    final ds = fmtDate(day);
    return _tasks.where((t) => t.date == ds).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().preset;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
                leading: const DrawerMenuButton(),
                title: const Text('事项管理'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: p.pri,
          labelColor: p.pri,
          unselectedLabelColor: p.ink2,
          tabs: const [
            Tab(text: '📋 模块'),
            Tab(text: '✅ 任务'),
            Tab(text: '📅 日历'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildModules(p), _buildTasks(p), _buildCalendar(p)],
      ),
    );
  }

  // ---------- Tab 1: 模块 ----------
  Widget _buildModules(ThemePreset p) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        child: const Icon(Icons.add),
        onPressed: () => _addModuleDialog(p),
      ),
      body: _modules.isEmpty
          ? EmptyState(icon: '📂', text: '还没有模块，点 + 添加')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _modules.length,
                itemBuilder: (_, i) {
                  final m = _modules[i];
                  final color = _parseColor(m.color);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _filterModuleId = m.id;
                          _tabController.animateTo(1);
                        },
                        onLongPress: () => _deleteModule(m, p),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Text(m.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(m.name, style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w600))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text('${_taskCount(m.id ?? 0)} 项', style: TextStyle(color: color, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ---------- Tab 2: 任务 ----------
  Widget _buildTasks(ThemePreset p) {
    final filtered = _filteredTasks();
    final wt = _weekTotal();
    final wd = _weekDone();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        child: const Icon(Icons.add),
        onPressed: () => _addTaskDialog(p, null),
      ),
      body: Column(
        children: [
          // 过滤芯片
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _filterChip('全部', null, p),
                ..._modules.map((m) => _filterChip(m.name, m.id, p)),
              ],
            ),
          ),
          // 统计
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _statItem(p, '全部', '${_tasks.length}', p.ink, false),
                _statItem(p, '今日完成', '${_completedToday()}', p.pri, false),
                _statItem(p, '本周', wt == 0 ? '0%' : '${(wd * 100 / wt).round()}%', p.accent, true),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 进度条
          if (wt > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: wd / wt,
                  minHeight: 6,
                  backgroundColor: p.line,
                  valueColor: AlwaysStoppedAnimation(p.pri),
                ),
              ),
            ),
          // 任务列表
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(icon: '✅', text: '没有任务')
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        return Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            final messenger = ScaffoldMessenger.of(context);
                            await AppDatabase.instance.deleteTodoTask(t.id!);
                            await _loadData();
                            messenger.showSnackBar(SnackBar(
                                content: const Text('已删除'),
                                action: SnackBarAction(
                                  label: '撤销',
                                  onPressed: () async {
                                    await AppDatabase.instance.addTodoTask(t);
                                    _loadData();
                                  },
                                ),
                              ));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onLongPress: () async {
                                  await AppDatabase.instance.updateTodoTask(t.copyWith(pinned: !t.pinned));
                                  _loadData();
                                },
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        await AppDatabase.instance.updateTodoTask(t.copyWith(done: !t.done));
                                        _loadData();
                                      },
                                      child: Icon(
                                        t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: t.done ? Colors.green : p.ink2, size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(t.title,
                                        style: TextStyle(
                                          color: t.done ? p.ink2 : p.ink,
                                          decoration: t.done ? TextDecoration.lineThrough : null,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (t.pinned) Icon(Icons.push_pin, size: 16, color: p.pri),
                                    if (t.date != null)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: p.pri.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(t.date!.substring(5), style: TextStyle(color: p.pri, fontSize: 11)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? id, ThemePreset p) {
    final selected = _filterModuleId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filterModuleId = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? p.pri : p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? p.pri : p.line),
          ),
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : p.ink, fontSize: 13,
          )),
        ),
      ),
    );
  }

  Widget _statItem(ThemePreset p, String label, String value, Color color, bool showBar) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Baloo 2')),
          Text(label, style: TextStyle(color: p.ink2, fontSize: 11)),
        ],
      ),
    );
  }

  // ---------- Tab 3: 日历 ----------
  Widget _buildCalendar(ThemePreset p) {
    final dayTasks = _tasksOnDay(_calSelected);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        child: const Icon(Icons.add),
        onPressed: () => _addTaskDialog(p, _calSelected),
      ),
      body: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(10),
            child: TableCalendar(
              firstDay: DateTime(2024), lastDay: DateTime(2030),
              focusedDay: _calFocused,
              selectedDayPredicate: (d) => isSameDay(_calSelected, d),
              calendarFormat: _calFormat,
              onFormatChanged: (f) => setState(() => _calFormat = f),
              onDaySelected: (s, f) => setState(() { _calSelected = s; _calFocused = f; }),
              onPageChanged: (f) => _calFocused = f,
              locale: 'zh_CN',
              headerStyle: HeaderStyle(
                titleCentered: true, formatButtonVisible: false,
                titleTextStyle: TextStyle(color: p.ink, fontSize: 17, fontWeight: FontWeight.w700),
                leftChevronIcon: Icon(Icons.chevron_left, color: p.pri),
                rightChevronIcon: Icon(Icons.chevron_right, color: p.pri),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: p.pri.withValues(alpha: 0.2), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: p.pri, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white),
                defaultTextStyle: TextStyle(color: p.ink),
                weekendTextStyle: TextStyle(color: p.ink.withValues(alpha: 0.6)),
                outsideTextStyle: TextStyle(color: p.ink2.withValues(alpha: 0.3)),
              ),
              eventLoader: (day) => _taskDateSet().contains(DateTime(day.year, day.month, day.day))
                  ? [Container(width: 6, height: 6, decoration: BoxDecoration(color: p.priDeep, shape: BoxShape.circle))]
                  : [],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(DateFormat('M月d日 EEEE', 'zh_CN').format(_calSelected),
                    style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${dayTasks.length} 项', style: TextStyle(color: p.ink2, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: dayTasks.isEmpty
                ? EmptyState(icon: '📅', text: '这天没有任务')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: dayTasks.length,
                    itemBuilder: (_, i) {
                      final t = dayTasks[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await AppDatabase.instance.updateTodoTask(t.copyWith(done: !t.done));
                                  _loadData();
                                },
                                child: Icon(t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: t.done ? Colors.green : p.ink2, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(t.title,
                                  style: TextStyle(color: t.done ? p.ink2 : p.ink,
                                      decoration: t.done ? TextDecoration.lineThrough : null))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- Dialogs ----------
  void _addModuleDialog(ThemePreset p) {
    final nameCtl = TextEditingController();
    String selectedColor = _presetColors[0];
    String selectedIcon = '📌';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: p.card,
          title: Text('添加模块', style: TextStyle(color: p.ink)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtl,
                  style: TextStyle(color: p.ink),
                  decoration: InputDecoration(hintText: '模块名称', hintStyle: TextStyle(color: p.ink2)),
                ),
                const SizedBox(height: 12),
                Text('选择颜色', style: TextStyle(color: p.ink2, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _presetColors.map((c) {
                    final col = _parseColor(c);
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDlgState(() => selectedColor = c),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: p.ink, width: 3) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('选择图标', style: TextStyle(color: p.ink2, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _emojiList.map((e) {
                    final isSel = selectedIcon == e;
                    return GestureDetector(
                      onTap: () => setDlgState(() => selectedIcon = e),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSel ? p.pri.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSel ? Border.all(color: p.pri) : null,
                        ),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消', style: TextStyle(color: p.ink2))),
            FilledButton(onPressed: () async {
              if (nameCtl.text.trim().isEmpty) return;
              await AppDatabase.instance.addTodoModule(TodoModule(
                name: nameCtl.text.trim(), color: selectedColor, icon: selectedIcon,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            }, child: const Text('添加')),
          ],
        ),
      ),
    );
  }

  void _addTaskDialog(ThemePreset p, DateTime? presetDate) {
    final titleCtl = TextEditingController();
    DateTime? pickedDate = presetDate;
    int? selectedModuleId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: p.card,
          title: Text('添加任务', style: TextStyle(color: p.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                style: TextStyle(color: p.ink),
                decoration: InputDecoration(hintText: '任务标题', hintStyle: TextStyle(color: p.ink2)),
              ),
              const SizedBox(height: 12),
              // 日期选择
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: pickedDate ?? DateTime.now(),
                    firstDate: DateTime(2024), lastDate: DateTime(2030),
                  );
                  if (d != null) setDlgState(() => pickedDate = d);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Text(
                    pickedDate != null ? fmtDate(pickedDate!) : '选择日期（可选）',
                    style: TextStyle(color: pickedDate != null ? p.ink : p.ink2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 模块选择
              if (_modules.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: selectedModuleId,
                  decoration: InputDecoration(
                    hintText: '选择模块（可选）',
                    hintStyle: TextStyle(color: p.ink2),
                    filled: true, fillColor: p.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: _modules.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Row(children: [Text(m.icon), const SizedBox(width: 6), Text(m.name)]),
                  )).toList(),
                  onChanged: (v) => setDlgState(() => selectedModuleId = v),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消', style: TextStyle(color: p.ink2))),
            FilledButton(onPressed: () async {
              if (titleCtl.text.trim().isEmpty) return;
              await AppDatabase.instance.addTodoTask(TodoTask(
                title: titleCtl.text.trim(),
                moduleId: selectedModuleId,
                date: pickedDate != null ? fmtDate(pickedDate!) : null,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            }, child: const Text('添加')),
          ],
        ),
      ),
    );
  }

  void _deleteModule(TodoModule m, ThemePreset p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        title: Text('删除模块', style: TextStyle(color: p.ink)),
        content: Text('确定要删除「${m.name}」吗？\n模块中的任务不会被删除。', style: TextStyle(color: p.ink2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消', style: TextStyle(color: p.ink2))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await AppDatabase.instance.deleteTodoModule(m.id!);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}