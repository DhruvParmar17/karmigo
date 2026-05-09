import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RatingScreen extends StatefulWidget {
  final String jobId;
  const RatingScreen({super.key, required this.jobId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rating = prefs.getInt('rating_${widget.jobId}') ?? 0;
      _reviewController.text = prefs.getString('review_${widget.jobId}') ?? '';
      if (_rating > 0) _isSubmitted = true;
    });
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a star rating")));
      return;
    }
    
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rating_${widget.jobId}', _rating);
    await prefs.setString('review_${widget.jobId}', _reviewController.text);

    setState(() => _isSubmitted = true);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rate Service")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("How was your experience?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: _isSubmitted ? null : () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: "Write a review (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isSubmitted,
            ),
            const Spacer(),
            if (!_isSubmitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text("Submit Rating"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
