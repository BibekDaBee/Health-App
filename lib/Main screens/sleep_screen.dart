// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/pages/Calculator/sleep_calculator.dart';
import 'package:intl/intl.dart';

class SleepTrackerApp extends StatelessWidget {
  const SleepTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SleepTrackerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SleepTrackerHomePage extends StatefulWidget {
  const SleepTrackerHomePage({super.key});

  @override
  _SleepTrackerHomePageState createState() => _SleepTrackerHomePageState();
}

class _SleepTrackerHomePageState extends State<SleepTrackerHomePage> {
  final TextEditingController _sleptAtController = TextEditingController();
  final TextEditingController _wokeUpController = TextEditingController();
  final CollectionReference _sleepDataCollection =
      FirebaseFirestore.instance.collection('sleep_data');

  DateTime? sleptAt;
  DateTime? wokeUpAt;
  int currentWeekOffset = 0;

  @override
  void dispose() {
    _sleptAtController.dispose();
    _wokeUpController.dispose();
    super.dispose();
  }

  void _addSleepData() async {
    if (sleptAt != null && wokeUpAt != null) {
      // Correcting the calculation for overnight sleep
      if (wokeUpAt!.isBefore(sleptAt!)) {
        wokeUpAt = wokeUpAt!.add(const Duration(days: 1));
      }
      
      Duration sleepDuration = wokeUpAt!.difference(sleptAt!);
      double sleptHours = sleepDuration.inHours + (sleepDuration.inMinutes % 60) / 60;

      // Save to Firestore
      await _saveSleepData(sleptHours);

      // Display feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep data saved successfully!')),
      );

      // Clear input fields
      _sleptAtController.clear();
      _wokeUpController.clear();

      // Update the screen state
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid sleep and wake times')),
      );
    }
  }

  Future<void> _saveSleepData(double sleptHours) async {
    try {
      String userId = "YOUR_USER_ID"; // Replace with actual user ID retrieval method
      await _sleepDataCollection.doc(userId).collection('user_sleep_data').add({
        'date': DateTime.now().toIso8601String(),
        'slept_at': sleptAt!.toIso8601String(),
        'woke_up_at': wokeUpAt!.toIso8601String(),
        'slept_hours': sleptHours,
      });
    } catch (e) {
      print('Error saving sleep data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      currentWeekOffset += offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              EnterSleepDataWidget(
                sleptAtController: _sleptAtController,
                wokeUpController: _wokeUpController,
                onSave: _addSleepData,
                onSleptAtSelected: (DateTime selectedDateTime) {
                  sleptAt = selectedDateTime;
                },
                onWokeUpSelected: (DateTime selectedDateTime) {
                  wokeUpAt = selectedDateTime;
                },
              ),
              const SizedBox(height: 20),
              SleepHistoryWidget(sleepDataCollection: _sleepDataCollection, userId: "YOUR_USER_ID"),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => _changeWeek(-1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _changeWeek(1),
                        ),
                      ],
                    ),
                    SleepChart(
                      sleepDataCollection: _sleepDataCollection,
                      userId: "YOUR_USER_ID",
                      weekOffset: currentWeekOffset,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnterSleepDataWidget extends StatelessWidget {
  final TextEditingController sleptAtController;
  final TextEditingController wokeUpController;
  final VoidCallback onSave;
  final Function(DateTime) onSleptAtSelected;
  final Function(DateTime) onWokeUpSelected;

  const EnterSleepDataWidget({
    super.key,
    required this.sleptAtController,
    required this.wokeUpController,
    required this.onSave,
    required this.onSleptAtSelected,
    required this.onWokeUpSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Sleep Data', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          SleepTimeInputField(
            label: 'Slept At:',
            controller: sleptAtController,
            onDateTimeSelected: onSleptAtSelected,
          ),
          const SizedBox(height: 10),
          SleepTimeInputField(
            label: 'Woke Up At:',
            controller: wokeUpController,
            onDateTimeSelected: onWokeUpSelected,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onSave,
            child: const Text('Add Sleep Data'),
          ),
        ],
      ),
    );
  }
}

class SleepHistoryWidget extends StatelessWidget {
  final CollectionReference sleepDataCollection;
  final String userId;

  const SleepHistoryWidget({super.key, required this.sleepDataCollection, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sleep History', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: sleepDataCollection
                .doc(userId)
                .collection('user_sleep_data')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];
                    double sleptHours = (data['slept_hours'] is String
                        ? double.tryParse(data['slept_hours'])
                        : data['slept_hours']) ??
                        0.0;
                    return Dismissible(
                      key: Key(data.id),
                      onDismissed: (direction) async {
                        // Delete the document from Firestore
                        await sleepDataCollection
                            .doc(userId)
                            .collection('user_sleep_data')
                            .doc(data.id)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sleep data deleted successfully!')),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: SleepHistoryItem(
                        date: data['slept_at'],
                        hours: "${sleptHours.toStringAsFixed(2)} hours",
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return const Text('Error loading data');
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ],
      ),
    );
  }
}

class SleepChart extends StatelessWidget {
  final CollectionReference sleepDataCollection;
  final String userId;
  final int weekOffset;

  const SleepChart({super.key, required this.sleepDataCollection, required this.userId, required this.weekOffset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: sleepDataCollection
            .doc(userId)
            .collection('user_sleep_data')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          List<BarChartGroupData> barGroups = List.generate(7, (index) => BarChartGroupData(x: index, barRods: [BarChartRodData(toY: 0, color: Colors.blue, width: 15, borderRadius: BorderRadius.circular(5))]));
          int weekIndex = 0;
          DateTime now = DateTime.now().add(Duration(days: weekOffset * 7));
          DateTime monday = now.subtract(Duration(days: now.weekday - 1));
          String weekRange = "${DateFormat('dd MMM').format(monday)} - ${DateFormat('dd MMM').format(monday.add(const Duration(days: 6)))}";

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var doc in snapshot.data!.docs) {
              DateTime date = DateTime.parse(doc['slept_at']);
              DateTime startOfWeek = monday;
              DateTime endOfWeek = monday.add(const Duration(days: 6));

              if (date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
                int dayIndex = date.weekday - 1;

                // Safely parse 'slept_hours' as a double
                double hours = 0;
                if (doc['slept_hours'] is String) {
                  hours = double.tryParse(doc['slept_hours']) ?? 0;
                } else if (doc['slept_hours'] is double) {
                  hours = doc['slept_hours'];
                }

                barGroups[dayIndex] = BarChartGroupData(
                  x: dayIndex,
                  barRods: [
                    BarChartRodData(
                      toY: hours,
                      color: Colors.blue,
                      width: 15,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                );
              }
            }
          }

          return Column(
            children: [
              Text('Week Range: $weekRange', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 1.5,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 12,
                    barGroups: barGroups,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '${value.toInt()} hrs',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                daysOfWeek[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}