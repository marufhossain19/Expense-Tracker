import 'package:hive/hive.dart';

part 'expense.g.dart';

/// Represents a single financial transaction (expense or income).
@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final dynamic id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int categoryIcon;

  @HiveField(5)
  final int categoryColor;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final bool isIncome;

  @HiveField(8)
  final String? note;

  @HiveField(9)
  final String? userName;

  @HiveField(10)
  final bool isFamily;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.date,
    this.isIncome = false,
    this.note,
    this.userName,
    this.isFamily = false,
  });

  /// Transaction type string matching assignment: 'Income' or 'Expense'
  String get type => isIncome ? 'Income' : 'Expense';

  /// Helper to get numeric SQLite ID
  int? get intId => id is int ? id as int : int.tryParse(id.toString());

  /// Convert to SQLite map matching table structure:
  /// id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, category TEXT, type TEXT, date TEXT
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
    };
    if (intId != null) {
      map['id'] = intId;
    }
    return map;
  }

  /// Create Expense from SQLite map
  factory Expense.fromMap(
    Map<String, dynamic> map, {
    int? defaultIcon,
    int? defaultColor,
    String? note,
  }) {
    final typeStr = (map['type'] as String?)?.toLowerCase() ?? 'expense';
    final isInc = typeStr == 'income';
    final rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Expense(
      id: map['id'],
      title: (map['title'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: (map['category'] as String?) ?? 'Other',
      categoryIcon: defaultIcon ?? 0xe0af,
      categoryColor: defaultColor ?? 0xFF6C5CE7,
      date: parsedDate,
      isIncome: isInc,
      note: note ?? map['note'] as String?,
    );
  }

  /// Create a copy with modified fields
  Expense copyWith({
    dynamic id,
    String? title,
    double? amount,
    String? category,
    int? categoryIcon,
    int? categoryColor,
    DateTime? date,
    bool? isIncome,
    String? note,
    String? userName,
    bool? isFamily,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      userName: userName ?? this.userName,
      isFamily: isFamily ?? this.isFamily,
    );
  }
}
