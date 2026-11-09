part of '../../events.dart';

/// نموذج تتبع ختمة القرآن
/// Quran Khatma tracking model
class QuranKhatma {
  final int id;
  final int completedJuz;
  final DateTime startDate;
  final DateTime? completionDate;
  final int hijriYear;
  final int hijriMonth;

  QuranKhatma({
    required this.id,
    required this.completedJuz,
    required this.startDate,
    this.completionDate,
    required this.hijriYear,
    required this.hijriMonth,
  });

  /// إجمالي الأجزاء
  static const int totalJuz = 30;

  /// هل اكتملت الختمة؟
  bool get isCompleted => completedJuz >= totalJuz;

  /// نسبة الإنجاز
  double get progressPercentage => (completedJuz / totalJuz) * 100;

  /// الأجزاء المتبقية
  int get remainingJuz => totalJuz - completedJuz;

  /// تحويل من JSON
  factory QuranKhatma.fromJson(Map<String, dynamic> json) {
    return QuranKhatma(
      id: json['id'] as int,
      completedJuz: json['completedJuz'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      completionDate: json['completionDate'] != null
          ? DateTime.parse(json['completionDate'] as String)
          : null,
      hijriYear: json['hijriYear'] as int,
      hijriMonth: json['hijriMonth'] as int,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedJuz': completedJuz,
      'startDate': startDate.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'hijriYear': hijriYear,
      'hijriMonth': hijriMonth,
    };
  }

  /// إنشاء نسخة معدّلة
  QuranKhatma copyWith({
    int? id,
    int? completedJuz,
    DateTime? startDate,
    DateTime? completionDate,
    int? hijriYear,
    int? hijriMonth,
  }) {
    return QuranKhatma(
      id: id ?? this.id,
      completedJuz: completedJuz ?? this.completedJuz,
      startDate: startDate ?? this.startDate,
      completionDate: completionDate ?? this.completionDate,
      hijriYear: hijriYear ?? this.hijriYear,
      hijriMonth: hijriMonth ?? this.hijriMonth,
    );
  }
}

/// نموذج تتبع القرآن الكامل
/// Full Quran tracker model
class QuranTracker {
  final List<QuranKhatma> khatmas;
  final int currentKhatmaId;

  QuranTracker({
    required this.khatmas,
    required this.currentKhatmaId,
  });

  /// الختمة الحالية
  QuranKhatma? get currentKhatma => khatmas.isNotEmpty
      ? khatmas.firstWhere((k) => k.id == currentKhatmaId)
      : null;

  /// عدد الختمات المكتملة
  int get completedKhatmasCount => khatmas.where((k) => k.isCompleted).length;

  /// تحويل من JSON
  factory QuranTracker.fromJson(Map<String, dynamic> json) {
    return QuranTracker(
      khatmas: (json['khatmas'] as List)
          .map((e) => QuranKhatma.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentKhatmaId: json['currentKhatmaId'] as int,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'khatmas': khatmas.map((e) => e.toJson()).toList(),
      'currentKhatmaId': currentKhatmaId,
    };
  }

  /// إنشاء نسخة معدّلة
  QuranTracker copyWith({
    List<QuranKhatma>? khatmas,
    int? currentKhatmaId,
  }) {
    return QuranTracker(
      khatmas: khatmas ?? this.khatmas,
      currentKhatmaId: currentKhatmaId ?? this.currentKhatmaId,
    );
  }
}

/// نموذج تتبع الصدقات
/// Sadaqah tracker model
class SadaqahEntry {
  final DateTime date;
  final double amount;
  final String? note;
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;

  SadaqahEntry({
    required this.date,
    required this.amount,
    this.note,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
  });

  /// تحويل من JSON
  factory SadaqahEntry.fromJson(Map<String, dynamic> json) {
    return SadaqahEntry(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      hijriDay: json['hijriDay'] as int,
      hijriMonth: json['hijriMonth'] as int,
      hijriYear: json['hijriYear'] as int,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'note': note,
      'hijriDay': hijriDay,
      'hijriMonth': hijriMonth,
      'hijriYear': hijriYear,
    };
  }
}

/// نموذج تتبع الصدقات الكامل
/// Full Sadaqah tracker model
class SadaqahTracker {
  final List<SadaqahEntry> entries;
  final int hijriYear;
  final int hijriMonth;

  SadaqahTracker({
    required this.entries,
    required this.hijriYear,
    required this.hijriMonth,
  });

  /// إجمالي الصدقات
  double get totalAmount =>
      entries.fold(0.0, (sum, entry) => sum + entry.amount);

  /// صدقات الشهر الحالي
  List<SadaqahEntry> get currentMonthEntries => entries
      .where((e) => e.hijriMonth == hijriMonth && e.hijriYear == hijriYear)
      .toList();

  /// إجمالي صدقات الشهر
  double get currentMonthTotal =>
      currentMonthEntries.fold(0.0, (sum, entry) => sum + entry.amount);

  /// عدد أيام الصدقة في الشهر
  int get daysWithSadaqah =>
      currentMonthEntries.map((e) => e.hijriDay).toSet().length;

  /// تحويل من JSON
  factory SadaqahTracker.fromJson(Map<String, dynamic> json) {
    return SadaqahTracker(
      entries: (json['entries'] as List)
          .map((e) => SadaqahEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      hijriYear: json['hijriYear'] as int,
      hijriMonth: json['hijriMonth'] as int,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'hijriYear': hijriYear,
      'hijriMonth': hijriMonth,
    };
  }

  /// إنشاء نسخة معدّلة
  SadaqahTracker copyWith({
    List<SadaqahEntry>? entries,
    int? hijriYear,
    int? hijriMonth,
  }) {
    return SadaqahTracker(
      entries: entries ?? this.entries,
      hijriYear: hijriYear ?? this.hijriYear,
      hijriMonth: hijriMonth ?? this.hijriMonth,
    );
  }
}
