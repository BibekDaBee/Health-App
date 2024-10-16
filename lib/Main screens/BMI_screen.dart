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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBMIHistory();
  }

  // Fetch BMI history from Firestore with pagination and caching
  Future<void> _fetchBMIHistory({bool forceUpdate = false}) async {
    if (_bmiRecords.isNotEmpty && !forceUpdate) return; // Use cache if available and no force update

    setState(() {
      _isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .orderBy('date', descending: true)
          .limit(10) // Limit records for pagination
          .get();

      List<Map<String, dynamic>> fetchedRecords = [];
      List<FlSpot> chartSpots = [];

      for (var i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        var bmi = double.parse(data['value'].toStringAsFixed(2)); // Limit to two decimals
        var date = DateTime.parse(data['date']);

        fetchedRecords.add({
          'id': doc.id, // Store the document ID for deletion
          'bmi': bmi,
          'date': date,
        });

        chartSpots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), bmi)); // Use timestamp for x-axis
      }

      setState(() {
        _bmiRecords = fetchedRecords;
        _bmiSpots = chartSpots;
      });
    } catch (e) {
      print('Error fetching BMI history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete a BMI record from Firestore
  Future<void> _deleteRecord(String recordId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .doc(recordId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted successfully!')),
      );
      _fetchBMIHistory(forceUpdate: true); // Refresh data after deletion
    } catch (e) {
      print('Error deleting BMI record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete the record')),
      );
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
                _fetchBMIHistory(forceUpdate: true); // Refresh data when returning
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 173, 238, 227),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Calculator',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : SafeArea(
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
                                        return Dismissible(
                                          key: Key(record['id']),
                                          onDismissed: (direction) {
                                            _deleteRecord(record['id']); // Swipe-to-delete
                                          },
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: const Icon(Icons.delete, color: Colors.white),
                                          ),
                                          child: ListTile(
                                            leading: const Icon(Icons.fitness_center, color: Colors.blue),
                                            title: Text('BMI: ${record['bmi'].toStringAsFixed(2)}'),
                                            subtitle: Text('Date: $formattedDate'),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Text('No BMI records found. Start tracking your BMI!'),
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
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) {
                                          final DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                          return Text(DateFormat('MM-dd').format(date));
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
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
                                      isCurved: false,
                                      barWidth: 5,
                                      shadow: const Shadow(
                                        blurRadius: 10,
                                        color: Colors.blueGrey,
                                        offset: Offset(4, 4),
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.withOpacity(0.7),
                                          Colors.lightBlueAccent.withOpacity(0.3),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.1),
                                            Colors.lightBlueAccent.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: const FlDotData(show: true), // Show dots for emphasis
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
