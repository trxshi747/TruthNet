import 'package:flutter/material.dart';
import 'package:model2/services/api_service.dart';

enum UserRole { guest, member, moderator, admin }

class User {
  String id;
  String email;
  String name;
  UserRole role;
  String? profileImageUrl;
  String? bio;
  String? profileColor; // Hex string, e.g., "0xFFF0C38E"

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    this.bio,
    this.profileColor,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole role = UserRole.member;
    if (json['role'] == 'Admin') role = UserRole.admin;
    if (json['role'] == 'Moderator') role = UserRole.moderator;

    switch ((json['role'] ?? '').toString().toLowerCase()) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'moderator':
        role = UserRole.moderator;
        break;
      case 'member':
        role = UserRole.member;
        break;
      default:
        role = UserRole.guest;
    }

    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: role,
      bio: json['bio'],
      profileImageUrl: json['avatar'],
      profileColor: json['profileColor'],
    );
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  UserRole get role => _user?.role ?? UserRole.guest;

  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isModerator => _user?.role == UserRole.moderator;
  bool get isMember => _user?.role == UserRole.member;
  bool get isGuest => _user?.role == UserRole.guest;

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

  void updateLocalName(String newName) {
    if (_user != null) {
      _user!.name = newName;
      notifyListeners();
    }
  }

  void updateLocalEmail(String newEmail) {
    if (_user != null) {
      _user!.email = newEmail;
      notifyListeners();
    }
  }

  void updateLocalProfileColor(String color) {
    if (_user != null) {
      _user!.profileColor = color;
      notifyListeners();
    }
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
