import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserStorageService {
  // Supabase configuration
  static final supabase = Supabase.instance.client;

  // API Keys and constants (consider moving to a secure configuration)
  static const String imgBbApiKey = '2ba2c000eb664f7f885f1653aad35ed8';

  // Authentication Methods
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Sign up user with additional metadata
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      // If signup is successful, insert user profile
      if (response.user != null) {
        await _insertUserProfile(
          id: response.user!.id,
          email: email,
          name: name,
        );

        return response;
      }
      return null;
    } on AuthException catch (e) {
      // More detailed error logging for authentication exceptions
      debugPrint('Authentication Error: ${e.message}');
      return null;
    } catch (e) {
      // Catch any other unexpected errors
      debugPrint('Signup error: $e');
      return null;
    }
  }

  // Manually insert user profile after signup
  static Future<bool> _insertUserProfile({
    required String id,
    required String email,
    required String name,
  }) async {
    try {
      // Upsert user profile with detailed error handling
      final response = await supabase
          .from('profiles')
          .upsert({
        'id': id,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select();

      // Verify the insert was successful
      if (response == null || response.isEmpty) {
        debugPrint('Failed to insert user profile');
        return false;
      }

      debugPrint('User profile inserted successfully');
      return true;
    } catch (e) {
      debugPrint('Error inserting user profile: $e');
      return false;
    }
  }

  // Login method with improved error handling
  static Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response.user != null ? response : null;
    } on AuthException catch (e) {
      debugPrint('Login error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      return null;
    }
  }

  // Logout method
  static Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // Upload image to ImgBB with proper URL extraction
  static Future<String?> uploadImageToImgBB(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );

      request.fields['key'] = imgBbApiKey;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parse JSON response to extract image URL
        final jsonResponse = json.decode(responseBody);

        // ImgBB typically returns image URL in this structure
        if (jsonResponse['data'] != null && jsonResponse['data']['url'] != null) {
          return jsonResponse['data']['url'];
        }

        debugPrint('Unexpected ImgBB response structure');
        return null;
      }

      debugPrint('Image upload failed with status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // Get user profile with comprehensive error handling
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile with comprehensive error handling
  static Future<bool> updateUserProfile({
    required String name,
    required String email,
    String? profileImageUrl,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'email': email,
        'profile_image_url': profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Method to pick an image from gallery
  static Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      debugPrint('Image picking error: $e');
      return null;
    }
  }
}