import 'package:flutter/material.dart';
import 'package:health/widgets/activity_details_card.dart';
import 'package:health/widgets/header_widget.dart';
import 'package:health/widgets/line_chart_card.dart';
class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 18),
            const HeaderWidget(),
            const SizedBox(height: 18),
            const ActivityDetailsCard(),
            const SizedBox(height: 18),
            const LineChartCard(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
