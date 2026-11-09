part of '../../events.dart';

/// نموذج بيانات يوم القضاء
/// Qada day data model
class QadaDay {
  final int day;
  final int month;
  final int year;
  final DateTime? fastedDate;
  final String? reason;

  QadaDay({
    required this.day,
    required this.month,
    required this.year,
    this.fastedDate,
    this.reason,
  });

  /// تحويل من JSON
  factory QadaDay.fromJson(Map<String, dynamic> json) {
    return QadaDay(
      day: json['day'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      fastedDate: json['fastedDate'] != null
          ? DateTime.parse(json['fastedDate'] as String)
          : null,
      reason: json['reason'] as String?,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'fastedDate': fastedDate?.toIso8601String(),
      'reason': reason,
    };
  }

  /// إنشاء نسخة معدّلة
  QadaDay copyWith({
    int? day,
    int? month,
    int? year,
    DateTime? fastedDate,
    String? reason,
  }) {
    return QadaDay(
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
      fastedDate: fastedDate ?? this.fastedDate,
      reason: reason ?? this.reason,
    );
  }

  /// مفتاح فريد لليوم
  String get uniqueKey => '$year-$month-$day';

  /// هل تم صيام هذا اليوم؟
  bool get isFasted => fastedDate != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QadaDay &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => day.hashCode ^ month.hashCode ^ year.hashCode;
}

/// نموذج تتبع القضاء الكامل
/// Full Qada tracking model
class QadaTracker {
  final List<QadaDay> missedDays;
  final List<QadaDay> fastedDays;
  final int hijriYear;

  QadaTracker({
    required this.missedDays,
    required this.fastedDays,
    required this.hijriYear,
  });

  /// إجمالي أيام القضاء المطلوبة
  int get totalMissedDays => missedDays.length;

  /// أيام القضاء التي تم صيامها
  int get totalFastedDays => fastedDays.length;

  /// أيام القضاء المتبقية
  int get remainingDays => totalMissedDays - totalFastedDays;

  /// نسبة الإنجاز
  double get progressPercentage =>
      totalMissedDays > 0 ? (totalFastedDays / totalMissedDays) * 100 : 0;

  /// تحويل من JSON
  factory QadaTracker.fromJson(Map<String, dynamic> json) {
    return QadaTracker(
      missedDays: (json['missedDays'] as List)
          .map((e) => QadaDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      fastedDays: (json['fastedDays'] as List)
          .map((e) => QadaDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      hijriYear: json['hijriYear'] as int,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'missedDays': missedDays.map((e) => e.toJson()).toList(),
      'fastedDays': fastedDays.map((e) => e.toJson()).toList(),
      'hijriYear': hijriYear,
    };
  }

  /// إنشاء نسخة معدّلة
  QadaTracker copyWith({
    List<QadaDay>? missedDays,
    List<QadaDay>? fastedDays,
    int? hijriYear,
  }) {
    return QadaTracker(
      missedDays: missedDays ?? this.missedDays,
      fastedDays: fastedDays ?? this.fastedDays,
      hijriYear: hijriYear ?? this.hijriYear,
    );
  }
}
