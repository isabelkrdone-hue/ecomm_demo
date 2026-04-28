import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileModel extends ChangeNotifier {
  ProfileModel._privateConstructor();
  static final ProfileModel instance = ProfileModel._privateConstructor();

  String _name = 'Isabel';
  String _email = 'isabel@email.com';
  String _phone = '+62 812-3456-7890';
  String _bio = 'Senang berbelanja produk lokal berkualitas.';
  String? _profileImagePath;

  // Getters
  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get bio => _bio;
  String? get profileImagePath => _profileImagePath;

  // Load profile data from SharedPreferences
  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('profile_name') ?? 'Isabel';
      _email = prefs.getString('profile_email') ?? 'isabel@email.com';
      _phone = prefs.getString('profile_phone') ?? '+62 812-3456-7890';
      _bio = prefs.getString('profile_bio') ?? 'Senang berbelanja produk lokal berkualitas.';
      _profileImagePath = prefs.getString('profile_image_path');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  // Save profile data to SharedPreferences
  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', name);
      await prefs.setString('profile_email', email);
      await prefs.setString('profile_phone', phone);
      await prefs.setString('profile_bio', bio);

      _name = name;
      _email = email;
      _phone = phone;
      _bio = bio;

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  // Save profile image path
  Future<void> saveProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', imagePath);
      _profileImagePath = imagePath;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      rethrow;
    }
  }

  // Check if profile image exists
  bool hasProfileImage() {
    if (_profileImagePath == null || _profileImagePath!.isEmpty) {
      return false;
    }
    return File(_profileImagePath!).existsSync();
  }
}
