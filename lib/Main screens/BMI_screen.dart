import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/pages/Calculator/bmi_calculator_page.dart';

class BMIChartAndHistoryPage extends StatefulWidget {
  const BMIChartAndHistoryPage({super.key});

  @override
  _BMIChartAndHistoryPageState createState() => _BMIChartAndHistoryPageState();
}

class _BMIChartAndHistoryPageState extends State<BMIChartAndHistoryPage> {
  List<Map<String, dynamic>> _bmiRecords = [];
  List<FlSpot> _bmiSpots = [];

  @override
  void initState() {
    super.initState();
    _fetchBMIHistory();
  }

  // Fetch BMI history from Firestore
  Future<void> _fetchBMIHistory() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> fetchedRecords = [];
      List<FlSpot> chartSpots = [];

      for (var i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        var bmi = double.parse(data['value'].toStringAsFixed(2)); // Limit to two decimals
        var date = DateTime.parse(data['date']);

        fetchedRecords.add({
          'bmi': bmi,
          'date': date,
        });

        chartSpots.add(FlSpot(i.toDouble(), bmi)); // Add BMI data to chart
      }

      setState(() {
        _bmiRecords = fetchedRecords;
        _bmiSpots = chartSpots;
      });
    } catch (e) {
      print('Error fetching BMI history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BMICalculatorPage()),
              );
              if (result == true) {
                _fetchBMIHistory(); // Refresh data when returning
              }
            },
            child: const Text(
              'Calculator',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 173, 238, 227),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your BMI Records and Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),

              // Section for displaying the BMI records
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'BMI Records',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _bmiRecords.isNotEmpty
                          ? Expanded(
                              child: ListView.builder(
                                itemCount: _bmiRecords.length,
                                itemBuilder: (context, index) {
                                  final record = _bmiRecords[index];
                                  final formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                                      .format(record['date']);
                                  return ListTile(
                                    title: Text('BMI: ${record['bmi'].toStringAsFixed(2)}'),
                                    subtitle: Text('Date: $formattedDate'),
                                  );
                                },
                              ),
                            )
                          : const Text('No BMI records found.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section for displaying the BMI chart
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 235, 248, 255),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _bmiSpots.isNotEmpty
                      ? LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false), // Hide top titles
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false), // Hide right titles
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),  // Keep bottom titles for date
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),  // Keep left titles for BMI values
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                bottom: BorderSide(color: Colors.black),
                                left: BorderSide(color: Colors.black),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _bmiSpots,
                                isCurved: false, // Smooth lines for more appealing graph
                                barWidth: 5,
                                shadow: const Shadow(
                                  blurRadius: 10,
                                  color: Colors.blueGrey,
                                  offset: Offset(4, 4),
                                ),
                                gradient: LinearGradient(
                                  colors:[
                                  Colors.blue.withOpacity(0.7), // Gradient effect for a more appealing chart
                                  Colors.lightBlueAccent.withOpacity(0.3),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors:[
                                    Colors.blue.withOpacity(0.1),  // Shaded area below the line
                                    Colors.lightBlueAccent.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  ),
                                ),
                                dotData: FlDotData(show: true),  // Show dots for a 3D-like effect
                              ),
                            ],
                          ),
                        )
                      : const Center(child: Text('No chart data available.')),
                ),
              ),

              const SizedBox(height: 20),

              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
