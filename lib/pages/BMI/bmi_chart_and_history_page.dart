import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'bmi_calculator_page.dart';
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
        var bmi = data['value'];
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BMICalculatorPage()),
              );
            },
            icon: const Icon(Icons.calculate),
            tooltip: 'Go to BMI Calculator',
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
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: true),
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
                                isCurved: false, // Straight line
                                barWidth: 3,
                                color: Colors.blue,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        )
                      : const Center(child: Text('No chart data available.')),
                ),
              ),

              const SizedBox(height: 20),

              // Section for BMI motivational message
              if (_bmiRecords.isNotEmpty)
                Text(
                  'Your BMI is ${_bmiRecords.first['bmi'].toStringAsFixed(2)}. Keep it up!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
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
