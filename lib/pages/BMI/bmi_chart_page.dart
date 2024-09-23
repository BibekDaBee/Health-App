import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BMIChartPage extends StatelessWidget {
  final List<Map<String, dynamic>> bmiRecords;

  const BMIChartPage({super.key, required this.bmiRecords});

  @override
  Widget build(BuildContext context) {
    // Determine the range of Y-axis (BMI values)
    final double minBMI = bmiRecords
        .map((record) => record['bmi'] as double)
        .reduce((a, b) => a < b ? a : b);
    final double maxBMI = bmiRecords
        .map((record) => record['bmi'] as double)
        .reduce((a, b) => a > b ? a : b);

    // Add padding to the Y-axis to keep data in the center
    final double yAxisPadding = (maxBMI - minBMI) * 0.5;
    
    // Ensure there's always space below the data, and prevent minY from being too low
    final double adjustedMinY = (minBMI - yAxisPadding).clamp(minBMI * 0.8, minBMI);
    final double adjustedMaxY = maxBMI + yAxisPadding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Chart'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bmiRecords.isEmpty
            ? const Center(
                child: Text(
                  'No BMI data available.',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1, // Show every data point on the X-axis
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < bmiRecords.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${bmiRecords[index]['date'].day}/${bmiRecords[index]['date'].month}',
                                style: const TextStyle(
                                  fontSize: 9, // Reduced font size for X-axis
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 40, // Ensure Y-axis labels have enough space
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 9, // Reduced font size for Y-axis
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide right-side labels
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide top labels
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: bmiRecords
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value['bmi'],
                              ))
                          .toList(),
                      barWidth: 4,
                      color: Colors.deepPurple,
                    ),
                  ],
                  minX: 0,
                  maxX: bmiRecords.length.toDouble() - 1,
                  // Adjust minY and maxY to center the data in the chart and avoid attaching to X-axis
                  minY: adjustedMinY,
                  maxY: adjustedMaxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: const LineTouchTooltipData(
                      tooltipPadding: EdgeInsets.all(8), // Add padding around tooltips
                      tooltipRoundedRadius: 8, // Customize tooltip's rounded corners
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      // Handle touch event logic
                    },
                    handleBuiltInTouches: true, // Enable built-in touch interactions
                  ),
                ),
              ),
      ),
    );
  }
}
