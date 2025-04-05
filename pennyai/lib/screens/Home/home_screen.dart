import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pennyai/screens/profile/bank_balance.dart';
import 'package:pennyai/screens/expenditure/expenditure.dart';
import 'package:pennyai/screens/expenditure/all_expence.dart';
import 'package:pennyai/screens/penny_assistant/penny_assistant.dart';
import 'package:pennyai/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  List<Expense> _recentExpenses = [];
  bool _isLoading = true;
  double _totalBalance = 0.0;
  double _monthlyBudget = 3000.0;
  double _monthlySpent = 0.0;
  double _remainingBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // Comprehensive data fetching method
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Fetch bank balance
      final balanceResponse = await supabase
          .from('bank_balances')
          .select('balance')
          .eq('user_id', user.id)
          .single();

      // Fetch recent expenses (last 30 days)
      final expensesResponse = await supabase
          .from('expenses')
          .select('*')
          .gte('date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('date', ascending: false)
          .limit(5);

      // Calculate monthly expenses
      final monthlyResponse = await supabase
          .from('expenses')
          .select('amount')
          .gte('date', DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String());

      // Update state with fetched data
      setState(() {
        // Total balance from bank balances
        _totalBalance = balanceResponse != null
            ? (balanceResponse['balance'] as num).toDouble()
            : 0.0;

        // Recent expenses
        _recentExpenses = expensesResponse.map((json) => Expense.fromMap(json)).toList();

        // Monthly spent calculation
        _monthlySpent = monthlyResponse.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

        // Remaining budget calculation
        _remainingBudget = _monthlyBudget - _monthlySpent;

        _isLoading = false;
      });
    } catch (error) {
      // Error handling
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Currency formatting method
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // App Bar Widget
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Penny AI',
        style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Times New Roman',
        color: Colors.white,
      ),),// ),
      backgroundColor: const Color(0xFF5E72E4),
      elevation: 0,
      actions: [
        CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.9),
          radius: 15,
          child: const Text('👤', style: TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // Body Widget
  Widget _buildBody() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 10),
              _buildBudgetCard(),
              const SizedBox(height: 10),
              _buildRecentExpenses(),
            ],
          ),
        ),
      ),
    );
  }

  // Balance Card Widget
  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Balance',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatCurrency(_totalBalance),
                  style: const TextStyle(
                    color: Color(0xFF2DCE89),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BankBalanceScreen()),
              );

              // Refresh data if balance was updated
              if (result == true) {
                _fetchInitialData();
              }
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF5E72E4),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('💲', style: TextStyle(fontSize: 14, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Budget Card Widget
  Widget _buildBudgetCard() {
    // Calculate budget progress
    double budgetProgress = (_monthlySpent / _monthlyBudget).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF5E72E4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📊', style: TextStyle(fontSize: 14, color: Colors.white)),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budgetProgress,
              backgroundColor: const Color(0xFFE9ECEF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5E72E4)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),

          // Spent and Budget Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatCurrency(_monthlySpent)} spent',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                '${_formatCurrency(_monthlyBudget)} budget',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Remaining Budget and Total Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining: ${_formatCurrency(_remainingBudget)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _remainingBudget > 0 ? const Color(0xFF2DCE89) : Colors.red,
                ),
              ),
              Text(
                'Total Balance: ${_formatCurrency(_totalBalance)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E72E4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent Expenses Widget
  Widget _buildRecentExpenses() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expenses Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Add Expense Button
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpenditureScreen()),
                      );

                      // Refresh if new expense added
                      if (result == true) {
                        _fetchInitialData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E72E4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '+ Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // See All Expenses
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllExpensesScreen()),
                      );
                    },
                    child: Text(
                      'See All →',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Expenses List
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentExpenses.isEmpty
              ? const Center(child: Text('No recent expenses'))
              : Column(
            children: _recentExpenses.map(_buildExpenseItem).toList(),
          ),
        ],
      ),
    );
  }

  // Single Expense Item Widget
  Widget _buildExpenseItem(Expense expense) {
    // Expense category emojis
    final categoryEmojis = {
      'food & dining': '🍔',
      'shopping': '🛒',
      'transportation': '🚗',
      'entertainment': '🎬',
      'utilities': '💡',
      'housing': '🏠',
      'health': '💊',
      'travel': '✈️',
      'education': '📚',
      'personal care': '💇',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Category Emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                categoryEmojis[expense.category.toLowerCase()] ?? '💸',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Expense Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(expense.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Expense Amount
          Text(
            _formatCurrency(expense.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E72E4),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar Widget
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) async {
        switch (index) {
          case 1:
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpenditureScreen()),
            );
            if (result == true) {
              _fetchInitialData();
            }
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllExpensesScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PennyAssistantScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Text('🏠', style: TextStyle(fontSize: 18)),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Text('💰', style: TextStyle(fontSize: 18)),
          label: 'Expense',
        ),
        BottomNavigationBarItem(
          icon: Text('🏦', style: TextStyle(fontSize: 18)),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: Text('🤖', style: TextStyle(fontSize: 18)),
          label: 'Penny',
        ),
        BottomNavigationBarItem(
          icon: Text('👤', style: TextStyle(fontSize: 18)),
          label: 'Profile',
        ),
      ],
      selectedItemColor: const Color(0xFF5E72E4),
      unselectedItemColor: Colors.grey.shade600,
    );
  }
}

// Expense Model
class Expense {
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String? receiptImagePath;

  Expense({
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.receiptImagePath,
  });

  // Factory method to create an expense from a map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? 'Uncategorized',
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      paymentMethod: map['payment_method'] ?? '',
      receiptImagePath: map['receipt_image_path'],
    );
  }
}