import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/model/health_model.dart';



class HealthDetails {
  List<HealthModel> healthData = [
    HealthModel(icon: 'assets/icons/burn.png', value: "Loading...", title: "Calories Intake"),
    HealthModel(icon: 'assets/icons/water.png', value: "Loading...", title: "Water"),
    HealthModel(icon: 'assets/icons/distance.png', value: "Loading...", title: "BMI"),
    HealthModel(icon: 'assets/icons/sleep.png', value: "Loading...", title: "Sleep"),
  ];

  Future<void> fetchLatestHealthData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the latest calorie intake data
      var calorieSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calorieIntakeData')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (calorieSnapshot.docs.isNotEmpty) {
        healthData[0] = HealthModel(
          icon: 'assets/icons/burn.png',
          value: calorieSnapshot.docs.first['value'].toString() + " kcal",
          title: "Calories Intake",
        );
      }

      // Fetch the latest water intake data
      var waterSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('waterIntakeData')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (waterSnapshot.docs.isNotEmpty) {
        healthData[1] = HealthModel(
          icon: 'assets/icons/water.png',
          value: waterSnapshot.docs.first['value'].toString() + " liters",
          title: "Water",
        );
      }

      // Fetch the latest BMI data
      var bmiSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bmiData')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (bmiSnapshot.docs.isNotEmpty) {
        healthData[2] = HealthModel(
          icon: 'assets/icons/distance.png',
          value: bmiSnapshot.docs.first['value'].toString(),
          title: "BMI",
        );
      }

      // Fetch the latest sleep data from the correct path
      var sleepSnapshot = await FirebaseFirestore.instance
          .collection('sleepDataCollection')  // Collection name
          .doc(userId)
          .collection('user_sleep_data')  // Subcollection name
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      // Add debug statement
      print("Sleep data snapshot: ${sleepSnapshot.docs}");

      if (sleepSnapshot.docs.isNotEmpty) {
        double sleepHours = sleepSnapshot.docs.first['slept_hours'];
        print("Fetched sleep hours: $sleepHours");  // Debug print

        healthData[3] = HealthModel(
          icon: 'assets/icons/sleep.png',
          value: "${sleepHours.toStringAsFixed(1)} h",
          title: "Sleep",
        );
      } else {
        print("No sleep data available");
      }
    } catch (e) {
      print('Error fetching health data: $e');
    }
  }
}