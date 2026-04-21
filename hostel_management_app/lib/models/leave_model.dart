import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String id;
  final String studentId;
  final String studentName;
  final String leaveType;
  final String userId;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final String reason;
  final String adminRemarks;
  final String remarks;
  final DateTime createdAt;

  LeaveModel({
    this.id = '',
    this.studentId = '',
    this.studentName = '',
    this.leaveType = 'other',
    this.userId = '',
    DateTime? fromDate,
    DateTime? toDate,
    this.status = 'pending',
    this.reason = '',
    this.adminRemarks = '',
    this.remarks = '',
    DateTime? createdAt,
  })  : fromDate = fromDate ?? DateTime.now(),
        toDate = toDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory LeaveModel.fromMap(Map<String, dynamic> map, String documentId) {
    final resolvedUserId =
        (map['userId'] as String?) ?? (map['studentId'] as String?) ?? '';
    return LeaveModel(
      id: documentId,
      studentId: map['studentId'] as String? ?? resolvedUserId,
      studentName: map['studentName'] as String? ?? '',
      leaveType: map['leaveType'] as String? ?? 'other',
      userId: resolvedUserId,
      fromDate: (map['fromDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      toDate: (map['toDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      reason: map['reason'] as String? ?? '',
      adminRemarks: map['adminRemarks'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId.isNotEmpty ? studentId : userId,
      'studentName': studentName,
      'leaveType': leaveType,
      'userId': userId,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'status': status,
      'reason': reason,
      'adminRemarks': adminRemarks,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get totalDays => toDate.difference(fromDate).inDays + 1;
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
