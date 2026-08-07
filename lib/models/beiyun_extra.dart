/// 备孕周期事件（日历多色圆点）
enum CycleEventType {
  taboo, // 禁忌
  period, // 经期
  ovulation, // 排卵
  fertile, // 易孕
  release, // 解禁
  due, // 到期
}

class CycleEvent {
  final int? id;
  final String date; // yyyy-MM-dd
  final CycleEventType type;
  final String note;

  CycleEvent({this.id, required this.date, required this.type, this.note = ''});

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'type': type.index,
        'note': note,
      };

  factory CycleEvent.fromMap(Map<String, dynamic> m) => CycleEvent(
        id: m['id'],
        date: m['date'] as String,
        type: CycleEventType.values[m['type'] as int],
        note: (m['note'] ?? '') as String,
      );
}

/// 备孕营养打卡
class SupplementLog {
  final int? id;
  final String date; // yyyy-MM-dd
  final String type; // 营养品类
  final bool done;

  SupplementLog({this.id, required this.date, required this.type, this.done = true});

  Map<String, dynamic> toMap() =>
      {'id': id, 'date': date, 'type': type, 'done': done ? 1 : 0};
  factory SupplementLog.fromMap(Map<String, dynamic> m) => SupplementLog(
        id: m['id'],
        date: m['date'] as String,
        type: m['type'] as String,
        done: (m['done'] ?? 1) == 1,
      );
}

/// 备孕财务记账
class BeiyunFinance {
  final int? id;
  final double amount;
  final String date; // yyyy-MM-dd
  final String note;
  final String category;

  BeiyunFinance({
    this.id,
    required this.amount,
    required this.date,
    this.note = '',
    this.category = '一般',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': date,
        'note': note,
        'category': category,
      };
  factory BeiyunFinance.fromMap(Map<String, dynamic> m) => BeiyunFinance(
        id: m['id'],
        amount: (m['amount'] ?? 0).toDouble(),
        date: m['date'] as String,
        note: (m['note'] ?? '') as String,
        category: (m['category'] ?? '一般') as String,
      );
}