import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pennyai/screens/expenditure/expenditure.dart';
import 'package:pennyai/screens/expenditure/graph.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllExpenses();
  }

  Future<void> _fetchAllExpenses() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch all expenses without user filtering
      final response = await supabase
          .from('expenses')
          .select('*')
          .order('date', ascending: false);

      setState(() {
        _expenses = response.map((json) => Expense.fromMap(json)).toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching expenses: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching expenses: $error')),
      );
    }
  }

  // Method to delete an expense
  Future<void> _deleteExpense(int expenseId) async {
    try {
      final supabase = Supabase.instance.client;

      // Show confirmation dialog
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      // If user confirms deletion
      if (confirmDelete == true) {
        // Delete the expense from Supabase
        await supabase.from('expenses').delete().eq('id', expenseId);

        // Remove from local list and update UI
        setState(() {
          _expenses.removeWhere((expense) => expense.id == expenseId);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      // Handle any errors during deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format currency in INR
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    return formatter.format(amount);
  }

  // Calculate total expenses
  double get _totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('All Expenses'),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: _expenses.isEmpty
                ? _buildEmptyState()
                : _buildExpensesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5E72E4),
        onPressed: () {
          // Navigate to add expense screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenditureScreen(),
            ),
          ).then((_) {
            // Refresh the list when returning from add expense screen
            _fetchAllExpenses();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Expenses',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(_totalExpenses),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E72E4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_expenses.length} expenses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Export or view detailed reports functionality
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExpenseAnalysisScreen()),
                    );
                  },
                  child: const Text(
                    'View Reports',
                    style: TextStyle(
                      color: Color(0xFF5E72E4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildExpenseCard(expense),
        );
      },
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildCategoryIcon(expense.category),
        title: Text(
          expense.description,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM, yyyy').format(expense.date),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              expense.paymentMethod,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCurrency(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  // Navigate to edit expense screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenditureScreen(
                        expenseToEdit: ExpenseModel(
                          id: expense.id,
                          amount: expense.amount,
                          category: expense.category,
                          date: expense.date,
                          description: expense.description,
                          paymentMethod: expense.paymentMethod,
                          receiptImageUrl: expense.receiptImagePath,
                        ),
                      ),
                    ),
                  ).then((_) {
                    // Refresh the list when returning from edit screen
                    _fetchAllExpenses();
                  });
                } else if (value == 'delete') {
                  // Call delete method
                  _deleteExpense(expense.id!);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    IconData iconData;
    Color backgroundColor;

    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        iconData = Icons.restaurant;
        backgroundColor = Colors.red.shade100;
        break;
      case 'shopping':
        iconData = Icons.shopping_bag;
        backgroundColor = Colors.blue.shade100;
        break;
      case 'transportation':
        iconData = Icons.directions_car;
        backgroundColor = Colors.green.shade100;
        break;
      case 'entertainment':
        iconData = Icons.movie;
        backgroundColor = Colors.purple.shade100;
        break;
      case 'utilities':
        iconData = Icons.lightbulb;
        backgroundColor = Colors.orange.shade100;
        break;
      case 'health':
        iconData = Icons.healing;
        backgroundColor = Colors.pink.shade100;
        break;
      case 'travel':
        iconData = Icons.flight;
        backgroundColor = Colors.indigo.shade100;
        break;
      case 'education':
        iconData = Icons.school;
        backgroundColor = Colors.teal.shade100;
        break;
      case 'housing':
        iconData = Icons.home;
        backgroundColor = Colors.brown.shade100;
        break;
      case 'personal care':
        iconData = Icons.person;
        backgroundColor = Colors.cyan.shade100;
        break;
      default:
        iconData = Icons.category;
        backgroundColor = Colors.grey.shade100;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense by tapping the + button',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// Update the Expense class to include an id
class Expense {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String? receiptImagePath;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.receiptImagePath,
  });

  // Factory method to create an expense from a map (Supabase JSON)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? 'Uncategorized',
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      paymentMethod: map['payment_method'] ?? '',
      receiptImagePath: map['receipt_image_url'],
    );
  }
}