import 'package:flutter/material.dart';
import 'package:health/Main%20screens/bmi_screen.dart';
import 'package:health/Main%20screens/calorie_screen.dart';
import 'package:health/Main%20screens/sleep_screen.dart';
import 'package:health/Main%20screens/water_screen.dart';
import 'package:health/util/responsive.dart';
import 'package:health/widgets/bottom_nav_bar_widget.dart';
import 'package:health/widgets/dashboard_widget.dart';
import 'package:health/widgets/summary_widget.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Default to 'Home'

  // List of screens to display based on selected index
  final List<Widget> _screens = [
    const CalorieDataScreen(), // Index 0
    const BMIScreen(),         // Index 1
    const DashboardWidget(),   // Index 2 - Default Home Page
    const SleepScreen(),       // Index 3
    const WaterScreen(),       // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: BottomNavBarWidget(
        onItemSelected: _onItemTapped, // Handle navigation
        currentIndex: _selectedIndex,   // Pass current index
      ),
    );
  }
}
