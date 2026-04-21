import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNumber;
  final String title;
  final String description;
  final String category;
  final String userId;
  final String issue;
  final String status;
  final String priority;
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? resolvedAt;
  final String response;

  ComplaintModel({
    this.id = '',
    this.studentId = '',
    this.studentName = '',
    this.roomNumber = '',
    this.title = '',
    this.description = '',
    this.category = 'other',
    this.userId = '',
    this.issue = '',
    this.status = 'pending',
    this.priority = 'medium',
    DateTime? createdAt,
    this.adminResponse,
    this.resolvedAt,
    this.response = '',
  }) : createdAt = createdAt ?? DateTime.now();

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String documentId) {
    final resolvedUserId =
        (map['userId'] as String?) ?? (map['studentId'] as String?) ?? '';
    final resolvedIssue =
        (map['issue'] as String?) ?? (map['title'] as String?) ?? '';

    return ComplaintModel(
      id: documentId,
      studentId: map['studentId'] as String? ?? resolvedUserId,
      studentName: map['studentName'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      title: map['title'] as String? ?? resolvedIssue,
      description: map['description'] as String? ?? map['issue'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      userId: resolvedUserId,
      issue: resolvedIssue,
      status: map['status'] as String? ?? 'pending',
      priority: map['priority'] as String? ?? 'medium',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponse: map['adminResponse'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      response: map['response'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId.isNotEmpty ? studentId : userId,
      'studentName': studentName,
      'roomNumber': roomNumber,
      'title': title.isNotEmpty ? title : issue,
      'description': description.isNotEmpty ? description : issue,
      'category': category,
      'userId': userId,
      'issue': issue,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminResponse': adminResponse,
      'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
      'response': response,
    };
  }

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isHighPriority => priority == 'high';
}
