// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: json['id'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.guest,
  profileImageUrl: json['profileImageUrl'] as String?,
  bio: json['bio'] as String?,
  profileColor: json['profileColor'] as String?,
  registrationDate: json['registrationDate'] as String?,
  privacyLevel: json['privacyLevel'] as String? ?? 'public',
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'role': _$UserRoleEnumMap[instance.role]!,
      'profileImageUrl': instance.profileImageUrl,
      'bio': instance.bio,
      'profileColor': instance.profileColor,
      'registrationDate': instance.registrationDate,
      'privacyLevel': instance.privacyLevel,
    };

const _$UserRoleEnumMap = {
  UserRole.guest: 'guest',
  UserRole.member: 'member',
  UserRole.moderator: 'moderator',
  UserRole.admin: 'admin',
};
