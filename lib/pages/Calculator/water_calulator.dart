import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterIntakePage extends StatefulWidget {
  const WaterIntakePage({super.key});

  @override
  _WaterIntakePageState createState() => _WaterIntakePageState();
}

class _WaterIntakePageState extends State<WaterIntakePage> {
  final TextEditingController _waterIntakeController = TextEditingController();
  String _waterIntakeResult = '';

  @override
  void dispose() {
    _waterIntakeController.dispose();
    super.dispose();
  }

  void _addWaterIntake() async {
    final double? waterIntake = double.tryParse(_waterIntakeController.text);

    if (waterIntake != null && waterIntake > 0) {
      setState(() {
        _waterIntakeResult = 'You have logged: ${waterIntake.toStringAsFixed(2)} L of water intake';
      });

      await _saveWaterIntakeData(waterIntake); // Save water intake data to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Water intake saved successfully! Stay hydrated!')),
      );
    } else {
      setState(() {
        _waterIntakeResult = 'Please enter a valid number for water intake';
      });
    }
  }

  Future<void> _saveWaterIntakeData(double waterIntake) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('waterIntakeData')
          .add({
        'value': waterIntake,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving water intake data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Your Water Intake',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            
            // Input field for water intake
            TextField(
              controller: _waterIntakeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Water intake in liters (e.g., 2.5)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Button to add water intake
            ElevatedButton(
              onPressed: _addWaterIntake,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Log Water Intake',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Display the water intake result
            Text(
              _waterIntakeResult,
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
