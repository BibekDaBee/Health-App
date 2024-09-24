import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'bmi_chart_page.dart'; // Import the chart page

class BMIInputPage extends StatefulWidget {
  const BMIInputPage({super.key});

  @override
  _BMIInputPageState createState() => _BMIInputPageState();
}

class _BMIInputPageState extends State<BMIInputPage> {
  // Store BMI values with corresponding dates
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Your BMI History',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              // Button to navigate to BMI Calculator Page
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BMIChartPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Go to BMI Calculator',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
