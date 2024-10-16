import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WaterIntakePage extends StatefulWidget {
  const WaterIntakePage({super.key});

  @override
  _WaterIntakePageState createState() => _WaterIntakePageState();
}

class _WaterIntakePageState extends State<WaterIntakePage> {
  final TextEditingController _waterIntakeController = TextEditingController();
  String _waterIntakeResult = '';
  DateTime? _selectedDate; // For storing the selected date
  TimeOfDay? _selectedTime; // For storing the selected time

  @override
  void dispose() {
    _waterIntakeController.dispose();
    super.dispose();
  }

  // Function to select the date for water intake
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Limit for earliest date
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to select time of water intake
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addWaterIntake() async {
    // Parse the entered value in milliliters
    final double? waterIntakeInMilliliters = double.tryParse(_waterIntakeController.text);

    if (waterIntakeInMilliliters != null && waterIntakeInMilliliters > 0 && _selectedDate != null && _selectedTime != null) {
      // Convert milliliters to liters before saving
      final double waterIntakeInLiters = waterIntakeInMilliliters / 1000;

      setState(() {
        _waterIntakeResult =
            'You have logged: ${waterIntakeInMilliliters.toStringAsFixed(0)} mL of water intake on ${DateFormat('EEEE, MMM d').format(_selectedDate!)} at ${_selectedTime!.format(context)}';
      });

      await _saveWaterIntakeData(waterIntakeInLiters); // Save water intake in liters to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Water intake saved successfully! Stay hydrated!')),
      );
    } else {
      setState(() {
        _waterIntakeResult = 'Please enter a valid number and select a date and time for water intake';
      });
    }
  }

  Future<void> _saveWaterIntakeData(double waterIntakeInLiters) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Combine the selected date and time into a single DateTime object
      DateTime intakeDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('waterIntakeData')
          .add({
        'value': waterIntakeInLiters,  // Save the intake in liters
        'date': intakeDateTime.toIso8601String(),  // Save the date and time as a single DateTime string
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
            
            // Input field for water intake in milliliters
            TextField(
              controller: _waterIntakeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Water intake in milliliters (e.g., 250)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Date picker for selecting the day of intake
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Select Date of Intake'
                    : 'Selected Date: ${DateFormat('EEEE, MMM d').format(_selectedDate!)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Time picker for selecting water intake time
            ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                _selectedTime == null
                    ? 'Select Time of Intake'
                    : 'Selected Time: ${_selectedTime!.format(context)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
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
