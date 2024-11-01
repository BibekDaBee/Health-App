import 'package:flutter/material.dart';
import 'package:health/widgets/activity_details_card.dart';
import 'package:health/widgets/header_widget.dart';
class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            SizedBox(height: 18),
            HeaderWidget(),
            SizedBox(height: 18),
            ActivityDetailsCard(),
            SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
