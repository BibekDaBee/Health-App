
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SleepTrackerApp extends StatelessWidget {
  const SleepTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SleepTrackerHomePage(),
    );
  }
}

class SleepTrackerHomePage extends StatefulWidget {
  const SleepTrackerHomePage({super.key});

  @override
  _SleepTrackerHomePageState createState() => _SleepTrackerHomePageState();
}

class _SleepTrackerHomePageState extends State<SleepTrackerHomePage> {
  final TextEditingController _sleptAtController = TextEditingController();
  final TextEditingController _wokeUpController = TextEditingController();
  final CollectionReference _sleepDataCollection =
  FirebaseFirestore.instance.collection('sleep_data');

  DateTime? sleptAt;
  DateTime? wokeUpAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        centerTitle: true,
        backgroundColor:const Color.fromARGB(255, 173, 238, 227),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            EnterSleepDataWidget(
              sleptAtController: _sleptAtController,
              wokeUpController: _wokeUpController,
              onSave: _saveSleepData,
              onSleptAtSelected: (DateTime selectedDateTime) {
                sleptAt = selectedDateTime;
              },
              onWokeUpSelected: (DateTime selectedDateTime) {
                wokeUpAt = selectedDateTime;
              },
            ),
            const SizedBox(height: 20),
            SleepHistoryWidget(sleepDataCollection: _sleepDataCollection),
          ],
        ),
      ),
    );
  }

  void _saveSleepData() async {
    if (sleptAt != null && wokeUpAt != null) {
      Duration sleepDuration = wokeUpAt!.difference(sleptAt!);
      String hours = "${sleepDuration.inHours}h ${sleepDuration.inMinutes % 60} mins";

      await _sleepDataCollection.add({
        'date': DateTime.now().toIso8601String(),
        'slept_at': sleptAt!.toIso8601String(),
        'woke_up_at': wokeUpAt!.toIso8601String(),
        'slept_hours': hours,
      });

      _sleptAtController.clear();
      _wokeUpController.clear();

      setState(() {});
    }
  }
}

class EnterSleepDataWidget extends StatelessWidget {
  final TextEditingController sleptAtController;
  final TextEditingController wokeUpController;
  final VoidCallback onSave;
  final Function(DateTime) onSleptAtSelected;
  final Function(DateTime) onWokeUpSelected;

  const EnterSleepDataWidget({super.key,
    required this.sleptAtController,
    required this.wokeUpController,
    required this.onSave,
    required this.onSleptAtSelected,
    required this.onWokeUpSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Sleep Data', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          SleepTimeInputField(
            label: 'Slept At:',
            controller: sleptAtController,
            onDateTimeSelected: onSleptAtSelected,
          ),
          const SizedBox(height: 10),
          SleepTimeInputField(
            label: 'Woke Up At:',
            controller: wokeUpController,
            onDateTimeSelected: onWokeUpSelected,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onSave,
            child: const Text('Add Sleep Data'),
          ),
        ],
      ),
    );
  }
}

class SleepTimeInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(DateTime) onDateTimeSelected;

  const SleepTimeInputField({super.key,
    required this.label,
    required this.controller,
    required this.onDateTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select Time',
            ),
            readOnly: true,
            onTap: () async {
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (date != null) {
                TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null) {
                  final dateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  controller.text = '${dateTime.hour}:${dateTime.minute}:00';
                  onDateTimeSelected(dateTime);
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

class SleepHistoryWidget extends StatelessWidget {
  final CollectionReference sleepDataCollection;

  const SleepHistoryWidget({super.key,
    required this.sleepDataCollection,
  });

  @override
  Widget build(BuildContext context) {

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sleep History', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: sleepDataCollection.orderBy('date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index];
                        return SleepHistoryItem(
                          date: data['slept_at'],
                          hours: data['slept_hours'],
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return const Text('Error loading data');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepHistoryItem extends StatelessWidget {
  final String date;
  final String hours;

  const SleepHistoryItem({super.key, required this.date, required this.hours});

  @override
  Widget build(BuildContext context) {
    DateTime sleptAtDate = DateTime.parse(date);
    String formattedDate = "${sleptAtDate.year}-${sleptAtDate.month.toString().padLeft(2, '0')}-${sleptAtDate.day.toString().padLeft(2, '0')}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(formattedDate, style: const TextStyle(fontSize: 16)),
          Text('Slept Hours: $hours', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}