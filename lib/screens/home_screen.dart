// lib/screens/home_screen.dart
//
// Exercise 1: Main dashboard — displays all expenses, filter chips, summary card.
// Exercise 2: Budget tracker — LinearProgressIndicator, Set Budget dialog,
//             80% threshold SnackBar alert, budget persisted in 'settings' box.
// Exercise 3: Export button in AppBar — calls ExportService and shows SnackBar.
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/export_service.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // null = show ALL categories; non-null = filter to that category only
  ExpenseCategory? _selectedCategory;

  //Exercise 2: Budget state
  // _budgetAlertShown prevents the SnackBar from firing on every rebuild
  bool _budgetAlertShown = false;

  // Returns the currently saved monthly budget from the 'settings' Hive box.
  // Returns 0.0 if no budget has been set yet.
  double _getBudget() {
    final box = Hive.box('settings');
    return (box.get('monthly_budget') ?? 0.0) as double;
  }

  // Saves the budget to the 'settings' box and triggers a rebuild so the
  // progress bar and SnackBar logic re-evaluate.
  Future<void> _setBudget(double value) async {
    await Hive.box('settings').put('monthly_budget', value);
    // Reset alert flag so the SnackBar can fire again for the new budget
    setState(() => _budgetAlertShown = false);
  }

  //Exercise 2: Set Budget Dialog
  // Shows a dialog with a text field for entering the monthly budget amount.
  void _showSetBudgetDialog() {
    final ctrl = TextEditingController(
      text: _getBudget() > 0 ? _getBudget().toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixText: '₱ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                await _setBudget(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  //Exercise 3: Export Handler
  // Calls ExportService, awaits the file path, then shows a SnackBar.
  Future<void> _exportMonth() async {
    try {
      final path = await ExportService.exportCurrentMonth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $path'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  // Maps enum to display string for filter chip labels
  String _label(ExpenseCategory? cat) {
    if (cat == null) return 'All';
    switch (cat) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpendWise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          //Exercise 3: Export icon button
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export this month',
            onPressed: _exportMonth,
          ),
          //Exercise 2: Set Budget icon button
          IconButton(
            icon: const Icon(Icons.savings_outlined),
            tooltip: 'Set monthly budget',
            onPressed: _showSetBudgetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'SpendWise',
              applicationVersion: '1.0.0',
              children: [
                const Text('A personal expense tracker built with Hive.\n'
                    'Lab 05 — Mobile Applications Development'),
              ],
            ),
          ),
        ],
      ),

      // ValueListenableBuilder subscribes to Hive box changes.
      // Any add, update, or delete automatically rebuilds the entire body —
      // no setState() needed for data changes.
      body: ValueListenableBuilder<Box<Expense>>(
        valueListenable: ExpenseService.listenable,
        builder: (context, box, _) {
          // Recalculate totals every time the box notifies a change
          final double total = box.values.fold(0.0, (s, e) => s + e.amount);
          final double budget = _getBudget();

          // Filter or show all, then sort newest-first
          final List<Expense> expenses = _selectedCategory == null
              ? ExpenseService.getAllExpenses()
              : ExpenseService.getExpensesByCategory(_selectedCategory!);
          expenses.sort((a, b) => b.date.compareTo(a.date));

          //Exercise 2: Budget alert at 80% threshold
          // addPostFrameCallback defers the SnackBar until after build completes
          if (budget > 0 && !_budgetAlertShown) {
            final pct = total / budget;
            if (pct >= 0.8) {
              _budgetAlertShown = true; // Prevents repeated firing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '⚠️ Budget Alert: You\'ve used '
                        '${(pct * 100).toStringAsFixed(0)}% of your '
                        'monthly budget!',
                      ),
                      backgroundColor: Colors.orange[800],
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              });
            }
          }

          return Column(
            children: [
              _buildSummaryCard(context, total, box.length, budget),
              _buildFilterChips(),
              Expanded(child: _buildExpenseList(context, expenses)),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  //Summary Card (Exercise 1 + Exercise 2)
  // Shows total spending, expense count, and — if a budget is set —
  // a LinearProgressIndicator that turns red at 80%.
  Widget _buildSummaryCard(
      BuildContext context, double total, int count, double budget) {
    final double pct = budget > 0 ? (total / budget).clamp(0.0, 1.0) : 0.0;
    final bool overThreshold = pct >= 0.8 && budget > 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Top row: label + total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Spending',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      '$count expense${count == 1 ? '' : 's'}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),

            //Exercise 2: Budget progress bar
            if (budget > 0) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget: ₱${budget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}% used',
                    style: TextStyle(
                      fontSize: 12,
                      color: overThreshold ? Colors.red[700] : Colors.black54,
                      fontWeight:
                          overThreshold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar turns red when spending >= 80% of budget
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey[300],
                  color: overThreshold ? Colors.red : Colors.indigo,
                  minHeight: 12,
                ),
              ),
              if (overThreshold)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '⚠️ You are approaching or over your budget!',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            // Prompt to set a budget if none exists yet
            if (budget <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: _showSetBudgetDialog,
                  child: Row(
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 14, color: Colors.indigo[300]),
                      const SizedBox(width: 4),
                      Text(
                        'Tap the 🏦 icon to set a monthly budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo[300],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //Filter Chips
  // Horizontal scrollable row: "All" plus one chip per category.
  // Selecting a chip updates _selectedCategory which re-filters the list.
  Widget _buildFilterChips() {
    final categories = [null, ...ExpenseCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_label(cat)),
              selected: _selectedCategory == cat,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  //Expense List
  // Empty state with icon + message when no expenses match the current filter.
  Widget _buildExpenseList(BuildContext context, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No expenses yet!',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == null
                  ? 'Tap the button below to add your first expense.'
                  : 'No expenses in the "${_label(_selectedCategory)}" category.',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (ctx, i) {
        final expense = expenses[i];
        final int key = expense.key as int;
        return ExpenseTile(
          expense: expense,
          // Pass the Hive key to deleteExpense so the correct record is removed
          onDelete: () => ExpenseService.deleteExpense(key),
          onEdit: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => EditExpenseScreen(
                expense: expense,
                expenseKey: key,
              ),
            ),
          ),
        );
      },
    );
  }
}
