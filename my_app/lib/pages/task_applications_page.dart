import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/application_service.dart';
import '../services/task_service.dart';
import 'chat_page.dart';
import 'client_profile_page.dart';

class TaskApplicationsPage extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskApplicationsPage({
    Key? key,
    required this.taskId,
    required this.taskTitle,
  }) : super(key: key);

  @override
  _TaskApplicationsPageState createState() => _TaskApplicationsPageState();
}

class _TaskApplicationsPageState extends State<TaskApplicationsPage>
    with SingleTickerProviderStateMixin {
  final ApplicationService _applicationService = ApplicationService();
  final TaskService _taskService = TaskService();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Applications'),
        backgroundColor: Colors.teal,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Task Info Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taskTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: _applicationService.getApplicationsForTask(
                    widget.taskId,
                  ),
                  builder: (context, snapshot) {
                    final total = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    final pending = snapshot.hasData
                        ? snapshot.data!.docs
                              .where(
                                (doc) =>
                                    (doc.data()
                                        as Map<String, dynamic>)['status'] ==
                                    'pending',
                              )
                              .length
                        : 0;
                    return Text(
                      '$total applications ($pending pending)',
                      style: TextStyle(color: Colors.white70),
                    );
                  },
                ),
              ],
            ),
          ),
          // Applications List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _applicationService.getApplicationsForTask(widget.taskId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final allApps = snapshot.data?.docs ?? [];
                final pendingApps = allApps
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['status'] ==
                          'pending',
                    )
                    .toList();
                final acceptedApps = allApps
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['status'] ==
                          'accepted',
                    )
                    .toList();
                final rejectedApps = allApps
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['status'] ==
                          'rejected',
                    )
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApplicationsList(pendingApps, 'pending'),
                    _buildApplicationsList(acceptedApps, 'accepted'),
                    _buildApplicationsList(rejectedApps, 'rejected'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(
    List<QueryDocumentSnapshot> applications,
    String status,
  ) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.hourglass_empty
                  : status == 'accepted'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No ${status} applications',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.teal[100],
                  child: Text(
                    (app['applicantName'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        app['applicantEmail'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        app['status']?.toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Budget & Availability
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Expected Budget',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$${app['expectedBudget'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  Column(
                    children: [
                      Text(
                        'Availability',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        app['availability'] ?? 'Flexible',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Cover Letter
            Text(
              'Cover Letter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app['coverLetter'] ?? 'No cover letter provided',
                style: TextStyle(color: Colors.grey[800], height: 1.4),
              ),
            ),

            // Experience
            if (app['experience']?.isNotEmpty == true) ...[
              SizedBox(height: 16),
              Text(
                'Experience',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                app['experience'],
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],

            // Skills
            if (app['skills']?.isNotEmpty == true) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (app['skills'] as String).split(',').map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      skill.trim(),
                      style: TextStyle(fontSize: 12, color: Colors.teal[800]),
                    ),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 16),

            // Action Buttons
            if (app['status'] == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              receiverId: app['applicantId'],
                              receiverName: app['applicantName'] ?? 'Unknown',
                              receiverEmail: app['applicantEmail'] ?? '',
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(appId),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAcceptDialog(appId, app),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show contact button for accepted applications
              if (app['status'] == 'accepted')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverId: app['applicantId'],
                            receiverName: app['applicantName'] ?? 'Unknown',
                            receiverEmail: app['applicantEmail'] ?? '',
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.chat_bubble_outline),
                    label: Text('Contact ${app['applicantName']}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAcceptDialog(String appId, Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Accept Application'),
          ],
        ),
        content: Text(
          'Are you sure you want to accept ${app['applicantName']}\'s application?\n\nThey will be notified and you can start working together.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _applicationService.acceptApplication(appId);
              // Optionally mark task as assigned
              await _taskService.updateTask(
                taskId: widget.taskId,
                status: 'assigned',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Application accepted successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String appId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Reject Application'),
          ],
        ),
        content: Text(
          'Are you sure you want to reject this application?\n\nThe applicant will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _applicationService.rejectApplication(appId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Application rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }
}
