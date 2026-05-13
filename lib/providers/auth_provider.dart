import 'package:flutter/material.dart';
import 'package:model2/services/api_service.dart';

enum UserRole { guest, member, moderator, admin }

class User {
  String id;
  String email;
  String firstName;
  String lastName;
  UserRole role;
  String? profileImageUrl;
  String? bio;
  String? profileColor;
  String? registrationDate;
  String privacyLevel;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profileImageUrl,
    this.bio,
    this.profileColor,
    this.registrationDate,
    this.privacyLevel = 'public',
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole role = UserRole.member;
    String roleStr = (json['role'] ?? '').toString().toLowerCase();
    
    if (roleStr == 'admin') role = UserRole.admin;
    else if (roleStr == 'moderator') role = UserRole.moderator;
    else if (roleStr == 'member') role = UserRole.member;
    else role = UserRole.guest;

    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: role,
      bio: json['bio'],
      profileImageUrl: json['avatar'],
      profileColor: json['profileColor'],
      registrationDate: json['registrationDate']?.toString(),
      privacyLevel: json['privacyLevel'] ?? 'public',
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

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.login(email, password);
    if (response['success'] == true) {
      _user = User.fromJson(response['user']);
      notifyListeners();
    }
    return response;
  }

  Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName, String username, String role) async {
    final response = await ApiService.register(email, password, firstName, lastName, username, role);
    if (response['success'] == true) {
      _user = User.fromJson(response['user']);
      notifyListeners();
    }
    return response;
  }

  void updateLocalProfile(String newFirstName, String newLastName, String newBio) {
    if (_user != null) {
      _user!.firstName = newFirstName;
      _user!.lastName = newLastName;
      _user!.bio = newBio;
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
