import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/beiyun_extra.dart';
import '../../main.dart';

/// 备孕工作台 — 4 个标签页
class BeiyunPage extends StatefulWidget {
  const BeiyunPage({super.key});

  @override
  State<BeiyunPage> createState() => _BeiyunPageState();
}

class _BeiyunPageState extends State<BeiyunPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── 任务 ──
  List<BeiyunTask> _tasks = [];
  final Set<int> _expandedStages = {0};

  // ── 周期 ──
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  List<CycleEvent> _cycleEvents = [];

  // ── 财务 ──
  List<BeiyunFinance> _finances = [];

  // ── 营养 ──
  final List<String> _supplementTypes = ['叶酸', '钙片', '维生素D', '铁剂', 'DHA'];
  List<SupplementLog> _supplementLogs = [];
  String _todayStr = '';

  static const _stageLabels = ['备孕前期', '备孕期', '怀孕期'];
  static const _stageKeys = ['preparation', 'trying', 'pregnant'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _todayStr = todayStr();
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final db = AppDatabase.instance;
    final tasks = await db.getBeiyunTasks();
    final events = await db.getCycleEvents();
    final finances = await db.getBeiyunFinance();
    final logs = await db.getSupplementLogs();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _cycleEvents = events;
        _finances = finances;
        _supplementLogs = logs;
      });
    }
  }

  // ═══════════════════════════════════════════
  //  TAB 1: 任务
  // ═══════════════════════════════════════════

  List<BeiyunTask> _tasksForStage(String stage) {
    final filtered = _tasks.where((t) => t.stage == stage).toList();
    // 排序：置顶优先 > 有 planDate 的优先 > 按 created_at 降序
    filtered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.planDate != null && b.planDate != null) {
        return a.planDate!.compareTo(b.planDate!);
      }
      if (a.planDate != null) return -1;
      if (b.planDate != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  Future<void> _toggleTaskDone(BeiyunTask task) async {
    task.done = !task.done;
    await AppDatabase.instance.updateBeiyunTask(task);
    setState(() {});
  }

  Future<void> _toggleTaskFav(BeiyunTask task) async {
    task.fav = !task.fav;
    await AppDatabase.instance.updateBeiyunTask(task);
    setState(() {});
  }

  Future<void> _deleteTask(BeiyunTask task) async {
    if (task.id == null) return;
    await AppDatabase.instance.deleteBeiyunTask(task.id!);
    setState(() => _tasks.remove(task));
  }

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    int stageIdx = 0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('添加任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '任务标题'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: stageIdx,
                decoration: const InputDecoration(labelText: '阶段'),
                items: _stageLabels
                    .asMap()
                    .entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setD(() => stageIdx = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: '计划日期 (可选)',
                  hintText: 'yyyy-MM-dd',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'title': titleCtrl.text.trim(),
                  'stage': _stageKeys[stageIdx],
                  'planDate': dateCtrl.text.trim().isEmpty
                      ? null
                      : dateCtrl.text.trim(),
                });
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final task = BeiyunTask(
      title: result['title'],
      stage: result['stage'],
      planDate: result['planDate'],
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await AppDatabase.instance.addBeiyunTask(task);
    _loadAll();
  }

  Widget _buildTasksTab() {
    final p = context.watch<ThemeProvider>().preset;
    final hasTasks = _tasks.isNotEmpty;

    if (!hasTasks) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: EmptyState(icon: '📋', text: '还没有备孕任务，点击 + 添加'),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: List.generate(_stageKeys.length, (i) {
          final stage = _stageKeys[i];
          final stageTasks = _tasksForStage(stage);
          final isExpanded = _expandedStages.contains(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedStages.remove(i);
                        } else {
                          _expandedStages.add(i);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: p.ink2,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _stageLabels[i],
                            style: TextStyle(
                              color: p.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.pri.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${stageTasks.length}',
                              style: TextStyle(
                                  color: p.pri, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded && stageTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        '暂无任务',
                        style: TextStyle(color: p.ink2, fontSize: 13),
                      ),
                    ),
                  if (isExpanded)
                    ...stageTasks.map((task) => _buildTaskRow(task, p)),
                ],
              ),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskRow(BeiyunTask task, ThemePreset p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () => _deleteTask(task),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.done,
                    onChanged: (_) => _toggleTaskDone(task),
                    activeColor: p.pri,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.done ? p.ink2 : p.ink,
                          fontSize: 14,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.planDate != null)
                        Text(
                          '📅 ${task.planDate}',
                          style: TextStyle(
                              color: p.ink2, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleTaskFav(task),
                  child: Icon(
                    task.fav ? Icons.star : Icons.star_border,
                    color: task.fav ? Colors.amber : p.ink2,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 2: 周期
  // ═══════════════════════════════════════════

  Color _colorForEvent(CycleEventType type) {
    switch (type) {
      case CycleEventType.taboo:
        return Colors.red;
      case CycleEventType.period:
        return Colors.pink;
      case CycleEventType.ovulation:
        return Colors.purple;
      case CycleEventType.fertile:
        return Colors.orange;
      case CycleEventType.release:
        return Colors.green;
      case CycleEventType.due:
        return Colors.blue;
    }
  }

  String _labelForEventType(CycleEventType type) {
    switch (type) {
      case CycleEventType.taboo:
        return '禁忌';
      case CycleEventType.period:
        return '经期';
      case CycleEventType.ovulation:
        return '排卵';
      case CycleEventType.fertile:
        return '易孕';
      case CycleEventType.release:
        return '解禁';
      case CycleEventType.due:
        return '到期';
    }
  }

  List<CycleEvent> _eventsForDay(DateTime day) {
    final ds = fmtDate(day);
    return _cycleEvents.where((e) => e.date == ds).toList();
  }

  Future<void> _showAddCycleEventDialog() async {
    DateTime pickedDate = _selectedDay;
    CycleEventType pickedType = CycleEventType.period;
    final noteCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('添加周期事件'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: pickedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setD(() => pickedDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '日期'),
                  child: Text(DateFormat('yyyy-MM-dd').format(pickedDate)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CycleEventType>(
                value: pickedType,
                decoration: const InputDecoration(labelText: '类型'),
                items: CycleEventType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _colorForEvent(t),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_labelForEventType(t)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setD(() => pickedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: '备注 (可选)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, {
                  'date': fmtDate(pickedDate),
                  'type': pickedType,
                  'note': noteCtrl.text.trim(),
                });
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final event = CycleEvent(
      date: result['date'],
      type: result['type'],
      note: result['note'] ?? '',
    );
    final id = await AppDatabase.instance.addCycleEvent(event);
    // 赋值 id 以便删除
    final newEvent = CycleEvent(
      id: id,
      date: result['date'],
      type: result['type'],
      note: result['note'] ?? '',
    );
    setState(() => _cycleEvents.add(newEvent));
  }

  Future<void> _deleteCycleEvent(CycleEvent event) async {
    if (event.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除事件'),
        content: Text('删除 ${_labelForEventType(event.type)} 事件？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteCycleEvent(event.id!);
    setState(() => _cycleEvents.remove(event));
  }

  Widget _buildCycleTab() {
    final p = context.watch<ThemeProvider>().preset;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AppCard(
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
                weekendTextStyle:
                    TextStyle(color: p.ink.withValues(alpha: 0.6)),
                outsideTextStyle:
                    TextStyle(color: p.ink2.withValues(alpha: 0.3)),
                markerDecoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) {
                final dayEvents = _eventsForDay(day);
                return dayEvents.map((e) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _colorForEvent(e.type),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  DateFormat('M月d日', 'zh_CN').format(_selectedDay),
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE', 'zh_CN').format(_selectedDay),
                  style: TextStyle(color: p.ink2, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _buildDayEventsList(p),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCycleEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayEventsList(ThemePreset p) {
    final events = _eventsForDay(_selectedDay);
    if (events.isEmpty) {
      return EmptyState(icon: '📅', text: '这天没有事件');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => _deleteCycleEvent(e),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colorForEvent(e.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _labelForEventType(e.type),
                    style: TextStyle(
                      color: p.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (e.note.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.note,
                        style: TextStyle(color: p.ink2, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.delete_outline,
                      size: 18, color: p.ink2.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 3: 财务
  // ═══════════════════════════════════════════

  double get _totalFinance =>
      _finances.fold(0.0, (sum, f) => sum + f.amount);

  Future<void> _showAddFinanceDialog() async {
    DateTime pickedDate = DateTime.now();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('添加财务记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: pickedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setD(() => pickedDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '日期'),
                  child: Text(DateFormat('yyyy-MM-dd').format(pickedDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '金额'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(
                  labelText: '分类',
                  hintText: '如：检查、药品、营养品',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: '备注 (可选)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;
                Navigator.pop(ctx, {
                  'date': fmtDate(pickedDate),
                  'amount': amount,
                  'category': categoryCtrl.text.trim().isEmpty
                      ? '一般'
                      : categoryCtrl.text.trim(),
                  'note': noteCtrl.text.trim(),
                });
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final finance = BeiyunFinance(
      amount: result['amount'],
      date: result['date'],
      category: result['category'],
      note: result['note'] ?? '',
    );
    await AppDatabase.instance.addBeiyunFinance(finance);
    _loadAll();
  }

  Future<void> _deleteFinance(BeiyunFinance f) async {
    if (f.id == null) return;
    await AppDatabase.instance.deleteBeiyunFinance(f.id!);
    setState(() => _finances.remove(f));
  }

  Widget _buildFinanceTab() {
    final p = context.watch<ThemeProvider>().preset;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AppCard(
            child: Row(
              children: [
                Text('💰 总支出',
                    style: TextStyle(color: p.ink2, fontSize: 14)),
                const Spacer(),
                Text(
                  '¥${fmtMoney(_totalFinance)}',
                  style: TextStyle(
                    color: p.pri,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Baloo 2',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _finances.isEmpty
                ? EmptyState(icon: '💰', text: '还没有财务记录')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _finances.length,
                    itemBuilder: (_, i) {
                      final f = _finances[i];
                      return Dismissible(
                        key: ValueKey(f.id ?? i),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteFinance(f),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.category,
                                        style: TextStyle(
                                          color: p.ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${f.date}${f.note.isNotEmpty ? ' · ${f.note}' : ''}',
                                        style: TextStyle(
                                          color: p.ink2,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '¥${fmtMoney(f.amount)}',
                                  style: TextStyle(
                                    color: p.pri,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Baloo 2',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFinanceDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 4: 营养
  // ═══════════════════════════════════════════

  bool _isSupplementDone(String type) {
    return _supplementLogs
        .any((l) => l.date == _todayStr && l.type == type && l.done);
  }

  Future<void> _toggleSupplement(String type, bool value) async {
    // 如果已有记录，更新；否则插入
    final existing = _supplementLogs.where(
        (l) => l.date == _todayStr && l.type == type);
    if (existing.isNotEmpty) {
      final log = existing.first;
      await AppDatabase.instance.update(
        'supplement_logs',
        {'done': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [log.id],
      );
    } else {
      await AppDatabase.instance.addSupplementLog(SupplementLog(
        date: _todayStr,
        type: type,
        done: value,
      ));
    }
    _loadAll();
  }

  Widget _buildSupplementsTab() {
    final p = context.watch<ThemeProvider>().preset;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '今日打卡 · $_todayStr',
              style: TextStyle(
                color: p.ink2,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: _supplementTypes.isEmpty
                ? EmptyState(icon: '💊', text: '暂无营养品类')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _supplementTypes.length,
                    itemBuilder: (_, i) {
                      final type = _supplementTypes[i];
                      final done = _isSupplementDone(type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: done
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : p.pri.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _supplementIcon(type),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: done ? p.ink2 : p.ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              Switch(
                                value: done,
                                onChanged: (v) => _toggleSupplement(type, v),
                                activeColor: Colors.green,
                              ),
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

  String _supplementIcon(String type) {
    switch (type) {
      case '叶酸':
        return '🌿';
      case '钙片':
        return '🦴';
      case '维生素D':
        return '☀️';
      case '铁剂':
        return '🩸';
      case 'DHA':
        return '🧠';
      default:
        return '💊';
    }
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().preset;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('备孕工作台'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: p.pri.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: p.pri,
              unselectedLabelColor: p.ink2,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: '📋 任务'),
                Tab(text: '📅 周期'),
                Tab(text: '💰 财务'),
                Tab(text: '💊 营养'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTasksTab(),
          _buildCycleTab(),
          _buildFinanceTab(),
          _buildSupplementsTab(),
        ],
      ),
    );
  }
}