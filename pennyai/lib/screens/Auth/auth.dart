import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pennyai/screens/profile/edit_profile.dart';
import 'package:pennyai/screens/Profile/profile_screen.dart';
import 'package:pennyai/screens/Home/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controllers for text inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // State variables
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Toggle between login and signup modes
  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  // Handle authentication process
  Future<void> _authenticate() async {
    // Validate input fields
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login process
        await _loginUser();
      } else {
        // Signup process
        await _signUpUser();
      }
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Login user method
  Future<void> _loginUser() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // Navigate to EditProfileScreen after successful login
        _navigateToEditProfile();
      } else {
        _showErrorSnackBar('Login failed. Please check your credentials.');
      }
    } catch (e) {
      _showErrorSnackBar('Login error: $e');
    }
  }

  // Signup user method
  Future<void> _signUpUser() async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'name': _nameController.text.trim()},
      );

      if (response.user != null) {
        // Reset to login mode after successful signup
        _resetSignupForm();
      } else {
        _showErrorSnackBar('Signup failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Signup error: $e');
    }
  }

  // Reset signup form after successful registration
  void _resetSignupForm() {
    setState(() {
      _isLogin = true;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
    });
    _showSuccessSnackBar('Signup successful. Please log in.');
  }

  // Navigate to edit profile screen
  void _navigateToEditProfile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // Input validation method
  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Please enter an email');
      return false;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return false;
    }

    if (!_isLogin && name.isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return false;
    }

    return true;
  }

  // Email validation method
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Show success messages
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Title
              _buildAppTitle(),
              const SizedBox(height: 30),

              // Name Field (Only for Signup)
              if (!_isLogin)
                _buildNameField(),

              // Email Field
              _buildEmailField(),

              // Password Field
              _buildPasswordField(),

              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 20),

              // Toggle between Login and Signup
              _buildToggleAuthModeButton(),
            ],
          ),
        ),
      ),
    );
  }

  // App Title Widget
  Widget _buildAppTitle() {
    return Text(
      'PennyAI',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5E72E4),
      ),
    );
  }

  // Widget for name input field
  Widget _buildNameField() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget for email input field
  Widget _buildEmailField() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget for password input field
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      obscureText: _obscurePassword,
    );
  }

  // Widget for submit button
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _authenticate,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E72E4),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
        _isLogin ? 'Login' : 'Sign Up',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  // Widget for toggling between login and signup
  Widget _buildToggleAuthModeButton() {
    return TextButton(
      onPressed: _toggleAuthMode,
      child: Text(
        _isLogin
            ? 'Create an account'
            : 'Already have an account? Login',
        style: TextStyle(color: const Color(0xFF5E72E4)),
      ),
    );
  }

  // Dispose controllers to prevent memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}