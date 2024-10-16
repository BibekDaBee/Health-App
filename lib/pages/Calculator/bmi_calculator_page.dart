import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  _BMICalculatorPageState createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _bmiResult = '';
  String _bmiCategory = '';
  Color _bmiCategoryColor = Colors.black;
  String _selectedGender = 'Male'; // Default gender selection

  // Variables to store selected date and time
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Function to select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to select time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Calculate BMI and classify it based on the selected gender
  void _calculateBMI() async {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0 && weight > 0) {
      final double bmi = weight / (height * height);

      // Classify BMI
      _classifyBMI(bmi);

      setState(() {
        _bmiResult = 'Your BMI is: ${bmi.toStringAsFixed(2)}';
      });

      // Show a dialog to save the data
      _showSaveDialog(bmi);
    } else {
      setState(() {
        _bmiResult = 'Please enter valid height and weight';
        _bmiCategory = '';
      });
    }
  }

  // Save BMI data to Firestore after user confirmation
  Future<void> _saveBMIData(double bmi) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Combine the selected date and time into a DateTime object
      final DateTime dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .add({
        'value': bmi,
        'gender': _selectedGender,
        'date': dateTime.toIso8601String(),
      });
    } catch (e) {
      print('Error saving BMI data: $e');
    }
  }

  // Classify BMI based on standard categories
  void _classifyBMI(double bmi) {
    final bmiCategories = {
      'Underweight': {'range': [0.0, 18.5], 'color': Colors.blue},
      'Normal weight': {'range': [18.5, 24.9], 'color': Colors.green},
      'Overweight': {'range': [25.0, 29.9], 'color': Colors.orange},
      'Obese': {'range': [30.0, double.infinity], 'color': Colors.red},
    };

    for (var category in bmiCategories.entries) {
      final range = category.value['range'] as List<double>;
      if (bmi >= range[0] && bmi < range[1]) {
        _bmiCategory = category.key;
        _bmiCategoryColor = category.value['color'] as Color;
        break;
      }
    }
  }

  // Show a dialog asking whether the user wants to save the BMI data
  Future<void> _showSaveDialog(double bmi) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must confirm
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save BMI Data'),
          content: const Text('Do you want to save your BMI data?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without saving
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                await _saveBMIData(bmi);
                Navigator.of(context).pop(); // Close dialog after saving
                Navigator.pop(context, true);  // Notify BMIChartAndHistoryPage to refresh
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Calculate Your BMI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),

            // Gender selection (Radio Buttons)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Gender:'),
                const SizedBox(width: 10),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Male',
                      groupValue: _selectedGender,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const Text('Male'),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Female',
                      groupValue: _selectedGender,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const Text('Female'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input field for height
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Height in meters (e.g., 1.75)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Input field for weight
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight in kilograms (e.g., 70)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Date and Time Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  onPressed: () => _selectDate(context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedTime.format(context)),
                  onPressed: () => _selectTime(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Button to calculate BMI
            ElevatedButton(
              onPressed: _calculateBMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Calculate BMI',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display the BMI result
            Text(
              _bmiResult,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 20),

            // Display the BMI category with specific colors
            Text(
              _bmiCategory.isNotEmpty
                  ? 'Category: $_bmiCategory'
                  : '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _bmiCategoryColor,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
