import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/beiyun_extra.dart';
import '../../main.dart';
import 'finance_page.dart';
import 'cycle_page.dart';
import 'supplement_page.dart';
import 'links_page.dart';
import 'taboo_page.dart';
import 'beiyun_logic.dart';

/// 备孕工作台 — 完整还原 Web 版（5 Tab + 子页面）
class BeiyunPage extends StatefulWidget {
  const BeiyunPage({super.key});

  @override
  State<BeiyunPage> createState() => _BeiyunPageState();
}

class _BeiyunPageState extends State<BeiyunPage> {
  // ── Tab state ──
  int _currentTab = 0;

  // ── Data ──
  List<BeiyunTask> _tasks = [];
  List<CycleEvent> _cycleEvents = [];
  List<BeiyunFinance> _finances = [];
  String? _targetDate; // 备孕目标起始日
  String? _pregnantDate; // 确认怀孕日期

  // ── Calendar state ──
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  // ── Task filter state ──
  String _stageFilter = '全部';
  String _statusFilter = '全部';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Time filter (今日 tab) ──
  String _timeFilter = '今日';

  // ── Colors ──
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color orange = Color(0xFFF5A623);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color pinkBg = Color(0xFFFFE4E9);
  static const Color textDark = Color(0xFF333333);
  static const Color textGray = Color(0xFF999999);
  static const Color redBadge = Color(0xFFE64A4A);
  static const Color greenBadge = Color(0xFF7ED321);
  static const Color blueText = Color(0xFF54A0FF);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = AppDatabase.instance;
    final tasks = await db.getBeiyunTasks();
    final events = await db.getCycleEvents();
    final finances = await db.getBeiyunFinance();
    final settings = await db.getSettings();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _cycleEvents = events;
        _finances = finances;
        _targetDate = settings['target_date'] as String?;
        _pregnantDate = settings['pregnant_date'] as String?;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  AppBar
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr = '${now.month}月${now.day}日 · ${weekdays[now.weekday - 1]}';
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              // Menu button 32x32
              GestureDetector(
                onTap: () => appDrawerKey.currentState?.openDrawer(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu, size: 18, color: orange),
                ),
              ),
              const SizedBox(width: 8),
              // 36x36 orange rounded-square with "孕"
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: Text('孕',
                      style: TextStyle(
                        fontFamily: 'ZCOOL KuaiLe',
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
              const SizedBox(width: 10),
              // Title + subtitle
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('备孕工作台',
                      style: TextStyle(
                        fontFamily: 'ZCOOL KuaiLe',
                        fontSize: 18,
                        color: textDark,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('深圳 · 好孕规划',
                      style: TextStyle(fontSize: 11, color: textGray)),
                ],
              ),
              const Spacer(),
              // Date capsule
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Body router
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildTodayTab();
      case 1:
        return _buildCalendarTab();
      case 3:
        return _buildTasksTab();
      case 4:
        return _buildProfileTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1: 今日
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
      child: Column(
        children: [
          _buildTimeFilter(),
          const SizedBox(height: 12),
          _buildHeroCard(),
          const SizedBox(height: 12),
          _buildStatsCard(),
          const SizedBox(height: 12),
          _buildTodoCard(),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    const filters = ['今日', '1月', '3月', '自定'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = _timeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _timeFilter = f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? orange : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: selected ? orange : const Color(0xFFE0E0E0)),
                ),
                child: Text(f,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : textDark,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCard() {
    final stage = computeStage(_targetDate, _pregnantDate);
    final countdown = stage.days != null ? '${stage.days}' : (stage.week != null ? '${stage.week}' : '--');
    final countLabel = stage.key == BeiyunStage.preg ? '已孕周数' : '距目标日(天)';
    final targetDisplay = _targetDate != null ? '目标日 ${fmtDate(_targetDate)}' : '目标日 未设置';
    // 计算标签状态
    String statusLabel = '可备孕';
    if (stage.key == BeiyunStage.preg) statusLabel = '孕期';
    for (final t in _tasks) {
      if (t.done || t.startDate == null) continue;
      final st = computeTaskStatus(t, todayStr());
      if (st == TaskStatus.doing || st == TaskStatus.waiting) {
        statusLabel = '禁忌期';
        break;
      }
    }

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
      child: Stack(
        children: [
          // Top-right decorative circle
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: lightOrange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Left: title + subtitles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stage.name,
                            style: const TextStyle(
                              fontFamily: 'ZCOOL KuaiLe',
                              fontSize: 22,
                              color: textDark,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 4),
                        Text(stage.sub,
                            style: const TextStyle(fontSize: 12, color: textGray)),
                        const SizedBox(height: 2),
                        Text(targetDisplay,
                            style: const TextStyle(fontSize: 12, color: textGray)),
                      ],
                    ),
                  ),
                  // Right: big number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(countdown,
                          style: TextStyle(
                            fontFamily: 'ZCOOL KuaiLe',
                            fontSize: 36,
                            color: orange,
                            fontWeight: FontWeight.w700,
                                                      )),
                                                  Text(countLabel,
                                                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                                                ],
                                              ),
                                            ],
                                          ),
              const SizedBox(height: 12),
              // Bottom tags row
              Row(
                children: [
                  // 状态 tag (orange dot + text, orange bg)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightOrange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 6, color: orange),
                        const SizedBox(width: 4),
                        Text(statusLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: orange,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 解禁还剩 (pink bg) - 计算最早解禁天数
                  _buildReleaseTag(),
                  const Spacer(),
                  const Text('查看任务 >',
                      style: TextStyle(
                        fontSize: 12,
                        color: orange,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 计算最早解禁天数标签
  Widget _buildReleaseTag() {
    final today = todayStr();
    int? minDays;
    for (final t in _tasks) {
      if (t.done || t.startDate == null) continue;
      final st = computeTaskStatus(t, today);
      if (st == TaskStatus.waiting) {
        final rel = computeReleaseDate(t);
        if (rel != null) {
          final days = diffDays(today, '${rel.year}-${rel.month.toString().padLeft(2, '0')}-${rel.day.toString().padLeft(2, '0')}');
          if (minDays == null || days < minDays) minDays = days;
        }
      }
    }
    if (minDays == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pinkBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('解禁还剩 $minDays 天',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFE64A4A),
            fontWeight: FontWeight.w600,
          )),
    );
  }

  Widget _buildStatsCard() {
    final today = todayStr();
    // 解禁：等待解禁的任务数
    final waitingCount = _tasks.where((t) =>
        !t.done && t.startDate != null &&
        computeTaskStatus(t, today) == TaskStatus.waiting).length;
    // 必做：当前阶段任务完成进度
    final stage = computeStage(_targetDate, _pregnantDate);
    final curStage = stage.key == BeiyunStage.pre ? 'preparation'
        : (stage.key == BeiyunStage.preg ? 'pregnant' : 'trying');
    final scope = _tasks.where((t) => t.stage == curStage).toList();
    final mustScope = scope.where((t) => t.pinned).toList();
    final doneCount = mustScope.where((t) =>
        computeTaskStatus(t, today) == TaskStatus.done).length;
    final rate = mustScope.isNotEmpty ? (doneCount * 100 / mustScope.length).round() : 0;
    // 花费
    final totalSpent = _finances.fold<double>(0, (s, f) => s + f.amount);
    final spentStr = moneyK(totalSpent);
    // 经期（阶段非 pre 时显示）
    final pred = predictCycle(_cycleEvents, null, null);
    final cycleCount = _cycleEvents.where((e) => e.type == CycleEventType.period).length;

    final showCycle = stage.key != BeiyunStage.pre && stage.key != BeiyunStage.none;
    final stats = <Widget>[
      Expanded(child: _statCol('$waitingCount', '解禁', waitingCount > 0 ? '待解禁${waitingCount}项' : '已全部解禁', waitingCount > 0 ? redBadge : greenBadge)),
      _divider(),
      Expanded(child: _statCol('$doneCount/${mustScope.length}', '必做', '完成$rate%', rate >= 80 ? greenBadge : (rate >= 50 ? blueText : redBadge))),
      _divider(),
      Expanded(child: _statCol(spentStr, '花费', '预算 8k', blueText)),
      if (showCycle) ...[
        _divider(),
        Expanded(child: _statCol('$cycleCount', '经期', '周期 ${pred.lenUsed}天', blueText)),
      ],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      child: Row(children: stats),
    );
  }

  Widget _statCol(String big, String label, String sub, Color subColor) {
    return Column(
      children: [
        Text(big,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textDark)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: textGray)),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(
                fontSize: 11,
                color: subColor,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFF0F0F0),
    );
  }

  Widget _buildTodoCard() {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final weekLater = DateTime(today.year, today.month, today.day + 7);
    final weekLaterStr = DateFormat('yyyy-MM-dd').format(weekLater);

    final undoneTasks = _tasks
        .where((t) =>
            !t.done &&
            t.planDate != null &&
            t.planDate!.compareTo(todayStr) >= 0 &&
            t.planDate!.compareTo(weekLaterStr) <= 0)
        .take(5)
        .toList();

    return Container(
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
          // Header
          const Row(
            children: [
              Text('今日待办',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
              Spacer(),
              Text('全部 >',
                  style: TextStyle(
                      fontSize: 12,
                      color: orange,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('前后 7 天到期 · 前 5 条',
              style: TextStyle(fontSize: 11, color: textGray)),
          const SizedBox(height: 12),
          if (undoneTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('暂无待办任务',
                    style: TextStyle(fontSize: 13, color: textGray)),
              ),
            )
          else
            ...undoneTasks.map((t) => _buildTodoItem(t)),
        ],
      ),
    );
  }

  Widget _buildTodoItem(BeiyunTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Circle checkbox
          GestureDetector(
            onTap: () async {
              final updated = task.copyWith(done: !task.done);
              await AppDatabase.instance.updateBeiyunTask(updated);
              _loadData();
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? orange : Colors.transparent,
                border: Border.all(
                    color: task.done ? orange : textGray, width: 1.5),
              ),
              child: task.done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(task.title,
                style: const TextStyle(fontSize: 14, color: textDark)),
          ),
          if (task.planDate != null)
            Text(task.planDate!,
                style: const TextStyle(fontSize: 11, color: textGray)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2: 日历
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 12),
          _buildCalendar(),
          const SizedBox(height: 16),
          _buildMonthTasks(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() =>
                  _focusedDay = DateTime(
                      _focusedDay.year, _focusedDay.month - 1, 1)),
              child: _calNavBtn('<'),
            ),
            const SizedBox(width: 8),
            Text('${_focusedDay.year}年${_focusedDay.month}月',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textDark)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() =>
                  _focusedDay = DateTime(
                      _focusedDay.year, _focusedDay.month + 1, 1)),
              child: _calNavBtn('>'),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('今天',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pinkBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('避孕中 1项',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE64A4A),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _calNavBtn(String label) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: lightOrange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  color: orange,
                  fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildLegend() {
    const items = [
      (orange, '禁忌期'),
      (Color(0xFFFF8FAB), '生理期'),
      (Color(0xFF7ED321), '可备孕'),
      (Color(0xFFE64A4A), '最晚到期'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: e.$1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(e.$2,
                style:
                    const TextStyle(fontSize: 11, color: textGray)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCalendar() {
    final eventMap = <DateTime, List<CycleEvent>>{};
    for (final e in _cycleEvents) {
      try {
        final dt = DateTime.parse(e.date);
        final date = DateTime(dt.year, dt.month, dt.day);
        eventMap.putIfAbsent(date, () => []).add(e);
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: TableCalendar<CycleEvent>(
          firstDay: DateTime(2024),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
          calendarFormat: _format,
          onFormatChanged: (f) => setState(() => _format = f),
          onDaySelected: (s, f) =>
              setState(() { _selectedDay = s; _focusedDay = f; }),
          onPageChanged: (f) => setState(() => _focusedDay = f),
          locale: 'zh_CN',
          headerVisible: false,
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle:
                TextStyle(fontSize: 12, color: textGray),
            weekendStyle:
                TextStyle(fontSize: 12, color: textGray),
          ),
          calendarStyle: const CalendarStyle(
            defaultTextStyle:
                TextStyle(color: textDark, fontSize: 14),
            weekendTextStyle:
                TextStyle(color: textDark, fontSize: 14),
            outsideTextStyle:
                TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
            cellMargin: EdgeInsets.symmetric(vertical: 4),
            markerDecoration: BoxDecoration(color: Colors.transparent),
            markersMaxCount: 3,
          ),
          daysOfWeekHeight: 28,
          rowHeight: 40,
          eventLoader: (day) => eventMap[day] ?? [],
          calendarBuilders: CalendarBuilders<CycleEvent>(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: events.map((e) {
                  Color dotColor;
                  switch (e.type) {
                    case CycleEventType.taboo:
                      dotColor = orange;
                    case CycleEventType.period:
                      dotColor = const Color(0xFFFF8FAB);
                    case CycleEventType.ovulation:
                      dotColor = const Color(0xFF7ED321);
                    case CycleEventType.fertile:
                      dotColor = const Color(0xFF54A0FF);
                    case CycleEventType.release:
                      dotColor = const Color(0xFF7ED321);
                    case CycleEventType.due:
                      dotColor = const Color(0xFFE64A4A);
                  }
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                        color: dotColor, shape: BoxShape.circle),
                  );
                }).toList(),
              );
            },
            defaultBuilder: (context, date, events) {
              final isPeriod = _cycleEvents.any((e) {
                try {
                  final dt = DateTime.parse(e.date);
                  return isSameDay(dt, date) &&
                      e.type == CycleEventType.period;
                } catch (_) {
                  return false;
                }
              });
              final isToday = isSameDay(date, DateTime.now());
              final isSelected = isSameDay(date, _selectedDay);

              Color? bgColor;
              if (isPeriod) {
                bgColor = pinkBg;
              } else if (isToday) {
                bgColor = const Color(0xFFFFF3E0);
              } else if (isSelected) {
                bgColor = lightOrange;
              }

              return Container(
                alignment: Alignment.center,
                decoration: bgColor != null
                    ? BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight:
                        isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthTasks() {
    final monthTasks = _tasks.where((t) {
      if (t.planDate == null) return false;
      try {
        final dt = DateTime.parse(t.planDate!);
        return dt.year == _focusedDay.year &&
            dt.month == _focusedDay.month;
      } catch (_) {
        return false;
      }
    }).toList();

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
          const Text('本月待办',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
          const SizedBox(height: 12),
          if (monthTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('本月暂无待办',
                    style: TextStyle(fontSize: 13, color: textGray)),
              ),
            )
          else
            ...monthTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.title,
                            style: const TextStyle(
                                fontSize: 13, color: textDark)),
                      ),
                      if (t.planDate != null)
                        Text(t.planDate!.substring(5),
                            style: const TextStyle(
                                fontSize: 11, color: textGray)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4: 任务
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTasksTab() {
    final filteredTasks = _filteredTasks();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('任务清单',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
          const SizedBox(height: 2),
          const Text('点状态圈完成 · 长按批量置顶/必做',
              style: TextStyle(fontSize: 11, color: textGray)),
          const SizedBox(height: 12),
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 10),
          // Filter chips row 1 - stage
          _buildStageChips(),
          const SizedBox(height: 8),
          // Filter chips row 2 - status
          _buildStatusChips(),
          const SizedBox(height: 12),
          // Stage progress section
          _buildStageProgress(),
          const SizedBox(height: 12),
          // Task list section
          _buildTaskListSection(filteredTasks),
        ],
      ),
    );
  }

  List<BeiyunTask> _filteredTasks() {
    var tasks = _tasks;

    // Stage filter
    if (_stageFilter != '全部') {
      tasks = tasks.where((t) => t.stage == _stageFilter).toList();
    }

    // Status filter
    if (_statusFilter == '待完成') {
      tasks = tasks.where((t) => !t.done).toList();
    } else if (_statusFilter == '进行中') {
      tasks = tasks.where((t) => !t.done && t.planDate == null).toList();
    } else if (_statusFilter == '待解禁') {
      tasks = tasks.where((t) => !t.done && t.planDate != null).toList();
    } else if (_statusFilter == '已完成') {
      tasks = tasks.where((t) => t.done).toList();
    }

    // Search
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.note.toLowerCase().contains(q))
          .toList();
    }

    return tasks;
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: '搜索任务名称 / 说明 / 地点',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
          prefixIcon:
              Icon(Icons.search, size: 18, color: Color(0xFFCCCCCC)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 13, color: textDark),
      ),
    );
  }

  Widget _buildStageChips() {
    const stages = ['全部', '备孕前期', '备孕期', '怀孕期'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stages.map((s) {
          final selected = _stageFilter == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _stageFilter = s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? orange : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(s,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : textDark,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChips() {
    const statuses = ['全部', '待完成', '进行中', '待解禁', '已完成'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final selected = _statusFilter == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? lightOrange : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(999),
                  border: selected ? Border.all(color: orange) : null,
                ),
                child: Text(s,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? orange : textDark,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStageProgress() {
    final preTasks =
        _tasks.where((t) => t.stage == 'preparation').toList();
    final preDone = preTasks.where((t) => t.done).length;
    final preTotal = preTasks.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // "前" badge (green bg)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: greenBadge,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('前',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              const Text('备孕前期',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark)),
              const SizedBox(width: 8),
              const Text('孕前 3-12 月',
                  style: TextStyle(fontSize: 11, color: textGray)),
              const Spacer(),
              Text('$preDone/$preTotal',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: orange)),
              const SizedBox(width: 8),
              // "+ 新增" button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('+ 新增',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar (orange fill)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: preTotal > 0 ? preDone / preTotal : 0,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation<Color>(orange),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListSection(List<BeiyunTask> filteredTasks) {
    final pinnedTasks =
        filteredTasks.where((t) => t.pinned).toList();
    final otherTasks =
        filteredTasks.where((t) => !t.pinned).toList();
    final displayTasks = [...pinnedTasks, ...otherTasks];

    if (displayTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('暂无任务',
              style: TextStyle(fontSize: 14, color: textGray)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header: 必做 with star icon + count
        Row(
          children: [
            const Icon(Icons.star, size: 16, color: orange),
            const SizedBox(width: 4),
            Text('必做 · ${displayTasks.length} 项 · 点击收起',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textDark)),
          ],
        ),
        const SizedBox(height: 8),
        ...displayTasks.map((t) => _buildTaskCard(t)),
      ],
    );
  }

  Widget _buildTaskCard(BeiyunTask task) {
    // Calculate remaining days
    String? remainingStr;
    if (task.planDate != null) {
      try {
        final dt = DateTime.parse(task.planDate!);
        final diff = dt.difference(DateTime.now()).inDays;
        remainingStr = diff > 0
            ? '剩 $diff 天'
            : (diff == 0
                ? '今天'
                : '已超${-diff}天');
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showTaskDetail(task),
      child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: circle checkbox (with dot if undone)
          GestureDetector(
            onTap: () async {
              final updated = task.copyWith(done: !task.done);
              await AppDatabase.instance.updateBeiyunTask(updated);
              _loadData();
            },
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? orange : Colors.transparent,
                border: Border.all(color: orange, width: 1.5),
              ),
              child: task.done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          // Center: title + tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // "必做" red badge
                    if (task.pinned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: redBadge.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('必做',
                            style: TextStyle(
                                fontSize: 10,
                                color: redBadge,
                                fontWeight: FontWeight.w600)),
                      ),
                    // "最晚 9/23" gray
                    if (task.planDate != null)
                      Text('最晚 ${task.planDate!.substring(5)}',
                          style: const TextStyle(
                              fontSize: 10, color: textGray)),
                  ],
                ),
              ],
            ),
          ),
          // Right: remaining days badge + price + arrow
          if (remainingStr != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: lightOrange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(remainingStr,
                  style: const TextStyle(
                      fontSize: 10,
                      color: orange,
                      fontWeight: FontWeight.w600)),
            ),
          const Text('¥120',
              style: TextStyle(
                  fontSize: 11,
                  color: orange,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 16, color: Color(0xFFCCCCCC)),
        ],
      ),
      ),
    );
  }

  /// 任务详情弹窗（Web 版底部抽屉样式）
  void _showTaskDetail(BeiyunTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(task.title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textDark)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.close, size: 16, color: textGray),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRow('阶段', task.stage == 'preparation' ? '备孕前期' : task.stage == 'trying' ? '备孕期' : '怀孕期'),
                if (task.planDate != null) _detailRow('最晚日期', task.planDate!),
                _detailRow('状态', task.done ? '✅ 已完成' : '⏳ 待完成'),
                if (task.note.isNotEmpty) _detailRow('备注', task.note),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = task.copyWith(done: !task.done);
                      AppDatabase.instance.updateBeiyunTask(updated).then((_) {
                        Navigator.pop(context);
                        _loadData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(task.done ? '标记为未完成' : '标记为已完成'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: textGray)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, color: textDark)),
          ),
        ],
      ),
    );
  }

  /// 新增任务弹窗
  void _showAddTaskModal() {
    final titleCtrl = TextEditingController();
    String stage = 'preparation';
    DateTime? planDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('新增任务',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: '任务名称',
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Stage picker
                Row(
                  children: [
                    _stageChip('备孕前期', 'preparation', stage == 'preparation', (s) => stage = s),
                    const SizedBox(width: 8),
                    _stageChip('备孕期', 'trying', stage == 'trying', (s) => stage = s),
                    const SizedBox(width: 8),
                    _stageChip('怀孕期', 'pregnant', stage == 'pregnant', (s) => stage = s),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) planDate = picked;
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(planDate != null ? '${planDate!.year}-${planDate!.month.toString().padLeft(2, '0')}-${planDate!.day.toString().padLeft(2, '0')}' : '选择日期'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final task = BeiyunTask(
                        title: titleCtrl.text.trim(),
                        stage: stage,
                        planDate: planDate != null ? '${planDate!.year}-${planDate!.month.toString().padLeft(2, '0')}-${planDate!.day.toString().padLeft(2, '0')}' : null,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                      );
                      AppDatabase.instance.addBeiyunTask(task).then((_) {
                        Navigator.pop(context);
                        _loadData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageChip(String label, String value, bool selected, void Function(String) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? orange : bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? orange : const Color(0xFFE0E0E0)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : textDark,
          fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 5: 我的
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. 备孕时间卡片 ───
          _buildProfileCard(
            title: '备孕时间',
            trailing: _buildCardLink('修改设置', onTap: () {}),
            child: Column(
              children: [
                _buildInfoRow('备孕目标起始日', '未设置'),
                const SizedBox(height: 10),
                _buildInfoRow('确认怀孕日期', '未设置'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── 2. 功能入口卡片 ───
          _buildProfileCard(
            title: '功能入口',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeatureEntry(
                    Icons.account_balance_wallet_outlined, '财务',
                    onTap: _navigateToFinance),
                _buildFeatureEntry(Icons.nightlight_outlined, '周期',
                    onTap: _navigateToCycle),
                _buildFeatureEntry(Icons.medication_outlined, '营养',
                    onTap: _navigateToSupplement),
                _buildFeatureEntry(Icons.link, '收藏',
                    onTap: _navigateToLinks),
                _buildFeatureEntry(Icons.block, '禁忌',
                    onTap: _navigateToTaboo),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── 3. 外观设置卡片 ───
          _buildProfileCard(
            title: '外观设置',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCardLink('主题', onTap: () {}),
                const SizedBox(width: 12),
                _buildCardLink('字体', onTap: () {}),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow('当前主题', '樱花粉'),
                const SizedBox(height: 10),
                _buildInfoRow('当前字体', '圆体'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── 4. 数据管理卡片 ───
          _buildProfileCard(
            title: '数据管理',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDataCount('任务', _tasks.length,
                        onTap: () {}),
                    _buildDataCount('财务', _finances.length,
                        onTap: () {}),
                    _buildDataCount('经期', _cycleEvents.length,
                        onTap: () {}),
                    _buildDataCount('营养', 0, onTap: () {}),
                    _buildDataCount('收藏', 0, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildDataButton('Excel导出', onTap: () {}),
                    _buildDataButton('Excel导入', onTap: () {}),
                    _buildDataButton('JSON导出', onTap: () {}),
                    _buildDataButton('JSON导入', onTap: () {}),
                    _buildDataButton('下载模板', onTap: () {}),
                    _buildDataButton('重置数据', danger: true, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── 5. 关于卡片 ───
          _buildProfileCard(
            title: '关于',
            child: const Text(
              '备孕助手是一款专注于科学备孕的轻量工具，帮助您记录备孕目标、'
              '经期周期、营养摄入与每日任务，陪伴您走好备孕的每一步。',
              style: TextStyle(fontSize: 13, color: textGray, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── 通用卡片容器（白底、圆角、阴影） ──
  Widget _buildProfileCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── 卡片右上角链接（如 "修改设置 >"） ──
  Widget _buildCardLink(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: orange,
                  fontWeight: FontWeight.w500)),
          const Icon(Icons.chevron_right, size: 16, color: orange),
        ],
      ),
    );
  }

  // ── 键值信息行 ──
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: textGray)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── 功能入口圆形按钮 ──
  Widget _buildFeatureEntry(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: lightOrange,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: orange),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: textDark)),
        ],
      ),
    );
  }

  // ── 数据统计项 ──
  Widget _buildDataCount(String label, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: orange)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: textGray)),
        ],
      ),
    );
  }

  // ── 数据管理操作按钮 ──
  Widget _buildDataButton(String label,
      {VoidCallback? onTap, bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: lightOrange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: danger ? redBadge : orange,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── 子页面导航（财务） ──
  void _navigateToFinance() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancePage()));
  }

  // ── 子页面导航（周期） ──
  void _navigateToCycle() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CyclePage()));
  }

  // ── 子页面导航（营养） ──
  void _navigateToSupplement() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplementPage()));
  }

  // ── 子页面导航（收藏） ──
  void _navigateToLinks() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LinksPage()));
  }

  // ── 子页面导航（禁忌） ──
  void _navigateToTaboo() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TabooPage()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  FAB → 快速操作 Bottom Sheet
  // ═══════════════════════════════════════════════════════════════
  Widget? _buildFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: orange,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('快速操作',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark)),
            const SizedBox(height: 20),
            // Row 1: 记一笔, 记经期, 新任务
            Row(
              children: [
                Expanded(
                    child: _quickActionBtn(Icons.edit_note, '记一笔', () { Navigator.pop(context); _navigateToFinance(); })),
                Expanded(
                    child: _quickActionBtn(Icons.local_florist, '记经期', () { Navigator.pop(context); _navigateToCycle(); })),
                Expanded(
                    child: _quickActionBtn(
                        Icons.check_circle_outline, '新任务', () { Navigator.pop(context); _showAddTaskModal(); })),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: 营养剂, 加收藏
            Row(
              children: [
                Expanded(
                    child: _quickActionBtn(Icons.medication, '营养剂', () { Navigator.pop(context); _navigateToSupplement(); })),
                Expanded(
                    child: _quickActionBtn(Icons.link, '加收藏', () { Navigator.pop(context); _navigateToLinks(); })),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: orange),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: textDark)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Bottom Navigation
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    const items = [
      (Icons.access_time, '今日'),
      (Icons.calendar_month, '日历'),
      (null, '快速操作'),
      (Icons.list_alt, '任务'),
      (Icons.person, '我的'),
    ];

    return BottomAppBar(
      color: Colors.white,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final icon = items[i].$1;
          final label = items[i].$2;
          final selected = _currentTab == i;

          // Center item: placeholder for FAB
          if (i == 2) {
            return const SizedBox(width: 56);
          }

          return GestureDetector(
            onTap: () => setState(() => _currentTab = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 24,
                    color: selected
                        ? orange
                        : const Color(0xFF999999)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? orange
                          : const Color(0xFF999999),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          );
        }),
      ),
    );
  }
}