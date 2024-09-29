import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieIntakePage extends StatefulWidget {
  const CalorieIntakePage({super.key});

  @override
  _CalorieIntakePageState createState() => _CalorieIntakePageState();
}

class _CalorieIntakePageState extends State<CalorieIntakePage> {
  final TextEditingController _calorieIntakeController = TextEditingController();
  String _calorieIntakeResult = '';

  @override
  void dispose() {
    _calorieIntakeController.dispose();
    super.dispose();
  }

  void _addCalorieIntake() async {
    final double? calorieIntake = double.tryParse(_calorieIntakeController.text);

    if (calorieIntake != null && calorieIntake > 0) {
      setState(() {
        _calorieIntakeResult = 'You have logged: ${calorieIntake.toStringAsFixed(2)} calories';
      });

      await _saveCalorieIntakeData(calorieIntake); // Save calorie intake data to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calorie intake saved successfully!')),
      );

      // Return true to indicate success and go back to the previous screen
      Navigator.pop(context, true);
    } else {
      setState(() {
        _calorieIntakeResult = 'Please enter a valid number for calorie intake';
      });
    }
  }

  Future<void> _saveCalorieIntakeData(double calorieIntake) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calorieIntakeData')
          .add({
        'value': calorieIntake,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving calorie intake data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Intake Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Your Calorie Intake',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            
            // Input field for calorie intake
            TextField(
              controller: _calorieIntakeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calorie intake (e.g., 500)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Button to add calorie intake
            ElevatedButton(
              onPressed: _addCalorieIntake,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Log Calorie Intake',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Display the calorie intake result
            Text(
              _calorieIntakeResult,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
