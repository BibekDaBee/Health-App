import 'package:flutter/material.dart';
import 'package:health/Main%20screens/calorie_screen.dart';
import 'package:health/util/responsive.dart';
import 'package:health/widgets/dashboard_widget.dart';
import 'package:health/widgets/summary_widget.dart';

// Import your screens here
import 'bmi_screen.dart';
import 'sleep_screen.dart';
import 'water_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Default to 'Home'

  // List of screens to display based on selected index
  final List<Widget> _screens = [
    const CalorieDataScreen(),
    const BMIScreen(),
    const DashboardWidget(), // Using DashboardWidget for Home
    const SleepScreen(),
    const WaterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final drawerWidth = isMobile 
        ? MediaQuery.of(context).size.width * 0.8 
        : 250.0;

    return Scaffold(
      endDrawer: isMobile
          ? SizedBox(
              width: drawerWidth,
              child: const SummaryWidget(),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _screens[_selectedIndex], // Display the selected screen
              ),
            ),
          ],
        ),
      ),
    );
  }
}
