import '../../models/beiyun_task.dart';
import '../../models/beiyun_extra.dart';

/// 备孕核心逻辑（对应 Web 版 utils.js）
// 作者：从 Web 版移植，保持逻辑一致

// ═══════════════════════════════════════════════
//  日期工具
// ═══════════════════════════════════════════════

String todayStr() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

DateTime? parseISO(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    final p = s.substring(0, 10).split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  } catch (_) {
    return null;
  }
}

DateTime addDays(DateTime d, int n) {
  return DateTime(d.year, d.month, d.day + n);
}

DateTime addMonths(DateTime d, int n) {
  final day = d.day;
  final r = DateTime(d.year, d.month + n, 1);
  final last = DateTime(r.year, r.month + 1, 0).day;
  return DateTime(r.year, r.month, day <= last ? day : last);
}

int diffDays(String a, String b) {
  final da = parseISO(a);
  final db = parseISO(b);
  if (da == null || db == null) return 0;
  return db.difference(da).inDays;
}

String fmtDate(String? s, {bool withYear = false}) {
  if (s == null || s.isEmpty) return '—';
  final p = s.substring(0, 10).split('-');
  return '${withYear ? '${p[0]}年' : ''}${int.parse(p[1])}月${int.parse(p[2])}日';
}

String moneyK(double n) {
  if (n == 0) return '0';
  if (n.abs() >= 1000) {
    final k = n / 1000;
    return '${k >= 10 ? k.toStringAsFixed(1) : k.toStringAsFixed(2)}k';
  }
  return n.round().toString();
}

// ═══════════════════════════════════════════════
//  医疗周期推算
// ═══════════════════════════════════════════════

DateTime? computeTreatmentEndDate(BeiyunTask t) {
  if (t.startDate == null) return null;
  final m = t.treatmentMonths ?? 0;
  if (m <= 0) return parseISO(t.startDate);
  return addMonths(parseISO(t.startDate)!, m);
}

DateTime? computeReleaseDate(BeiyunTask t) {
  if (t.startDate == null) return null;
  final tm = t.treatmentMonths ?? 0;
  final im = t.intervalMonths ?? 0;
  if (tm == 0 && im == 0) return parseISO(t.startDate);
  return addMonths(parseISO(t.startDate)!, tm + im);
}

// ═══════════════════════════════════════════════
//  任务四态推导
// ═══════════════════════════════════════════════

TaskStatus computeTaskStatus(BeiyunTask t, [String? todayOverride]) {
  if (t.done) return TaskStatus.done;
  if (t.startDate == null) {
    return TaskStatus.pending;
  }
  final today = parseISO(todayOverride ?? todayStr())!;
  final start = parseISO(t.startDate)!;
  if (today.isBefore(start)) return TaskStatus.pending;

  final rel = computeReleaseDate(t);
  final hasTreatment = (t.treatmentMonths ?? 0) > 0;
  final hasInterval = (t.intervalMonths ?? 0) > 0;

  if (hasTreatment) {
    final end = computeTreatmentEndDate(t);
    if (!t.treatmentDone && end != null && today.isBefore(end)) return TaskStatus.doing;
    if (rel != null && today.isBefore(rel)) return TaskStatus.waiting;
    return TaskStatus.done;
  }
  if (hasInterval) {
    if (rel != null && today.isBefore(rel)) return TaskStatus.waiting;
    return TaskStatus.done;
  }
  return t.treatmentDone ? TaskStatus.done : TaskStatus.pending;
}

String taskStatusLabel(TaskStatus s) {
  switch (s) {
    case TaskStatus.pending: return '待完成';
    case TaskStatus.doing: return '进行中';
    case TaskStatus.waiting: return '解禁期';
    case TaskStatus.done: return '已完成';
  }
}

// ═══════════════════════════════════════════════
//  任务最晚完成日
// ═══════════════════════════════════════════════

DateTime? computeTaskLatestDate(BeiyunTask t, String? targetDate) {
  if (targetDate == null || targetDate.isEmpty) return null;
  final td = parseISO(targetDate)!;

  final hasMedical = t.startDate != null && ((t.treatmentMonths ?? 0) > 0 || (t.intervalMonths ?? 0) > 0);
  if (hasMedical) {
    final months = (t.treatmentMonths ?? 0) + (t.intervalMonths ?? 0);
    return addDays(addMonths(td, -months), -15);
  }
  // 按阶段回退
  final off = t.stage == 'preparation' ? 3 : (t.stage == 'trying' ? 1 : 0);
  if (off == 0) return null;
  var latest = addMonths(td, -off);
  // 分散 offset
  latest = addDays(latest, -(((t.order ?? 99) * 2) % 30));
  return latest;
}

// ═══════════════════════════════════════════════
//  阶段计算
// ═══════════════════════════════════════════════

StageInfo computeStage(String? targetDate, String? pregnantDate, [String? todayOverride]) {
  final today = todayOverride ?? todayStr();
  if (pregnantDate != null && pregnantDate.isNotEmpty) {
    final w = (diffDays(pregnantDate, today) ~/ 7) + 1;
    return StageInfo(key: BeiyunStage.preg, name: '怀孕期', sub: '第 $w 周', week: w);
  }
  if (targetDate == null || targetDate.isEmpty) {
    return StageInfo(key: BeiyunStage.none, name: '未设置备孕目标日', sub: '去「我的」页设置');
  }
  final diff = diffDays(today, targetDate);
  if (diff > 90) return StageInfo(key: BeiyunStage.pre, name: '备孕前期', sub: '孕前 3-6 月', days: diff);
  if (diff > 30) return StageInfo(key: BeiyunStage.trying, name: '备孕期', sub: '孕前 1-3 月', days: diff);
  if (diff >= 0) return StageInfo(key: BeiyunStage.trying, name: '备孕期', sub: '临近目标日', days: diff);
  return StageInfo(key: BeiyunStage.trying, name: '备孕期', sub: '目标日已过 ${-diff} 天', days: diff);
}

