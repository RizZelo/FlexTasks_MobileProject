import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/application_service.dart';
import 'client_profile_page.dart';
import 'application_form_page.dart';
import 'chat_page.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;

  const TaskDetailPage({Key? key, required this.taskId}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TaskService _taskService = TaskService();
  final ApplicationService _applicationService = ApplicationService();
  bool _hasApplied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final hasApplied = await _applicationService.hasApplied(widget.taskId);
    if (mounted) {
      setState(() {
        _hasApplied = hasApplied;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _taskService.getTaskStream(widget.taskId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: Text('Error')),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(title: Text('Not Found')),
              body: Center(child: Text('Task not found')),
            );
          }

          final task = snapshot.data!.data() as Map<String, dynamic>;
          final isOwnTask = currentUser?.uid == task['clientId'];

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.teal,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    task['title'] ?? 'Task Details',
                    style: TextStyle(fontSize: 16),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.teal[400]!, Colors.teal[700]!],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          Icon(
                            _getCategoryIcon(task['category']),
                            size: 60,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              task['category'] ?? 'Other',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Budget Card
                      Card(
                        color: Colors.teal[50],
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budget',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '\$${task['budget'] ?? '0'}',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green[800],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Description Section
                      _buildSectionTitle('Description'),
                      SizedBox(height: 8),
                      Text(
                        task['description'] ?? 'No description provided',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Details Section
                      _buildSectionTitle('Details'),
                      SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Location',
                        task['location'] ?? 'Not specified',
                      ),
                      _buildDetailRow(
                        Icons.schedule_outlined,
                        'Duration',
                        task['duration'] ?? 'Flexible',
                      ),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Start Date',
                        task['startDate'] ?? 'To be discussed',
                      ),
                      _buildDetailRow(
                        Icons.people_outline,
                        'Applications',
                        '${task['applicationsCount'] ?? 0} applicants',
                      ),
                      SizedBox(height: 20),

                      // Requirements Section
                      if (task['backgroundCheckRequired'] == true ||
                          task['experienceRequired'] == true ||
                          task['referencesNeeded'] == true) ...[
                        _buildSectionTitle('Requirements'),
                        SizedBox(height: 12),
                        if (task['backgroundCheckRequired'] == true)
                          _buildRequirementChip(
                            Icons.verified_user,
                            'Background Check',
                          ),
                        if (task['experienceRequired'] == true)
                          _buildRequirementChip(
                            Icons.work_history,
                            'Experience Required',
                          ),
                        if (task['referencesNeeded'] == true)
                          _buildRequirementChip(
                            Icons.contact_page,
                            'References Needed',
                          ),
                        SizedBox(height: 20),
                      ],

                      // Additional Requirements
                      if (task['additionalRequirements']?.isNotEmpty ==
                          true) ...[
                        _buildSectionTitle('Additional Requirements'),
                        SizedBox(height: 8),
                        Text(
                          task['additionalRequirements'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      // Posted By Section
                      _buildSectionTitle('Posted By'),
                      SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text(
                              (task['clientName'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            task['clientName'] ?? 'Unknown User',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(task['clientEmail'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.person_outline,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClientProfilePage(
                                        clientId: task['clientId'],
                                      ),
                                    ),
                                  );
                                },
                                tooltip: 'View Profile',
                              ),
                              if (!isOwnTask)
                                IconButton(
                                  icon: Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          receiverId: task['clientId'],
                                          receiverName:
                                              task['clientName'] ?? 'Unknown',
                                          receiverEmail:
                                              task['clientEmail'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Message',
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Bottom Button
      bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
        stream: _taskService.getTaskStream(widget.taskId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return SizedBox.shrink();
          }

          final task = snapshot.data!.data() as Map<String, dynamic>;
          final isOwnTask = currentUser?.uid == task['clientId'];

          if (isOwnTask) {
            return SizedBox.shrink();
          }

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _hasApplied
                  ? Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Application Submitted',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplicationFormPage(
                              taskId: widget.taskId,
                              taskTitle: task['title'] ?? '',
                              clientId: task['clientId'] ?? '',
                              clientName: task['clientName'] ?? '',
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {
                            _hasApplied = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text(
                            'Apply for this Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.teal),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementChip(IconData icon, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.orange[800]),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Tutoring':
        return Icons.school;
      case 'Gardening':
        return Icons.yard;
      case 'Petcare':
        return Icons.pets;
      case 'Cleaning':
        return Icons.cleaning_services;
      case 'Babysitting':
        return Icons.child_care;
      case 'Moving':
        return Icons.local_shipping;
      default:
        return Icons.work;
    }
  }
}
