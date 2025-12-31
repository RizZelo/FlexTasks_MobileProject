import 'package:flutter/material.dart';
// Removed import of TaskListScreen to avoid circular import with
// `task_list_screen.dart`. We return to the previous screen using
// Navigator.pop after posting instead.

// The main screen where to post a task
class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({Key? key}) : super(key: key);

  @override
  _PostTaskScreenState createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  // Controllers to get text input from TextFields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _additionalReqController =
      TextEditingController();

  // Selected category
  String _selectedCategory = 'Tutoring';

  // Checkboxes
  bool _backgroundCheck = false;
  bool _experience = false;
  bool _references = false;

  // Categories
  final List<String> _categories = [
    'Tutoring',
    'Gardening',
    'Petcare',
    'Cleaning',
    'Babysitting',
    'Moving',
  ];

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
            Text('Flex Tasks'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Text(
                  'Post New Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Post a task and connect with skilled workers',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
            SizedBox(height: 16),
            // Task Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Budget
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Budget',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Duration
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Start Date
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Additional Requirements
            TextField(
              controller: _additionalReqController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Additional Requirements',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Checkboxes
            CheckboxListTile(
              title: Text('Background check required'),
              value: _backgroundCheck,
              onChanged: (val) {
                setState(() {
                  _backgroundCheck = val!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Experience required'),
              value: _experience,
              onChanged: (val) {
                setState(() {
                  _experience = val!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('References needed'),
              value: _references,
              onChanged: (val) {
                setState(() {
                  _references = val!;
                });
              },
            ),
            SizedBox(height: 16),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Save draft logic
                    print('Draft saved');
                  },
                  child: Text('Save Draft'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Post job logic
                    print('Task Posted: ${_titleController.text}');

                    // Return to the previous screen (TaskListScreen) so we avoid
                    // a circular import between the two pages.
                    Navigator.pop(context);
                  },
                  child: Text('Post Job'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
