import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard_card.dart';
import '../auth/login_screen.dart';
import '../rooms/rooms_screen.dart';
import '../complaints/complaints_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userRole = 'student';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = context.read<AuthService>();
    final role = await auth.getUserRole();
    final data = await auth.getUserData();
    if (mounted) {
      setState(() {
        _userRole = role;
        _userName = data?['name'] ?? auth.currentUser?.displayName ?? '';
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AuthService>().signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Manager'),
        actions: [
          // Role badge
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _userRole == 'admin'
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userRole.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      _userRole == 'admin' ? Colors.amber.shade100 : Colors.white70,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(context),
          const RoomsScreen(),
          const ComplaintsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bed_outlined),
            selectedIcon: Icon(Icons.bed),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()}, ${_userName.isNotEmpty ? _userName.split(' ').first : 'User'} 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Role: ',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _userRole == 'admin'
                      ? Colors.amber.withOpacity(0.15)
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _userRole == 'admin' ? '🛡 Admin' : '🎓 Student',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _userRole == 'admin'
                        ? Colors.amber.shade700
                        : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              DashboardCard(
                title: 'Total Rooms',
                value: '120',
                icon: Icons.bed_rounded,
                color: colorScheme.primary,
              ),
              DashboardCard(
                title: 'Occupied',
                value: '98',
                icon: Icons.people_rounded,
                color: Colors.orange,
              ),
              DashboardCard(
                title: 'Available',
                value: '22',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
              DashboardCard(
                title: 'Complaints',
                value: '5',
                icon: Icons.warning_rounded,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildActivityTile(
            icon: Icons.person_add,
            title: 'New student registered',
            subtitle: 'Rahul Sharma — Room 204',
            time: '2 hours ago',
          ),
          _buildActivityTile(
            icon: Icons.build,
            title: 'Complaint resolved',
            subtitle: 'Plumbing issue — Block A',
            time: '5 hours ago',
          ),
          _buildActivityTile(
            icon: Icons.swap_horiz,
            title: 'Room transfer',
            subtitle: 'Ankit moved to Room 108',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing:
            Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
