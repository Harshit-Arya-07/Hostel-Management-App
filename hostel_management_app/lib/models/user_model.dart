import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String parentPhone;
  final String hostelName;
  final String role;
  final String roomNumber;
  final String hostelBlock;
  final String roomId;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.parentPhone = '',
    this.hostelName = '',
    required this.role,
    this.roomNumber = '',
    this.hostelBlock = '',
    this.roomId = '',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final parsedRoomId = (map['roomId'] as String?) ?? '';
    final parsedRoomNumber = (map['roomNumber'] as String?) ?? '';
    return UserModel(
      uid: documentId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      parentPhone: map['parentPhone'] as String? ?? '',
      hostelName: map['hostelName'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      roomNumber: parsedRoomNumber,
      hostelBlock: map['hostelBlock'] as String? ?? '',
      roomId: parsedRoomId.isNotEmpty ? parsedRoomId : parsedRoomNumber,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'parentPhone': parentPhone,
      'hostelName': hostelName,
      'role': role,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'hostelBlock': hostelBlock,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
