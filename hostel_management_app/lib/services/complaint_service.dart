import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _complaints => _db.collection('complaints');

  Future<void> addComplaint({
    required String userId,
    required String issue,
  }) async {
    await _complaints.add({
      'userId': userId,
      'issue': issue,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'response': '',
    });
  }

  Stream<List<ComplaintModel>> streamAllComplaints() {
    return _complaints.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ComplaintModel>> streamComplaintsByUser(String userId) {
    return _complaints.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> resolveComplaint({
    required String complaintId,
    String response = '',
  }) async {
    await _complaints.doc(complaintId).update({
      'status': 'resolved',
      'response': response,
    });
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
  }) async {
    await _complaints.doc(complaintId).update({'status': status});
  }
}
