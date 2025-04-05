import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Screens
import 'package:pennyai/screens/profile/language.dart';
import 'package:pennyai/screens/profile/edit_profile.dart';
import 'package:pennyai/screens/profile/bank_balance.dart';
import 'package:pennyai/services/supabase.dart';
import 'package:pennyai/screens/Auth/auth.dart';
import 'package:pennyai/screens/expenditure/all_expence.dart';
import 'package:pennyai/screens/penny_assistant/penny_assistant.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _bankBalance = 0.0;
  double _totalExpenses = 0.0;
  String _userName = 'Loading...';
  String _userEmail = '';
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch user profile from user_profiles table
      final userId = UserStorageService.supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user profile
      final profileResponse = await UserStorageService.supabase
          .from('user_profiles')
          .select()
          .eq('auth_user_id', userId)
          .single();

      // Fetch total expenses
      final expensesResponse = await UserStorageService.supabase
          .from('expenses')
          .select('amount');

      // Fetch bank balance from bank_balances table
      final bankBalanceResponse = await UserStorageService.supabase
          .from('bank_balances')
          .select('balance')
          .limit(1)
          .single();

      if (profileResponse != null) {
        setState(() {
          _userName = profileResponse['name'] ?? 'User';
          _userEmail = profileResponse['email'] ?? '';
          _profileImageUrl = profileResponse['profile_image_url'];

          // Use bank balance from bank_balances table
          _bankBalance = bankBalanceResponse != null
              ? (bankBalanceResponse['balance'] as num?)?.toDouble() ?? 0.0
              : 0.0;
        });
      }

      // Calculate total expenses
      if (expensesResponse is List) {
        _totalExpenses = expensesResponse
            .map((e) => (e['amount'] as num?)?.toDouble() ?? 0.0)
            .fold(0.0, (a, b) => a + b);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Format currency in INR
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    return formatter.format(amount);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                // Call logout method from UserStorageService
                UserStorageService.logout().then((_) {
                  // Navigate to login screen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (Route<dynamic> route) => false,
                  );
                }).catchError((error) {
                  // Handle any potential logout errors
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $error')),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Times New Roman',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF5E72E4),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 10),
              _buildFinancialStatsSection(),
              const SizedBox(height: 15),
              _buildMenuItems(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5E72E4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              image: _profileImageUrl != null
                  ? DecorationImage(
                image: NetworkImage(_profileImageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _profileImageUrl == null
                ? const Center(
              child: Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF5E72E4),
              ),
            )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _userEmail,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            value: _formatCurrency(_bankBalance),
            label: 'Current Balance',
          ),
          _buildStatItem(
            value: _formatCurrency(_totalExpenses),
            label: 'Total Expenditure',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5E72E4),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.edit,
        'title': 'Edit Profile',
        'screen': const EditProfileScreen()
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Bank Balance',
        'screen': const BankBalanceScreen()
      },
      {
        'icon': Icons.language,
        'title': 'Language Preference',
        'screen': const LanguagePreferenceScreen()
      },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'screen': null
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFF5E72E4),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF5E72E4),
                ),
                onTap: () {
                  if (item['screen'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => item['screen'] as Widget,
                      ),
                    ).then((_) {
                      // Refresh financial stats when returning from screens
                      _fetchProfileData();
                    });
                  } else {
                    _showLogoutDialog(context);
                  }
                },
              ),
              if (index < menuItems.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.grey.shade300,
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pop(context);
            break;
          case 1:
          // Navigate to AllExpensesScreen when Insights is tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllExpensesScreen()),
            );
            break;
          case 2:
          // Navigate to AllExpensesScreen when Insights is tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PennyAssistantScreen()),
            );
        // Add other navigation logic as needed
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF5E72E4),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'Penny',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}