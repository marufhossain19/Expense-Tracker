import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/database_helper.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../utils/extensions.dart';

bool _dynBool(dynamic v, [bool d = false]) {
  if (v == null) return d;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final l = v.toLowerCase();
    if (l == 'true' || l == '1') return true;
    if (l == 'false' || l == '0') return false;
  }
  return d;
}

/// Core business logic provider for all expense/income operations.
/// Uses Supabase as primary data source when authenticated, Hive for offline/skip mode.
/// In cloud mode, all writes go to BOTH Supabase and Hive (dual-write cache).
class ExpenseProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SupabaseService _supabaseService;
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];

  /// Whether we're using cloud (Supabase) or local-only (Hive).
  bool _isCloudMode = false;

  ExpenseProvider(this._hiveService, this._supabaseService) {
    debugPrint('[ExpenseProvider] Created — loading initial SQLite local data');
    _loadLocalData();
  }

  // ── Getters ─────────────────────────────────────────────

  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  bool get isCloudMode => _isCloudMode;

  /// Total income for current month
  double get monthlyIncome {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.isIncome && e.date.isSameMonth(now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Total expenses for current month
  double get monthlyExpense {
    final now = DateTime.now();
    return _expenses
        .where((e) => !e.isIncome && e.date.isSameMonth(now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Current month balance
  double get monthlyBalance => monthlyIncome - monthlyExpense;

  /// All-time total income
  double get totalIncome =>
      _expenses.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

  /// All-time total expenses
  double get totalExpense =>
      _expenses.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

  /// All-time balance
  double get totalBalance => totalIncome - totalExpense;

  /// Today's expenses
  List<Expense> get todayExpenses {
    final now = DateTime.now();
    return _expenses.where((e) => e.date.isSameDay(now)).toList();
  }

  /// Today's total spending
  double get todayTotal {
    return todayExpenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Get spending totals per category (for pie chart) — current month only
  Map<String, double> get categoryTotals {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final e in _expenses) {
      if (!e.isIncome && e.date.isSameMonth(now)) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    return map;
  }

  /// Get category color by name
  int getCategoryColor(String name) {
    final cat = _categories.where((c) => c.name == name).firstOrNull;
    return cat?.colorValue ?? 0xFF6C5CE7;
  }

  /// Get category icon by name
  int getCategoryIcon(String name) {
    final cat = _categories.where((c) => c.name == name).firstOrNull;
    return cat?.iconCodePoint ?? 0xe0af;
  }

  /// Recent expenses (last 5)
  List<Expense> get recentExpenses =>
      _expenses.length > 5 ? _expenses.sublist(0, 5) : _expenses;

  /// Get daily totals for the current week (for potential bar chart)
  Map<String, double> get weeklyTotals {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final map = <String, double>{};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayTotal = _expenses
          .where((e) => !e.isIncome && e.date.isSameDay(day))
          .fold(0.0, (sum, e) => sum + e.amount);
      map[dayNames[i]] = dayTotal;
    }
    return map;
  }

  // ── Data Loading ────────────────────────────────────────

  /// Load local data from SQLite database expense_tracker.db (table transactions).
  Future<void> _loadLocalData() async {
    _categories = _hiveService.getAllCategories();
    try {
      final rows = await DatabaseHelper.instance.getTransactions();
      if (rows.isNotEmpty) {
        _expenses = rows
            .map((r) => Expense.fromMap(
                  r,
                  defaultIcon: getCategoryIcon(r['category'] as String? ?? ''),
                  defaultColor:
                      getCategoryColor(r['category'] as String? ?? ''),
                ))
            .toList();
        debugPrint(
            '[ExpenseProvider] _loadLocalData: loaded ${_expenses.length} expenses from SQLite');
      } else {
        // Fallback or seed from Hive cache if SQLite is initially empty
        final cached = _hiveService.getAllExpenses();
        if (cached.isNotEmpty) {
          for (final c in cached) {
            final newId =
                await DatabaseHelper.instance.insertTransaction(c.toMap());
            _expenses.add(c.copyWith(id: newId));
          }
          debugPrint(
              '[ExpenseProvider] Migrated ${cached.length} expenses into SQLite');
        }
      }
    } catch (e) {
      debugPrint('[ExpenseProvider] _loadLocalData SQLite error: $e');
      _expenses = _hiveService.getAllExpenses();
    }
    notifyListeners();
  }

  /// Load user-specific data from Supabase (called on login / session restore).
  /// First loads cached data from SQLite / Hive for instant UI, then fetches fresh from Supabase.
  Future<void> loadUserData() async {
    if (!_supabaseService.isEnabled || _supabaseService.currentUserId == null) {
      debugPrint(
          '[ExpenseProvider] loadUserData: no cloud — falling back to local');
      await _loadLocalData();
      return;
    }

    _isCloudMode = true;
    final uid = _supabaseService.currentUserId!;
    debugPrint(
        '[ExpenseProvider] loadUserData: cloud mode for user=${uid.substring(0, 8)}');

    // Step 1: Load from Hive cache immediately (instant UI)
    _expenses = _hiveService.getAllExpenses();
    _categories = _hiveService.getAllCategories();
    debugPrint(
        '[ExpenseProvider] loadUserData: cached ${_expenses.length} expenses from Hive');
    if (_expenses.isNotEmpty) {
      notifyListeners(); // Show cached data while fetching
    }

    // Step 2: Fetch fresh data from Supabase
    try {
      await _supabaseService.ensureSessionReady();

      // Fetch expenses from Supabase
      final expenseRows = await _supabaseService.fetchExpenses();
      _expenses = expenseRows
          .map((row) => Expense(
                id: row['id'] as String,
                title: row['title'] as String,
                amount: (row['amount'] as num).toDouble(),
                category: row['category'] as String,
                categoryIcon: row['category_icon'] as int,
                categoryColor: (row['category_color'] as num).toInt(),
                date: DateTime.parse(row['date'] as String),
                isIncome: _dynBool(row['is_income'], false),
                note: row['note'] as String?,
                userName: row['user_name'] as String?,
                isFamily: _dynBool(row['is_family'], false),
              ))
          .toList();

      // Cache to Hive for offline / next startup
      await _hiveService.cacheExpenses(_expenses);

      debugPrint(
          '[ExpenseProvider] loadUserData: fetched ${_expenses.length} expenses from Supabase');

      // Fetch categories from Supabase
      final catRows = await _supabaseService.fetchCategories();
      _categories = catRows.map((row) {
        final userId = row['user_id'];
        final isSystemDefault = userId == null;
        return ExpenseCategory(
          name: row['name'] as String,
          iconCodePoint: row['icon_code_point'] as int,
          colorValue: (row['color_value'] as num).toInt(),
          isDefault: _dynBool(row['is_default'], false) || isSystemDefault,
          supabaseId: row['id'] as String?,
        );
      }).toList()
        ..sort((a, b) {
          if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      notifyListeners();
    } catch (e) {
      debugPrint('[ExpenseProvider] loadUserData error: $e');
      // Keep whatever we loaded from cache
      if (_expenses.isEmpty) {
        debugPrint(
            '[ExpenseProvider] loadUserData: Supabase failed, keeping cached data');
      }
      notifyListeners();
    }
  }

  /// Clear all in-memory data (called on logout).
  void clearLocalData() {
    debugPrint('[ExpenseProvider] clearLocalData');
    _expenses = [];
    _categories = [];
    _isCloudMode = false;
    notifyListeners();
  }

  Future<List<Map<String, String>>> fetchFamilyPeerProfiles() async {
    if (!_isCloudMode) return [];
    try {
      return await _supabaseService.fetchFamilyPeerProfiles();
    } catch (e) {
      debugPrint('fetchFamilyPeerProfiles: $e');
      return [];
    }
  }

  Future<void> unlinkFamily() async {
    if (!_isCloudMode) return;
    try {
      await _supabaseService.unlinkFamily();
      notifyListeners();
    } catch (e) {
      debugPrint('Error unlinking family: $e');
    }
  }

  /// Switch to offline mode (SQLite local storage).
  Future<void> loadOfflineData() async {
    _isCloudMode = false;
    await _loadLocalData();
  }

  // ── Data Operations ─────────────────────────────────────

  /// Add a new expense or income to SQLite (and cloud if enabled)
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    bool isIncome = false,
    String? note,
  }) async {
    int? sqlId;
    try {
      sqlId = await DatabaseHelper.instance.insertTransaction({
        'title': title,
        'amount': amount,
        'category': category,
        'type': isIncome ? 'Income' : 'Expense',
        'date': date.toIso8601String(),
      });
      debugPrint(
          '[ExpenseProvider] addExpense: inserted to SQLite with id=$sqlId');
    } catch (e) {
      debugPrint('[ExpenseProvider] addExpense SQLite error: $e');
    }

    final expense = Expense(
      id: sqlId ?? const Uuid().v4(),
      title: title,
      amount: amount,
      category: category,
      categoryIcon: getCategoryIcon(category),
      categoryColor: getCategoryColor(category),
      date: date,
      isIncome: isIncome,
      note: note,
    );

    // Add to local state immediately
    _expenses.insert(0, expense);
    notifyListeners();

    // Always write to Hive cache
    await _hiveService.addExpense(expense);

    if (_isCloudMode) {
      try {
        await _supabaseService.addExpense({
          'id': expense.id.toString(),
          'title': title,
          'amount': amount,
          'category': category,
          'category_icon': getCategoryIcon(category),
          'category_color': getCategoryColor(category),
          'date': date.toIso8601String(),
          'is_income': isIncome,
          'note': note,
        });
        debugPrint(
            '[ExpenseProvider] addExpense: synced to cloud id=${expense.id}');
      } catch (e) {
        debugPrint('[ExpenseProvider] addExpense cloud error: $e');
      }
    }
  }

  /// Update an existing transaction in SQLite, Hive, and memory
  Future<void> updateExpense({
    required dynamic id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required bool isIncome,
    String? note,
  }) async {
    final intId = id is int ? id : int.tryParse(id.toString());
    if (intId != null) {
      try {
        await DatabaseHelper.instance.updateTransaction({
          'id': intId,
          'title': title,
          'amount': amount,
          'category': category,
          'type': isIncome ? 'Income' : 'Expense',
          'date': date.toIso8601String(),
        });
        debugPrint(
            '[ExpenseProvider] updateExpense: updated SQLite transaction id=$intId');
      } catch (e) {
        debugPrint('[ExpenseProvider] updateExpense SQLite error: $e');
      }
    }

    final updated = Expense(
      id: id,
      title: title,
      amount: amount,
      category: category,
      categoryIcon: getCategoryIcon(category),
      categoryColor: getCategoryColor(category),
      date: date,
      isIncome: isIncome,
      note: note,
    );

    final idx = _expenses
        .indexWhere((e) => e.id == id || e.id.toString() == id.toString());
    if (idx != -1) {
      _expenses[idx] = updated;
    }
    notifyListeners();

    await _hiveService.updateExpense(updated);

    if (_isCloudMode) {
      try {
        await _supabaseService.updateExpense(id.toString(), {
          'title': title,
          'amount': amount,
          'category': category,
          'category_icon': getCategoryIcon(category),
          'category_color': getCategoryColor(category),
          'date': date.toIso8601String(),
          'is_income': isIncome,
          'note': note,
        });
        debugPrint('[ExpenseProvider] updateExpense: synced to cloud id=$id');
      } catch (e) {
        debugPrint('[ExpenseProvider] updateExpense cloud error: $e');
      }
    }
  }

  /// Delete an expense by ID from SQLite, Hive, and in-memory state
  Future<void> deleteExpense(dynamic id) async {
    final intId = id is int ? id : int.tryParse(id.toString());
    if (intId != null) {
      try {
        await DatabaseHelper.instance.deleteTransaction(intId);
        debugPrint(
            '[ExpenseProvider] deleteExpense: deleted from SQLite id=$intId');
      } catch (e) {
        debugPrint('[ExpenseProvider] deleteExpense SQLite error: $e');
      }
    }

    _expenses
        .removeWhere((e) => e.id == id || e.id.toString() == id.toString());
    notifyListeners();

    // Always delete from Hive cache
    await _hiveService.deleteExpense(id.toString());

    if (_isCloudMode) {
      try {
        await _supabaseService.deleteExpense(id.toString());
        debugPrint('[ExpenseProvider] deleteExpense: synced to cloud id=$id');
      } catch (e) {
        debugPrint('[ExpenseProvider] deleteExpense cloud error: $e');
      }
    }
  }

  /// Add a new custom category
  Future<void> addCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    String? cloudId;
    if (_isCloudMode) {
      try {
        cloudId = await _supabaseService.addCategory({
          'name': name,
          'icon_code_point': iconCodePoint,
          'color_value': colorValue,
          'is_default': false,
        });
      } catch (e) {
        debugPrint('Error syncing category to cloud: $e');
        return;
      }
    } else {
      final category = ExpenseCategory(
        name: name,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        isDefault: false,
      );
      await _hiveService.addCategory(category);
    }

    _categories.add(ExpenseCategory(
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isDefault: false,
      supabaseId: cloudId,
    ));
    notifyListeners();
  }

  /// Delete a category locally and in Supabase when applicable.
  /// Returns an error message, or null on success.
  Future<String?> deleteCategory(ExpenseCategory cat) async {
    if (_isCloudMode) {
      if (cat.supabaseId == null) {
        return 'Missing category id — sign out and back in, then try again.';
      }
      try {
        await _supabaseService.deleteCategory(cat.supabaseId!);
      } catch (e) {
        debugPrint('Error deleting category from cloud: $e');
        return 'Delete failed. Built-in categories may be protected in your Supabase policies.';
      }
    } else {
      if (cat.isDefault) {
        return 'Built-in categories cannot be deleted in offline mode.';
      }
      await _hiveService.deleteCategory(cat.name);
    }

    _categories.removeWhere((c) => c.name == cat.name);
    notifyListeners();
    return null;
  }

  /// Check if category name already exists
  bool categoryExists(String name) {
    return _categories.any((c) => c.name.toLowerCase() == name.toLowerCase());
  }
}
