import 'package:flutter/material.dart';
import '../services/application_service.dart';

class ApplicationFormPage extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String clientId;
  final String clientName;

  const ApplicationFormPage({
    Key? key,
    required this.taskId,
    required this.taskTitle,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  _ApplicationFormPageState createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApplicationService _applicationService = ApplicationService();

  final TextEditingController _coverLetterController = TextEditingController();
  final TextEditingController _expectedBudgetController =
      TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    _expectedBudgetController.dispose();
    _availabilityController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _applicationService.submitApplication(
        taskId: widget.taskId,
        taskTitle: widget.taskTitle,
        clientId: widget.clientId,
        clientName: widget.clientName,
        coverLetter: _coverLetterController.text.trim(),
        expectedBudget: _expectedBudgetController.text.trim(),
        availability: _availabilityController.text.trim(),
        experience: _experienceController.text.trim(),
        skills: _skillsController.text.trim(),
        portfolio: _portfolioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Application submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Task'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Applying for:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.taskTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Posted by ${widget.clientName}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Cover Letter *'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _coverLetterController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Introduce yourself and explain why you are the best fit for this task...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please write a cover letter';
                        }
                        if (value.length < 50) {
                          return 'Cover letter should be at least 50 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Expected Budget *'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _expectedBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter your expected payment',
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your expected budget';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Availability *'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _availabilityController,
                      decoration: InputDecoration(
                        hintText:
                            'When are you available? (e.g., Weekdays 9am-5pm)',
                        prefixIcon: Icon(
                          Icons.schedule_outlined,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your availability';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Relevant Experience'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _experienceController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Describe your relevant experience for this task...',
                        prefixIcon: Icon(
                          Icons.work_history_outlined,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Skills'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _skillsController,
                      decoration: InputDecoration(
                        hintText: 'List your relevant skills (comma separated)',
                        prefixIcon: Icon(
                          Icons.star_outline,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Portfolio/References'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _portfolioController,
                      decoration: InputDecoration(
                        hintText: 'Add links to your work or references',
                        prefixIcon: Icon(
                          Icons.link_outlined,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 30),

                    // Tips Card
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[800],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tips for a great application:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '• Be specific about your experience\n'
                                    '• Mention any certifications\n'
                                    '• Be clear about your availability\n'
                                    '• Set a competitive budget',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 13,
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

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Application',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}
