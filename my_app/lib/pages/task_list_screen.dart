import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_task_screen.dart';
import 'users_list_page.dart';
import 'student_home_page.dart';
import 'task_detail_page.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline),
            SizedBox(width: 8),
            Text('My Tasks'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentHomePage()),
              );
            },
            tooltip: 'Browse Tasks',
          ),
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
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Search functionality
                    });
                  },
                ),
              ),
              // Tabs
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
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
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          // My Posted Tasks Header with Add Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Posted Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostTaskScreen()),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // Task List with Tabs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskService.getMyTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tasks posted yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Add Task" to post your first task',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final allTasks = snapshot.data!.docs;
                final activeTasks = allTasks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'active';
                }).toList();
                final completedTasks = allTasks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'completed';
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Tasks Tab
                    _buildTaskList(activeTasks),
                    // Completed Tasks Tab
                    _buildTaskList(completedTasks),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<QueryDocumentSnapshot> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
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
  }

  Widget _buildTaskCard(String taskId, Map<String, dynamic> task) {
    bool isCompleted = task['status'] == 'completed';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(taskId: taskId),
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
                      task['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'Active',
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 6),
                  Text(
                    task['category'] ?? 'Other',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(width: 20),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 6),
                  Text(
                    task['location'] ?? 'Not specified',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 20, color: Colors.teal),
                      Text(
                        '${task['budget'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.message_outlined, color: Colors.teal),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UsersListPage(),
                            ),
                          );
                        },
                        tooltip: 'Contact about task',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () {
                          // TODO: Implement edit task
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edit feature coming soon')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          _showDeleteDialog(
                            taskId,
                            task['title'] ?? 'this task',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String taskId, String taskTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _taskService.deleteTask(taskId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
