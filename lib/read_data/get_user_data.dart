import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Class to hold user data
class UserData {
  final String firstName;
  final String lastName;
  final String age;
  final String phone;  // Added phone field
  final String email;  // Added email field

  UserData({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.phone,  // New field
    required this.email,  // New field
  });

  // Convert from Firestore document data to UserData
  factory UserData.fromMap(Map<String, dynamic> data) {
    String firstName = data.containsKey('firstName') ? data['firstName'] : 'No first name available';
    String lastName = data.containsKey('lastName') ? data['lastName'] : 'No last name available';
    String age = data.containsKey('age') ? data['age']?.toString() ?? 'No age available' : 'No age available';
    String phone = data.containsKey('phone') ? data['phone'] : 'No phone available';
    String email = data.containsKey('email') ? data['email'] : 'No email available';

    return UserData(
      firstName: firstName,
      lastName: lastName,
      age: age,
      phone: phone,  // Set phone
      email: email,  // Set email
    );
  }

  // Fallback UserData in case of errors or missing data
  factory UserData.error() {
    return UserData(
      firstName: 'Error',
      lastName: 'Error',
      age: 'Error',
      phone: 'Error',
      email: 'Error',
    );
  }

  @override
  String toString() {
    return 'UserData(firstName: $firstName, lastName: $lastName, age: $age, phone: $phone, email: $email)';
  }
}

class GetUserData {
  // Method to fetch user profile data from Firestore
  static Future<UserData> fetchUserData(String uid, {String collection = 'profile', String document = 'profileData'}) async {
    try {
      // Fetch the document from Firestore
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collection) // Flexible collection name
          .doc(document)           // Flexible document name
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
          phone: 'No phone available',
          email: 'No email available',
        );
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firebase error: $e');
      }
      return UserData.error(); // Specific error handling for Firebase exceptions
    } catch (e) {
      if (kDebugMode) {
        print('Unknown error fetching user data: $e');
      }
      return UserData.error(); // General error handling
    }
  }
}
