import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  @JsonKey(name: 'firebaseUid')
  final String firebaseUid;
  final String email;
  @JsonKey(name: 'displayName')
  final String? displayName;
  @JsonKey(name: 'contactNumber')
  final String? contactNumber;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;
  
  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.contactNumber,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
