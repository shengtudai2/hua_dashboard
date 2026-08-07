import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../database/database_helper.dart';
import '../../models/todo.dart';
import '../../widgets/web_widgets.dart';
import '../../widgets/common.dart';

const _emojiList = [
  '📌', '📝', '📋', '✅', '🎯', '⭐', '❤️', '🔥', '💪',
  '📅', '🎉', '💡', '🏠', '🛒', '📚', '💼', '🏃', '🎨', '📷', '✈️',
];

const _moduleColors = [
  WebTheme.evRed,
  WebTheme.evPink,
  WebTheme.evGold,
  WebTheme.evPurple,
  WebTheme.evGreen,
  WebTheme.evBlue,
  WebTheme.evOrange,
  WebTheme.pri,
];

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage>
    with SingleTickerProviderStateMixin {
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
    if (mounted) {
      setState(() {
        _modules = modules;
        _tasks = tasks;
      });
    }
  }

  String _colorToHex(Color c) {
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#$r$g$b';
}

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  List<TodoTask> _filteredTasks() {
    var list = _tasks
        .where((t) => _filterModuleId == null || t.moduleId == _filterModuleId)
        .toList();
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

  int _taskCount(int modId) =>
      _tasks.where((t) => t.moduleId == modId).length;

  int _completedToday() =>
      _tasks.where((t) => t.done && t.date == todayStr()).length;

  int _weekDone() {
    final ws =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final we = ws.add(const Duration(days: 7));
    return _tasks.where((t) {
      if (t.date == null) return false;
      final d = parseDate(t.date!);
      return d != null && !d.isBefore(ws) && d.isBefore(we) && t.done;
    }).length;
  }

  int _weekTotal() {
    final ws =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
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
    return Scaffold(
      backgroundColor: WebTheme.bg,
      appBar: AppBar(
        backgroundColor: WebTheme.bg,
        elevation: 0,
        leading: const DrawerMenuButton(),
        title: const Text(
          '事项管理',
          style: TextStyle(
            fontFamily: 'ZCOOL KuaiLe',
            fontSize: 20,
            color: WebTheme.ink,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WebTheme.pri,
          labelColor: WebTheme.pri,
          unselectedLabelColor: WebTheme.ink2,
          tabs: const [
            Tab(text: '📋 模块'),
            Tab(text: '✅ 任务'),
            Tab(text: '📅 日历'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildModules(), _buildTasks(), _buildCalendar()],
      ),
    );
  }

  // ==================== Tab 1: 模块 ====================
  Widget _buildModules() {
    final wt = _weekTotal();
    final wd = _weekDone();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: WebTheme.pri,
        foregroundColor: Colors.white,
        onPressed: _addModuleSheet,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            WebStatsGrid(items: [
              WebStatItem('${_modules.length}', '模块'),
              WebStatItem('${_tasks.length}', '总任务'),
              WebStatItem('${_completedToday()}', '今日完成'),
              WebStatItem(
                  wt == 0 ? '0%' : '${(wd * 100 / wt).round()}%', '本周完成'),
            ]),
            ..._modules.map((m) => _buildModuleCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(TodoModule m) {
    final color = _parseColor(m.color);
    return WebCard(
      onTap: () {
        _filterModuleId = m.id;
        _tabController.animateTo(1);
      },
      child: InkWell(
        onLongPress: () => _deleteModule(m),
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(m.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                m.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.ink,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_taskCount(m.id ?? 0)} 项',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Tab 2: 任务 ====================
  Widget _buildTasks() {
    final filtered = _filteredTasks();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: WebTheme.pri,
        foregroundColor: Colors.white,
        onPressed: () => _addTaskSheet(null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                WebChip(
                  label: '全部',
                  active: _filterModuleId == null,
                  onTap: () => setState(() => _filterModuleId = null),
                ),
                ..._modules.map((m) => WebChip(
                      label: m.name,
                      active: _filterModuleId == m.id,
                      onTap: () =>
                          setState(() => _filterModuleId = m.id),
                    )),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const WebEmptyState(icon: '✅', text: '没有任务')
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          _buildTaskItem(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TodoTask t) {
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: WebTheme.danger.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(WebTheme.rCard),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await AppDatabase.instance.deleteTodoTask(t.id!);
        await _loadData();
        if (mounted) {
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
        }
      },
      child: GestureDetector(
        onLongPress: () async {
          await AppDatabase.instance
              .updateTodoTask(t.copyWith(pinned: !t.pinned));
          _loadData();
        },
        child: WebTaskRow(
          title: t.title,
          done: t.done,
          badge: t.date?.substring(5),
          badgeColor: WebTheme.pri,
          meta: t.pinned ? '📌 已置顶' : null,
          onTap: () async {
            await AppDatabase.instance
                .updateTodoTask(t.copyWith(done: !t.done));
            _loadData();
          },
        ),
      ),
    );
  }

  // ==================== Tab 3: 日历 ====================
  Widget _buildCalendar() {
    final dayTasks = _tasksOnDay(_calSelected);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: WebTheme.pri,
        foregroundColor: Colors.white,
        onPressed: () => _addTaskSheet(_calSelected),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          WebCard(
            padding: const EdgeInsets.all(10),
            child: TableCalendar(
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              focusedDay: _calFocused,
              selectedDayPredicate: (d) => isSameDay(_calSelected, d),
              calendarFormat: _calFormat,
              onFormatChanged: (f) => setState(() => _calFormat = f),
              onDaySelected: (s, f) =>
                  setState(() { _calSelected = s; _calFocused = f; }),
              onPageChanged: (f) => _calFocused = f,
              locale: 'zh_CN',
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: WebTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: WebTheme.pri),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: WebTheme.pri),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Color(0x33E8638C),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: WebTheme.pri,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                defaultTextStyle: const TextStyle(color: WebTheme.ink),
                weekendTextStyle:
                    const TextStyle(color: Color(0x996A2B36)),
                outsideTextStyle:
                    const TextStyle(color: Color(0x4D9A7383)),
              ),
              eventLoader: (day) =>
                  _taskDateSet().contains(
                          DateTime(day.year, day.month, day.day))
                      ? [
                          const _CalendarDot(),
                        ]
                      : [],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('M月d日 EEEE', 'zh_CN')
                      .format(_calSelected),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dayTasks.length} 项',
                  style: const TextStyle(
                      fontSize: 13, color: WebTheme.ink2),
                ),
              ],
            ),
          ),
          Expanded(
            child: dayTasks.isEmpty
                ? const WebEmptyState(icon: '📅', text: '这天没有任务')
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: dayTasks.length,
                    itemBuilder: (_, i) =>
                        _buildDayTaskItem(dayTasks[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTaskItem(TodoTask t) {
    return WebCard(
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await AppDatabase.instance
                  .updateTodoTask(t.copyWith(done: !t.done));
              _loadData();
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.done ? WebTheme.accent : WebTheme.card,
                border: Border.all(
                  color: t.done ? WebTheme.accent : WebTheme.pri,
                  width: 2,
                ),
              ),
              child: t.done
                  ? const Icon(Icons.check,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.done ? WebTheme.ink2 : WebTheme.ink,
                decoration: t.done
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Bottom Sheets ====================
  void _addModuleSheet() {
    final nameCtl = TextEditingController();
    Color selectedColor = _moduleColors[0];
    String selectedIcon = '📌';

    WebBottomSheet.show(
      context,
      title: '添加模块',
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '取消',
            ghost: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: WebGradientButton(
            label: '添加',
            onPressed: () async {
              if (nameCtl.text.trim().isEmpty) return;
              await AppDatabase.instance.addTodoModule(TodoModule(
                name: nameCtl.text.trim(),
                color: _colorToHex(selectedColor),
                icon: selectedIcon,
              ));
              if (mounted) Navigator.pop(context);
              _loadData();
            },
          ),
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setDlgState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebFormField(
              label: '模块名称',
              required: true,
              child:
                  WebInput(controller: nameCtl, hint: '输入模块名称'),
            ),
            const SizedBox(height: 8),
            const Text(
              '选择颜色',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebTheme.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _moduleColors.map((c) {
                final isSel = selectedColor == c;
                return GestureDetector(
                  onTap: () =>
                      setDlgState(() => selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSel
                          ? Border.all(
                              color: WebTheme.ink, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              '选择图标',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebTheme.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojiList.map((e) {
                final isSel = selectedIcon == e;
                return GestureDetector(
                  onTap: () =>
                      setDlgState(() => selectedIcon = e),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSel
                          ? WebTheme.pri.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSel
                          ? Border.all(color: WebTheme.pri)
                          : null,
                    ),
                    child: Center(
                      child: Text(e,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _addTaskSheet(DateTime? presetDate) {
    final titleCtl = TextEditingController();
    DateTime? pickedDate = presetDate;
    int? selectedModuleId;

    WebBottomSheet.show(
      context,
      title: '添加任务',
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '取消',
            ghost: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: WebGradientButton(
            label: '添加',
            onPressed: () async {
              if (titleCtl.text.trim().isEmpty) return;
              await AppDatabase.instance.addTodoTask(TodoTask(
                title: titleCtl.text.trim(),
                moduleId: selectedModuleId,
                date: pickedDate != null
                    ? fmtDate(pickedDate!)
                    : null,
              ));
              if (mounted) Navigator.pop(context);
              _loadData();
            },
          ),
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setDlgState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebFormField(
              label: '任务标题',
              required: true,
              child:
                  WebInput(controller: titleCtl, hint: '输入任务标题'),
            ),
            const SizedBox(height: 8),
            const Text(
              '计划日期',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebTheme.ink2,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: pickedDate ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (d != null) {
                  setDlgState(() => pickedDate = d);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: WebTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: WebTheme.line, width: 1.5),
                ),
                child: Text(
                  pickedDate != null
                      ? fmtDate(pickedDate!)
                      : '选择日期（可选）',
                  style: TextStyle(
                    color: pickedDate != null
                        ? WebTheme.ink
                        : WebTheme.ink2,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_modules.isNotEmpty) ...[
              const Text(
                '所属模块',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.ink2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: WebTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: WebTheme.line, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedModuleId,
                    hint: const Text(
                      '选择模块（可选）',
                      style: TextStyle(
                          color: WebTheme.ink2, fontSize: 14),
                    ),
                    isExpanded: true,
                    items: _modules.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Row(children: [
                        Text(m.icon,
                            style:
                                const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: WebTheme.ink,
                          ),
                        ),
                      ]),
                    )).toList(),
                    onChanged: (v) =>
                        setDlgState(() => selectedModuleId = v),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _deleteModule(TodoModule m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WebTheme.card,
        title: const Text(
          '删除模块',
          style: TextStyle(color: WebTheme.ink),
        ),
        content: Text(
          '确定要删除「${m.name}」吗？\n模块中的任务不会被删除。',
          style: const TextStyle(color: WebTheme.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: WebTheme.ink2),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: WebTheme.danger),
            onPressed: () async {
              await AppDatabase.instance
                  .deleteTodoModule(m.id!);
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

/// Tiny calendar dot widget.
class _CalendarDot extends StatelessWidget {
  const _CalendarDot();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 6,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WebTheme.priDeep,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}