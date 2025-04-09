import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import screens
import 'screens/penny_assistant/penny_assistant.dart';
import 'screens/expenditure/expenditure.dart';
import 'screens/Home/home_screen.dart';
import 'screens/Auth/auth.dart'; // Add the new auth screen
import 'screens/profile/edit_profile.dart'; // Add the edit profile screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://abenadgfboxxgsrdwswk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiZW5hZGdmYm94eGdzcmR3c3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI2NjY4MTQsImV4cCI6MjA1ODI0MjgxNH0.EJ1V95vPNf2vpcIpS77ME1rsaDPWasnw173bEBLEKlU',
  );

  runApp(const PennyAIApp());
}

class PennyAIApp extends StatelessWidget {
  const PennyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penny AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5E72E4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E72E4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      // Use onGenerateRoute for more dynamic routing
      onGenerateRoute: (settings) {
        // Check if user is authenticated
        final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

        // Define route mapping
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => isAuthenticated ? HomeScreen() : const AuthScreen(),
            );
          case '/assistant':
            return MaterialPageRoute(
              builder: (_) => isAuthenticated
                  ? const PennyAssistantScreen()
                  : const AuthScreen(),
            );
          case '/expense':
            return MaterialPageRoute(
              builder: (_) => isAuthenticated
                  ? const ExpenditureScreen()
                  : const AuthScreen(),
            );
          case '/edit-profile':
            return MaterialPageRoute(
              builder: (_) => isAuthenticated
                  ? const EditProfileScreen()
                  : const AuthScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => isAuthenticated ? HomeScreen() : const AuthScreen(),
            );
        }
      },
      // Fallback route
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Determine initial screen based on authentication state
          return snapshot.data?.session != null
              ? HomeScreen()
              : const AuthScreen();
        },
      ),
    );
  }
}