// lib/models/expense.dart
import 'package:hive/hive.dart';

// The 'part' directive links this file to its generated counterpart.
// Run: flutter pub run build_runner build --delete-conflicting-outputs
part 'expense.g.dart';

// ── Expense Category Enum ──────────────────────────────────────────────────
// typeId: 0 — must be unique across the entire project
@HiveType(typeId: 0)
enum ExpenseCategory {
  @HiveField(0)
  food, // ₱ spent on meals, snacks, groceries
  @HiveField(1)
  transport, // ₱ spent on Grab, jeep, tricycle, bus
  @HiveField(2)
  shopping, // ₱ spent on clothing, supplies, gadgets
  @HiveField(3)
  utilities, // ₱ spent on load, WiFi, electricity
  @HiveField(4)
  entertainment, // ₱ spent on streaming, movies, events
  @HiveField(5)
  other, // Everything else
}

// ── Expense Class ──────────────────────────────────────────────────────────
// typeId: 1 — different from the enum's typeId: 0
// Extending HiveObject gives access to .key, .save(), and .delete() shortcuts
@HiveType(typeId: 1)
class Expense extends HiveObject {
  // ⚠️ IMPORTANT: Once data is stored, NEVER change these @HiveField IDs.
  // Changing a field ID causes Hive to read the wrong value for that field.

  @HiveField(0)
  late String title; // e.g., "Jollibee Lunch", "Grab Ride to School"

  @HiveField(1)
  late double amount; // Always store in Philippine Peso (₱)

  @HiveField(2)
  late ExpenseCategory category; // Which category this expense belongs to

  @HiveField(3)
  late DateTime date; // The date the expense was incurred

  // Constructor — used when creating new Expense objects in the app
  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  // Helper getter — returns a human-readable name for the category.
  // NOT stored in Hive (no @HiveField annotation).
  String get categoryName {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}
