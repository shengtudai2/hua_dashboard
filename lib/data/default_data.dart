import 'package:shared_preferences/shared_preferences.dart';
import '../models/beiyun_task.dart';
import '../models/budget.dart';
import '../models/todo.dart';
import '../database/database_helper.dart';

/// 首次启动时载入初始数据（匹配 Web 版默认模板）
Future<void> loadDefaultData() async {
  // 仅在首次启动时载入
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('data_initialized') == true) return;

  final db = AppDatabase.instance;

  // 检查是否已有数据（避免覆盖）
  final existingCount = await db.count('beiyun_tasks');
  if (existingCount > 0) return;

  // ===== 备孕任务 =====
  const beiyunTasks = [
    // 备孕前期
    ('孕前检查', 'preparation', false),
    ('调整作息', 'preparation', false),
    ('补充叶酸', 'preparation', false),
    ('口腔检查', 'preparation', false),
    ('戒除烟酒', 'preparation', false),
    // 备孕期
    ('监测排卵', 'trying', false),
    ('基础体温记录', 'trying', false),
    ('排卵试纸', 'trying', false),
    ('调整饮食', 'trying', false),
    ('适度运动', 'trying', false),
    // 怀孕期
    ('确认怀孕', 'pregnant', false),
    ('建档产检', 'pregnant', false),
    ('NT检查', 'pregnant', false),
    ('唐氏筛查', 'pregnant', false),
    ('大排畸', 'pregnant', false),
  ];

  for (final t in beiyunTasks) {
    await db.addBeiyunTask(BeiyunTask(
      title: t.$1, stage: t.$2, createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  // ===== 备婚预算分类 =====
  const categories = [
    // 拍摄准备
    ('婚纱照', '拍摄准备', 8000),
    ('婚纱礼服', '拍摄准备', 3000),
    ('西装', '拍摄准备', 2000),
    // 婚礼当天
    ('婚宴', '婚礼当天', 30000),
    ('婚庆策划', '婚礼当天', 15000),
    ('摄影摄像', '婚礼当天', 8000),
    ('跟妆造型', '婚礼当天', 3000),
    ('婚车', '婚礼当天', 2000),
    // 备婚选品
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

  await prefs.setBool('data_initialized', true);
}