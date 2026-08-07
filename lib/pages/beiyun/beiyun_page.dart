import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/beiyun_task.dart';
import '../../models/beiyun_extra.dart';
import '../../main.dart';

/// 备孕工作台 — 像素级还原 Web 版
class BeiyunPage extends StatefulWidget {
  const BeiyunPage({super.key});

  @override
  State<BeiyunPage> createState() => _BeiyunPageState();
}

class _BeiyunPageState extends State<BeiyunPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<BeiyunTask> _tasks = [];
  List<BeiyunFinance> _finances = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
    final finances = await db.getBeiyunFinance();
    if (mounted) setState(() {
      _tasks = tasks; _finances = finances;
    });
  }

  int get _totalDone => _tasks.where((t) => t.done).length;
  int get _totalTasks => _tasks.length;
  double get _totalSpent => _finances.fold(0, (s, f) => s + f.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => appDrawerKey.currentState?.openDrawer(),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu, size: 18, color: Color(0xFFCC6600)),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('孕', style: TextStyle(
                          fontFamily: 'ZCOOL KuaiLe', fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('备孕工作台', style: TextStyle(
                          fontFamily: 'ZCOOL KuaiLe', fontSize: 18, color: Color(0xFF333333), fontWeight: FontWeight.w700,
                        )),
                        const Text('深圳 · 好孕规划', style: TextStyle(
                          fontSize: 11, color: Color(0xFF999999),
                        )),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    DateFormat('M月d日 · EEEE', 'zh_CN').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8B6914), fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 30),
        child: Column(
          children: [
            // 时间筛选
            _buildTimeFilter(),
            const SizedBox(height: 14),
            // 备孕阶段 Hero 卡
            _buildHeroCard(),
            const SizedBox(height: 12),
            // 统计卡片
            _buildStatsCard(),
            const SizedBox(height: 12),
            // 今日待办
            _buildTodoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Row(
      children: ['今日', '1月', '3月', '自定'].map((t) {
        final active = t == '今日';
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFF5A623) : const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(t, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF666666),
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeroCard() {
    // 模拟倒计时（示例数据）
    const targetDate = '2027-06-23';
    final target = DateTime(2027, 6, 23);
    final daysLeft = target.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: const Color(0xFF965A6E).withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Stack(
        children: [
          // 右上角装饰光晕
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF3E0).withValues(alpha: 0.5),
              ),
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('备孕前期', style: TextStyle(
                        fontFamily: 'ZCOOL KuaiLe',
                        fontSize: 20, color: Color(0xFF4A2B36), fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 4),
                      const Text('孕前 3-6 月', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      const SizedBox(height: 2),
                      Text('目标日 $targetDate', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _tag('禁忌期', const Color(0xFFF5A623), const Color(0xFFFFF3E0)),
                          const SizedBox(width: 6),
                          _tag('解禁还剩 87 天', const Color(0xFFD6336C), const Color(0xFFFFE4E9)),
                          const Spacer(),
                          const Text('查看任务 >', style: TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$daysLeft', style: const TextStyle(
                      fontFamily: 'ZCOOL KuaiLe',
                      fontSize: 42, color: Color(0xFFF5A623), fontWeight: FontWeight.w800,
                    )),
                    const Text('距目标日(天)', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10.5, color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: const Color(0xFF965A6E).withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Row(
        children: [
          _statCol('1', '解禁', '待解禁1项', const Color(0xFFF5A623)),
          Container(width: 1, height: 40, color: const Color(0xFFF0E8E0)),
          _statCol('$_totalDone/$_totalTasks', '必做', '完成${_totalTasks > 0 ? (_totalDone * 100 ~/ _totalTasks) : 0}%', const Color(0xFFF5A623)),
          Container(width: 1, height: 40, color: const Color(0xFFF0E8E0)),
          _statCol('${_totalSpent > 1000 ? '${(_totalSpent / 1000).toStringAsFixed(1)}k' : _totalSpent.toStringAsFixed(0)}', '花费', '预算 8k', const Color(0xFF54A0FF)),
        ],
      ),
    );
  }

  Widget _statCol(String num, String label, String sub, Color subColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(num, style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF333333),
            )),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF999999))),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: const Color(0xFF965A6E).withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日待办', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF333333),
                )),
                const Text('全部 >', style: TextStyle(
                  fontSize: 12, color: Color(0xFFF5A623), fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Text('前后 7 天到期 · 前 5 条', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
          ),
          // 待办列表
          ..._tasks.where((t) => !t.done && t.planDate != null).take(3).map((t) => Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF5A623), width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.title, style: const TextStyle(
                    fontSize: 13.5, color: Color(0xFF333333), fontWeight: FontWeight.w500,
                  )),
                ),
                if (t.planDate != null)
                  Text(t.planDate!.substring(5), style: const TextStyle(
                    fontSize: 11, color: Color(0xFF999999),
                  )),
              ],
            ),
          )),
          if (_tasks.where((t) => !t.done && t.planDate != null).isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Center(child: Text('今天没有待办', style: TextStyle(fontSize: 13, color: Color(0xFF999999)))),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}