import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint_model.dart';
import '../models/fee_model.dart';
import '../models/leave_model.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _roomsRef => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _feesRef => _db.collection('fees');
  CollectionReference<Map<String, dynamic>> get _complaintsRef => _db.collection('complaints');
  CollectionReference<Map<String, dynamic>> get _leavesRef => _db.collection('leaves');
  CollectionReference<Map<String, dynamic>> get _roomRequestsRef => _db.collection('roomRequests');

  Future<void> setUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return streamUser(uid);
  }

  Future<void> updateStudentSelfProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _usersRef.doc(uid).set(
      {
        'name': name,
        'phone': phone,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateAdminStudentProfileFields({
    required String studentUid,
    required String parentPhone,
    required String hostelName,
  }) async {
    await _usersRef.doc(studentUid).set(
      {
        'parentPhone': parentPhone,
        'hostelName': hostelName,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateAdminEditableStudentProfile({
    required String studentUid,
    required String name,
    required String phone,
    required String parentPhone,
    required String hostelName,
  }) async {
    await _usersRef.doc(studentUid).set(
      {
        'name': name,
        'phone': phone,
        'parentPhone': parentPhone,
        'hostelName': hostelName,
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<UserModel>> streamUsersByRole(String role) {
    return _usersRef
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapUsers);
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _usersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapUsers);
  }

  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  Future<int> countUsers({String? role}) async {
    Query<Map<String, dynamic>> query = _usersRef;
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }
    final snapshot = await query.get();
    return snapshot.size;
  }

  Stream<List<RoomModel>> streamRooms() {
    return _roomsRef
        .orderBy('hostelBlock')
        .orderBy('roomNumber')
        .snapshots()
        .map(_mapRooms);
  }

  Stream<List<RoomModel>> streamAvailableRooms() {
    return streamRooms().map(
      (rooms) => rooms.where((room) => !room.isFull && room.isAvailable).toList(),
    );
  }

  Future<String> addRoom(RoomModel room) async {
    final doc = await _roomsRef.add(room.toMap());
    await _roomsRef.doc(doc.id).set({'id': doc.id}, SetOptions(merge: true));
    return doc.id;
  }

  Future<void> updateRoom(String id, Map<String, dynamic> data) async {
    await _roomsRef.doc(id).update(data);
  }

  Future<void> deleteRoom(String id) async {
    await _roomsRef.doc(id).delete();
  }

  Future<RoomModel?> getRoom(String id) async {
    final doc = await _roomsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return RoomModel.fromMap(doc.data()!, doc.id);
  }

  List<String> _roomStudentIds(Map<String, dynamic> roomData) {
    final assigned = List<String>.from(roomData['assignedStudentIds'] as List? ?? const []);
    final occupants = List<String>.from(roomData['occupants'] as List? ?? const []);
    final merged = <String>{...assigned, ...occupants}.toList();
    return merged;
  }

  bool _roomContainsStudent(RoomModel room, String studentId) {
    return room.assignedStudentIds.contains(studentId) || room.occupants.contains(studentId);
  }

  Future<RoomModel?> getRoomByStudentId(String studentId) async {
    final snapshot = await _roomsRef.get();
    for (final doc in snapshot.docs) {
      final room = RoomModel.fromMap(doc.data(), doc.id);
      if (_roomContainsStudent(room, studentId)) {
        return room;
      }
    }
    return null;
  }

  Stream<RoomModel?> streamRoomByStudentId(String studentId) {
    return streamRooms().map((rooms) {
      for (final room in rooms) {
        if (_roomContainsStudent(room, studentId)) {
          return room;
        }
      }
      return null;
    });
  }

  Stream<List<Map<String, dynamic>>> streamRoomRequests() {
    return _roomRequestsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> streamRoomRequestsByUser(String userId) {
    return streamRoomRequests().map(
      (requests) => requests.where((request) => request['userId'] == userId).toList(),
    );
  }

  Future<void> createRoomRequest({
    required String userId,
    required String userName,
    required String roomId,
  }) async {
    final room = await getRoom(roomId);
    await _roomRequestsRef.doc('${userId}_$roomId').set({
      'userId': userId,
      'userName': userName,
      'roomId': roomId,
      'roomNumber': room?.roomNumber ?? '',
      'hostelBlock': room?.hostelBlock ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveRoomRequest(String requestId) async {
    final requestDoc = await _roomRequestsRef.doc(requestId).get();
    if (!requestDoc.exists || requestDoc.data() == null) return;

    final request = requestDoc.data()!;
    final userId = request['userId'] as String? ?? '';
    final roomId = request['roomId'] as String? ?? '';
    if (userId.isEmpty || roomId.isEmpty) return;

    final approved = await transferStudentToRoom(studentId: userId, roomId: roomId);
    if (!approved) return;

    await _roomRequestsRef.doc(requestId).set({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> rejectRoomRequest(String requestId) async {
    await _roomRequestsRef.doc(requestId).set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeStudentFromRoom(String roomId, String studentId) async {
    final roomRef = _roomsRef.doc(roomId);
    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) return;
      final roomData = roomSnap.data() ?? <String, dynamic>{};
      final students = _roomStudentIds(roomData);
      final occupancy = (roomData['occupancy'] as num?)?.toInt() ?? students.length;
      students.remove(studentId);
      transaction.update(roomRef, {
        'assignedStudentIds': students,
        'occupants': students,
        'occupancy': occupancy > 0 ? occupancy - 1 : 0,
        'isAvailable': true,
      });
    });

    await _usersRef.doc(studentId).set({
      'roomId': '',
      'roomNumber': '',
      'hostelBlock': '',
    }, SetOptions(merge: true));
  }

  Future<void> removeStudentFromCurrentRoom(String studentId) async {
    final room = await getRoomByStudentId(studentId);
    if (room == null) {
      await _usersRef.doc(studentId).set({
        'roomId': '',
        'roomNumber': '',
        'hostelBlock': '',
      }, SetOptions(merge: true));
      return;
    }
    await removeStudentFromRoom(room.id, studentId);
  }

  Future<bool> transferStudentToRoom({
    required String studentId,
    required String roomId,
  }) async {
    final roomRef = _roomsRef.doc(roomId);
    final userRef = _usersRef.doc(studentId);

    final roomSnap = await roomRef.get();
    if (!roomSnap.exists || roomSnap.data() == null) return false;

    final room = RoomModel.fromMap(roomSnap.data()!, roomSnap.id);
    if (room.isFull && !room.assignedStudentIds.contains(studentId) && !room.occupants.contains(studentId)) {
      return false;
    }

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final previousRoomId = (userSnap.data() as Map<String, dynamic>?)?['roomId'] as String? ?? '';

      if (previousRoomId.isNotEmpty && previousRoomId != roomId) {
        final previousRoomRef = _roomsRef.doc(previousRoomId);
        final previousRoomSnap = await transaction.get(previousRoomRef);
        if (previousRoomSnap.exists) {
          final previousData = previousRoomSnap.data() ?? <String, dynamic>{};
          final previousAssigned = _roomStudentIds(previousData);
          final previousOccupancy = (previousData['occupancy'] as num?)?.toInt() ?? previousAssigned.length;
          previousAssigned.remove(studentId);
          transaction.update(previousRoomRef, {
            'assignedStudentIds': previousAssigned,
            'occupants': previousAssigned,
            'occupancy': previousOccupancy > 0 ? previousOccupancy - 1 : 0,
            'isAvailable': true,
          });
        }
      }

      final activeRoomSnap = await transaction.get(roomRef);
      final activeData = activeRoomSnap.data() ?? <String, dynamic>{};
      final activeAssigned = _roomStudentIds(activeData);
      final activeOccupancy = (activeData['occupancy'] as num?)?.toInt() ?? activeAssigned.length;
      if (!activeAssigned.contains(studentId)) {
        activeAssigned.add(studentId);
      }

      final nextCapacity = (activeData['capacity'] as num?)?.toInt() ?? room.capacity;
      final nextOccupancy = activeAssigned.length > activeOccupancy ? activeAssigned.length : activeOccupancy;

      transaction.update(roomRef, {
        'assignedStudentIds': activeAssigned,
        'occupants': activeAssigned,
        'occupancy': nextOccupancy,
        'isAvailable': nextOccupancy < nextCapacity,
      });

      transaction.set(userRef, {
        'roomId': roomId,
        'roomNumber': activeData['roomNumber'] ?? room.roomNumber,
        'hostelBlock': activeData['hostelBlock'] ?? room.hostelBlock,
      }, SetOptions(merge: true));
    });

    return true;
  }

  Future<List<UserModel>> getRoommates(String roomId, String currentStudentId) async {
    final roomDoc = await _roomsRef.doc(roomId).get();
    if (!roomDoc.exists || roomDoc.data() == null) return [];

    final room = RoomModel.fromMap(roomDoc.data()!, roomDoc.id);
    final roommates = <UserModel>[];

    for (final uid in room.assignedStudentIds.isNotEmpty ? room.assignedStudentIds : room.occupants) {
      if (uid == currentStudentId) continue;
      final user = await getUser(uid);
      if (user != null) roommates.add(user);
    }

    return roommates;
  }

  Future<String> addFee(FeeModel fee) async {
    final doc = await _feesRef.add(fee.toMap());
    return doc.id;
  }

  Stream<List<FeeModel>> streamAllFees() {
    return _feesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapFees);
  }

  Stream<List<FeeModel>> streamFeesByStudent(String studentId) {
    return _feesRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapFees);
  }

  Stream<List<FeeModel>> streamRecentFees({int limit = 3}) {
    return _feesRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapFees);
  }

  Future<void> recordPayment({
    required String feeId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final doc = await _feesRef.doc(feeId).get();
    if (!doc.exists || doc.data() == null) return;

    final fee = FeeModel.fromMap(doc.data()!, doc.id);
    final updatedPaidAmount = fee.paidAmount + amount;
    final status = updatedPaidAmount >= fee.amount ? 'paid' : 'partial';

    await _feesRef.doc(feeId).update({
      'paidAmount': updatedPaidAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    });
  }

  Future<void> deleteFee(String id) async {
    await _feesRef.doc(id).delete();
  }

  Future<Map<String, double>> getFeeStats() async {
    final snapshot = await _feesRef.get();
    final fees = _mapFees(snapshot);
    return {
      'totalAmount': fees.fold(0, (sum, item) => sum + item.amount),
      'collectedAmount': fees.fold(0, (sum, item) => sum + item.paidAmount),
      'pendingAmount': fees.fold(0, (sum, item) => sum + item.balanceDue),
    };
  }

  Future<String> addComplaint(ComplaintModel complaint) async {
    final doc = await _complaintsRef.add(complaint.toMap());
    return doc.id;
  }

  Stream<List<ComplaintModel>> streamAllComplaints() {
    return _complaintsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapComplaints);
  }

  Stream<List<ComplaintModel>> streamRecentComplaints({int limit = 5}) {
    return _complaintsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapComplaints);
  }

  Stream<List<ComplaintModel>> streamComplaintsByStudent(String studentId) {
    return streamAllComplaints().map(
      (complaints) => complaints.where((item) => item.userId == studentId || item.studentId == studentId).toList(),
    );
  }

  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? adminResponse,
  }) async {
    await _complaintsRef.doc(complaintId).update({
      'status': status,
      'adminResponse': adminResponse,
      'resolvedAt': status == 'resolved' ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteComplaint(String id) async {
    await _complaintsRef.doc(id).delete();
  }

  Future<String> addLeave(LeaveModel leave) async {
    final doc = await _leavesRef.add(leave.toMap());
    return doc.id;
  }

  Stream<List<LeaveModel>> streamAllLeaves() {
    return _leavesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapLeaves);
  }

  Stream<List<LeaveModel>> streamLeavesByStudent(String studentId) {
    return streamAllLeaves().map(
      (leaves) => leaves.where((item) => item.userId == studentId || item.studentId == studentId).toList(),
    );
  }

  Stream<List<LeaveModel>> streamRecentLeavesByStudent(
    String studentId, {
    int limit = 3,
  }) {
    return streamLeavesByStudent(studentId).map(
      (leaves) => leaves.take(limit).toList(),
    );
  }

  Future<void> updateLeaveStatus(
    String leaveId,
    String status, {
    String? adminRemarks,
  }) async {
    await _leavesRef.doc(leaveId).update({
      'status': status,
      'adminRemarks': adminRemarks ?? '',
    });
  }

  Future<void> deleteLeave(String id) async {
    await _leavesRef.doc(id).delete();
  }

  Future<Map<String, int>> getComplaintStats() async {
    final snapshot = await _complaintsRef.get();
    final complaints = _mapComplaints(snapshot);
    return {
      'total': complaints.length,
      'pending': complaints.where((item) => item.isPending).length,
      'resolved': complaints.where((item) => item.isResolved).length,
      'highPriority': complaints.where((item) => item.isHighPriority).length,
    };
  }

  Future<Map<String, int>> getLeaveStats() async {
    final snapshot = await _leavesRef.get();
    final leaves = _mapLeaves(snapshot);
    return {
      'total': leaves.length,
      'pending': leaves.where((item) => item.isPending).length,
      'approved': leaves.where((item) => item.isApproved).length,
      'rejected': leaves.where((item) => item.isRejected).length,
    };
  }

  Future<Map<String, int>> getRoomStats() async {
    final snapshot = await _roomsRef.get();
    final rooms = _mapRooms(snapshot);
    return {
      'total': rooms.length,
      'occupied': rooms.where((item) => item.isFull).length,
      'available': rooms.where((item) => !item.isFull).length,
      'totalBeds': rooms.fold(0, (sum, item) => sum + item.capacity),
      'occupiedBeds': rooms.fold(0, (sum, item) => sum + item.occupancy),
    };
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait<dynamic>([
      countUsers(role: 'student'),
      getRoomStats(),
      getComplaintStats(),
      getFeeStats(),
      getLeaveStats(),
    ]);

    return {
      'totalStudents': results[0] as int,
      'rooms': results[1] as Map<String, int>,
      'complaints': results[2] as Map<String, int>,
      'fees': results[3] as Map<String, double>,
      'leaves': results[4] as Map<String, int>,
    };
  }

  List<UserModel> _mapUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  List<RoomModel> _mapRooms(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  List<FeeModel> _mapFees(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => FeeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  List<ComplaintModel> _mapComplaints(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  List<LeaveModel> _mapLeaves(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => LeaveModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
