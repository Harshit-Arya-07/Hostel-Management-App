import 'package:cloud_firestore/cloud_firestore.dart';

class FeeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNumber;
  final String userId;
  final double amount;
  final double paidAmount;
  final String feeType;
  final String status;
  final String paymentMethod;
  final String? transactionId;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String month;
  final DateTime createdAt;
  final DateTime date;
  final String note;

  FeeModel({
    required this.id,
    this.studentId = '',
    this.studentName = '',
    this.roomNumber = '',
    this.userId = '',
    required this.amount,
    this.paidAmount = 0,
    this.feeType = 'hostel_rent',
    this.status = 'pending',
    this.paymentMethod = '',
    this.transactionId,
    DateTime? dueDate,
    this.paidDate,
    this.month = '',
    DateTime? createdAt,
    DateTime? date,
    this.note = '',
  })  : dueDate = dueDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        date = date ?? DateTime.now();

  factory FeeModel.fromMap(Map<String, dynamic> map, String documentId) {
    final resolvedUserId =
        (map['userId'] as String?) ?? (map['studentId'] as String?) ?? '';
    final resolvedDate = (map['date'] as Timestamp?)?.toDate() ??
        (map['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.now();

    return FeeModel(
      id: documentId,
      studentId: map['studentId'] as String? ?? resolvedUserId,
      studentName: map['studentName'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      userId: resolvedUserId,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      feeType: map['feeType'] as String? ?? 'hostel_rent',
      status: map['status'] as String? ?? 'pending',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      transactionId: map['transactionId'] as String?,
      dueDate:
          (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        paidDate: (map['paidDate'] as Timestamp?)?.toDate(),
      month: map['month'] as String? ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? resolvedDate,
      date: resolvedDate,
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId.isNotEmpty ? studentId : userId,
      'studentName': studentName,
      'roomNumber': roomNumber,
      'userId': userId,
      'amount': amount,
      'paidAmount': paidAmount,
      'feeType': feeType,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate == null ? null : Timestamp.fromDate(paidDate!),
      'month': month,
      'createdAt': Timestamp.fromDate(createdAt),
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  double get balanceDue => amount - paidAmount;
  bool get isPaid => status == 'paid' || balanceDue <= 0;
  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
}
