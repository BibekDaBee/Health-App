import 'package:health/model/health_model.dart';

class HealthDetails {
  final healthData = const [
    HealthModel(
        icon: 'assets/icons/burn.png', value: "305", title: "Calories INtake"),
    HealthModel(
        icon: 'assets/icons/water.png', value: "600 ml", title: "Water"),
    HealthModel(
        icon: 'assets/icons/distance.png', value: "22.1", title: "BMI"),
    HealthModel(icon: 'assets/icons/sleep.png', value: "7h48m", title: "Sleep"),
  ];
}
