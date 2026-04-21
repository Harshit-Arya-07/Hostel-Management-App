import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Screen to view, submit, and manage complaints.
class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      body: StreamBuilder<List<ComplaintModel>>(
        stream: firestoreService.streamAllComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No complaints yet!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything is running smoothly 🎉',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          // Group by status
          final pending =
              complaints.where((c) => c.status == 'pending').toList();
          final inProgress =
              complaints.where((c) => c.status == 'in_progress').toList();
          final resolved =
              complaints.where((c) => c.status == 'resolved').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // ── Tab bar ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
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
                const SizedBox(height: 8),

                // ── Tab views ──
                Expanded(
                  child: TabBarView(
                    children: [
                      _ComplaintList(complaints: pending),
                      _ComplaintList(complaints: inProgress),
                      _ComplaintList(complaints: resolved),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddComplaintSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Add Complaint Bottom Sheet
  // ─────────────────────────────────────────────
  void _showAddComplaintSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'other';

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
                      'Report a Complaint',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Category
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'plumbing', child: Text('🔧 Plumbing')),
                        DropdownMenuItem(
                            value: 'electrical', child: Text('⚡ Electrical')),
                        DropdownMenuItem(
                            value: 'furniture', child: Text('🪑 Furniture')),
                        DropdownMenuItem(
                            value: 'cleanliness',
                            child: Text('🧹 Cleanliness')),
                        DropdownMenuItem(
                            value: 'other', child: Text('📋 Other')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => category = v ?? 'other'),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final auth = context.read<AuthService>();
                          final complaint = ComplaintModel(
                            id: '',
                            studentId: auth.currentUser?.uid ?? '',
                            studentName:
                                auth.currentUser?.displayName ?? 'Unknown',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            category: category,
                            status: 'pending',
                            createdAt: DateTime.now(),
                          );

                          await context
                              .read<FirestoreService>()
                              .addComplaint(complaint);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Complaint submitted successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Submit Complaint'),
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
//  Complaint List
// ─────────────────────────────────────────────
class _ComplaintList extends StatelessWidget {
  final List<ComplaintModel> complaints;

  const _ComplaintList({required this.complaints});

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) {
      return Center(
        child: Text(
          'No complaints in this category',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        return _ComplaintCard(complaint: complaints[index]);
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Complaint Card
// ─────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintCard({required this.complaint});

  IconData _categoryIcon(String cat) {
    switch (cat) {
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(complaint.status);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showComplaintActions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(complaint.category),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${complaint.studentName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(complaint.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(complaint.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplaintActions(BuildContext context) {
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
                complaint.title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (complaint.status != 'resolved') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newStatus = complaint.status == 'pending'
                          ? 'in_progress'
                          : 'resolved';
                      await context
                          .read<FirestoreService>()
                          .updateComplaintStatus(complaint.id, newStatus);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: Icon(complaint.status == 'pending'
                        ? Icons.play_arrow
                        : Icons.check),
                    label: Text(complaint.status == 'pending'
                        ? 'Mark In Progress'
                        : 'Mark Resolved'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
