// lib/services/expense_service.dart
//
// Service Layer Pattern: All Hive box operations are centralised here.
// UI widgets never access the Hive box directly — they only call this service.
// This keeps data logic decoupled from presentation logic.
import 'package:flutter/foundation.dart'; // For ValueListenable
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  // Box name constant — must match the name used in Hive.openBox() in main.dart.
  // Using a constant prevents typo bugs (e.g., 'expense' vs 'expenses').
  static const String _boxName = 'expenses';

  // Private getter that retrieves the already-open typed box.
  // Using a getter (not a stored field) ensures we always get the live reference.
  static Box<Expense> get _box => Hive.box<Expense>(_boxName);

  // ── CREATE ──────────────────────────────────────────────────────────────
  // box.add() stores the expense and auto-assigns a unique integer key.
  // The returned Future<int> (the new key) is ignored here.
  static Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }

  // ── READ (ALL) ──────────────────────────────────────────────────────────
  // box.values returns an Iterable — converted to a List for UI use.
  // Returned in insertion order (oldest first) unless sorted by the caller.
  static List<Expense> getAllExpenses() {
    return _box.values.toList();
  }

  // ── READ (FILTERED BY CATEGORY) ─────────────────────────────────────────
  // Uses Dart's where() for in-memory filtering.
  // Hive has no query language, so all filtering is done in Dart.
  static List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _box.values
        .where((expense) => expense.category == category)
        .toList();
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────
  // box.put(key, value) replaces the value stored at the given integer key.
  // The key is the auto-assigned integer from box.add(), accessed via expense.key.
  static Future<void> updateExpense(int key, Expense updated) async {
    await _box.put(key, updated);
  }

  // ── DELETE ──────────────────────────────────────────────────────────────
  // box.delete(key) removes the entry from the box entirely.
  static Future<void> deleteExpense(int key) async {
    await _box.delete(key);
  }

  // ── REACTIVE LISTENER ───────────────────────────────────────────────────
  // Returns a ValueListenable that notifies listeners on ANY box change.
  // Pass this to ValueListenableBuilder in your widgets for auto-rebuilds
  // without polling or setState calls for data changes.
  static ValueListenable<Box<Expense>> get listenable => _box.listenable();

  // ── HELPERS ─────────────────────────────────────────────────────────────

  // Sum of all expense amounts currently in the box.
  static double getTotalExpenses() {
    return _box.values.fold(0.0, (sum, e) => sum + e.amount);
  }

  // Sum of expenses for a specific year + month combination.
  // Used by Exercise 2 (budget tracker) and Exercise 3 (monthly export).
  static double getMonthlyTotal(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Returns expenses for a specific month, sorted by date ascending.
  // Used by Exercise 3 export feature.
  static List<Expense> getMonthlyExpenses(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
