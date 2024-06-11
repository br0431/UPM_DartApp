import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ThirdScreen extends StatefulWidget {
  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _moodRating = 0;
  bool _isSubmitting = false;
  bool _showTick = false;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'Comments',
          style: TextStyle(color: Colors.deepOrange),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Comment'),
            ),
            SizedBox(height: 16.0),
            Text('Mood Rating:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (int i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _moodRating = i;
                      });
                    },
                    child: Text(
                      _getMoodEmoji(i),
                      style: TextStyle(
                        fontSize: 24.0,
                        color: _moodRating == i ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _canSubmitFeedback() ? _submitFeedback : null,
              child: _isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : _showTick
                  ? Icon(Icons.check, color: Colors.deepOrange)
                  : Text('Submit Feedback'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepOrange,
              ),
            ),
            SizedBox(height: 16.0),
            // StreamBuilder y otros widgets para mostrar comentarios...
          ],
        ),
      ),
    );
  }

  bool _canSubmitFeedback() {
    return !_isSubmitting && _commentController.text.isNotEmpty && _moodRating > 0;
  }

  void _submitFeedback() async {
    User? user = _auth.currentUser;
    String comment = _commentController.text;
    if (!_canSubmitFeedback()) {
      Fluttertoast.showToast(
        msg: "Please fill all fields.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showTick = false;
    });

    try {
      DatabaseReference feedbackRef = FirebaseDatabase.instance.reference().child('feedback');
      await feedbackRef.push().set({
        'uid': user?.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'comment': comment,
        'moodRating': _moodRating,
      });

      Fluttertoast.showToast(
        msg: "Feedback submitted successfully.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      _commentController.clear();
      setState(() {
        _moodRating = 0;
      });

      // Esperar 3 segundos
      await Future.delayed(Duration(seconds: 3));

      setState(() {
        _showTick = true;
      });

      // Esperar 2 segundos
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isSubmitting = false;
        _showTick = false;
      });
    } catch (error) {
      print("Failed to submit feedback: $error");
      Fluttertoast.showToast(
        msg: "Failed to submit feedback.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _getMoodEmoji(int moodRating) {
    switch (moodRating) {
      case 1:
        return '😢';
      case 2:
        return '😞';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '';
    }
  }
}
