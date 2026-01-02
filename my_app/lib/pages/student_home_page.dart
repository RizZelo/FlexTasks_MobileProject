import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_page.dart';
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
  final ConnectionService _connectionService = ConnectionService();
  Set<String> _priorityClientIds = {};
  bool _isLoadingConnections = true;
  final ChatService _chatService = ChatService();
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  Timestamp? _lastSeenMessageTime;

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
  void initState() {
    super.initState();
    _loadConnections();
    _startChatListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    try {
      final ids = await _connectionService.getAcceptedConnectionUserIds();
      setState(() {
        _priorityClientIds = ids;
        _isLoadingConnections = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des connexions: $e');
      setState(() {
        _priorityClientIds = {};
        _isLoadingConnections = false;
      });
    }
  }

  void _startChatListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _chatSubscription = _chatService.getChats(currentUser.uid).listen((
      snapshot,
    ) {
      if (!mounted) return;

      // On first snapshot, establish baseline so we don't notify for old messages
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

              // Lazy import to avoid circular dependency in analysis; ChatPage is in pages
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
              // If something goes wrong, we just ignore for now
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
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
          children: const [
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
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApplicationsPage()),
              );
            },
            tooltip: 'My Applications',
          ),
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
            tooltip: 'Logout',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              // Welcome Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Find the perfect task for you',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Tasks', style: theme.textTheme.titleLarge),
                StreamBuilder<QuerySnapshot>(
                  stream: _taskService.getAllActiveTasks(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return Text(
                      '$count tasks',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tasks List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskService.getAllActiveTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                        const SizedBox(height: 16),
                        Text(
                          'No tasks available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
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

                // Prioritize tasks from connected clients
                if (_priorityClientIds.isNotEmpty) {
                  tasks.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final clientA = dataA['clientId'] as String? ?? '';
                    final clientB = dataB['clientId'] as String? ?? '';

                    final isAFromPriority = _priorityClientIds.contains(
                      clientA,
                    );
                    final isBFromPriority = _priorityClientIds.contains(
                      clientB,
                    );

                    if (isAFromPriority == isBFromPriority) {
                      final tsA = dataA['createdAt'];
                      final tsB = dataB['createdAt'];
                      if (tsA is Timestamp && tsB is Timestamp) {
                        return tsB.compareTo(tsA); // newer first
                      }
                      return 0;
                    }

                    return isAFromPriority ? -1 : 1;
                  });
                }

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
                        const SizedBox(height: 16),
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
                  padding: const EdgeInsets.all(16),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnTask = currentUser?.uid == task['clientId'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(16),
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
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task['category'] ?? 'Other',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                task['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              // Info Row
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task['location'] ?? 'Not specified',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task['duration'] ?? 'Flexible',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Budget
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      Text(
                        '${task['budget'] ?? '0'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  // Posted by
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          (task['clientName'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task['clientName'] ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // Applications count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                        const SizedBox(width: 4),
                        Text(
                          '${task['applicationsCount'] ?? 0}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Your task',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange[800],
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
