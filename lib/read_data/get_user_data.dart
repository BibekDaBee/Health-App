import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Class to hold user data
class UserData {
  final String firstName;
  final String lastName;
  final String age;

  UserData({
    required this.firstName,
    required this.lastName,
    required this.age,
  });

  // Convert from Firestore document data to UserData
  factory UserData.fromMap(Map<String, dynamic> data) {
    // Use the correct field names from Firestore
    String firstName = data['firstName'] ?? 'No first name available';  // Correct key
    String lastName = data['lastName'] ?? 'No last name available';      // Correct key
    String age = data['age']?.toString() ?? 'No age available';

    return UserData(
      firstName: firstName,
      lastName: lastName,
      age: age,
    );
  }

  // Fallback UserData in case of errors or missing data
  factory UserData.error() {
    return UserData(
      firstName: 'Error',
      lastName: 'Error',
      age: 'Error',
    );
  }

  @override
  String toString() {
    return 'UserData(firstName: $firstName, lastName: $lastName, age: $age)';
  }
}

class GetUserData {
  // Method to fetch user profile data from Firestore
  static Future<UserData> fetchUserData(String uid) async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('profileData') // the specific profile document
          .get();

      if (profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>;

        // Debugging: Print fetched data to verify field names
        if (kDebugMode) {
          print("Fetched data: $data");
        }

        return UserData.fromMap(data); // Create UserData from Firestore document
      } else {
        return UserData(
          firstName: 'No first name available',
          lastName: 'No last name available',
          age: 'No age available',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
      return UserData.error();
    }
  }
}
