import 'package:flutter/material.dart';
import 'package:health/pages/BMI/bmi_input_page.dart'; // Correct import for BMIInputPage

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
              // Navigate to BMIInputPage instead of BMICalculatorPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BMIInputPage(), // Navigate to BMIInputPage
                ),
              );
            },
            child: const Text('Go to BMI History and Calculator'),
          ),
        ],
      ),
    );
  }
}
