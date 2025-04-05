import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BankBalanceScreen extends StatefulWidget {
  const BankBalanceScreen({super.key});

  @override
  _BankBalanceScreenState createState() => _BankBalanceScreenState();
}

class _BankBalanceScreenState extends State<BankBalanceScreen> {
  final TextEditingController _balanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBalance();
  }

  // Fetch current bank balance
  Future<void> _fetchCurrentBalance() async {
    try {
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Fetch bank balance
      final response = await supabase
          .from('bank_balances')
          .select('balance')
          .eq('user_id', user.id)
          .single();

      // Set balance if found
      if (response != null) {
        setState(() {
          _balanceController.text = response['balance'].toString();
        });
      }
    } catch (e) {
      print('Error fetching balance: $e');
    }
  }

  // Update bank balance
  Future<void> _updateBankBalance() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Get current user
        final user = supabase.auth.currentUser;
        if (user == null) {
          throw Exception('No user logged in');
        }

        // Parse balance
        final balance = double.parse(_balanceController.text);

        // Upsert balance (insert or update)
        await supabase
            .from('bank_balances')
            .upsert({
          'user_id': user.id,
          'balance': balance,
        },
            onConflict: 'user_id'
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bank Balance Updated: $balance'),
              backgroundColor: Colors.green,
            )
        );

        // Return to previous screen with a flag to indicate update
        Navigator.pop(context, true);

      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating balance: $e'),
              backgroundColor: Colors.red,
            )
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Balance'),
        backgroundColor: const Color(0xFF5E72E4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Enter Bank Balance',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your bank balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateBankBalance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E72E4),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Update Bank Balance',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}