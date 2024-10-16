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

class _WaterScreenState extends State<WaterScreen> with SingleTickerProviderStateMixin {
  List<BarChartGroupData> _waterBars = [];
  final List<String> _dayLabels = []; // Store day labels for x-axis (e.g., Sunday, Monday)
  late TabController _tabController; // Tab controller for switching between tabs

  final double _dailyGoal = 2000; // Example goal of 2000 mL or 2 liters of water per day
  double _totalIntakeToday = 0; // Track total water intake for today
  DateTime _selectedWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs: Logs and Goal
    _fetchTotalIntakeToday(); // Fetch the total intake for today
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch total water intake for today from Firestore
  Future<void> _fetchTotalIntakeToday() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day); // Start of today's date
      DateTime endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59)); // End of today's date

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('waterIntakeData')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      double totalIntake = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double intakeInLiters = data['value'];
        totalIntake += intakeInLiters * 1000; // Convert liters to milliliters
      }

      setState(() {
        _totalIntakeToday = totalIntake;
      });
    } catch (e) {
      print('Error fetching today\'s total intake: $e');
    }
  }

  // Function to transform Firestore snapshot data into bar chart data by day of the week
  List<BarChartGroupData> _generateBarChartData(QuerySnapshot snapshot) {
    List<BarChartGroupData> barData = [];
    _dayLabels.clear(); // Clear existing day labels for the x-axis

    // Create a map to store total water intake for each day of the week
    Map<int, double> intakeByDay = {
      for (int i = 1; i <= 7; i++) i: 0.0 // Initialize with zero for each day of the week
    };

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      var intakeInLiters = data['value'];
      var intakeInMilliliters = intakeInLiters * 1000; // Convert liters to milliliters
      var date = DateTime.parse(data['date']);

      // Extract the weekday (Sunday=0, Monday=1, etc.)
      int weekday = date.weekday;
      String dayName = DateFormat('EEEE').format(date); // Get the day name (e.g., Sunday)

      // Store the day labels for the x-axis (in order)
      if (!_dayLabels.contains(dayName)) {
        _dayLabels.add(dayName);
      }

      // Sum water intake by day of the week
      intakeByDay[weekday] = (intakeByDay[weekday] ?? 0) + intakeInMilliliters;
    }

    // Generate BarChartGroupData for each day of the week (x: day index, y: intake)
    intakeByDay.forEach((weekday, totalIntake) {
      barData.add(
        BarChartGroupData(
          x: weekday,
          barRods: [
            BarChartRodData(toY: totalIntake, color: Colors.blueAccent)
          ],
        ),
      );
    });

    return barData;
  }

  // Function to delete a water intake record from Firestore
  Future<void> _deleteRecord(String documentId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('waterIntakeData')
          .doc(documentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted successfully!')),
      );
      // Recalculate today's intake after deletion
      _fetchTotalIntakeToday();
    } catch (e) {
      print('Error deleting record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete the record')),
      );
    }
  }

  void _changeWeek(bool isNext) {
    setState(() {
      _selectedWeekStart = isNext
          ? _selectedWeekStart.add(const Duration(days: 7))
          : _selectedWeekStart.subtract(const Duration(days: 7));
    });
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Water Logs'),
            Tab(text: 'Daily Goal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // First tab: Water Intake Logs
          _buildWaterLogsTab(),

          // Second tab: Water Intake Goal
          _buildGoalTab(),
        ],
      ),
    );
  }

  // Function to build the Water Logs tab
  Widget _buildWaterLogsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Water Intake Records by Day of the Week',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),

            // Week navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _changeWeek(false),
                ),
                Text(
                  'Week of ${DateFormat('MMM dd').format(_selectedWeekStart)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _changeWeek(true),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // StreamBuilder to listen to Firestore data in real-time
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('waterIntakeData')
                    .where('date',
                        isGreaterThanOrEqualTo: _selectedWeekStart.toIso8601String(),
                        isLessThanOrEqualTo: _selectedWeekStart
                            .add(const Duration(days: 6))
                            .toIso8601String())
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

                  // Generating bar chart data from Firestore snapshot
                  _waterBars = _generateBarChartData(snapshot.data!);

                  return Column(
                    children: [
                      // Display Water Intake Records with swipe to delete option
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var document = snapshot.data!.docs[index];
                            Map<String, dynamic> record = document.data() as Map<String, dynamic>;
                            var intakeInMilliliters = (record['value'] as double) * 1000;
                            var date = DateTime.parse(record['date']);
                            String formattedDate = DateFormat('EEEE, yyyy-MM-dd').format(date);

                            return Dismissible(
                              key: Key(document.id),
                              onDismissed: (direction) {
                                _deleteRecord(document.id); // Delete the record on swipe
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: ListTile(
                                title: Text(
                                    'Water Intake: ${intakeInMilliliters.toStringAsFixed(0)} mL'),
                                subtitle: Text('Date: $formattedDate'),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Display Water Intake Bar Chart by Day
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
                          child: _waterBars.isNotEmpty
                              ? BarChart(
                                  BarChartData(
                                    barGroups: _waterBars,
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            int index = value.toInt();
                                            if (index >= 1 && index <= 7) {
                                              return Text(
                                                DateFormat('E').format(
                                                    _selectedWeekStart.add(Duration(days: index - 1))),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                          interval: 1,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true, // Show y-axis labels for milliliters
                                          interval: 500,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${value.toInt()} mL',
                                              style: const TextStyle(
                                                  color: Colors.black, fontSize: 12),
                                            );
                                          },
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
          ],
        ),
      ),
    );
  }

  // Function to build the Daily Goal tab
  Widget _buildGoalTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Daily Water Intake Goal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            // Display the daily goal and progress
            Text(
              'Daily Goal: ${_dailyGoal.toStringAsFixed(0)} mL',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Total Intake Today: ${_totalIntakeToday.toStringAsFixed(0)} mL',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _totalIntakeToday / _dailyGoal, // Progress towards the daily goal
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            // Show a motivational message based on goal completion
            Text(
              _totalIntakeToday >= _dailyGoal
                  ? 'Great job! You have reached your daily goal!'
                  : 'Keep going! You are ${(_dailyGoal - _totalIntakeToday).toStringAsFixed(0)} mL away from your goal.',
              style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeComparison on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year &&
           month == other.month &&
           day == other.day;
  }
}