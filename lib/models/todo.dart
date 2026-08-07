/// 事项管理：模块分类
class TodoModule {
  final int? id;
  final String name;
  final String color;
  final String icon;

  TodoModule({this.id, required this.name, this.color = '#FFB74D', this.icon = '📌'});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color, 'icon': icon};
  factory TodoModule.fromMap(Map<String, dynamic> m) => TodoModule(
        id: m['id'],
        name: m['name'] as String,
        color: (m['color'] ?? '#FFB74D') as String,
        icon: (m['icon'] ?? '📌') as String,
      );
}

/// 事项管理：待办任务
class TodoTask {
  final int? id;
  final int? moduleId;
  final String title;
  final String? date; // yyyy-MM-dd 计划日期
  bool done;
  bool pinned;
  int? orderIndex;

  TodoTask({
    this.id,
    this.moduleId,
    required this.title,
    this.date,
    this.done = false,
    this.pinned = false,
    this.orderIndex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'module_id': moduleId,
        'title': title,
        'date': date,
        'done': done ? 1 : 0,
        'pinned': pinned ? 1 : 0,
        'order_index': orderIndex,
      };

  factory TodoTask.fromMap(Map<String, dynamic> m) => TodoTask(
        id: m['id'],
        moduleId: m['module_id'] as int?,
        title: m['title'] as String,
        date: m['date'] as String?,
        done: (m['done'] ?? 0) == 1,
        pinned: (m['pinned'] ?? 0) == 1,
        orderIndex: m['order_index'] as int?,
      );

  TodoTask copyWith({bool? done, bool? pinned, String? date, int? moduleId}) =>
      TodoTask(
        id: id,
        moduleId: moduleId ?? this.moduleId,
        title: title,
        date: date ?? this.date,
        done: done ?? this.done,
        pinned: pinned ?? this.pinned,
        orderIndex: orderIndex,
      );
}