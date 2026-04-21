import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fee_model.dart';

class FeeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _fees => _db.collection('fees');

  Future<void> addFeeRecord({
    required String userId,
    required double amount,
    required String status,
    DateTime? date,
    String note = '',
  }) async {
    await _fees.add({
      'userId': userId,
      'amount': amount,
      'status': status,
      'date': Timestamp.fromDate(date ?? DateTime.now()),
      'note': note,
    });
  }

  Stream<List<FeeModel>> streamAllFees() {
    return _fees.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FeeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<FeeModel>> streamFeesByUser(String userId) {
    return _fees.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FeeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateFeeStatus({
    required String feeId,
    required String status,
  }) async {
    await _fees.doc(feeId).update({'status': status});
  }
}
