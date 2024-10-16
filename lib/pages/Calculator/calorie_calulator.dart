import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/data/calorie_data.dart';
import 'package:intl/intl.dart'; // Assuming your food data is here

class CalorieIntakePage extends StatefulWidget {
  const CalorieIntakePage({super.key});

  @override
  _CalorieIntakePageState createState() => _CalorieIntakePageState();
}

class _CalorieIntakePageState extends State<CalorieIntakePage> {
  String? _selectedCategory; // Stores the selected category
  String? _selectedFood; // Stores the selected food item
  String _calorieIntakeResult = ''; // Result message for displaying calorie intake
  String _searchQuery = ''; // Search query input from the user

  DateTime? selectedDate; // To store the selected date
  TimeOfDay? selectedTime; // To store the selected time

  @override
  void dispose() {
    super.dispose();
  }

  // Method to handle adding calorie intake
  void _addCalorieIntake() async {
    if (_selectedFood != null && selectedDate != null && selectedTime != null) {
      final double? calorieIntake = foodDataFromCSV[_selectedCategory]![_selectedFood];

      if (calorieIntake != null) {
        // Combine the selected date and time into a DateTime object
        DateTime fullDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );

        setState(() {
          _calorieIntakeResult =
              'You have logged: ${calorieIntake.toStringAsFixed(2)} calories from $_selectedFood on ${fullDateTime.toString()}';
        });

        await _saveCalorieIntakeData(calorieIntake, fullDateTime); // Save to Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calorie intake saved successfully!')),
        );

        // Return true to indicate success and go back to the previous screen
        Navigator.pop(context, true);
      } else {
        setState(() {
          _calorieIntakeResult = 'Please select a valid food item.';
        });
      }
    } else {
      setState(() {
        _calorieIntakeResult = 'Please select a food item, date, and time.';
      });
    }
  }

  // Save the selected food, calorie intake, and timestamp to Firestore
  Future<void> _saveCalorieIntakeData(double calorieIntake, DateTime dateTime) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calorieIntakeData')
          .add({
        'value': calorieIntake,
        'food': _selectedFood,
        'date': dateTime.toIso8601String(),
      });
    } catch (e) {
      print('Error saving calorie intake data: $e');
    }
  }

  // Show a date picker to select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Show a time picker to select a time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // Method to filter food items based on the search query
  List<String> _filterFoodItems(String query, List<String> foodItems) {
    if (query.isEmpty) {
      return foodItems;
    } else {
      return foodItems
          .where((food) => food.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the food items for the selected category
    List<String> foodItems = _selectedCategory != null
        ? foodDataFromCSV[_selectedCategory]!.keys.toList()
        : [];

    // Filter food items based on the search query
    List<String> filteredFoodItems = _filterFoodItems(_searchQuery, foodItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Intake Tracker'),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Your Calorie Intake',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown for selecting a category
            DropdownButton<String>(
              hint: const Text('Select a food category'),
              value: _selectedCategory,
              items: foodDataFromCSV.keys.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _selectedFood = null; // Reset the selected food when category changes
                });
              },
            ),
            const SizedBox(height: 20),

            // Search bar for filtering food items
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search food items',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value; // Update the search query
                });
              },
            ),
            const SizedBox(height: 20),

            // Dropdown for selecting a food item (filtered by category and search)
            DropdownButton<String>(
              hint: const Text('Select a food item'),
              value: _selectedFood,
              items: filteredFoodItems.map((String food) {
                return DropdownMenuItem<String>(
                  value: food,
                  child: Text(
                      '$food (${foodDataFromCSV[_selectedCategory]![food]!.toStringAsFixed(2)} kcal)'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFood = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            // Date picker button
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                selectedDate != null
                    ? 'Selected date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'
                    : 'Select Date',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Time picker button
            ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                selectedTime != null
                    ? 'Selected time: ${selectedTime!.format(context)}'
                    : 'Select Time',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Button to add calorie intake
            ElevatedButton(
              onPressed: _addCalorieIntake,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 238, 227),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Log Calorie Intake',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display the calorie intake result
            Text(
              _calorieIntakeResult,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
