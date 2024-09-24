import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class BMIChartPage extends StatefulWidget {
  const BMIChartPage({super.key});

  @override
  _BMIChartPageState createState() => _BMIChartPageState();
}

class _BMIChartPageState extends State<BMIChartPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  String _bmiResult = '';
  List<Map<String, dynamic>> _bmiRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchBMIHistory(); // Fetch stored BMI history on initialization
  }

  // Method to fetch BMI history from Firestore
  Future<void> _fetchBMIHistory() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .orderBy('date', descending: true)
          .get();

      // Populate _bmiRecords with the fetched data
      List<Map<String, dynamic>> fetchedRecords = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'bmi': data['value'],
          'date': DateTime.parse(data['date']),
        };
      }).toList();

      setState(() {
        _bmiRecords = fetchedRecords;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching BMI history: $e');
      }
    }
  }

  // Method to calculate BMI and store it with a timestamp
  void _calculateBMI() async {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final double bmi = weight / (height * height);

      setState(() {
        _bmiResult = 'Your BMI is: ${bmi.toStringAsFixed(2)}';
      });

      _showSaveDialog(bmi); // Show save dialog
    } else {
      setState(() {
        _bmiResult = 'Please enter valid numbers for height and weight';
      });
    }
  }

  // Method to show dialog to save BMI
  void _showSaveDialog(double bmi) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save BMI'),
          content: Text('Your BMI is ${bmi.toStringAsFixed(2)}. Do you want to save this data?'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                saveBMIData(FirebaseAuth.instance.currentUser!.uid, bmi, DateTime.now().toIso8601String());
                Navigator.of(context).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('BMI saved successfully!')),
                );
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to save BMI data to Firestore
  Future<void> saveBMIData(String userId, double bmi, String date) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .add({
        'date': date,
        'value': bmi,
      });

      setState(() {
        _bmiRecords.insert(0, {
          'bmi': bmi,
          'date': DateTime.parse(date),
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving BMI data: $e');
      }
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
              const SizedBox(height: 20),
              const Text(
                'Your BMI History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 10),
              // Show BMI history
              if (_bmiRecords.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _bmiRecords.length,
                    itemBuilder: (context, index) {
                      final bmiEntry = _bmiRecords[index];
                      final formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                          .format(bmiEntry['date']);

                      return ListTile(
                        title:
                            Text('BMI: ${bmiEntry['bmi'].toStringAsFixed(2)}'),
                        subtitle: Text('Date: $formattedDate'),
                      );
                    },
                  ),
                )
              else
                const Text('No BMI records found.'),
            ],
          ),
        ),
      ),
    );
  }
}
