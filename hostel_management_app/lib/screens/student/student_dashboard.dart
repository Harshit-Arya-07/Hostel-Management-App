import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../models/fee_model.dart';
import '../../models/leave_model.dart';
import '../profile/profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  static const routeName = '/student-dashboard';
  final int initialIndex;

  const StudentDashboard({super.key, this.initialIndex = 0});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late int _currentIndex;

  void jumpToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const _StudentHomeTab();
      case 1:
        return const _StudentRoomTab();
      case 2:
        return const _StudentComplaintsTab();
      case 3:
        return const _StudentFeesTab();
      case 4:
        return const _StudentLeaveTab();
      case 5:
        return const _StudentProfileTab();
      default:
        return const _StudentHomeTab();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
        onDestinationSelected: (i) => jumpToTab(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bed_outlined),
            selectedIcon: Icon(Icons.bed),
            label: 'Room',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Fees',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Leave',
          ),
        ],
      ),
    );
  }
}

class _StudentProfileTab extends StatelessWidget {
  const _StudentProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const ProfileScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 1: HOME
// ═══════════════════════════════════════════════════════════════
class _StudentHomeTab extends StatefulWidget {
  const _StudentHomeTab();

  @override
  State<_StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<_StudentHomeTab> {
  bool _initialized = false;
  String _displayName = 'Student';
  String _uid = '';
  Stream<RoomModel?> _roomStream = const Stream.empty();
  Stream<List<ComplaintModel>> _complaintsStream = const Stream.empty();
  Stream<List<LeaveModel>> _leavesStream = const Stream.empty();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;
    _uid = user?.uid ?? '';
    _displayName = user?.displayName ?? 'Student';

    if (_uid.isNotEmpty) {
      _roomStream = firestore.streamRoomByStudentId(_uid);
      _complaintsStream = firestore.streamComplaintsByStudent(_uid);
      _leavesStream = firestore.streamRecentLeavesByStudent(_uid, limit: 3);
      Future<void>.microtask(() async {
        final profile = await firestore.getUser(_uid);
        if (!mounted || profile == null) return;
        setState(() {
          if (profile.name.isNotEmpty) {
            _displayName = profile.name;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              context.findAncestorStateOfType<_StudentDashboardState>()?.jumpToTab(5);
            },
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              (_displayName.isEmpty ? 'S' : _displayName)[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getGreeting(),
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                                Text(_displayName,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Stack(
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                Positioned(
                                  right: 0, top: 0,
                                  child: Container(width: 10, height: 10,
                                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Room info bar from Firestore
                      StreamBuilder<RoomModel?>(
                        stream: _roomStream,
                        builder: (context, snap) {
                          final room = snap.data;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school, color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text('🎓 Student', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                                const Spacer(),
                                const Icon(Icons.bed, color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  room != null ? 'Room ${room.roomNumber}' : 'No Room',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _QuickAction(icon: Icons.report_problem_outlined, label: 'New\nComplaint', color: Colors.orange, onTap: () {}),
                _QuickAction(icon: Icons.event_note, label: 'Apply\nLeave', color: Colors.indigo, onTap: () {}),
                _QuickAction(icon: Icons.bed, label: 'Room\nDetails', color: colorScheme.primary, onTap: () {}),
                _QuickAction(icon: Icons.receipt_long, label: 'Fee\nHistory', color: Colors.purple, onTap: () {}),
                _QuickAction(icon: Icons.support_agent, label: 'Contact\nAdmin', color: Colors.teal, onTap: () {}),
              ],
            ),
          ),
        ),

        // My Complaints
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Text('My Complaints', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: StreamBuilder<List<ComplaintModel>>(
              stream: _complaintsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final complaints = snapshot.data ?? [];
                if (complaints.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle, size: 40, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    Text('No complaints!', style: TextStyle(color: Colors.grey.shade500)),
                  ]));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: complaints.length > 5 ? 5 : complaints.length,
                  itemBuilder: (_, i) => _ComplaintMiniCard(complaint: complaints[i]),
                );
              },
            ),
          ),
        ),

        // Leave Status
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Recent Leaves', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        SliverToBoxAdapter(
          child: StreamBuilder<List<LeaveModel>>(
            stream: _leavesStream,
            builder: (context, snapshot) {
              final leaves = snapshot.data ?? [];
              if (leaves.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No leave records', style: TextStyle(color: Colors.grey.shade500))),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: leaves.length > 3 ? 3 : leaves.length,
                itemBuilder: (_, i) => _LeaveMiniCard(leave: leaves[i]),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌅';
    if (h < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 2: ROOM DETAILS (LIVE FROM FIRESTORE)
// ═══════════════════════════════════════════════════════════════
class _StudentRoomTab extends StatelessWidget {
  const _StudentRoomTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Room')),
      body: StreamBuilder<RoomModel?>(
        stream: user != null ? firestore.streamRoomByStudentId(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final room = snapshot.data;
          final pct = room != null && room.capacity > 0 ? room.occupancy / room.capacity : 0.0;
          final statusColor = room == null
              ? Colors.grey
              : room.isFull
                  ? Colors.red
                  : (pct > 0.5 ? Colors.orange : Colors.green);
          final currentRoomId = room?.id ?? '';
          final studentId = user?.uid ?? '';
            final studentName = user?.displayName ?? 'Student';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (room == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bed_outlined, size: 60, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 20),
                        Text('No Room Assigned', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text('Contact your hostel admin to get a room assigned.',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(room.roomNumber, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Room ${room.roomNumber}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(room.isFull ? 'FULL' : 'AVAILABLE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                          const SizedBox(height: 20),
                          _infoRow(Icons.apartment, 'Block', room.hostelBlock),
                          _infoRow(Icons.layers, 'Floor', '${room.floor}'),
                          _infoRow(Icons.category, 'Type', room.roomType.toUpperCase()),
                          _infoRow(Icons.people, 'Occupancy', '${room.occupancy}/${room.capacity}'),
                          _infoRow(Icons.attach_money, 'Rent/Month', '₹${room.rentPerMonth.toStringAsFixed(0)}'),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('${room.availableBeds} bed(s) available',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group, color: colorScheme.primary, size: 22),
                              const SizedBox(width: 10),
                              Text('Roommates',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<UserModel>>(
                            future: firestore.getRoommates(room.id, user?.uid ?? ''),
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                              }
                              final mates = snap.data ?? [];
                              if (mates.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Icon(Icons.person_off, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text('No roommates yet', style: TextStyle(color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: mates
                                    .map((m) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor: colorScheme.primaryContainer,
                                            child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                          ),
                                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
                                          trailing: Text(m.phone.isNotEmpty ? m.phone : '--',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _availableRoomsSection(context, firestore, studentId, studentName, currentRoomId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _availableRoomsSection(
    BuildContext context,
    FirestoreService firestore,
    String studentId,
    String studentName,
    String currentRoomId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Available Rooms',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        StreamBuilder<List<RoomModel>>(
          stream: firestore.streamAvailableRooms(),
          builder: (context, snapshot) {
            final rooms = (snapshot.data ?? const [])
                .where((room) => room.id != currentRoomId)
                .toList();

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }

            if (rooms.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No rooms available right now', style: TextStyle(color: Colors.grey.shade500)),
              );
            }

            return Column(
              children: rooms
                  .map(
                    (room) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            room.roomNumber.isNotEmpty ? room.roomNumber[0].toUpperCase() : '?',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        title: Text('Room ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${room.hostelBlock} · ${room.occupancy}/${room.capacity} occupied'),
                        trailing: TextButton(
                          onPressed: () async {
                            await firestore.createRoomRequest(
                              userId: studentId,
                              userName: studentName,
                              roomId: room.id,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Room request sent')),
                            );
                          },
                          child: const Text('Request'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 3: COMPLAINTS (RAISE + LIST)
// ═══════════════════════════════════════════════════════════════
class _StudentComplaintsTab extends StatelessWidget {
  const _StudentComplaintsTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: user != null ? firestore.streamComplaintsByStudent(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
              const SizedBox(height: 16),
              Text('No complaints', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Text('Everything is great! 🎉', style: TextStyle(color: Colors.grey.shade400)),
            ]));
          }

          final pending = complaints.where((c) => c.status == 'pending').toList();
          final inProgress = complaints.where((c) => c.status == 'in_progress').toList();
          final resolved = complaints.where((c) => c.status == 'resolved').toList();

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
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Pending (${pending.length})'),
                      Tab(text: 'Active (${inProgress.length})'),
                      Tab(text: 'Resolved (${resolved.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(children: [
                    _complaintList(pending),
                    _complaintList(inProgress),
                    _complaintList(resolved),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewComplaint(context),
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
    );
  }

  Widget _complaintList(List<ComplaintModel> list) {
    if (list.isEmpty) return Center(child: Text('No complaints here', style: TextStyle(color: Colors.grey.shade400)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _ComplaintFullCard(complaint: list[i]),
    );
  }

  void _showNewComplaint(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    String category = 'other';
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                  Text('Raise a Complaint', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Room Number', prefixIcon: Icon(Icons.meeting_room)),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'plumbing', child: Text('🔧 Plumbing')),
                      DropdownMenuItem(value: 'electrical', child: Text('⚡ Electrical')),
                      DropdownMenuItem(value: 'furniture', child: Text('🪑 Furniture')),
                      DropdownMenuItem(value: 'cleanliness', child: Text('🧹 Cleanliness')),
                      DropdownMenuItem(value: 'other', child: Text('📋 Other')),
                    ],
                    onChanged: (v) => setModalState(() => category = v ?? 'other'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority', prefixIcon: Icon(Icons.flag_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                      DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                      DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                    ],
                    onChanged: (v) => setModalState(() => priority = v ?? 'medium'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final auth = context.read<AuthService>();
                        final complaint = ComplaintModel(
                          id: '',
                          studentId: auth.currentUser?.uid ?? '',
                          userId: auth.currentUser?.uid ?? '',
                          studentName: auth.currentUser?.displayName ?? '',
                          roomNumber: roomCtrl.text.trim(),
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          category: category,
                          status: 'pending',
                          priority: priority,
                          createdAt: DateTime.now(),
                        );
                        await context.read<FirestoreService>().addComplaint(complaint);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Complaint submitted!'), backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                        }
                      },
                      child: const Text('Submit Complaint'),
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

// ═══════════════════════════════════════════════════════════════
//  TAB 4: FEES (VIEW DETAILS)
// ═══════════════════════════════════════════════════════════════
class _StudentFeesTab extends StatelessWidget {
  const _StudentFeesTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Fees')),
      body: StreamBuilder<List<FeeModel>>(
        stream: user != null ? firestore.streamFeesByStudent(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final fees = snapshot.data ?? [];
          if (fees.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No fee records', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
            ]));
          }

          final totalDue = fees.fold<double>(0, (s, f) => s + f.balanceDue);
          final totalPaid = fees.fold<double>(0, (s, f) => s + f.paidAmount);
          final totalAmount = fees.fold<double>(0, (s, f) => s + f.amount);
          final paidPercent = totalAmount > 0 ? totalPaid / totalAmount : 0.0;

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: Column(children: [
                        const Text('Total Paid', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('₹${totalPaid.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ])),
                      Container(width: 1, height: 40, color: Colors.white30),
                      Expanded(child: Column(children: [
                        const Text('Due Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('₹${totalDue.toStringAsFixed(0)}',
                            style: TextStyle(
                                color: totalDue > 0 ? Colors.amber.shade200 : Colors.greenAccent,
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ])),
                    ]),
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
                      child: Text('${(paidPercent * 100).toStringAsFixed(0)}% paid',
                          style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ),
                  ],
                ),
              ),

              // Fee list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: fees.length,
                  itemBuilder: (_, i) => _FeeFullCard(fee: fees[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 5: APPLY LEAVE
// ═══════════════════════════════════════════════════════════════
class _StudentLeaveTab extends StatelessWidget {
  const _StudentLeaveTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Leaves')),
      body: StreamBuilder<List<LeaveModel>>(
        stream: user != null ? firestore.streamLeavesByStudent(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final leaves = snapshot.data ?? [];

          if (leaves.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.event_available, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No leave applications', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Text('Tap + to apply for leave', style: TextStyle(color: Colors.grey.shade400)),
            ]));
          }

          final pending = leaves.where((l) => l.isPending).length;
          final approved = leaves.where((l) => l.isApproved).length;
          final rejected = leaves.where((l) => l.isRejected).length;

          return Column(
            children: [
              // Stats bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.06),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('Total', '${leaves.length}', Theme.of(context).colorScheme.primary),
                    _miniStat('Pending', '$pending', Colors.orange),
                    _miniStat('Approved', '$approved', Colors.green),
                    _miniStat('Rejected', '$rejected', Colors.red),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: leaves.length,
                  itemBuilder: (_, i) => _LeaveFullCard(leave: leaves[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeave(context),
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }

  void _showApplyLeave(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final reasonCtrl = TextEditingController();
    String leaveType = 'home_visit';
    DateTime? fromDate;
    DateTime? toDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                  Text('Apply for Leave', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: leaveType,
                    decoration: const InputDecoration(labelText: 'Leave Type', prefixIcon: Icon(Icons.event_note)),
                    items: const [
                      DropdownMenuItem(value: 'home_visit', child: Text('🏠 Home Visit')),
                      DropdownMenuItem(value: 'medical', child: Text('🏥 Medical')),
                      DropdownMenuItem(value: 'emergency', child: Text('🚨 Emergency')),
                      DropdownMenuItem(value: 'personal', child: Text('👤 Personal')),
                      DropdownMenuItem(value: 'other', child: Text('📋 Other')),
                    ],
                    onChanged: (v) => setModalState(() => leaveType = v ?? 'home_visit'),
                  ),
                  const SizedBox(height: 14),

                  // From Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setModalState(() => fromDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'From Date', prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(fromDate != null ? _fmtDate(fromDate!) : 'Select date'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // To Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fromDate ?? DateTime.now(),
                        firstDate: fromDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setModalState(() => toDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'To Date', prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(toDate != null ? _fmtDate(toDate!) : 'Select date'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (fromDate != null && toDate != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Duration: ${toDate!.difference(fromDate!).inDays + 1} day(s)',
                            style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  if (fromDate != null && toDate != null) const SizedBox(height: 14),

                  TextFormField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Reason', prefixIcon: Icon(Icons.note_outlined), alignLabelWithHint: true),
                    validator: (v) => v == null || v.isEmpty ? 'Please provide a reason' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (fromDate == null || toDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Please select both dates'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                          return;
                        }
                        if (toDate!.isBefore(fromDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('To date cannot be before From date'), backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                          return;
                        }

                        final auth = context.read<AuthService>();
                        final leave = LeaveModel(
                          id: '',
                          studentId: auth.currentUser?.uid ?? '',
                          userId: auth.currentUser?.uid ?? '',
                          studentName: auth.currentUser?.displayName ?? '',
                          reason: reasonCtrl.text.trim(),
                          leaveType: leaveType,
                          status: 'pending',
                          fromDate: fromDate!,
                          toDate: toDate!,
                          createdAt: DateTime.now(),
                        );
                        await context.read<FirestoreService>().addLeave(leave);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Leave application submitted!'), backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                        }
                      },
                      child: const Text('Submit Application'),
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

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ComplaintMiniCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintMiniCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = complaint.status == 'resolved' ? Colors.green : complaint.status == 'in_progress' ? Colors.blue : Colors.orange;
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(complaint.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 6),
              Text(complaint.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const Spacer(),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(complaint.status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ),
                const Spacer(),
                Text(complaint.priority.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: complaint.priority == 'high' ? Colors.red : Colors.grey)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveMiniCard extends StatelessWidget {
  final LeaveModel leave;
  const _LeaveMiniCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final color = leave.isApproved ? Colors.green : leave.isRejected ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.event_note, color: color, size: 22),
        ),
        title: Text(leave.leaveType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('${leave.totalDays} day(s)', style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(leave.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}

class _ComplaintFullCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintFullCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = complaint.status == 'resolved' ? Colors.green : complaint.status == 'in_progress' ? Colors.blue : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(_catIcon(complaint.category), size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(complaint.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(complaint.status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(complaint.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            if (complaint.adminResponse != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(complaint.adminResponse!, style: const TextStyle(fontSize: 12, color: Colors.blue))),
                ]),
              ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Text(_fmtDate(complaint.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              const Spacer(),
              Icon(Icons.flag, size: 14, color: complaint.priority == 'high' ? Colors.red : complaint.priority == 'medium' ? Colors.orange : Colors.green),
              const SizedBox(width: 4),
              Text(complaint.priority.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ]),
          ],
        ),
      ),
    );
  }

  IconData _catIcon(String c) {
    switch (c) {
      case 'plumbing': return Icons.plumbing;
      case 'electrical': return Icons.electrical_services;
      case 'furniture': return Icons.chair;
      case 'cleanliness': return Icons.cleaning_services;
      default: return Icons.report;
    }
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _FeeFullCard extends StatelessWidget {
  final FeeModel fee;
  const _FeeFullCard({required this.fee});

  @override
  Widget build(BuildContext context) {
    final color = fee.isPaid ? Colors.green : fee.isOverdue ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showFeeDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_long, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(fee.feeType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(fee.month, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${fee.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(fee.isPaid ? 'PAID' : 'DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ),
                ]),
              ]),
              if (!fee.isPaid) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fee.amount > 0 ? fee.paidAmount / fee.amount : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Paid: ₹${fee.paidAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('Balance: ₹${fee.balanceDue.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFeeDetail(BuildContext context) {
    final color = fee.isPaid ? Colors.green : fee.isOverdue ? Colors.red : Colors.orange;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Fee Details', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _row(Icons.receipt, 'Type', fee.feeType.replaceAll('_', ' ').toUpperCase()),
            _row(Icons.calendar_month, 'Month', fee.month),
            _row(Icons.attach_money, 'Amount', '₹${fee.amount.toStringAsFixed(0)}'),
            _row(Icons.check_circle, 'Paid', '₹${fee.paidAmount.toStringAsFixed(0)}'),
            _row(Icons.warning, 'Balance', '₹${fee.balanceDue.toStringAsFixed(0)}'),
            _row(Icons.circle, 'Status', fee.isPaid ? 'Paid' : fee.isOverdue ? 'Overdue' : 'Pending'),
            if (fee.paymentMethod.isNotEmpty)
              _row(Icons.payment, 'Method', fee.paymentMethod.toUpperCase()),
            if (fee.transactionId != null)
              _row(Icons.tag, 'Transaction ID', fee.transactionId!),
            _row(Icons.event, 'Due Date', _fmtDate(fee.dueDate)),
            if (fee.paidDate != null)
              _row(Icons.event_available, 'Paid Date', _fmtDate(fee.paidDate!)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _LeaveFullCard extends StatelessWidget {
  final LeaveModel leave;
  const _LeaveFullCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final color = leave.isApproved ? Colors.green : leave.isRejected ? Colors.red : Colors.orange;
    final colorScheme = Theme.of(context).colorScheme;

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
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_typeIcon(leave.leaveType), size: 22, color: colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(leave.leaveType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${leave.totalDays} day(s) · ${_fmtDate(leave.fromDate)} → ${_fmtDate(leave.toDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(leave.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(leave.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              if (leave.adminRemarks != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: leave.isApproved ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (leave.isApproved ? Colors.green : Colors.red).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings, size: 16, color: leave.isApproved ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(leave.adminRemarks!, style: TextStyle(fontSize: 12, color: leave.isApproved ? Colors.green : Colors.red))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = leave.isApproved ? Colors.green : leave.isRejected ? Colors.red : Colors.orange;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Leave Details', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _row(Icons.event_note, 'Type', leave.leaveType.replaceAll('_', ' ').toUpperCase()),
            _row(Icons.calendar_today, 'From', _fmtDate(leave.fromDate)),
            _row(Icons.calendar_today, 'To', _fmtDate(leave.toDate)),
            _row(Icons.timelapse, 'Duration', '${leave.totalDays} day(s)'),
            _row(Icons.circle, 'Status', leave.status.toUpperCase()),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: Text('Reason:', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(leave.reason, style: const TextStyle(fontSize: 14))),
            if (leave.adminRemarks != null) ...[
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: Text('Admin Remarks:', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerLeft, child: Text(leave.adminRemarks!, style: TextStyle(fontSize: 14, color: color))),
            ],
            const SizedBox(height: 20),
            Row(children: [
              if (leave.isPending)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<FirestoreService>().deleteLeave(leave.id);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ),
              if (leave.isPending) const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'home_visit': return Icons.home;
      case 'medical': return Icons.local_hospital;
      case 'emergency': return Icons.warning;
      case 'personal': return Icons.person;
      default: return Icons.event_note;
    }
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
}
