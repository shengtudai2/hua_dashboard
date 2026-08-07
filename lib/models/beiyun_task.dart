/// 备孕任务模型（扩展 Web 版字段）
class BeiyunTask {
  final int? id;
  final String title;
  /// 阶段：preparation / trying / pregnant
  final String stage;
  bool done;
  bool fav;
  String note;
  final int createdAt;
  String? planDate; // 最晚日期
  bool pinned;
  String? startDate; // 开始日期（医疗任务）
  int? treatmentMonths; // 治疗月数
  int? intervalMonths; // 间隔月数/禁忌月数
  bool treatmentDone; // 治疗已完成
  double? price; // 预估费用
  double? insurancePay; // 医保报销
  String? description; // 说明
  String? location; // 地点
  String? shenzhenTip; // 深圳提示
  int? order; // 排序

  BeiyunTask({
    this.id,
    required this.title,
    required this.stage,
    this.done = false,
    this.fav = false,
    this.note = '',
    required this.createdAt,
    this.planDate,
    this.pinned = false,
    this.startDate,
    this.treatmentMonths,
    this.intervalMonths,
    this.treatmentDone = false,
    this.price,
    this.insurancePay,
    this.description,
    this.location,
    this.shenzhenTip,
    this.order,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'stage': stage,
        'done': done ? 1 : 0,
        'fav': fav ? 1 : 0,
        'note': note,
        'created_at': createdAt,
        'plan_date': planDate,
        'pinned': pinned ? 1 : 0,
        'start_date': startDate,
        'treatment_months': treatmentMonths,
        'interval_months': intervalMonths,
        'treatment_done': treatmentDone ? 1 : 0,
        'price': price,
        'insurance_pay': insurancePay,
        'description': description,
        'location': location,
        'shenzhen_tip': shenzhenTip,
        'task_order': order,
      };

  factory BeiyunTask.fromMap(Map<String, dynamic> m) => BeiyunTask(
        id: m['id'],
        title: m['title'] as String,
        stage: m['stage'] as String,
        done: (m['done'] ?? 0) == 1,
        fav: (m['fav'] ?? 0) == 1,
        note: (m['note'] ?? '') as String,
        createdAt: (m['created_at'] ?? 0) as int,
        planDate: m['plan_date'] as String?,
        pinned: (m['pinned'] ?? 0) == 1,
        startDate: m['start_date'] as String?,
        treatmentMonths: m['treatment_months'] as int?,
        intervalMonths: m['interval_months'] as int?,
        treatmentDone: (m['treatment_done'] ?? 0) == 1,
        price: (m['price'] as num?)?.toDouble(),
        insurancePay: (m['insurance_pay'] as num?)?.toDouble(),
        description: m['description'] as String?,
        location: m['location'] as String?,
        shenzhenTip: m['shenzhen_tip'] as String?,
        order: m['task_order'] as int?,
      );

  BeiyunTask copyWith({
    bool? done,
    bool? fav,
    String? note,
    String? planDate,
    bool? pinned,
    String? startDate,
    int? treatmentMonths,
    int? intervalMonths,
    bool? treatmentDone,
    double? price,
    double? insurancePay,
    bool? favToggled,
  }) =>
      BeiyunTask(
        id: id,
        title: title,
        stage: stage,
        done: done ?? this.done,
        fav: favToggled != null ? !this.fav : (fav ?? this.fav),
        note: note ?? this.note,
        createdAt: createdAt,
        planDate: planDate ?? this.planDate,
        pinned: pinned ?? this.pinned,
        startDate: startDate ?? this.startDate,
        treatmentMonths: treatmentMonths ?? this.treatmentMonths,
        intervalMonths: intervalMonths ?? this.intervalMonths,
        treatmentDone: treatmentDone ?? this.treatmentDone,
        price: price ?? this.price,
        insurancePay: insurancePay ?? this.insurancePay,
        description: description,
        location: location,
        shenzhenTip: shenzhenTip,
        order: order,
      );
}

/// 任务状态枚举（四态推导）
enum TaskStatus {
  pending, // 待完成
  doing, // 进行中
  waiting, // 解禁期
  done, // 已完成
}

/// 备孕阶段
enum BeiyunStage {
  pre, // 备孕前期
  trying, // 备孕期
  preg, // 怀孕期
  none, // 未设置
}

/// 阶段信息
class StageInfo {
  final BeiyunStage key;
  final String name;
  final String sub;
  final int? days; // 距目标日天数
  final int? week; // 孕周（怀孕期）
  StageInfo({required this.key, required this.name, required this.sub, this.days, this.week});
}

/// 周期预测结果
class CyclePrediction {
  final int? latest;
  final int lenUsed;
  final int periodUsed;
  final String? nextPeriod;
  final String? ovulation;
  final String? fertileStart;
  final String? fertileEnd;
  CyclePrediction({
    this.latest,
    required this.lenUsed,
    required this.periodUsed,
    this.nextPeriod,
    this.ovulation,
    this.fertileStart,
    this.fertileEnd,
  });
}

/// 单日状态
class DayStatus {
  final String key; // taboo/period/ovulation/fertile/safe
  final String label;
  final String color;
  DayStatus({required this.key, required this.label, required this.color});
}