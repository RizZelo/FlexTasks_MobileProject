import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_page.dart';
import 'client_profile_page.dart';
import 'post_task_screen.dart';
import 'task_applications_page.dart';
import 'users_list_page.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({Key? key}) : super(key: key);

  @override
  _ClientDashboardPageState createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final ApplicationService _applicationService = ApplicationService();
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  Timestamp? _lastSeenMessageTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startChatListener();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startChatListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _chatSubscription = _chatService.getChats(currentUser.uid).listen((
      snapshot,
    ) {
      if (!mounted) return;

      if (_lastSeenMessageTime == null) {
        Timestamp? maxTime;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['lastMessageTime'];
          if (ts is Timestamp) {
            if (maxTime == null || ts.compareTo(maxTime) > 0) {
              maxTime = ts;
            }
          }
        }
        _lastSeenMessageTime = maxTime;
        return;
      }

      Timestamp? newMax = _lastSeenMessageTime;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['lastMessageTime'];

        if (ts is! Timestamp) continue;
        if (_lastSeenMessageTime != null &&
            ts.compareTo(_lastSeenMessageTime!) <= 0) {
          continue;
        }

        final lastSenderId = data['lastMessageSenderId'] as String?;
        if (lastSenderId == null || lastSenderId == currentUser.uid) {
          if (newMax == null || ts.compareTo(newMax) > 0) {
            newMax = ts;
          }
          continue;
        }

        final participants = (data['participants'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        String? otherUserId;
        if (participants.length == 2) {
          otherUserId = participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => currentUser.uid,
          );
          if (otherUserId == currentUser.uid) {
            otherUserId = null;
          }
        }

        final participantNames =
            (data['participantNames'] as Map<String, dynamic>?) ?? {};
        String? otherName;
        if (otherUserId != null) {
          otherName = participantNames[otherUserId]?.toString();
        }

        final lastMessage = data['lastMessage']?.toString() ?? '';

        if (otherUserId != null) {
          _showNewMessageSnackBar(
            otherUserId: otherUserId,
            otherName: otherName ?? 'New message',
            preview: lastMessage,
          );
        }

        if (newMax == null || ts.compareTo(newMax) > 0) {
          newMax = ts;
        }
      }

      _lastSeenMessageTime = newMax;
    });
  }

  void _showNewMessageSnackBar({
    required String otherUserId,
    required String otherName,
    required String preview,
  }) {
    if (!mounted) return;

    final theme = Theme.of(context);
    final messageText = preview.isNotEmpty ? preview : 'You have a new message';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'New message from $otherName: $messageText',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onInverseSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            try {
              final userDoc = await UserService().getUserById(otherUserId);
              final data = userDoc.data() as Map<String, dynamic>? ?? {};
              final email = data['email']?.toString() ?? '';

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverId: otherUserId,
                    receiverName: otherName,
                    receiverEmail: email,
                  ),
                ),
              );
            } catch (e) {
              // Ignore errors for now
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person_outline, size: 28),
          onPressed: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClientProfilePage(clientId: currentUser.uid),
                ),
              );
            }
          },
          tooltip: 'My Profile',
        ),
        title: const Text('My Tasks'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersListPage()),
              );
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService().signOut();
            },
            tooltip: 'Logout',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Quick Post Task Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildQuickPostCard(context, colorScheme),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: _taskService.getMyTasks(),
                builder: (context, taskSnapshot) {
                  int totalTasks = 0;
                  int activeTasks = 0;
                  int completedTasks = 0;
                  int inProgressTasks = 0;

                  if (taskSnapshot.hasData) {
                    totalTasks = taskSnapshot.data!.docs.length;
                    for (var doc in taskSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'active';
                      // Count both active and in_progress as "active" tasks
                      if (status == 'active' || status == 'in_progress') activeTasks++;
                      if (status == 'completed') completedTasks++;
                      if (status == 'in_progress') inProgressTasks++;
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _applicationService.getReceivedApplications(),
                    builder: (context, appSnapshot) {
                      int pendingApps = 0;
                      if (appSnapshot.hasData) {
                        pendingApps = appSnapshot.data!.docs
                            .where(
                              (doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['status'] ==
                                  'pending',
                            )
                            .length;
                      }

                      return Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.work_outline_rounded,
                            value: '$totalTasks',
                            label: 'Total',
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            icon: Icons.schedule_rounded,
                            value: '$activeTasks',
                            label: 'Active',
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            icon: Icons.inbox_rounded,
                            value: '$pendingApps',
                            label: 'Pending',
                            color: const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            icon: Icons.check_circle_outline_rounded,
                            value: '$completedTasks',
                            label: 'Done',
                            color: const Color(0xFF22C55E),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tab Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelPadding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Applications'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Content
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksList('active'),
                  _buildApplicationsList(),
                  _buildTasksList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostTaskScreen()),
            );
          },
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Post Task'),
        ),
      ),
    );
  }

  Widget _buildQuickPostCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_task_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need help with something?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Post a task and get skilled students to help',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostTaskScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create New Task',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick category buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickCategoryChip('🎓 Tutoring', colorScheme),
                const SizedBox(width: 8),
                _buildQuickCategoryChip('🧹 Cleaning', colorScheme),
                const SizedBox(width: 8),
                _buildQuickCategoryChip('🐾 Petcare', colorScheme),
                const SizedBox(width: 8),
                _buildQuickCategoryChip('🌱 Gardening', colorScheme),
                const SizedBox(width: 8),
                _buildQuickCategoryChip('📦 Moving', colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategoryChip(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(String status) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _taskService.getMyTasks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final taskStatus = data['status'] ?? 'active';
          
          // For 'active' tab, show both 'active' and 'in_progress' tasks
          if (status == 'active') {
            return taskStatus == 'active' || taskStatus == 'in_progress';
          }
          return taskStatus == status;
        }).toList() ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    status == 'active'
                        ? Icons.work_off_outlined
                        : Icons.check_circle_outline,
                    size: 48,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  status == 'active' ? 'No active tasks' : 'No completed tasks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (status == 'active') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a new task',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final taskDoc = tasks[index];
            final task = taskDoc.data() as Map<String, dynamic>;
            return _buildTaskCard(taskDoc.id, task);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(String taskId, Map<String, dynamic> task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskStatus = task['status'] ?? 'active';
    final applicationsCount = task['applicationsCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskApplicationsPage(
                  taskId: taskId,
                  taskTitle: task['title'] ?? 'Task',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] ?? 'Untitled',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    _buildTaskStatusBadge(taskStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(Icons.category_outlined, task['category'] ?? 'Other'),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.location_on_outlined, task['location'] ?? 'Not set'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '\$',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${task['budget'] ?? '0'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: applicationsCount > 0
                            ? const Color(0xFF3B82F6).withOpacity(0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 18,
                            color: applicationsCount > 0
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$applicationsCount',
                            style: TextStyle(
                              color: applicationsCount > 0
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Show assigned student for in_progress or completed tasks
                if (task['selectedApplicantName'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Assigned to ${task['selectedApplicantName']}',
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Mark as Completed button for in_progress tasks
                if (taskStatus == 'in_progress') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markTaskAsCompleted(taskId, task),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'Mark as Completed',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                if (applicationsCount > 0 && (taskStatus == 'active' || taskStatus == 'in_progress')) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tap to view applications',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _applicationService.getReceivedApplications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data?.docs ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'No applications received',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Post tasks to receive applications from students',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final appDoc = applications[index];
            final app = appDoc.data() as Map<String, dynamic>;
            return _buildApplicationCard(appDoc.id, app);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(String appId, Map<String, dynamic> app) {
    Color statusColor;
    IconData statusIcon;

    switch (app['status']) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    app['taskTitle'] ?? 'Unknown Task',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        app['status']?.toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal[100],
                  child: Text(
                    (app['applicantName'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['applicantName'] ?? 'Unknown',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        app['applicantEmail'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${app['expectedBudget'] ?? '0'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (app['status'] == 'pending') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _applicationService.rejectApplication(appId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Application rejected'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _applicationService.acceptApplication(appId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Application accepted! Task is now in progress.'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error accepting application: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                          print('Error accepting application: $e');
                        }
                      },
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markTaskAsCompleted(String taskId, Map<String, dynamic> task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Task as Completed'),
        content: Text(
          'Are you sure you want to mark "${task['title']}" as completed?\n\n'
          'This action confirms that ${task['selectedApplicantName'] ?? 'the student'} '
          'has successfully completed the work.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _taskService.markTaskAsCompleted(taskId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('🎉 Task marked as completed!'),
              ],
            ),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTaskStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'completed':
        bgColor = const Color(0xFF22C55E).withOpacity(0.1);
        textColor = const Color(0xFF22C55E);
        icon = Icons.check_circle_rounded;
        label = 'Completed';
        break;
      case 'in_progress':
        bgColor = const Color(0xFF3B82F6).withOpacity(0.1);
        textColor = const Color(0xFF3B82F6);
        icon = Icons.pending_actions_rounded;
        label = 'In Progress';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFEF4444).withOpacity(0.1);
        textColor = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
        label = 'Cancelled';
        break;
      default: // active
        bgColor = const Color(0xFF22C55E).withOpacity(0.1);
        textColor = const Color(0xFF22C55E);
        icon = Icons.circle;
        label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 8,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
