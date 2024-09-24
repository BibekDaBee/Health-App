import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Calculate BMI and classify it based on the selected gender
  void _calculateBMI() async {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final double bmi = weight / (height * height);

      // Classify BMI based on the selected gender
      _classifyBMI(bmi);

      setState(() {
        _bmiResult = 'Your BMI is: ${bmi.toStringAsFixed(2)}';
      });

      // After calculating, ask the user if they want to save the data
      _showSaveDialog(bmi);
    } else {
      setState(() {
        _bmiResult = 'Please enter valid numbers for height and weight';
        _bmiCategory = '';
      });
    }
  }

  // Save BMI data to Firestore after user confirmation
  Future<void> _saveBMIData(double bmi) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .add({
        'value': bmi,
        'gender': _selectedGender,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving BMI data: $e');
    }
  }

  // Classify BMI based on standard categories
  void _classifyBMI(double bmi) {
    if (bmi < 18.5) {
      _bmiCategory = 'Underweight';
      _bmiCategoryColor = Colors.blue;
    } else if (bmi >= 18.5 && bmi < 24.9) {
      _bmiCategory = 'Normal weight';
      _bmiCategoryColor = Colors.green;
    } else if (bmi >= 25 && bmi < 29.9) {
      _bmiCategory = 'Overweight';
      _bmiCategoryColor = Colors.orange;
    } else {
      _bmiCategory = 'Obese';
      _bmiCategoryColor = Colors.red;
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
              keyboardType: TextInputType.number,
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

            // Additional health tips
            if (_bmiCategory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _getBMIMotivationText(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Method to provide health tips based on BMI category
  String _getBMIMotivationText() {
    switch (_bmiCategory) {
      case 'Underweight':
        return 'You are underweight. It\'s important to maintain a healthy diet and consult a nutritionist if needed.';
      case 'Normal weight':
        return 'You have a normal weight. Keep up the good work with a balanced diet and regular exercise!';
      case 'Overweight':
        return 'You are overweight. Consider adjusting your diet and increasing physical activity.';
      case 'Obese':
        return 'You are obese. It\'s recommended to consult a healthcare provider for advice on managing your health.';
      default:
        return '';
    }
  }
}
