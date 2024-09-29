import 'package:flutter/material.dart';
import 'package:health/pages/Calculator/water_calulator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  _WaterScreenState createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  List<FlSpot> _waterSpots = [];
  final List<String> _timeLabels = []; // Store time labels for x-axis

  // Function to transform Firestore snapshot data into chart spots
  List<FlSpot> _generateChartSpots(QuerySnapshot snapshot) {
    List<FlSpot> chartSpots = [];
    _timeLabels.clear(); // Clear existing labels for the x-axis

    for (var i = 0; i < snapshot.docs.length; i++) {
      var doc = snapshot.docs[i];
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      var intake = data['value'];
      var date = DateTime.parse(data['date']);
      
      // Add a human-readable time label for the x-axis
      _timeLabels.add(DateFormat('HH:mm').format(date));

      // Create a FlSpot for each record
      chartSpots.add(FlSpot(i.toDouble(), intake));
    }

    return chartSpots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WaterIntakePage()),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Go to Water Intake Log',
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
                'Your Water Intake Records and Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),

              // StreamBuilder to listen to Firestore data in real-time
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('waterIntakeData')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong.');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No water intake records found.');
                    }

                    // Generating chart spots and data from Firestore snapshot
                    final records = snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      var intake = data['value'];
                      var date = DateTime.parse(data['date']);
                      return {
                        'intake': intake,
                        'date': date,
                      };
                    }).toList();

                    _waterSpots = _generateChartSpots(snapshot.data!);

                    return Column(
                      children: [
                        // Display Water Intake Records
                        Expanded(
                          child: ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              final formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                                  .format(record['date']);
                              return ListTile(
                                title: Text(
                                    'Water Intake: ${record['intake'].toStringAsFixed(2)} L'),
                                subtitle: Text('Date: $formattedDate'),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Display Water Intake Chart
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
                            child: _waterSpots.isNotEmpty
                                ? LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Colors.grey.withOpacity(0.3),
                                            strokeWidth: 1,
                                          );
                                        },
                                        getDrawingVerticalLine: (value) {
                                          return FlLine(
                                            color: Colors.grey.withOpacity(0.3),
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              // Show x-axis time labels
                                              if (value.toInt() < _timeLabels.length) {
                                                return Text(_timeLabels[value.toInt()],
                                                    style: const TextStyle(
                                                        color: Colors.black, fontSize: 12));
                                              }
                                              return const Text('');
                                            },
                                            interval: 1,
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false, // Hide the y-axis labels
                                          ),
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
                                          spots: _waterSpots,
                                          isCurved: true, // Smooth curve
                                          barWidth: 3,
                                          color: Colors.blueAccent,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blueAccent.withOpacity(0.3),
                                                Colors.blueAccent.withOpacity(0), // Fades to transparent
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          dotData: const FlDotData(show: true),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Center(child: Text('No chart data available.')),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Section for Water Intake motivational message
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('waterIntakeData')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final record = snapshot.data!.docs.first;
                    double intake = (record.data() as Map<String, dynamic>)['value'];
                    return Text(
                      'You have logged ${intake.toStringAsFixed(2)} L of water intake today. Keep it up!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
