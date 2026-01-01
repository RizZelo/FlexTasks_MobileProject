import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewPage extends StatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String revieweeRole;
  final String taskId;
  final String taskTitle;

  const ReviewPage({
    Key? key,
    required this.revieweeId,
    required this.revieweeName,
    required this.revieweeRole,
    required this.taskId,
    required this.taskTitle,
  }) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${widget.revieweeName}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              widget.taskTitle.isEmpty ? 'Task' : widget.taskTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 24),
            Text(
              'Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                  icon: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
            Text(
              'Comment (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Describe their professionalism, communication, and overall experience...',
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting || _rating == 0 ? null : _submitReview,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.check),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reviewService.submitReview(
        revieweeId: widget.revieweeId,
        revieweeName: widget.revieweeName,
        revieweeRole: widget.revieweeRole,
        taskId: widget.taskId,
        taskTitle: widget.taskTitle,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
