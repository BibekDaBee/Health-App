import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SleepIntakePage extends StatefulWidget {
  const SleepIntakePage({super.key});

  @override
  _SleepIntakePageState createState() => _SleepIntakePageState();
}

class _SleepIntakePageState extends State<SleepIntakePage> {
  final TextEditingController _sleepHoursController = TextEditingController();
  String _sleepResult = '';

  @override
  void dispose() {
    _sleepHoursController.dispose();
    super.dispose();
  }

  void _addSleepHours() async {
    final double? sleepHours = double.tryParse(_sleepHoursController.text);

    if (sleepHours != null && sleepHours > 0) {
      setState(() {
        _sleepResult = 'You have logged: ${sleepHours.toStringAsFixed(2)} hours of sleep';
      });

      await _saveSleepData(sleepHours); // Save sleep data to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep data saved successfully!')),
      );
    } else {
      setState(() {
        _sleepResult = 'Please enter a valid number for sleep hours';
      });
    }
  }

  Future<void> _saveSleepData(double sleepHours) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleepData')
          .add({
        'hours': sleepHours,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving sleep data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Your Sleep Hours',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            
            // Input field for sleep hours
            TextField(
              controller: _sleepHoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sleep hours (e.g., 8.0)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Button to log sleep hours
            ElevatedButton(
              onPressed: _addSleepHours,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Log Sleep Hours',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Display the logged sleep result
            Text(
              _sleepResult,
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
