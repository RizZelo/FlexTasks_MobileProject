import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/application_service.dart';
import '../services/connection_service.dart';
import 'chat_page.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({Key? key}) : super(key: key);

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ApplicationService _applicationService = ApplicationService();
  final ConnectionService _connectionService = ConnectionService();
  Set<String> _allowedUserIds = {};
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadWorkedWithUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkedWithUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final role = await _userService.getCurrentUserRole();

      if (currentUser == null || role == null) {
        setState(() {
          _allowedUserIds = {};
          _isLoadingContacts = false;
        });
        return;
      }

      Set<String> ids = {};

      if (role == 'client') {
        final snapshot = await _applicationService
            .getReceivedApplications()
            .first;
        ids = snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'accepted';
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['applicantId'] ?? '') as String;
            })
            .where((id) => id.isNotEmpty)
            .toSet();
      } else if (role == 'student') {
        final snapshot = await _applicationService.getMyApplications().first;
        ids = snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'accepted';
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['clientId'] ?? '') as String;
            })
            .where((id) => id.isNotEmpty)
            .toSet();
      }

      // Add accepted connections to contacts
      final connectedIds = await _connectionService
          .getAcceptedConnectionUserIds();
      ids.addAll(connectedIds);

      setState(() {
        _allowedUserIds = ids;
        _isLoadingContacts = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des contacts: $e');
      setState(() {
        _allowedUserIds = {};
        _isLoadingContacts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          title: const Text('Messages'),
          elevation: 0,
          bottom: TabBar(
            indicatorColor: colorScheme.onPrimary,
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Contacts'),
              Tab(text: 'All users'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Tab views
            Expanded(
              child: _isLoadingContacts
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [_buildContactsList(), _buildAllUsersList()],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userService.getUsers(),
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
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No contacts found',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userId = (data['uid'] ?? '').toString();

          if (!_allowedUserIds.contains(userId)) return false;

          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty ||
              name.contains(_searchQuery) ||
              email.contains(_searchQuery);
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isEmpty
                  ? 'You have no contacts yet.'
                  : 'No contacts match your search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = userData['uid'] ?? '';
            final userName = userData['name'] ?? 'Unknown User';
            final userEmail = userData['email'] ?? '';
            final isOnline = userData['isOnline'] ?? false;

            return _buildContactTile(
              userId: userId,
              userName: userName,
              userEmail: userEmail,
              isOnline: isOnline,
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userService.getUsers(),
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
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();

          return _searchQuery.isEmpty ||
              name.contains(_searchQuery) ||
              email.contains(_searchQuery);
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users match your search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = userData['uid'] ?? '';
            final userName = userData['name'] ?? 'Unknown User';
            final userEmail = userData['email'] ?? '';
            final isOnline = userData['isOnline'] ?? false;

            final isContact = _allowedUserIds.contains(userId);

            if (isContact) {
              return _buildContactTile(
                userId: userId,
                userName: userName,
                userEmail: userEmail,
                isOnline: isOnline,
              );
            }

            return _buildUserSearchTile(
              userId: userId,
              userName: userName,
              userEmail: userEmail,
              isOnline: isOnline,
            );
          },
        );
      },
    );
  }

  Widget _buildContactTile({
    required String userId,
    required String userName,
    required String userEmail,
    required bool isOnline,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(userName, style: theme.textTheme.titleMedium),
        subtitle: Text(
          userEmail,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverId: userId,
                receiverName: userName,
                receiverEmail: userEmail,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserSearchTile({
    required String userId,
    required String userName,
    required String userEmail,
    required bool isOnline,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(userName, style: theme.textTheme.titleMedium),
        subtitle: Text(
          userEmail,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: () async {
            try {
              await _connectionService.connectWithUser(userId);
              setState(() {
                _allowedUserIds = {..._allowedUserIds, userId};
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connected successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error connecting: $e')));
            }
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Connect'),
        ),
      ),
    );
  }
}
