import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pennyai/services/supabase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseModel {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String? receiptImageUrl;

  ExpenseModel({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.receiptImageUrl,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
    'payment_method': paymentMethod,
    'receipt_image_url': receiptImageUrl,
  };
}

class ExpenditureScreen extends StatefulWidget {
  final ExpenseModel? expenseToEdit;

  const ExpenditureScreen({Key? key, this.expenseToEdit}) : super(key: key);

  @override
  _ExpenditureScreenState createState() => _ExpenditureScreenState();
}

class _ExpenditureScreenState extends State<ExpenditureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  File? _receiptImage;
  String? _receiptImageUrl;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Entertainment',
    'Utilities',
    'Health',
    'Travel',
    'Education',
    'Others'
  ];

  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Cash',
    'Bank Transfer',
    'Mobile Payment',
    'UPI',
    'Check'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
  }

  void _initializeFormFields() {
    final expense = widget.expenseToEdit;

    _amountController = TextEditingController(
      text: expense != null
          ? NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(expense.amount)
          : '',
    );

    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );

    _selectedDate = expense?.date ?? DateTime.now();
    _selectedCategory = expense?.category ?? _categories.first;
    _selectedPaymentMethod = expense?.paymentMethod ?? _paymentMethods.first;
    _receiptImageUrl = expense?.receiptImageUrl;
  }

  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = '2ba2c000eb664f7f885f1653aad35ed8'
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<void> _pickReceiptImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_receiptImage != null) {
        _receiptImageUrl = await _uploadImageToImgBB(_receiptImage!);
      }

      final expenseData = ExpenseModel(
        id: widget.expenseToEdit?.id,
        amount: _parseAmount(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        description: _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
        receiptImageUrl: _receiptImageUrl,
      );

      if (widget.expenseToEdit == null) {
        await _supabase.from('expenses').insert(expenseData.toJson());
      } else {
        await _supabase
            .from('expenses')
            .update(expenseData.toJson())
            .eq('id', widget.expenseToEdit!.id as Object);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.expenseToEdit == null
                ? 'Expense added successfully'
                : 'Expense updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          widget.expenseToEdit == null
              ? 'Add Expense'
              : 'Edit Expense',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      )
          : _buildExpenseForm(),
    );
  }

  Widget _buildExpenseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Expense Details'),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildPaymentMethodDropdown(),
            const SizedBox(height: 16),
            _buildReceiptUpload(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = _parseAmount(value);
        if (amount <= 0) {
          return 'Amount must be greater than zero';
        }
        return null;
      },
      onChanged: (value) {
        final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
        final parts = cleanedValue.split('.');
        String formattedValue;

        if (parts.length > 2) {
          formattedValue = parts.first + '.' + parts.sublist(1).join('');
        } else {
          formattedValue = cleanedValue;
        }

        if (parts.length == 2 && parts[1].length > 2) {
          formattedValue = '${parts[0]}.${parts[1].substring(0, 2)}';
        }

        if (formattedValue != value) {
          _amountController.value = TextEditingValue(
            text: formattedValue,
            selection: TextSelection.collapsed(offset: formattedValue.length),
          );
        }
      },
    );
  }

  double _parseAmount(String amountText) {
    final cleanedText = amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanedText) ?? 0.0;
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      items: _categories
          .map((category) => DropdownMenuItem(
        value: category,
        child: Text(category),
      ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
      validator: (value) =>
      value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.deepPurple,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
            Icon(Icons.calendar_today, color: Colors.deepPurple.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'What was this expense for?',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      items: _paymentMethods
          .map((method) => DropdownMenuItem(
        value: method,
        child: Text(method),
      ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        }
      },
      validator: (value) =>
      value == null ? 'Please select a payment method' : null,
    );
  }

  Widget _buildReceiptUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Receipt Image (Optional)'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickReceiptImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildReceiptContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptContent() {
    if (_receiptImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          _receiptImage!,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_receiptImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          _receiptImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
            );
          },
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, size: 50, color: Colors.deepPurple),
          SizedBox(height: 10),
          Text(
            'Tap to upload receipt',
            style: TextStyle(color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveExpense,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
      ),
      child: Text(
        widget.expenseToEdit == null
            ? 'Add Expense'
            : 'Update Expense',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}