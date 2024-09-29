import 'package:flutter/material.dart';
import 'package:health/pages/Calculator/calorie_calulator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class CalorieDataScreen extends StatefulWidget {
  const CalorieDataScreen({super.key});

  @override
  _CalorieDataScreenState createState() => _CalorieDataScreenState();
}

class _CalorieDataScreenState extends State<CalorieDataScreen> {
  List<Map<String, dynamic>> _calorieRecords = [];
  List<FlSpot> _calorieSpots = [];

  @override
  void initState() {
    super.initState();
    _fetchCalorieHistory();
  }

  // Fetch Calorie history from Firestore
  Future<void> _fetchCalorieHistory() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calorieIntakeData')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> fetchedRecords = [];
      List<FlSpot> chartSpots = [];

      for (var i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        var calorie = double.parse(data['value'].toStringAsFixed(2)); // Limit to two decimals
        var date = DateTime.parse(data['date']);

        fetchedRecords.add({
          'calorie': calorie,
          'date': date,
        });

        chartSpots.add(FlSpot(i.toDouble(), calorie)); // Add Calorie data to chart
      }

      setState(() {
        _calorieRecords = fetchedRecords;
        _calorieSpots = chartSpots;
      });
    } catch (e) {
      print('Error fetching calorie history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
        actions: [
          // Button to navigate to Calorie Intake Page
          TextButton(
            onPressed: () async {
              // Navigate to CalorieIntakePage and wait for result
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalorieIntakePage(),
                ),
              );
              // Refresh data after returning from CalorieIntakePage
              if (result == true) {
                _fetchCalorieHistory(); // Refresh the data
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 173, 238, 227),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Add Intake',
              style: TextStyle(color: Colors.white, fontSize: 16),
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
                'Your Calorie Records and Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),

              // Section for displaying the Calorie records
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
                        'Calorie Records',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _calorieRecords.isNotEmpty
                          ? Expanded(
                              child: ListView.builder(
                                itemCount: _calorieRecords.length,
                                itemBuilder: (context, index) {
                                  final record = _calorieRecords[index];
                                  final formattedDate = DateFormat(
                                          'yyyy-MM-dd – kk:mm')
                                      .format(record['date']);
                                  return ListTile(
                                    title: Text(
                                        'Calories: ${record['calorie'].toStringAsFixed(2)} kcal'),
                                    subtitle: Text('Date: $formattedDate'),
                                  );
                                },
                              ),
                            )
                          : const Text('No calorie records found.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section for displaying the Calorie chart
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
                  child: _calorieSpots.isNotEmpty
                      ? LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              show: true,
                              topTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false), // Hide top titles
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false), // Hide right titles
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true), // Keep bottom titles for date
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true), // Keep left titles for Calorie values
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
                                spots: _calorieSpots,
                                isCurved: false, // Smooth lines for more appealing graph
                                barWidth: 5,
                                shadow: const Shadow(
                                  blurRadius: 10,
                                  color: Colors.blueGrey,
                                  offset: Offset(4, 4),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.withOpacity(0.7), // Gradient effect for a more appealing chart
                                    Colors.deepOrangeAccent.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.1), // Shaded area below the line
                                      Colors.deepOrangeAccent.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                dotData: const FlDotData(show: true), // Show dots for a 3D-like effect
                              ),
                            ],
                          ),
                        )
                      : const Center(child: Text('No chart data available.')),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
