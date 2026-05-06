// lib/services/export_service.dart
//
// Exercise 3: Monthly Data Export
// Generates a plain-text expense report for the current month and saves it
// to the device's documents directory using path_provider.
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'expense_service.dart';

class ExportService {
  /// Exports all expenses for the current month to a .txt file.
  ///
  /// Returns the absolute file path so the UI can display it in a SnackBar.
  /// File is saved to getApplicationDocumentsDirectory(), which is persistent
  /// and survives app restarts (but is app-private on Android/iOS).
  static Future<String> exportCurrentMonth() async {
    final now = DateTime.now();
    // Human-readable month label for the report header (e.g., "May 2025")
    final monthLabel = DateFormat('MMMM yyyy').format(now);
    // Short date format used per expense line (e.g., "May 15, 2025")
    final fmt = DateFormat('MMM dd, yyyy');

    // Retrieve and sort expenses for the current month only
    final monthly = ExpenseService.getMonthlyExpenses(now.year, now.month);

    // Build the report as a StringBuffer (efficient for many string appends)
    final buf = StringBuffer();
    buf.writeln('========================================');
    buf.writeln('        SPENDWISE EXPENSE REPORT');
    buf.writeln('        $monthLabel');
    buf.writeln('========================================');
    buf.writeln();

    if (monthly.isEmpty) {
      // Inform the reader if there are no expenses for this month
      buf.writeln('  No expenses recorded for $monthLabel.');
      buf.writeln();
    }

    double total = 0;
    for (final e in monthly) {
      // Each line: Date (padded) | Category (padded) | Amount (right-aligned) | Title
      buf.writeln(
        '${fmt.format(e.date).padRight(16)} '
        '${e.categoryName.padRight(14)} '
        '₱${e.amount.toStringAsFixed(2).padLeft(10)} '
        '  ${e.title}',
      );
      total += e.amount;
    }

    buf.writeln();
    buf.writeln('----------------------------------------');
    // Right-align the total to match the amount column
    buf.writeln('${' ' * 32}TOTAL  ₱${total.toStringAsFixed(2)}');
    buf.writeln('========================================');
    buf.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}');
    buf.writeln('Expenses exported: ${monthly.length}');

    // Resolve the app's documents directory (cross-platform, persistent)
    final dir = await getApplicationDocumentsDirectory();

    // Filename pattern: spendwise_2025_05.txt
    final fileName =
        'spendwise_${now.year}_${now.month.toString().padLeft(2, '0')}.txt';
    final file = File('${dir.path}/$fileName');

    // Write the report to disk (overwrites if file already exists)
    await file.writeAsString(buf.toString());

    // Return the full path so the calling UI can display it
    return file.path;
  }
}
