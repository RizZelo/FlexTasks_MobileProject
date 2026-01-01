import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.account_circle),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard),
            SizedBox(width: 8),
            Text('Client Dashboard'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersListPage()),
              );
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
            tooltip: 'Logout',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.white,
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Applications'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats Row
          Padding(
            padding: EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskService.getMyTasks(),
              builder: (context, taskSnapshot) {
                int totalTasks = 0;
                int activeTasks = 0;
                int completedTasks = 0;

                if (taskSnapshot.hasData) {
                  totalTasks = taskSnapshot.data!.docs.length;
                  for (var doc in taskSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['status'] == 'active') activeTasks++;
                    if (data['status'] == 'completed') completedTasks++;
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
                          icon: Icons.work,
                          value: '$totalTasks',
                          label: 'Total',
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        _buildStatCard(
                          icon: Icons.pending_actions,
                          value: '$activeTasks',
                          label: 'Active',
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        _buildStatCard(
                          icon: Icons.mail,
                          value: '$pendingApps',
                          label: 'Pending',
                          color: Colors.purple,
                        ),
                        SizedBox(width: 8),
                        _buildStatCard(
                          icon: Icons.check_circle,
                          value: '$completedTasks',
                          label: 'Done',
                          color: Colors.green,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Tasks Tab
                _buildTasksList('active'),
                // Applications Tab
                _buildApplicationsList(),
                // Completed Tasks Tab
                _buildTasksList('completed'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostTaskScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: Icon(Icons.add),
        label: Text('Post Task'),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _taskService.getMyTasks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final tasks =
            snapshot.data?.docs
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['status'] == status,
                )
                .toList() ??
            [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'active'
                      ? Icons.work_off_outlined
                      : Icons.check_circle_outline,
                  size: 60,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16),
                Text(
                  status == 'active' ? 'No active tasks' : 'No completed tasks',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                if (status == 'active') ...[
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create a new task',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
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
    final isActive = task['status'] == 'active';
    final applicationsCount = task['applicationsCount'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Completed',
                      style: TextStyle(
                        color: isActive ? Colors.green[800] : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    task['category'] ?? 'Other',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    task['location'] ?? 'Not set',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 18, color: Colors.teal),
                      Text(
                        '${task['budget'] ?? '0'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: applicationsCount > 0
                          ? Colors.blue[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: applicationsCount > 0
                              ? Colors.blue[700]
                              : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$applicationsCount applications',
                          style: TextStyle(
                            color: applicationsCount > 0
                                ? Colors.blue[700]
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: applicationsCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (applicationsCount > 0 && isActive) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: Colors.orange[800],
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap to view and manage applications',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
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
                        await _applicationService.acceptApplication(appId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Application accepted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
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
}
