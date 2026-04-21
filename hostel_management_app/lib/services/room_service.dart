import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<List<RoomModel>> streamRooms() {
    return _rooms.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> createRoom({
    required String roomId,
    required int capacity,
  }) async {
    await _rooms.doc(roomId).set({
      'roomId': roomId,
      'capacity': capacity,
      'occupants': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> assignStudentToRoom({
    required String studentId,
    required String roomId,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final studentRef = _users.doc(studentId);

    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) {
        throw Exception('Room not found');
      }

      final roomData = roomSnap.data() ?? <String, dynamic>{};
      final occupants = List<String>.from(roomData['occupants'] as List? ?? const []);
      final capacity = (roomData['capacity'] as num?)?.toInt() ?? 0;
      if (occupants.length >= capacity) {
        throw Exception('Room is full');
      }

      final studentSnap = await transaction.get(studentRef);
      final previousRoomId = (studentSnap.data() as Map<String, dynamic>?)?['roomId'] as String? ?? '';
      if (previousRoomId.isNotEmpty && previousRoomId != roomId) {
        final previousRoomRef = _rooms.doc(previousRoomId);
        final previousRoomSnap = await transaction.get(previousRoomRef);
        if (previousRoomSnap.exists) {
          final previousData = previousRoomSnap.data() ?? <String, dynamic>{};
          final previousOccupants = List<String>.from(previousData['occupants'] as List? ?? const []);
          previousOccupants.remove(studentId);
          transaction.update(previousRoomRef, {'occupants': previousOccupants});
        }
      }

      if (!occupants.contains(studentId)) {
        occupants.add(studentId);
      }

      transaction.update(roomRef, {'occupants': occupants});
      transaction.set(studentRef, {'roomId': roomId}, SetOptions(merge: true));
    });
  }

  Future<void> removeStudentFromRoom({
    required String studentId,
    required String roomId,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final studentRef = _users.doc(studentId);

    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) return;

      final roomData = roomSnap.data() ?? <String, dynamic>{};
      final occupants = List<String>.from(roomData['occupants'] as List? ?? const []);
      occupants.remove(studentId);

      transaction.update(roomRef, {'occupants': occupants});
      transaction.set(studentRef, {'roomId': ''}, SetOptions(merge: true));
    });
  }

  Stream<RoomModel?> streamRoomByStudentId(String studentId) {
    return _rooms
        .where('occupants', arrayContains: studentId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return RoomModel.fromMap(doc.data(), doc.id);
        });
  }

  Future<RoomModel?> getRoomByStudentId(String studentId) async {
    final snapshot = await _rooms.where('occupants', arrayContains: studentId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return RoomModel.fromMap(doc.data(), doc.id);
  }
}
