import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/complaint_model.dart';
import '../../models/fee_model.dart';
import '../../models/leave_model.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../profile/admin_profile_edit_screen.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = const [
    _AdminHomeTab(),
    _AdminStudentsTab(),
    _AdminRoomsTab(),
    _AdminComplaintsTab(),
    _AdminLeavesTab(),
    _AdminProfileTab(),
  ];

  void jumpToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
        onDestinationSelected: jumpToTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.bed_outlined), selectedIcon: Icon(Icons.bed), label: 'Rooms'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), selectedIcon: Icon(Icons.report_problem), label: 'Complaints'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Leaves'),
        ],
      ),
    );
  }
}

class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  bool _initialized = false;
  late Future<Map<String, dynamic>> _statsFuture;
  late Stream<List<ComplaintModel>> _recentComplaints;
  late Stream<List<FeeModel>> _recentFees;
  String _displayName = 'Admin';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final candidateName = auth.currentUser?.displayName?.trim() ?? '';

    _displayName = candidateName.isEmpty ? 'Admin' : candidateName;
    _statsFuture = firestore.getDashboardStats();
    _recentComplaints = firestore.streamRecentComplaints(limit: 5);
    _recentFees = firestore.streamRecentFees(limit: 3);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 180,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => context.findAncestorStateOfType<_AdminDashboardState>()?.jumpToTab(5),
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, const Color(0xFF4A42D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_greeting(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Hostel Management Panel', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final rooms = (data?['rooms'] as Map<String, int>?) ?? const {};
                final complaints = (data?['complaints'] as Map<String, int>?) ?? const {};
                final fees = (data?['fees'] as Map<String, dynamic>?) ?? const {};
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _StatCard(title: 'Students', value: '${data?['totalStudents'] ?? '-'}', icon: Icons.school, color: colorScheme.primary),
                    _StatCard(title: 'Rooms', value: '${rooms['total'] ?? '-'}', icon: Icons.bed, color: Colors.teal),
                    _StatCard(title: 'Pending Complaints', value: '${complaints['pending'] ?? '-'}', icon: Icons.warning_amber, color: Colors.orange),
                    _StatCard(title: 'Fees Collected', value: fees.isNotEmpty ? '₹${(fees['collectedAmount'] as num? ?? 0).toStringAsFixed(0)}' : '₹-', icon: Icons.account_balance_wallet, color: Colors.green),
                  ],
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Recent Complaints', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        SliverToBoxAdapter(
          child: StreamBuilder<List<ComplaintModel>>(
            stream: _recentComplaints,
            builder: (context, snapshot) {
              final complaints = snapshot.data ?? const [];
              if (complaints.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No complaints yet', style: TextStyle(color: Colors.grey.shade500))),
                );
              }
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: complaints.length > 5 ? 5 : complaints.length,
                  itemBuilder: (_, index) => _CompactComplaintCard(complaint: complaints[index]),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Recent Fees', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        SliverToBoxAdapter(
          child: StreamBuilder<List<FeeModel>>(
            stream: _recentFees,
            builder: (context, snapshot) {
              final fees = snapshot.data ?? const [];
              if (fees.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No fee records yet', style: TextStyle(color: Colors.grey.shade500))),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: fees.length > 3 ? 3 : fees.length,
                itemBuilder: (_, index) => _FeeTile(fee: fees[index]),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _AdminStudentsTab extends StatelessWidget {
  const _AdminStudentsTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.findAncestorStateOfType<_AdminDashboardState>()?.jumpToTab(5),
          icon: const Icon(Icons.person_outline),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestore.streamUsersByRole('student'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data ?? const [];
          if (students.isEmpty) {
            return Center(child: Text('No students', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)));
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text('${students.length} Students', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: students.length,
                  itemBuilder: (_, index) => _StudentTile(student: students[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminRoomsTab extends StatelessWidget {
  const _AdminRoomsTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.findAncestorStateOfType<_AdminDashboardState>()?.jumpToTab(5),
          icon: const Icon(Icons.person_outline),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddRoomSheet(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: firestore.streamRooms(),
        builder: (context, roomsSnapshot) {
          final rooms = roomsSnapshot.data ?? const [];
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestore.streamRoomRequests(),
            builder: (context, requestsSnapshot) {
              final requests = (requestsSnapshot.data ?? const [])
                  .where((request) => request['status'] == 'pending')
                  .toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (requests.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pending Room Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            ...requests.map((request) => _RoomRequestTile(
                                  request: request,
                                  onApprove: () async {
                                    final requestId = request['id'] as String? ?? '';
                                    if (requestId.isNotEmpty) await firestore.approveRoomRequest(requestId);
                                  },
                                  onReject: () async {
                                    final requestId = request['id'] as String? ?? '';
                                    if (requestId.isNotEmpty) await firestore.rejectRoomRequest(requestId);
                                  },
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text('All Rooms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (rooms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No rooms found', style: TextStyle(color: Colors.grey.shade500))),
                    )
                  else
                    ...rooms.map((room) => _RoomTile(
                          room: room,
                          onDelete: () async {
                            await firestore.deleteRoom(room.id);
                          },
                        )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddRoomSheet(BuildContext context) async {
    final firestore = context.read<FirestoreService>();
    final formKey = GlobalKey<FormState>();
    final roomNumberCtrl = TextEditingController();
    final blockCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '2');
    final rentCtrl = TextEditingController();
    String roomType = 'double';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)))),
                        const SizedBox(height: 20),
                        Text('Add Room', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: roomNumberCtrl,
                          decoration: const InputDecoration(labelText: 'Room Number', prefixIcon: Icon(Icons.meeting_room)),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: blockCtrl,
                          decoration: const InputDecoration(labelText: 'Block', prefixIcon: Icon(Icons.apartment)),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: floorCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Floor', prefixIcon: Icon(Icons.layers)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: capacityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Capacity', prefixIcon: Icon(Icons.people)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: roomType,
                          decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                          items: const [
                            DropdownMenuItem(value: 'single', child: Text('Single')),
                            DropdownMenuItem(value: 'double', child: Text('Double')),
                            DropdownMenuItem(value: 'triple', child: Text('Triple')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              roomType = value ?? 'double';
                              capacityCtrl.text = roomType == 'single' ? '1' : roomType == 'double' ? '2' : '3';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: rentCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rent per month', prefixIcon: Icon(Icons.currency_rupee)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final room = RoomModel(
                              roomNumber: roomNumberCtrl.text.trim(),
                              hostelBlock: blockCtrl.text.trim(),
                              floor: int.tryParse(floorCtrl.text.trim()) ?? 0,
                              capacity: int.tryParse(capacityCtrl.text.trim()) ?? 1,
                              roomType: roomType,
                              rentPerMonth: double.tryParse(rentCtrl.text.trim()) ?? 0,
                              isAvailable: true,
                              createdAt: DateTime.now(),
                            );
                            await firestore.addRoom(room);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Save Room'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminComplaintsTab extends StatelessWidget {
  const _AdminComplaintsTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.findAncestorStateOfType<_AdminDashboardState>()?.jumpToTab(5),
          icon: const Icon(Icons.person_outline),
        ),
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: firestore.streamAllComplaints(),
        builder: (context, snapshot) {
          final complaints = snapshot.data ?? const [];
          if (complaints.isEmpty) {
            return Center(child: Text('No complaints found', style: TextStyle(color: Colors.grey.shade500)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (_, index) {
              final complaint = complaints[index];
              return Card(
                child: ListTile(
                  title: Text(complaint.title.isEmpty ? complaint.issue : complaint.title),
                  subtitle: Text('${complaint.studentName.isEmpty ? 'Student' : complaint.studentName} · ${complaint.status}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'resolved') {
                        await firestore.updateComplaintStatus(complaint.id, 'resolved');
                      } else if (value == 'pending') {
                        await firestore.updateComplaintStatus(complaint.id, 'pending');
                      } else if (value == 'delete') {
                        await firestore.deleteComplaint(complaint.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
                      PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminLeavesTab extends StatelessWidget {
  const _AdminLeavesTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaves'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.findAncestorStateOfType<_AdminDashboardState>()?.jumpToTab(5),
          icon: const Icon(Icons.person_outline),
        ),
      ),
      body: StreamBuilder<List<LeaveModel>>(
        stream: firestore.streamAllLeaves(),
        builder: (context, snapshot) {
          final leaves = snapshot.data ?? const [];
          if (leaves.isEmpty) {
            return Center(child: Text('No leave requests found', style: TextStyle(color: Colors.grey.shade500)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (_, index) {
              final leave = leaves[index];
              return Card(
                child: ListTile(
                  title: Text(leave.studentName.isEmpty ? 'Student Leave' : leave.studentName),
                  subtitle: Text('${_dateText(leave.fromDate)} - ${_dateText(leave.toDate)} · ${leave.status}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'approved') {
                        await firestore.updateLeaveStatus(leave.id, 'approved');
                      } else if (value == 'rejected') {
                        await firestore.updateLeaveStatus(leave.id, 'rejected');
                      } else if (value == 'delete') {
                        await firestore.deleteLeave(leave.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'approved', child: Text('Approve')),
                      PopupMenuItem(value: 'rejected', child: Text('Reject')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: uid.isEmpty
          ? const Center(child: Text('No profile available'))
          : StreamBuilder<UserModel?>(
              stream: firestore.streamUserProfile(uid),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting && profile == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (profile == null) {
                  return const Center(child: Text('Profile not found'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.admin_panel_settings, size: 30),
                            ),
                            const SizedBox(height: 16),
                            Text(profile.name.isEmpty ? 'Admin' : profile.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(profile.email),
                            const SizedBox(height: 6),
                            Text(profile.phone.isEmpty ? 'No phone number' : profile.phone),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _RoomRequestTile extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RoomRequestTile({required this.request, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final userName = request['userName'] as String? ?? 'Student';
    final roomNumber = request['roomNumber'] as String? ?? '';
    final hostelBlock = request['hostelBlock'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Room ${roomNumber.isEmpty ? '--' : roomNumber}${hostelBlock.isEmpty ? '' : ' · $hostelBlock'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          TextButton(onPressed: onReject, child: const Text('Reject')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onApprove, child: const Text('Approve')),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onDelete;

  const _RoomTile({required this.room, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Room ${room.roomNumber}'),
        subtitle: Text('${room.hostelBlock.isEmpty ? 'Block' : room.hostelBlock} · ${room.roomType} · ${room.occupancy}/${room.capacity} occupied'),
        trailing: IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final UserModel student;

  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Card(
      child: ListTile(
        title: Text(student.name.isEmpty ? 'Student' : student.name),
        subtitle: Text('${student.email}${student.roomNumber.isNotEmpty ? ' · Room ${student.roomNumber}' : ''}'),
        leading: CircleAvatar(child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S')),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminProfileEditScreen(studentUid: student.uid)));
            } else if (value == 'assign') {
              await _showAssignRoomSheet(context, firestore, student);
            } else if (value == 'remove_room') {
              await firestore.removeStudentFromCurrentRoom(student.uid);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
            PopupMenuItem(value: 'assign', child: Text('Assign Room')),
            PopupMenuItem(value: 'remove_room', child: Text('Remove From Room')),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignRoomSheet(BuildContext context, FirestoreService firestore, UserModel student) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)))),
                  const SizedBox(height: 16),
                  Text('Assign Room', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<List<RoomModel>>(
                      stream: firestore.streamAvailableRooms(),
                      builder: (context, snapshot) {
                        final rooms = snapshot.data ?? const [];
                        if (rooms.isEmpty) {
                          return Center(child: Text('No available rooms', style: TextStyle(color: Colors.grey.shade600)));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: rooms.length,
                          itemBuilder: (_, index) {
                            final room = rooms[index];
                            return Card(
                              child: ListTile(
                                title: Text('Room ${room.roomNumber}'),
                                subtitle: Text('${room.hostelBlock} · ${room.occupancy}/${room.capacity} occupied'),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    await firestore.transferStudentToRoom(studentId: student.uid, roomId: room.id);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                                  child: const Text('Assign'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CompactComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _CompactComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(complaint.title.isEmpty ? complaint.issue : complaint.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(complaint.studentName.isEmpty ? 'Student' : complaint.studentName, style: TextStyle(color: Colors.grey.shade700)),
              const Spacer(),
              Text(complaint.status.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeTile extends StatelessWidget {
  final FeeModel fee;

  const _FeeTile({required this.fee});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(fee.studentName.isEmpty ? 'Fee record' : fee.studentName),
        subtitle: Text(fee.roomNumber.isEmpty ? fee.feeType : 'Room ${fee.roomNumber}'),
        trailing: Text('₹${fee.paidAmount.toStringAsFixed(0)}/${fee.amount.toStringAsFixed(0)}'),
      ),
    );
  }
}

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
  /*
    ),
      ),
    );
  }

  Future<void> _showAssignRoomSheet(BuildContext context, UserModel student) async {
    final firestore = context.read<FirestoreService>();
    String? selectedRoomId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<List<RoomModel>>(
          stream: firestore.streamRooms(),
          builder: (context, snapshot) {
            final rooms = snapshot.data ?? const [];
            return StatefulBuilder(
              builder: (context, setModalState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Assign Room', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (rooms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No rooms available', style: TextStyle(color: Colors.grey.shade500)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedRoomId,
                      decoration: const InputDecoration(labelText: 'Room', prefixIcon: Icon(Icons.bed_outlined)),
                      items: rooms
                          .map(
                            (room) => DropdownMenuItem<String>(
                              value: room.id,
                              child: Text('${room.roomNumber} - ${room.hostelBlock} (${room.occupancy}/${room.capacity})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setModalState(() => selectedRoomId = value),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: rooms.isEmpty || selectedRoomId == null
                          ? null
                          : () async {
                              await firestore.transferStudentToRoom(studentId: student.uid, roomId: selectedRoomId!);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AdminRoomsTab extends StatelessWidget {
  const _AdminRoomsTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: StreamBuilder<List<RoomModel>>(
        stream: firestore.streamRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data ?? const [];
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bed_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No rooms', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final totalBeds = rooms.fold<int>(0, (sum, room) => sum + room.capacity);
          final usedBeds = rooms.fold<int>(0, (sum, room) => sum + room.occupancy);
          final availableRooms = rooms.where((room) => !room.isFull).length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary.withOpacity(0.10), colorScheme.secondary.withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('Rooms', '${rooms.length}', colorScheme.primary),
                    _miniStat('Beds', '$usedBeds/$totalBeds', Colors.orange),
                    _miniStat('Open', '$availableRooms', Colors.green),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _roomRequestsSection(context, firestore),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: rooms.length,
                  itemBuilder: (_, index) => _RoomTile(room: rooms[index]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  void _showAddRoomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final roomNumberCtrl = TextEditingController();
    final blockCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: '1');
    final capacityCtrl = TextEditingController(text: '2');
    final rentCtrl = TextEditingController(text: '5000');
    String roomType = 'double';

    showModalBottomSheet(

  Widget _roomRequestsSection(BuildContext context, FirestoreService firestore) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestore.streamRoomRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final requests = (snapshot.data ?? const [])
            .where((request) => request['status'] == 'pending')
            .toList();

        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Room Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...requests.map((request) => _roomRequestTile(context, firestore, request)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roomRequestTile(BuildContext context, FirestoreService firestore, Map<String, dynamic> request) {
    final requestId = request['id'] as String? ?? '';
    final userName = request['userName'] as String? ?? 'Student';
    final roomNumber = request['roomNumber'] as String? ?? '';
    final hostelBlock = request['hostelBlock'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Room ${roomNumber.isEmpty ? '--' : roomNumber} ${hostelBlock.isEmpty ? '' : '· $hostelBlock'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          TextButton(
            onPressed: requestId.isEmpty
                ? null
                : () async {
                    await firestore.rejectRoomRequest(requestId);
                  },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: requestId.isEmpty
                ? null
                : () async {
                    await firestore.approveRoomRequest(requestId);
                  },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Add Room', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: roomNumberCtrl,
                    decoration: const InputDecoration(labelText: 'Room Number', prefixIcon: Icon(Icons.meeting_room)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: blockCtrl,
                    decoration: const InputDecoration(labelText: 'Block', prefixIcon: Icon(Icons.apartment)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: floorCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Floor', prefixIcon: Icon(Icons.layers)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Capacity', prefixIcon: Icon(Icons.people)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: roomType,
                    decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('Single')),
                      DropdownMenuItem(value: 'double', child: Text('Double')),
                      DropdownMenuItem(value: 'triple', child: Text('Triple')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        roomType = value ?? 'double';
                        capacityCtrl.text = roomType == 'single' ? '1' : roomType == 'double' ? '2' : '3';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rent per month', prefixIcon: Icon(Icons.currency_rupee)),
                  ),
                  const SizedBox(height: 20),
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
                          floor: int.tryParse(floorCtrl.text.trim()) ?? 0,
                          capacity: int.tryParse(capacityCtrl.text.trim()) ?? 1,
                          roomType: roomType,
                          rentPerMonth: double.tryParse(rentCtrl.text.trim()) ?? 0,
                          isAvailable: true,
                          createdAt: DateTime.now(),
                        );
                        await context.read<FirestoreService>().addRoom(room);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;

  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firestore = context.read<FirestoreService>();
    final percent = room.capacity > 0 ? room.occupancy / room.capacity : 0.0;
    final statusColor = room.isFull ? Colors.red : (percent > 0.5 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRoomDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(room.roomNumber, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Block ${room.hostelBlock} · ${room.roomType.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${room.occupancy}/${room.capacity} occupied', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(room.isFull ? 'Full' : 'Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDetail(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Room ${room.roomNumber}', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _detailRow(Icons.apartment, 'Block', room.hostelBlock),
              _detailRow(Icons.layers, 'Floor', '${room.floor}'),
              _detailRow(Icons.category, 'Type', room.roomType.toUpperCase()),
              _detailRow(Icons.people, 'Occupancy', '${room.occupancy}/${room.capacity}'),
              _detailRow(Icons.currency_rupee, 'Rent', '₹${room.rentPerMonth.toStringAsFixed(0)}/mo'),
              const SizedBox(height: 20),
              Text('Assigned Students', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              FutureBuilder<List<UserModel>>(
                future: _loadAssignedStudents(firestore),
                builder: (context, snapshot) {
                  final students = snapshot.data ?? const [];
                  if (students.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No students assigned', style: TextStyle(color: Colors.grey.shade500)),
                    );
                  }
                  return Column(
                    children: students
                        .map(
                          (student) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                              child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?', style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(student.name),
                            subtitle: Text(student.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () async {
                                await firestore.removeStudentFromRoom(room.id, student.uid);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _showAssignStudentSheet(context, room);
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Assign Student'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestore.deleteRoom(room.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete Room', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<UserModel>> _loadAssignedStudents(FirestoreService firestore) async {
    final students = <UserModel>[];
    for (final id in room.assignedStudentIds) {
      final user = await firestore.getUser(id);
      if (user != null) students.add(user);
    }
    return students;
  }

  Future<void> _showAssignStudentSheet(BuildContext context, RoomModel room) async {
    final firestore = context.read<FirestoreService>();
    String? selectedStudentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<List<UserModel>>(
          stream: firestore.streamUsersByRole('student'),
          builder: (context, snapshot) {
            final students = snapshot.data ?? const [];
            return StatefulBuilder(
              builder: (context, setModalState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Assign Student to Room', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No students available', style: TextStyle(color: Colors.grey.shade500)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedStudentId,
                      decoration: const InputDecoration(labelText: 'Student', prefixIcon: Icon(Icons.person)),
                      items: students
                          .map(
                            (student) => DropdownMenuItem<String>(
                              value: student.uid,
                              child: Text(student.name.isEmpty ? student.email : student.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setModalState(() => selectedStudentId = value),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: students.isEmpty || selectedStudentId == null
                          ? null
                          : () async {
                              await firestore.transferStudentToRoom(studentId: selectedStudentId!, roomId: room.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AdminComplaintsTab extends StatelessWidget {
  const _AdminComplaintsTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: firestore.streamAllComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final complaints = snapshot.data ?? const [];
          if (complaints.isEmpty) {
            return Center(child: Text('No complaints', style: TextStyle(color: Colors.grey.shade500)));
          }

          final pending = complaints.where((item) => item.status == 'pending').toList();
          final active = complaints.where((item) => item.status == 'in_progress').toList();
          final resolved = complaints.where((item) => item.status == 'resolved').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.primary),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Pending (${pending.length})'),
                      Tab(text: 'Active (${active.length})'),
                      Tab(text: 'Resolved (${resolved.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _complaintList(context, pending),
                      _complaintList(context, active),
                      _complaintList(context, resolved),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _complaintList(BuildContext context, List<ComplaintModel> items) {
    if (items.isEmpty) {
      return Center(child: Text('No complaints here', style: TextStyle(color: Colors.grey.shade400)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, index) => _ComplaintTile(complaint: items[index]),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintTile({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = complaint.status == 'resolved'
        ? Colors.green
        : complaint.status == 'in_progress'
            ? Colors.blue
            : complaint.status == 'rejected'
                ? Colors.red
                : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Icon(_catIcon(complaint.category), size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(complaint.studentName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(complaint.status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(complaint.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final responseCtrl = TextEditingController(text: complaint.adminResponse ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Complaint Detail', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('by ${complaint.studentName}', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              _row(Icons.title, 'Title', complaint.title),
              _row(Icons.category, 'Category', complaint.category.toUpperCase()),
              _row(Icons.flag, 'Priority', complaint.priority.toUpperCase()),
              _row(Icons.circle, 'Status', complaint.status.toUpperCase()),
              const SizedBox(height: 10),
              Text('Description', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 4),
              Text(complaint.description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextFormField(
                controller: responseCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Admin Response', prefixIcon: Icon(Icons.message_outlined), alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusButton(ctx, firestore, 'pending', 'Pending', Colors.orange),
                  _statusButton(ctx, firestore, 'in_progress', 'In Progress', Colors.blue),
                  _statusButton(ctx, firestore, 'resolved', 'Resolved', Colors.green),
                  _statusButton(ctx, firestore, 'rejected', 'Rejected', Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestore.deleteComplaint(complaint.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton(BuildContext ctx, FirestoreService firestore, String status, String label, Color color) {
    return ElevatedButton(
      onPressed: () async {
        await firestore.updateComplaintStatus(
          complaint.id,
          status,
          adminResponse: complaint.adminResponse,
        );
        if (ctx.mounted) Navigator.pop(ctx);
      },
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  IconData _catIcon(String category) {
    switch (category) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'furniture':
        return Icons.chair;
      case 'cleanliness':
        return Icons.cleaning_services;
      default:
        return Icons.report;
    }
  }
}

class _AdminFeesTab extends StatelessWidget {
  const _AdminFeesTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: StreamBuilder<List<FeeModel>>(
        stream: firestore.streamAllFees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final fees = snapshot.data ?? const [];
          if (fees.isEmpty) {
            return Center(child: Text('No fee records', style: TextStyle(color: Colors.grey.shade500)));
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: firestore.getFeeStats(),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? const {};
                    final totalAmount = (stats['totalAmount'] as double?) ?? 0;
                    final collectedAmount = (stats['collectedAmount'] as double?) ?? 0;
                    final pendingAmount = (stats['pendingAmount'] as double?) ?? 0;
                    final paidPercent = totalAmount > 0 ? collectedAmount / totalAmount : 0.0;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _metric('Collected', '₹${collectedAmount.toStringAsFixed(0)}')),
                            Container(width: 1, height: 40, color: Colors.white30),
                            Expanded(child: _metric('Pending', '₹${pendingAmount.toStringAsFixed(0)}')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: paidPercent,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('${(paidPercent * 100).toStringAsFixed(0)}% collected', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: fees.length,
                  itemBuilder: (_, index) => _FeeTile(fee: fees[index]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFeeSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Fee'),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  void _showAddFeeSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: '5000');
    final monthCtrl = TextEditingController(text: _monthLabel(DateTime.now()));
    final dueDateCtrl = TextEditingController(text: _dateLabel(DateTime.now().add(const Duration(days: 7))));
    final studentNameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    String feeType = 'hostel_rent';
    String? selectedStudentId;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StreamBuilder<List<UserModel>>(
          stream: context.read<FirestoreService>().streamUsersByRole('student'),
          builder: (context, studentSnapshot) {
            final students = studentSnapshot.data ?? const [];
            return StatefulBuilder(
              builder: (context, setModalState) => Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text('Add Fee', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      if (students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No students available', style: TextStyle(color: Colors.grey.shade500)),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedStudentId,
                          decoration: const InputDecoration(labelText: 'Student', prefixIcon: Icon(Icons.person)),
                          items: students
                              .map(
                                (student) => DropdownMenuItem<String>(
                                  value: student.uid,
                                  child: Text(student.name.isEmpty ? student.email : student.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            final student = students.firstWhere((item) => item.uid == value);
                            setModalState(() {
                              selectedStudentId = value;
                              studentNameCtrl.text = student.name;
                              roomCtrl.text = student.roomNumber;
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: studentNameCtrl,
                        decoration: const InputDecoration(labelText: 'Student Name', prefixIcon: Icon(Icons.badge)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: roomCtrl,
                        decoration: const InputDecoration(labelText: 'Room Number', prefixIcon: Icon(Icons.bed)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: feeType,
                        decoration: const InputDecoration(labelText: 'Fee Type', prefixIcon: Icon(Icons.category)),
                        items: const [
                          DropdownMenuItem(value: 'hostel_rent', child: Text('Hostel Rent')),
                          DropdownMenuItem(value: 'mess', child: Text('Mess')),
                          DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'security_deposit', child: Text('Security Deposit')),
                        ],
                        onChanged: (value) => setModalState(() => feeType = value ?? 'hostel_rent'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee)),
                        validator: (v) => v == null || double.tryParse(v.trim()) == null ? 'Valid amount required' : null,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              dueDate = picked;
                              dueDateCtrl.text = _dateLabel(picked);
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Due Date', prefixIcon: Icon(Icons.calendar_today)),
                          child: Text(dueDateCtrl.text),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: monthCtrl,
                        decoration: const InputDecoration(labelText: 'Month', prefixIcon: Icon(Icons.event_note)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: students.isEmpty || selectedStudentId == null
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final selectedStudent = students.firstWhere((student) => student.uid == selectedStudentId);
                                  final fee = FeeModel(
                                    id: '',
                                    studentId: selectedStudent.uid,
                                    studentName: studentNameCtrl.text.trim(),
                                    roomNumber: roomCtrl.text.trim(),
                                    amount: double.parse(amountCtrl.text.trim()),
                                    paidAmount: 0,
                                    feeType: feeType,
                                    status: 'pending',
                                    paymentMethod: '',
                                    transactionId: null,
                                    dueDate: dueDate,
                                    month: monthCtrl.text.trim(),
                                    createdAt: DateTime.now(),
                                  );
                                  await context.read<FirestoreService>().addFee(fee);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _monthLabel(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String _dateLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _FeeTile extends StatelessWidget {
  final FeeModel fee;

  const _FeeTile({required this.fee});

  @override
  Widget build(BuildContext context) {
    final color = fee.isPaid ? Colors.green : fee.isOverdue ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.receipt_long, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fee.feeType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${fee.studentName} · ${fee.month}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${fee.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(fee.isPaid ? 'PAID' : 'DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final paymentCtrl = TextEditingController(text: fee.balanceDue > 0 ? fee.balanceDue.toStringAsFixed(0) : '0');
    final methodCtrl = TextEditingController(text: fee.paymentMethod.isEmpty ? 'online' : fee.paymentMethod);
    final txnCtrl = TextEditingController(text: fee.transactionId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Fee Detail', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _row(Icons.badge, 'Student', fee.studentName),
              _row(Icons.bed, 'Room', fee.roomNumber.isEmpty ? '--' : fee.roomNumber),
              _row(Icons.category, 'Type', fee.feeType.replaceAll('_', ' ').toUpperCase()),
              _row(Icons.event_note, 'Month', fee.month),
              _row(Icons.currency_rupee, 'Amount', '₹${fee.amount.toStringAsFixed(0)}'),
              _row(Icons.check_circle, 'Paid', '₹${fee.paidAmount.toStringAsFixed(0)}'),
              _row(Icons.warning, 'Balance', '₹${fee.balanceDue.toStringAsFixed(0)}'),
              _row(Icons.circle, 'Status', fee.status.toUpperCase()),
              _row(Icons.calendar_today, 'Due Date', _dateLabel(fee.dueDate)),
              const SizedBox(height: 16),
              if (!fee.isPaid) ...[
                TextFormField(
                  controller: paymentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Payment Amount', prefixIcon: Icon(Icons.payments)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: methodCtrl,
                  decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.credit_card)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: txnCtrl,
                  decoration: const InputDecoration(labelText: 'Transaction ID', prefixIcon: Icon(Icons.tag)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(paymentCtrl.text.trim()) ?? 0;
                      if (amount <= 0) return;
                      await firestore.recordPayment(
                        feeId: fee.id,
                        amount: amount,
                        paymentMethod: methodCtrl.text.trim(),
                        transactionId: txnCtrl.text.trim().isEmpty ? null : txnCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Record Payment'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestore.deleteFee(fee.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _AdminLeavesTab extends StatelessWidget {
  const _AdminLeavesTab();

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: StreamBuilder<List<LeaveModel>>(
        stream: firestore.streamAllLeaves(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final leaves = snapshot.data ?? const [];
          if (leaves.isEmpty) {
            return Center(child: Text('No leave requests', style: TextStyle(color: Colors.grey.shade500)));
          }

          final pending = leaves.where((item) => item.isPending).toList();
          final approved = leaves.where((item) => item.isApproved).toList();
          final rejected = leaves.where((item) => item.isRejected).toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.primary),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Pending (${pending.length})'),
                      Tab(text: 'Approved (${approved.length})'),
                      Tab(text: 'Rejected (${rejected.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _leaveList(context, pending),
                      _leaveList(context, approved),
                      _leaveList(context, rejected),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _leaveList(BuildContext context, List<LeaveModel> leaves) {
    if (leaves.isEmpty) {
      return Center(child: Text('No leaves here', style: TextStyle(color: Colors.grey.shade400)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (_, index) => _LeaveTile(leave: leaves[index]),
    );
  }
}

class _LeaveTile extends StatelessWidget {
  final LeaveModel leave;

  const _LeaveTile({required this.leave});

  @override
  Widget build(BuildContext context) {
    final color = leave.isApproved ? Colors.green : leave.isRejected ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 52,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text('${leave.leaveType.replaceAll('_', ' ').toUpperCase()} · ${leave.totalDays} day(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    Text('${_dateLabel(leave.fromDate)} → ${_dateLabel(leave.toDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(leave.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final remarksCtrl = TextEditingController(text: leave.adminRemarks ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Leave Request', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('by ${leave.studentName}', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              _row(Icons.event_note, 'Type', leave.leaveType.replaceAll('_', ' ').toUpperCase()),
              _row(Icons.calendar_today, 'From', _dateLabel(leave.fromDate)),
              _row(Icons.calendar_today, 'To', _dateLabel(leave.toDate)),
              _row(Icons.timelapse, 'Duration', '${leave.totalDays} day(s)'),
              _row(Icons.circle, 'Status', leave.status.toUpperCase()),
              const SizedBox(height: 10),
              Text('Reason', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 4),
              Text(leave.reason, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextFormField(
                controller: remarksCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Admin Remarks', prefixIcon: Icon(Icons.message_outlined), alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              if (leave.isPending)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await firestore.updateLeaveStatus(leave.id, 'approved', adminRemarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await firestore.updateLeaveStatus(leave.id, 'rejected', adminRemarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              if (!leave.isPending && leave.adminRemarks != null) ...[
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: Text('Existing remarks: ${leave.adminRemarks!}')),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestore.deleteLeave(leave.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(
              radius: 52,
              backgroundColor: Colors.amber,
              child: Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? 'Admin', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 28),
            _profileItem(context, Icons.people, 'Manage Students', () => _jumpToTab(context, 1)),
            _profileItem(context, Icons.bed, 'Manage Rooms', () => _jumpToTab(context, 2)),
            _profileItem(context, Icons.report, 'Manage Complaints', () => _jumpToTab(context, 3)),
            _profileItem(context, Icons.event_note, 'Manage Leaves', () => _jumpToTab(context, 4)),
            _profileItem(context, Icons.receipt_long, 'Track Fees', () => _jumpToTab(context, 5)),
            _profileItem(context, Icons.info_outline, 'About', () {
              showAboutDialog(
                context: context,
                applicationName: 'Hostel Manager',
                applicationVersion: '1.0.0',
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await auth.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }

  void _jumpToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AdminDashboardState>();
    if (state != null) {
      state.jumpToTab(index);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _CompactComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _CompactComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = complaint.status == 'resolved'
        ? Colors.green
        : complaint.status == 'in_progress'
            ? Colors.blue
            : complaint.status == 'rejected'
                ? Colors.red
                : Colors.orange;

    return SizedBox(
      width: 220,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(complaint.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 6),
              Text(complaint.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(complaint.status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                  const Spacer(),
                  Text(complaint.priority.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: complaint.priority == 'high' ? Colors.red : Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
*/
