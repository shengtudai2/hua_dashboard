/// 备婚预算分类模型
/// 分组：拍摄准备 / 婚礼当天 / 备婚选品
class BudgetCategory {
  final int? id;
  final String name;
  final String group;
  double budget;
  double spent;
  bool pinned;
  bool done;
  String icon;

  BudgetCategory({
    this.id,
    required this.name,
    required this.group,
    this.budget = 0,
    this.spent = 0,
    this.pinned = false,
    this.done = false,
    this.icon = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'cat_group': group,
        'budget': budget,
        'spent': spent,
        'pinned': pinned ? 1 : 0,
        'done': done ? 1 : 0,
        'icon': icon,
      };

  factory BudgetCategory.fromMap(Map<String, dynamic> m) => BudgetCategory(
        id: m['id'],
        name: m['name'] as String,
        group: m['cat_group'] as String,
        budget: (m['budget'] ?? 0).toDouble(),
        spent: (m['spent'] ?? 0).toDouble(),
        pinned: (m['pinned'] ?? 0) == 1,
        done: (m['done'] ?? 0) == 1,
        icon: (m['icon'] ?? '') as String,
      );

  copyWith({double? budget, double? spent, bool? pinned, bool? done}) =>
      BudgetCategory(
        id: id,
        name: name,
        group: group,
        budget: budget ?? this.budget,
        spent: spent ?? this.spent,
        pinned: pinned ?? this.pinned,
        done: done ?? this.done,
        icon: icon,
      );
}

/// 备婚预算流水记录
class BudgetRecord {
  final int? id;
  final int categoryId;
  final String categoryName;
  final double amount;
  final String date; // yyyy-MM-dd
  final String note;

  BudgetRecord({
    this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'category_name': categoryName,
        'amount': amount,
        'date': date,
        'note': note,
      };

  factory BudgetRecord.fromMap(Map<String, dynamic> m) => BudgetRecord(
        id: m['id'],
        categoryId: m['category_id'] as int,
        categoryName: m['category_name'] as String,
        amount: (m['amount'] ?? 0).toDouble(),
        date: m['date'] as String,
        note: (m['note'] ?? '') as String,
      );
}