import 'package:flutter/material.dart';
import 'package:health/pages/BMI/bmi_input_page.dart'; // Make sure this import is correct

class BMIScreen extends StatelessWidget {
  const BMIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('BMI Screen'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to BMICalculatorPage when button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BMICalculatorPage(),
                ),
              );
            },
            child: const Text('Go to BMI Calculator'),
          ),
        ],
      ),
    );
  }
}
