import 'package:flutter/material.dart';
import 'package:model2/services/api_service.dart';

enum UserRole { guest, member, moderator, admin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole role = UserRole.member;
    if (json['role'] == 'Admin') role = UserRole.admin;
    if (json['role'] == 'Moderator') role = UserRole.moderator;

    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: role,
    );
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  UserRole get role => _user?.role ?? UserRole.guest;

  Future<bool> login(String email, String password) async {
    final response = await ApiService.login(email, password);
    if (response['success'] == true) {
      _user = User.fromJson(response['user']);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password, String name, String role) async {
    final response = await ApiService.register(email, password, name, role);
    if (response['success'] == true) {
      _user = User.fromJson(response['user']);
      notifyListeners();
      return true;
    }
    return false;
  }

  void loginAsGuest() {
    _user = null;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
