import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/budget.dart';
import '../../models/todo.dart';
import '../../main.dart';

/// 工作台首页 — 像素级还原 Web 版
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  DateTime? _memorialDate;
  int _daysTogether = 0;

  List<BeiyunTask> _tasks = [];
  List<BudgetRecord> _records = [];
  List<TodoTask> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadMemorial();
    _load();
  }

  Future<void> _loadMemorial() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('memorial_date');
    if (dateStr != null) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        _memorialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        _daysTogether = DateTime.now().difference(_memorialDate!).inDays;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final tasks = await db.getBeiyunTasks();
    final records = await db.getBudgetRecords();
    final todos = await db.getTodoTasks();
    if (mounted) setState(() {
      _tasks = tasks; _records = records; _todos = todos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                // 菜单按钮
                GestureDetector(
                  onTap: () => appDrawerKey.currentState?.openDrawer(),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu, size: 18, color: Color(0xFFD6336C)),
                  ),
                ),
                const SizedBox(width: 8),
                // Logo + 标题
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8FAB),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Text('台', style: TextStyle(
                          fontFamily: 'ZCOOL KuaiLe', fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('工作台', style: TextStyle(
                          fontFamily: 'ZCOOL KuaiLe', fontSize: 18, color: Color(0xFF333333), fontWeight: FontWeight.w700,
                        )),
                        const Text('备孕 · 备婚 · 事项 聚合', style: TextStyle(
                          fontSize: 11, color: Color(0xFF999999),
                        )),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // 日期按钮
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    DateFormat('M月d日 · EEEE', 'zh_CN').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12, color: Color(0xFFD6336C), fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
        child: Column(
          children: [
            // 纪念日横幅
            GestureDetector(
              onTap: () => _showBannerDialog(),
              child: _buildBanner(),
            ),
            const SizedBox(height: 12),
            // 三功能卡片
            _buildCards(),
            const SizedBox(height: 16),
            // 日历
            _buildCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    if (_memorialDate != null) {
      final dateStr = '${_memorialDate!.year}-${_memorialDate!.month.toString().padLeft(2, '0')}-${_memorialDate!.day.toString().padLeft(2, '0')}';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE4E9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('♡', style: TextStyle(fontSize: 14, color: Color(0xFFFF8FAB))),
            const SizedBox(width: 6),
            Text('在一起 $_daysTogether 天 ($dateStr) >', style: const TextStyle(
              fontSize: 13, color: Color(0xFFCC9999),
            )),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE4E9)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('♡', style: TextStyle(fontSize: 14, color: Color(0xFFFF8FAB))),
          SizedBox(width: 6),
          Text('记录在一起的纪念日 >', style: TextStyle(
            fontSize: 13, color: Color(0xFFCC9999),
          )),
        ],
      ),
    );
  }

  Widget _buildCards() {
    return Row(
      children: [
        _card('备婚预置', '👫', const Color(0xFFFF9F43), const Color(0xFFFFF5ED)),
        const SizedBox(width: 10),
        _card('备孕工作台', '🧪', const Color(0xFFFF8FAB), const Color(0xFFFFF0F5)),
        const SizedBox(width: 10),
        _card('事项管理', '📅', const Color(0xFF54A0FF), const Color(0xFFF0F6FF)),
      ],
    );
  }

  Widget _card(String title, String emoji, Color accent, Color bg) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: const Color(0xFF965A6E).withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          children: [
            // 顶部色条
            Container(
              width: double.infinity, height: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            // 图标
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333),
            )),
            const SizedBox(height: 4),
            const Text('--', style: TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
            const SizedBox(height: 4),
            const Text('未启用', style: TextStyle(
              fontSize: 10, color: Color(0xFFCCCCCC),
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: const Color(0xFF965A6E).withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日历头部控制
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeMonth(-1),
                      child: _calNavBtn('<'),
                    ),
                    const SizedBox(width: 8),
                    Text('${_focusedDay.year} 年 ${_focusedDay.month} 月', style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF333333),
                    )),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: _calNavBtn('>'),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8FAB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('今天', style: TextStyle(
                      fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 图例
            _buildLegend(),
            const SizedBox(height: 10),
            // 日历组件
            TableCalendar(
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              calendarFormat: _format,
              onFormatChanged: (f) => setState(() => _format = f),
              onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
              onPageChanged: (f) => setState(() => _focusedDay = f),
              locale: 'zh_CN',
              headerVisible: false,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                weekendStyle: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF8FAB), width: 1.5),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                ),
                todayTextStyle: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                ),
                selectedTextStyle: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600),
                defaultTextStyle: const TextStyle(color: Color(0xFF333333), fontSize: 14),
                weekendTextStyle: const TextStyle(color: Color(0xFF333333), fontSize: 14),
                outsideTextStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                cellMargin: const EdgeInsets.symmetric(vertical: 2),
                markerDecoration: const BoxDecoration(color: Colors.transparent),
                markersMaxCount: 3,
              ),
              eventLoader: (day) {
                final ds = DateFormat('yyyy-MM-dd').format(day);
                final r = <String>[];
                if (_tasks.any((t) => t.planDate == ds)) r.add('b');
                if (_records.any((t) => t.date == ds)) r.add('g');
                if (_todos.any((t) => t.date == ds)) r.add('t');
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
                        case 'b': dc = const Color(0xFFFF8FAB);
                        case 'g': dc = const Color(0xFFFF9F43);
                        case 't': dc = const Color(0xFF54A0FF);
                        default: dc = const Color(0xFFF3D7E0);
                      }
                      return Container(
                        width: 5, height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: dc, shape: BoxShape.circle),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calNavBtn(String label) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(label, style: const TextStyle(
        fontSize: 16, color: Color(0xFFD6336C), fontWeight: FontWeight.w600,
      ))),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, _focusedDay.day);
    });
  }

  void _showBannerDialog() {
    showDatePicker(
      context: context,
      initialDate: _memorialDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    ).then((picked) async {
      if (picked != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('memorial_date', '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        if (mounted) {
          setState(() {
            _memorialDate = picked;
            _daysTogether = DateTime.now().difference(picked).inDays;
          });
        }
      }
    });
  }

  Widget _buildLegend() {
    const items = [
      ('🔴', '备婚'), ('🟡', '备孕到期'), ('🟢', '备孕就诊'),
      ('🔵', '营养'), ('🔵', '事项'), ('🟣', '经期'), ('🟣', '易孕'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.$1, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(e.$2, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
        ],
      )).toList(),
    );
  }
}