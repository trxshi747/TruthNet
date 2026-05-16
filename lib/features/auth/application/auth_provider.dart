import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model2/services/api_service.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  bool get isAdmin => state.user?.role == UserRole.admin;
  bool get isModerator => state.user?.role == UserRole.moderator;
  bool get isMember => state.user?.role == UserRole.member;
  bool get isGuest => state.user?.role == UserRole.guest || state.user == null;

  Future<Map<String, dynamic>> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await ApiService.login(email, password);
      if (response['success'] == true) {
        state = state.copyWith(
          user: User.fromJson(response['user']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message'] ?? 'Login failed',
        );
      }
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName, String username, String roleStr) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await ApiService.register(email, password, firstName, lastName, username, roleStr);
      if (response['success'] == true) {
        state = state.copyWith(
          user: User.fromJson(response['user']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message'] ?? 'Registration failed',
        );
      }
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  void updateLocalProfile(String newFirstName, String newLastName, String newBio) {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(
          firstName: newFirstName,
          lastName: newLastName,
          bio: newBio,
        ),
      );
    }
  }

  void updateLocalEmail(String newEmail) {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(email: newEmail),
      );
    }
  }

  void updateLocalProfileColor(String color) {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(profileColor: color),
      );
    }
  }

  void loginAsGuest() {
    state = const AuthState();
  }

  void logout() {
    state = const AuthState();
  }
}
