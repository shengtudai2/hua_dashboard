/// 备孕工作台任务模型
/// 三阶段任务体系：备孕前期 / 备孕期 / 怀孕期
class BeiyunTask {
  final int? id;
  final String title;
  /// 阶段：preparation / trying / pregnant
  final String stage;
  /// 是否完成
  bool done;
  /// 是否收藏
  bool fav;
  /// 记事/备注
  String note;
  /// 创建时间戳
  final int createdAt;
  /// 可选的计划日期 (yyyy-MM-dd)
  String? planDate;
  /// 是否置顶
  bool pinned;

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
      );

  BeiyunTask copyWith({
    bool? done,
    bool? fav,
    String? note,
    String? planDate,
    bool? pinned,
  }) =>
      BeiyunTask(
        id: id,
        title: title,
        stage: stage,
        done: done ?? this.done,
        fav: fav ?? this.fav,
        note: note ?? this.note,
        createdAt: createdAt,
        planDate: planDate ?? this.planDate,
        pinned: pinned ?? this.pinned,
      );
}