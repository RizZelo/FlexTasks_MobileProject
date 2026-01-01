import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import 'client_profile_page.dart';
import 'task_detail_page.dart';
import 'users_list_page.dart';
import 'my_applications_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Tutoring',
    'Gardening',
    'Petcare',
    'Cleaning',
    'Babysitting',
    'Moving',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Icon(Icons.work_outline),
            SizedBox(width: 8),
            Text('Find Tasks'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.assignment_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApplicationsPage()),
              );
            },
            tooltip: 'My Applications',
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
          preferredSize: Size.fromHeight(140),
          child: Column(
            children: [
              // Welcome Message
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Find the perfect task for you',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
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
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          // Category Filter
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: Colors.teal[100],
                    checkmarkColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.teal : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          // Section Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _taskService.getAllActiveTasks(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return Text(
                      '$count tasks',
                      style: TextStyle(color: Colors.grey[600]),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // Tasks List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskService.getAllActiveTasks(),
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
                          Icons.work_off_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tasks available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back later for new opportunities',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Filter tasks
                final tasks = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '')
                      .toString()
                      .toLowerCase();
                  final category = data['category'] ?? '';
                  final location = (data['location'] ?? '')
                      .toString()
                      .toLowerCase();

                  // Apply search filter
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      title.contains(_searchQuery) ||
                      description.contains(_searchQuery) ||
                      location.contains(_searchQuery);

                  // Apply category filter
                  final matchesCategory =
                      _selectedCategory == 'All' ||
                      category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tasks match your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String taskId, Map<String, dynamic> task) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnTask = currentUser?.uid == task['clientId'];

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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? 'Untitled Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task['category'] ?? 'Other',
                      style: TextStyle(
                        color: Colors.teal[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Description
              Text(
                task['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 12),
              // Info Row
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    task['location'] ?? 'Not specified',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    task['duration'] ?? 'Flexible',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Budget
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
                  // Posted by
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.teal[100],
                        child: Text(
                          (task['clientName'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal[800],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        task['clientName'] ?? 'Unknown',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  // Applications count
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${task['applicationsCount'] ?? 0}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Own task indicator
              if (isOwnTask)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Your task',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
