import 'package:flutter/material.dart' show AppBar, BuildContext, Color, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, FontWeight, InputDecoration, MainAxisAlignment, OutlineInputBorder, Padding, SafeArea, Scaffold, SizedBox, State, StatefulWidget, Text, TextAlign, TextEditingController, TextField, TextInputType, TextStyle, Widget;

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BMICalculatorPageState createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _bmiResult = '';

  // Method to calculate BMI
  void _calculateBMI() {
    // Parse the height and weight values from the text fields
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    // Check if the inputs are valid numbers
    if (height != null && weight != null && height > 0) {
      // Perform the BMI calculation
      final double bmi = weight / (height * height);

      // Update the result string with the calculated BMI
      setState(() {
        _bmiResult = 'Your BMI is: ${bmi.toStringAsFixed(2)}'; // Show result with 2 decimal places
      });
    } else {
      // Show error message if inputs are not valid
      setState(() {
        _bmiResult = 'Please enter valid numbers for height and weight';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),
        ),
      ),
    );
  }
}