// ═══════════════════════════════════════════════
//  周期预测
// ═══════════════════════════════════════════════

CyclePrediction predictCycle(List<CycleEvent> cycles, String? customCycleLength, String? customPeriodDays) {
  // 按日期排序，只取 period 类型
  final periodEvents = cycles.where((c) => c.type == CycleEventType.period).toList();
  periodEvents.sort((a, b) => b.date.compareTo(a.date)); // 最新的在前

  final latest = periodEvents.isNotEmpty ? periodEvents.first : null;

  // 计算平均周期长度
  var diffs = <int>[];
  for (int i = 0; i < periodEvents.length - 1; i++) {
    final d = diffDays(periodEvents[i + 1].date, periodEvents[i].date);
    if (d >= 10 && d <= 90) diffs.add(d);
  }
  int? autoLen = diffs.isNotEmpty ? (diffs.reduce((a, b) => a + b) ~/ diffs.length) : null;

  int lenUsed;
  if (customCycleLength != null && customCycleLength.isNotEmpty) {
    lenUsed = int.parse(customCycleLength);
  } else {
    lenUsed = autoLen ?? 35;
  }

  int periodUsed;
  if (customPeriodDays != null && customPeriodDays.isNotEmpty) {
    periodUsed = int.parse(customPeriodDays);
  } else {
    periodUsed = 7;
  }

  if (latest == null) {
    return CyclePrediction(lenUsed: lenUsed, periodUsed: periodUsed);
  }

  final nextPeriod = addDays(parseISO(latest.date)!, lenUsed);
  final ovulation = addDays(nextPeriod, -14);

  return CyclePrediction(
    lenUsed: lenUsed,
    periodUsed: periodUsed,
    nextPeriod: '${nextPeriod.year}-${nextPeriod.month.toString().padLeft(2, '0')}-${nextPeriod.day.toString().padLeft(2, '0')}',
    ovulation: '${ovulation.year}-${ovulation.month.toString().padLeft(2, '0')}-${ovulation.day.toString().padLeft(2, '0')}',
    fertileStart: '${addDays(ovulation, -5).year}-${addDays(ovulation, -5).month.toString().padLeft(2, '0')}-${addDays(ovulation, -5).day.toString().padLeft(2, '0')}',
    fertileEnd: '${addDays(ovulation, 1).year}-${addDays(ovulation, 1).month.toString().padLeft(2, '0')}-${addDays(ovulation, 1).day.toString().padLeft(2, '0')}',
  );
}

// ═══════════════════════════════════════════════
//  单日状态判定
// ═══════════════════════════════════════════════

DayStatus dayStatus(String dateStr, List<BeiyunTask> tasks, List<CycleEvent> cycles, CyclePrediction? pred, String stageKey, bool isPregnant) {
  // 禁忌判定
  for (final t in tasks) {
    if (t.done || t.startDate == null) continue;
    final st = computeTaskStatus(t, dateStr);
    if (st == TaskStatus.doing || st == TaskStatus.waiting) {
      return DayStatus(key: 'taboo', label: '禁忌期', color: '#E88A8A');
    }
  }

  if (!isPregnant) {
    // 经期判定
    bool inPeriod = false;
    for (final c in cycles) {
      if (c.type != CycleEventType.period) continue;
      final s = parseISO(c.date)!;
      final e = addDays(s, 6); // 默认7天
      final d = parseISO(dateStr)!;
      if (!d.isBefore(s) && !d.isAfter(e)) {
        inPeriod = true;
        break;
      }
    }
    // 预测经期
    final np = pred?.nextPeriod;
    if (!inPeriod && np != null) {
      final ps = parseISO(np)!;
      final pe = addDays(ps, pred!.periodUsed - 1);
      final d = parseISO(dateStr)!;
      if (!d.isBefore(ps) && !d.isAfter(pe)) inPeriod = true;
    }
    if (inPeriod) return DayStatus(key: 'period', label: '生理期', color: '#E887A4');

    // 排卵/易孕判定
    if (stageKey != 'pre' && pred != null) {
      if (pred.ovulation == dateStr) return DayStatus(key: 'ovulation', label: '排卵日', color: '#D9A85A');
      if (pred.fertileStart != null && pred.fertileEnd != null) {
        final d = parseISO(dateStr)!;
        final fs = parseISO(pred.fertileStart)!;
        final fe = parseISO(pred.fertileEnd)!;
        if (!d.isBefore(fs) && !d.isAfter(fe)) return DayStatus(key: 'fertile', label: '易孕期', color: '#B59AD9');
      }
    }
  }
  return DayStatus(key: 'safe', label: '可备孕', color: '#5FA980');
}

// ═══════════════════════════════════════════════
//  财务统计
// ═══════════════════════════════════════════════

class FinanceSummary {
  final double spent;
  final double total;
  FinanceSummary({required this.spent, required this.total});
}

FinanceSummary financeSummary(List<BeiyunFinance> records) {
  double spent = 0;
  for (final r in records) {
    spent += r.amount;
  }
  return FinanceSummary(spent: spent, total: 8000);
}