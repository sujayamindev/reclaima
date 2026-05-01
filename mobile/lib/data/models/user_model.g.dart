// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  firebaseUid: json['firebaseUid'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String?,
  contactNumber: json['contactNumber'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'firebaseUid': instance.firebaseUid,
  'email': instance.email,
  'displayName': instance.displayName,
  'contactNumber': instance.contactNumber,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
