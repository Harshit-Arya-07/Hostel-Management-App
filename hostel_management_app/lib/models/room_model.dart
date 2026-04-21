import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String roomId;
  final String roomNumber;
  final String hostelBlock;
  final int floor;
  final int capacity;
  final int occupancy;
  final String roomType;
  final double rentPerMonth;
  final bool isAvailable;
  final List<String> assignedStudentIds;
  final List<String> occupants;
  final DateTime createdAt;

  const RoomModel({
    this.id = '',
    this.roomId = '',
    this.roomNumber = '',
    this.hostelBlock = '',
    this.floor = 0,
    this.capacity = 1,
    this.occupancy = 0,
    this.roomType = 'single',
    this.rentPerMonth = 0,
    this.isAvailable = true,
    this.assignedStudentIds = const [],
    this.occupants = const [],
    required this.createdAt,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String documentId) {
    final parsedRoomNumber = (map['roomNumber'] as String?) ?? '';
    final parsedRoomId = (map['roomId'] as String?) ?? parsedRoomNumber;
    final parsedAssigned = List<String>.from(
      map['assignedStudentIds'] as List? ?? const [],
    );
    final parsedOccupants = List<String>.from(
      map['occupants'] as List? ?? parsedAssigned,
    );
    final parsedCapacity = (map['capacity'] as num?)?.toInt() ?? 1;
    final parsedOccupancy =
        (map['occupancy'] as num?)?.toInt() ?? parsedOccupants.length;

    return RoomModel(
      id: documentId,
      roomId: parsedRoomId.isNotEmpty ? parsedRoomId : documentId,
      roomNumber: parsedRoomNumber.isNotEmpty ? parsedRoomNumber : documentId,
      hostelBlock: map['hostelBlock'] as String? ?? '',
      floor: (map['floor'] as num?)?.toInt() ?? 0,
      capacity: parsedCapacity,
      occupancy: parsedOccupancy,
      roomType: map['roomType'] as String? ?? 'single',
      rentPerMonth: (map['rentPerMonth'] as num?)?.toDouble() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? (parsedOccupancy < parsedCapacity),
      assignedStudentIds: parsedAssigned,
      occupants: parsedOccupants,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'hostelBlock': hostelBlock,
      'floor': floor,
      'capacity': capacity,
      'occupancy': occupancy,
      'roomType': roomType,
      'rentPerMonth': rentPerMonth,
      'isAvailable': isAvailable,
      'assignedStudentIds': assignedStudentIds,
      'occupants': occupants,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isFull => occupancy >= capacity;
  int get availableBeds => capacity - occupancy;
}
