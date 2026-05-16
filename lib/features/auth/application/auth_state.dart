import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

enum UserRole { guest, member, moderator, admin }

@freezed
class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    @Default(UserRole.guest) UserRole role,
    String? profileImageUrl,
    String? bio,
    String? profileColor,
    String? registrationDate,
    @Default('public') String privacyLevel,
  }) = _User;

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _AuthState;
}
