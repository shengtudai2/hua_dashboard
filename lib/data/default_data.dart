import 'package:shared_preferences/shared_preferences.dart';
import '../models/beiyun_task.dart';
import '../models/beiyun_extra.dart';
import '../models/budget.dart';
import '../models/todo.dart';
import '../database/database_helper.dart';

/// 首次启动时载入初始数据（匹配 Web 版默认模板）
Future<void> loadDefaultData() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('data_initialized') == true) return;

  final db = AppDatabase.instance;
  final existingCount = await db.count('beiyun_tasks');
  if (existingCount > 0) return;

  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // ===== 备孕任务（带计划日期） =====
  final tasks = [
    // 备孕前期
    BeiyunTask(title: '孕前全面检查', stage: 'preparation', planDate: _addDays(today, -30), createdAt: now.millisecondsSinceEpoch, pinned: true),
    BeiyunTask(title: 'HPV 疫苗(九价/四价)', stage: 'preparation', planDate: _addDays(today, 47), createdAt: now.millisecondsSinceEpoch, pinned: true),
    BeiyunTask(title: '风疹疫苗(含麻腮风)', stage: 'preparation', planDate: _addDays(today, 90), createdAt: now.millisecondsSinceEpoch, pinned: true),
    BeiyunTask(title: '乙肝疫苗(全程/补种)', stage: 'preparation', planDate: _addDays(today, 120), createdAt: now.millisecondsSinceEpoch, pinned: true),
    BeiyunTask(title: '调整作息规律', stage: 'preparation', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '补充叶酸 400μg/日', stage: 'preparation', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '口腔检查与治疗', stage: 'preparation', planDate: _addDays(today, 60), createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '戒除烟酒习惯', stage: 'preparation', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '甲状腺功能检查', stage: 'preparation', planDate: _addDays(today, 14), createdAt: now.millisecondsSinceEpoch, done: true),
    BeiyunTask(title: '优生五项(TORCH)筛查', stage: 'preparation', planDate: _addDays(today, 7), createdAt: now.millisecondsSinceEpoch, done: true),
    // 备孕期
    BeiyunTask(title: '监测排卵周期', stage: 'trying', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '基础体温记录', stage: 'trying', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '排卵试纸检测', stage: 'trying', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '调整饮食结构', stage: 'trying', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '适度运动锻炼', stage: 'trying', createdAt: now.millisecondsSinceEpoch),
    // 怀孕期
    BeiyunTask(title: '确认怀孕检查', stage: 'pregnant', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '建档产检预约', stage: 'pregnant', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: 'NT 检查(11-13周)', stage: 'pregnant', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '唐氏筛查(16-20周)', stage: 'pregnant', createdAt: now.millisecondsSinceEpoch),
    BeiyunTask(title: '大排畸(20-24周)', stage: 'pregnant', createdAt: now.millisecondsSinceEpoch),
  ];

  for (final t in tasks) {
    await db.addBeiyunTask(t);
  }

  // ===== 备孕财务记录 =====
  final finances = [
    BeiyunFinance(amount: 1200, date: _addDays(today, -20), category: '检查', note: '孕前体检套餐'),
    BeiyunFinance(amount: 350, date: _addDays(today, -15), category: '药品', note: '叶酸片 3个月量'),
    BeiyunFinance(amount: 800, date: _addDays(today, -10), category: '口腔', note: '洗牙+补牙'),
    BeiyunFinance(amount: 200, date: _addDays(today, -5), category: '其他', note: '排卵试纸 10支装'),
    BeiyunFinance(amount: 150, date: today, category: '药品', note: '维生素D滴剂'),
  ];
  for (final f in finances) {
    await db.addBeiyunFinance(f);
  }

  // ===== 周期事件 =====
  final events = [
    CycleEvent(date: _addDays(today, -14), type: CycleEventType.period, note: '经期第一天'),
    CycleEvent(date: _addDays(today, -10), type: CycleEventType.fertile, note: '易孕期'),
    CycleEvent(date: _addDays(today, -8), type: CycleEventType.ovulation, note: '排卵日'),
    CycleEvent(date: today, type: CycleEventType.fertile, note: '易孕期'),
    CycleEvent(date: _addDays(today, 14), type: CycleEventType.period, note: '预测经期'),
  ];
  for (final e in events) {
    await db.addCycleEvent(e);
  }

  // ===== 营养打卡（今天已打卡 2 种） =====
  final supplements = [
    SupplementLog(date: today, type: '叶酸', done: true),
    SupplementLog(date: today, type: '钙片', done: true),
    SupplementLog(date: today, type: '维生素D', done: false),
    SupplementLog(date: today, type: '铁剂', done: false),
    SupplementLog(date: today, type: 'DHA', done: false),
  ];
  for (final s in supplements) {
    await db.addSupplementLog(s);
  }

  // ===== 备婚预算分类 =====
  const categories = [
    ('婚纱照', '拍摄准备', 8000),
    ('婚纱礼服', '拍摄准备', 3000),
    ('西装', '拍摄准备', 2000),
    ('婚宴', '婚礼当天', 30000),
    ('婚庆策划', '婚礼当天', 15000),
    ('摄影摄像', '婚礼当天', 8000),
    ('跟妆造型', '婚礼当天', 3000),
    ('婚车', '婚礼当天', 2000),
    ('婚戒', '备婚选品', 10000),
    ('请柬伴手礼', '备婚选品', 2000),
    ('婚房布置', '备婚选品', 3000),
    ('蜜月旅行', '备婚选品', 15000),
  ];
  for (final c in categories) {
    await db.addBudgetCategory(BudgetCategory(
      name: c.$1, group: c.$2, budget: c.$3.toDouble(),
    ));
  }

  // ===== 事项模块 =====
  const colors = ['#FFB74D', '#81C784', '#64B5F6', '#E57373', '#BA68C8'];
  const modules = ['日常', '健康', '工作', '学习', '购物'];
  for (int i = 0; i < modules.length; i++) {
    await db.addTodoModule(TodoModule(
      name: modules[i], color: colors[i], icon: ['📌', '💪', '💼', '📚', '🛒'][i],
    ));
  }

  // ===== 事项任务 =====
  final todoTasks = [
    TodoTask(title: '每日喝水 8 杯', moduleId: 1, date: today),
    TodoTask(title: '散步 30 分钟', moduleId: 1, date: today),
    TodoTask(title: '88VIP 红包', moduleId: 1, date: today),
    TodoTask(title: 'App 签到打卡', moduleId: 1, date: today),
    TodoTask(title: '整理工作周报', moduleId: 3, date: _addDays(today, 1)),
  ];
  for (final t in todoTasks) {
    await db.addTodoTask(t);
  }

  await prefs.setBool('data_initialized', true);
}

String _addDays(String dateStr, int days) {
  final parts = dateStr.split('-');
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final result = dt.add(Duration(days: days));
  return '${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}';
}