import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_overlay.dart';

/// Screen that lists all rooms and allows adding/editing rooms.
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<List<RoomModel>>(
        stream: firestoreService.streamRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading rooms',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bed_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No rooms added yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first room',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          // ── Summary Bar ──
          final totalCapacity =
              rooms.fold<int>(0, (sum, r) => sum + r.capacity);
          final totalOccupancy =
              rooms.fold<int>(0, (sum, r) => sum + r.occupancy);
          final availableRooms = rooms.where((r) => !r.isFull).length;

          return Column(
            children: [
              // ── Stats strip ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.12),
                      colorScheme.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: '${rooms.length}',
                      color: colorScheme.primary,
                    ),
                    _StatChip(
                      label: 'Beds',
                      value: '$totalOccupancy/$totalCapacity',
                      color: Colors.orange,
                    ),
                    _StatChip(
                      label: 'Available',
                      value: '$availableRooms',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              // ── Room list ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _RoomCard(room: room);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoomDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Add Room Dialog
  // ─────────────────────────────────────────────
  void _showAddRoomDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final roomNumberCtrl = TextEditingController();
    final blockCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '2');
    String roomType = 'double';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add New Room',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Room Number
                    TextFormField(
                      controller: roomNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room Number',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Block
                    TextFormField(
                      controller: blockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hostel Block',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Room Type
                    DropdownButtonFormField<String>(
                      value: roomType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'single', child: Text('Single')),
                        DropdownMenuItem(
                            value: 'double', child: Text('Double')),
                        DropdownMenuItem(
                            value: 'triple', child: Text('Triple')),
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          roomType = v!;
                          capacityCtrl.text = v == 'single'
                              ? '1'
                              : v == 'double'
                                  ? '2'
                                  : '3';
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Capacity
                    TextFormField(
                      controller: capacityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || int.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final room = RoomModel(
                            id: '',
                            roomNumber: roomNumberCtrl.text.trim(),
                            hostelBlock: blockCtrl.text.trim(),
                            capacity: int.parse(capacityCtrl.text.trim()),
                            occupancy: 0,
                            roomType: roomType,
                            isAvailable: true,
                            assignedStudentIds: const [],
                            createdAt: DateTime.now(),
                          );

                          final service = context.read<FirestoreService>();
                          await service.addRoom(room);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Add Room'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Room Card Widget
// ─────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomModel room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final occupancyPercent =
        room.capacity > 0 ? room.occupancy / room.capacity : 0.0;
    final statusColor = room.isFull
        ? Colors.red
        : occupancyPercent > 0.5
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRoomDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Room icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    room.roomNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Block ${room.hostelBlock} — ${room.roomType.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: occupancyPercent,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${room.occupancy}/${room.capacity}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  room.isFull ? 'Full' : 'Open',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Room ${room.roomNumber}',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.apartment, 'Block', room.hostelBlock),
              _detailRow(Icons.category, 'Type', room.roomType),
              _detailRow(
                  Icons.people, 'Occupancy', '${room.occupancy}/${room.capacity}'),
              _detailRow(
                Icons.circle,
                'Status',
                room.isFull ? 'Full' : 'Available',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context
                            .read<FirestoreService>()
                            .deleteRoom(room.id);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Small stat chip
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
