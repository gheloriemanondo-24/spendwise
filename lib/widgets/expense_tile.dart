// lib/widgets/expense_tile.dart
//
// Reusable widget used by HomeScreen's ListView.
// Implements swipe-to-delete (Dismissible) with a confirmation dialog
// and an edit icon button that opens EditExpenseScreen.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete; // Called after confirmed swipe-delete
  final VoidCallback onEdit; // Called when the edit icon is tapped

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  // Maps each ExpenseCategory to a representative Material icon.
  // Adding a new category here requires a matching case in the switch.
  IconData _icon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.entertainment:
        return Icons.movie_outlined;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // expense.key is Hive's unique integer key — guaranteed unique per record.
      // Using ValueKey(expense.key) prevents duplicate-key errors when the list
      // reorders after a delete.
      key: ValueKey(expense.key),

      // Only allow right-to-left swipes (standard "delete" gesture on mobile)
      direction: DismissDirection.endToStart,

      // Red background revealed beneath the card as the user swipes left
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),

      // confirmDismiss lets us show a dialog BEFORE the item is removed.
      // Returning false cancels the dismiss and snaps the card back.
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Expense'),
                content:
                    Text('Delete "${expense.title}"? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false), // Cancel
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true), // Confirm
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false; // Null-safe: treat dialog dismissal (back button) as cancel
      },

      // onDismissed fires only when confirmDismiss returned true
      onDismissed: (_) => onDelete(),

      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          // Category icon in a coloured circle avatar
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              _icon(expense.category),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            expense.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            // e.g., "Food  ·  May 15, 2025"
            '${expense.categoryName}  ·  ${DateFormat('MMM dd, yyyy').format(expense.date)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount in bold indigo
              Text(
                '₱${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 4),
              // Edit button — navigates to EditExpenseScreen
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: onEdit,
                tooltip: 'Edit expense',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
