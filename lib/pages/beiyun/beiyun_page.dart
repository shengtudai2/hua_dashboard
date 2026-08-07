import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/beiyun_extra.dart';
import '../../widgets/web_widgets.dart';

/// 备孕工作台 — Web 版设计系统 4 个标签页
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

  // ── 周期 ──
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  List<CycleEvent> _cycleEvents = [];

  // ── 财务 ──
  List<BeiyunFinance> _finances = [];

  // ── 营养 ──
  static const _supplementTypes = ['叶酸', '钙片', '维生素D', '铁剂', 'DHA'];
  List<SupplementLog> _supplementLogs = [];
  String _todayStr = '';

  static const _stageLabels = ['备孕前期', '备孕期', '怀孕期'];
  static const _stageKeys = ['preparation', 'trying', 'pregnant'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ═══════════════════════════════════════════════
  //  TAB 1: 任务
  // ═══════════════════════════════════════════════
  List<BeiyunTask> _tasksForStage(String stage) {
    final filtered = _tasks.where((t) => t.stage == stage).toList();
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

  Future<void> _showAddTask() async {
    final titleCtrl = TextEditingController();
    int stageIdx = 0;
    DateTime pickedDate = DateTime.now();

    await WebBottomSheet.show<void>(
      context,
      title: '添加备孕任务',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WebFormField(
            label: '任务标题',
            required: true,
            child: WebInput(controller: titleCtrl, hint: '例如：补充叶酸'),
          ),
          WebFormField(
            label: '阶段',
            child: Wrap(
              spacing: 8,
              children: List.generate(_stageLabels.length, (i) {
                final active = stageIdx == i;
                return GestureDetector(
                  onTap: () => setState(() => stageIdx = i),
                  child: WebChip(label: _stageLabels[i], active: active),
                );
              }),
            ),
          ),
          WebFormField(
            label: '计划日期',
            child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: pickedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (d != null) pickedDate = d;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: WebTheme.card,
                  border: Border.all(color: WebTheme.line, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: WebTheme.ink2),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(pickedDate),
                      style: const TextStyle(fontSize: 14, color: WebTheme.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '取消',
            ghost: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: WebGradientButton(
            label: '添加',
            icon: Icons.add,
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final task = BeiyunTask(
                title: titleCtrl.text.trim(),
                stage: _stageKeys[stageIdx],
                planDate: _fmt(pickedDate),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              );
              await AppDatabase.instance.addBeiyunTask(task);
              await _loadAll();
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    final hasTasks = _tasks.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: hasTasks
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: List.generate(_stageKeys.length, (i) {
                final stage = _stageKeys[i];
                final stageTasks = _tasksForStage(stage);
                final done = stageTasks.where((t) => t.done).length;
                final progress =
                    stageTasks.isEmpty ? 0.0 : done / stageTasks.length;
                final badgeColor = switch (i) {
                  0 => const Color(0xFF4BA886),
                  1 => WebTheme.pri,
                  _ => const Color(0xFF9678CF),
                };
                final badge = switch (i) {
                  0 => '前期',
                  1 => '备孕',
                  _ => '孕期',
                };
                final subtitle = switch (i) {
                  0 => '孕前3-6个月',
                  1 => '排卵监测',
                  _ => '产检孕程',
                };
                return WebStageGroup(
                  badge: badge,
                  badgeColor: badgeColor,
                  name: _stageLabels[i],
                  subtitle: subtitle,
                  progress: progress,
                  onAdd: _showAddTask,
                  child: stageTasks.isEmpty
                      ? const WebEmptyState(text: '暂无任务，点击 + 添加')
                      : Column(
                          children: stageTasks.map((task) {
                            return WebTaskRow(
                              title: task.title,
                              meta: task.planDate != null
                                  ? '📅 ${task.planDate}'
                                  : null,
                              done: task.done,
                              badge: task.fav ? '★' : null,
                              badgeColor: Colors.amber,
                              onTap: () => _toggleTaskDone(task),
                            );
                          }).toList(),
                        ),
                );
              }),
            )
          : const WebEmptyState(icon: '📋', text: '还没有备孕任务，点击 + 添加'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTask,
        backgroundColor: WebTheme.pri,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 2: 周期
  // ═══════════════════════════════════════════════
  Color _colorForEvent(CycleEventType type) => switch (type) {
        CycleEventType.taboo => Colors.red,
        CycleEventType.period => Colors.pink,
        CycleEventType.ovulation => Colors.purple,
        CycleEventType.fertile => Colors.orange,
        CycleEventType.release => Colors.green,
        CycleEventType.due => Colors.blue,
      };

  String _labelForEventType(CycleEventType type) => switch (type) {
        CycleEventType.taboo => '禁忌',
        CycleEventType.period => '经期',
        CycleEventType.ovulation => '排卵',
        CycleEventType.fertile => '易孕',
        CycleEventType.release => '解禁',
        CycleEventType.due => '到期',
      };

  List<CycleEvent> _eventsForDay(DateTime day) {
    final ds = _fmt(day);
    return _cycleEvents.where((e) => e.date == ds).toList();
  }

  Future<void> _showAddCycleEvent() async {
    DateTime pickedDate = _selectedDay;
    CycleEventType pickedType = CycleEventType.period;
    final noteCtrl = TextEditingController();

    await WebBottomSheet.show<void>(
      context,
      title: '添加周期事件',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WebFormField(
            label: '日期',
            child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: pickedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => pickedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: WebTheme.card,
                  border: Border.all(color: WebTheme.line, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: WebTheme.ink2),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(pickedDate),
                      style: const TextStyle(fontSize: 14, color: WebTheme.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          WebFormField(
            label: '类型',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CycleEventType.values.map((t) {
                final active = pickedType == t;
                return GestureDetector(
                  onTap: () => setState(() => pickedType = t),
                  child: WebChip(
                    label: _labelForEventType(t),
                    active: active,
                  ),
                );
              }).toList(),
            ),
          ),
          WebFormField(
            label: '备注',
            child: WebInput(controller: noteCtrl, hint: '可填写备注（可选）'),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '取消',
            ghost: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: WebGradientButton(
            label: '添加',
            icon: Icons.add,
            onPressed: () async {
              final event = CycleEvent(
                date: _fmt(pickedDate),
                type: pickedType,
                note: noteCtrl.text.trim(),
              );
              final id = await AppDatabase.instance.addCycleEvent(event);
              setState(() => _cycleEvents.add(CycleEvent(
                    id: id,
                    date: _fmt(pickedDate),
                    type: pickedType,
                    note: noteCtrl.text.trim(),
                  )));
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ],
    );
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          WebCard(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<CycleEvent>(
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              calendarFormat: _format,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onFormatChanged: (f) => setState(() => _format = f),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) => _focusedDay = focused,
              eventLoader: (day) => _eventsForDay(day),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: WebTheme.priSoft,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: WebTheme.pri,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: WebTheme.pri,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonTextStyle:
                    TextStyle(color: WebTheme.priDeep, fontSize: 12),
                formatButtonDecoration: BoxDecoration(
                  color: WebTheme.bg2,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ..._eventsForDay(_selectedDay).map((e) {
            return WebTaskRow(
              title: _labelForEventType(e.type),
              meta: e.note.isEmpty ? null : e.note,
              badge: _fmt(DateTime.parse(e.date)),
              badgeColor: _colorForEvent(e.type),
              onTap: () => _deleteCycleEvent(e),
            );
          }),
          if (_eventsForDay(_selectedDay).isEmpty)
            const WebEmptyState(text: '这一天还没有周期事件，点击 + 添加'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCycleEvent,
        backgroundColor: WebTheme.pri,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 3: 财务
  // ═══════════════════════════════════════════════
  Future<void> _showAddFinance() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();
    final categoryCtrl = TextEditingController(text: '一般');

    await WebBottomSheet.show<void>(
      context,
      title: '添加财务记录',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WebFormField(
            label: '金额',
            required: true,
            child: WebInput(
              controller: amountCtrl,
              hint: '例如：120.50',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          WebFormField(
            label: '分类',
            child: WebInput(controller: categoryCtrl, hint: '例如：检查、药品'),
          ),
          WebFormField(
            label: '日期',
            child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: pickedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (d != null) pickedDate = d;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: WebTheme.card,
                  border: Border.all(color: WebTheme.line, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: WebTheme.ink2),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(pickedDate),
                      style: const TextStyle(fontSize: 14, color: WebTheme.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          WebFormField(
            label: '备注',
            child: WebInput(controller: noteCtrl, hint: '可填写备注（可选）'),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: WebGradientButton(
            label: '取消',
            ghost: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: WebGradientButton(
            label: '添加',
            icon: Icons.add,
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount < 0) return;
              final rec = BeiyunFinance(
                amount: amount,
                date: _fmt(pickedDate),
                note: noteCtrl.text.trim(),
                category: categoryCtrl.text.trim().isEmpty
                    ? '一般'
                    : categoryCtrl.text.trim(),
              );
              await AppDatabase.instance.addBeiyunFinance(rec);
              await _loadAll();
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteFinance(BeiyunFinance f) async {
    if (f.id == null) return;
    await AppDatabase.instance.deleteBeiyunFinance(f.id!);
    setState(() => _finances.remove(f));
  }

  Widget _buildFinanceTab() {
    final total = _finances.fold<double>(0, (s, f) => s + f.amount);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          WebCard(
            child: Column(
              children: [
                const Text('总支出', style: TextStyle(fontSize: 12, color: WebTheme.ink2)),
                const SizedBox(height: 4),
                Text(
                  '¥${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'ZCOOL KuaiLe',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_finances.isEmpty)
            const WebEmptyState(icon: '💰', text: '还没有财务记录，点击 + 添加')
          else
            ..._finances.map((f) {
              return WebTaskRow(
                title: '¥${f.amount.toStringAsFixed(2)}',
                meta: f.note.isEmpty ? null : f.note,
                badge: '${f.category} · ${f.date}',
                badgeColor: WebTheme.accent,
                onTap: () => _deleteFinance(f),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFinance,
        backgroundColor: WebTheme.pri,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 4: 营养
  // ═══════════════════════════════════════════════
  bool _supplementDone(String type) {
    final today = _supplementLogs
        .where((l) => l.date == _todayStr && l.type == type)
        .toList();
    if (today.isEmpty) return false;
    return today.last.done;
  }

  Future<void> _toggleSupplement(String type, bool done) async {
    await AppDatabase.instance.addSupplementLog(
      SupplementLog(date: _todayStr, type: type, done: done),
    );
    await _loadAll();
  }

  Widget _buildNutritionTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          WebCard(
            child: Column(
              children: [
                const Text('今日营养打卡', style: TextStyle(
                  fontFamily: 'ZCOOL KuaiLe',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.ink,
                )),
                const SizedBox(height: 4),
                Text(_todayStr, style: const TextStyle(
                  fontSize: 11,
                  color: WebTheme.ink2,
                )),
              ],
            ),
          ),
          const SizedBox(height: 4),
          WebCard(
            child: Column(
              children: List.generate(_supplementTypes.length, (i) {
                final type = _supplementTypes[i];
                final done = _supplementDone(type);
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1, color: WebTheme.line),
                    _buildSupplementRow(type, done),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementRow(String type, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? WebTheme.accent : WebTheme.card,
              border: Border.all(
                color: done ? WebTheme.accent : WebTheme.line,
                width: 2,
              ),
            ),
            child: done
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: done ? WebTheme.ink2 : WebTheme.ink,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Switch(
            value: done,
            activeColor: WebTheme.accent,
            onChanged: (v) => _toggleSupplement(type, v),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  主布局
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.bg,
      appBar: AppBar(
        backgroundColor: WebTheme.bg,
        elevation: 0,
        leading: const DrawerMenuButton(),
        title: const Text(
          '备孕工作台',
          style: TextStyle(
            fontFamily: 'ZCOOL KuaiLe',
            fontSize: 20,
            color: WebTheme.ink,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: WebTheme.priDeep,
          unselectedLabelColor: WebTheme.ink2,
          indicatorColor: WebTheme.pri,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'ZCOOL KuaiLe',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: '任务'),
            Tab(text: '周期'),
            Tab(text: '财务'),
            Tab(text: '营养'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTasksTab(),
          _buildCycleTab(),
          _buildFinanceTab(),
          _buildNutritionTab(),
        ],
      ),
    );
  }
}