import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leave_model.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _leaves => _db.collection('leaves');

  Future<void> applyLeave({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    await _leaves.add({
      'userId': userId,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'status': 'pending',
      'reason': reason,
      'remarks': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<LeaveModel>> streamAllLeaves() {
    return _leaves.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<LeaveModel>> streamLeavesByUser(String userId) {
    return _leaves.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String remarks = '',
  }) async {
    await _leaves.doc(leaveId).update({
      'status': status,
      'remarks': remarks,
    });
  }
}
