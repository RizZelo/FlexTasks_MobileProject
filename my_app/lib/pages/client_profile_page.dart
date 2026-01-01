import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/task_service.dart';
import '../services/review_service.dart';
import 'chat_page.dart';

class ClientProfilePage extends StatefulWidget {
  final String clientId;

  const ClientProfilePage({Key? key, required this.clientId}) : super(key: key);

  @override
  _ClientProfilePageState createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final UserService _userService = UserService();
  final TaskService _taskService = TaskService();
  final ReviewService _reviewService = ReviewService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _userService.getUserById(widget.clientId),
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
              body: Center(child: Text('User not found')),
            );
          }

          final user = snapshot.data!.data() as Map<String, dynamic>;
          final double ratingAverage = (user['ratingAverage'] ?? 0).toDouble();
          final int ratingCount = (user['ratingCount'] ?? 0) as int;

          return CustomScrollView(
            slivers: [
              // Profile Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.teal,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.teal[400]!, Colors.teal[700]!],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          // Profile Avatar
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Text(
                                  (user['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: user['isOnline'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: user['isOnline'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Name
                          Text(
                            user['name'] ?? 'Unknown User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Email
                          Text(
                            user['email'] ?? '',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Online Status
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: user['isOnline'] == true
                                      ? Colors.greenAccent
                                      : Colors.grey[400],
                                ),
                                SizedBox(width: 6),
                                Text(
                                  user['isOnline'] == true
                                      ? 'Online'
                                      : 'Offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                      // Contact Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverId: widget.clientId,
                                receiverName: user['name'] ?? 'Unknown',
                                receiverEmail: user['email'] ?? '',
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.chat_bubble_outline),
                        label: Text('Send Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Stats Section
                      Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: _taskService.getClientTasks(widget.clientId),
                        builder: (context, taskSnapshot) {
                          int totalTasks = 0;
                          int activeTasks = 0;
                          int completedTasks = 0;

                          if (taskSnapshot.hasData) {
                            totalTasks = taskSnapshot.data!.docs.length;
                            for (var doc in taskSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['status'] == 'active') {
                                activeTasks++;
                              } else if (data['status'] == 'completed') {
                                completedTasks++;
                              }
                            }
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.work,
                                  value: '$totalTasks',
                                  label: 'Total Tasks',
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.pending_actions,
                                  value: '$activeTasks',
                                  label: 'Active',
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.check_circle,
                                  value: '$completedTasks',
                                  label: 'Completed',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24),

                      // Ratings & Feedback
                      Text(
                        'Ratings & Feedback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: ratingCount > 0
                              ? Row(
                                  children: [
                                    _buildRatingStars(ratingAverage),
                                    SizedBox(width: 12),
                                    Text(
                                      ratingAverage.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '($ratingCount reviews)',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                )
                              : Text(
                                  'No reviews yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                        ),
                      ),
                      SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: _reviewService.getReviewsForUser(
                          widget.clientId,
                        ),
                        builder: (context, reviewSnapshot) {
                          if (reviewSnapshot.hasError) {
                            return Text('Error loading reviews');
                          }

                          if (reviewSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!reviewSnapshot.hasData ||
                              reviewSnapshot.data!.docs.isEmpty) {
                            return SizedBox.shrink();
                          }

                          final reviews = reviewSnapshot.data!.docs.take(5);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...reviews.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final int rating = (data['rating'] ?? 0) as int;
                                final String comment = data['comment'] ?? '';
                                final String reviewerName =
                                    data['reviewerName'] ?? 'User';

                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              reviewerName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            _buildRatingStars(
                                              rating.toDouble(),
                                            ),
                                          ],
                                        ),
                                        if (comment.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            comment,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24),

                      // Member Info
                      Text(
                        'Member Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.calendar_today,
                              title: 'Member Since',
                              value: _formatDate(user['createdAt']),
                            ),
                            Divider(height: 1),
                            _buildInfoTile(
                              icon: Icons.access_time,
                              title: 'Last Seen',
                              value: _formatDate(user['lastSeen']),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Posted Tasks Section
                      Text(
                        'Posted Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: _taskService.getClientTasks(widget.clientId),
                        builder: (context, taskSnapshot) {
                          if (taskSnapshot.hasError) {
                            return Text('Error loading tasks');
                          }

                          if (taskSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!taskSnapshot.hasData ||
                              taskSnapshot.data!.docs.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.work_off_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No tasks posted yet',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Show only active tasks
                          final activeTasks = taskSnapshot.data!.docs
                              .where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['status'] == 'active';
                              })
                              .take(5)
                              .toList();

                          if (activeTasks.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No active tasks',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: activeTasks.map((doc) {
                              final task = doc.data() as Map<String, dynamic>;
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.work_outline,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  title: Text(
                                    task['title'] ?? 'Untitled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${task['category']} • \$${task['budget']}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return Icon(
          starIndex <= rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }
}
