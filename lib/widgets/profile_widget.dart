import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String imageUrl; // Pass the profile picture URL

  const ProfileWidget({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the profile screen or show options
        Navigator.pushNamed(context, '/profile');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: CircleAvatar(
          radius: 20, // Adjust the size as needed
          backgroundImage: NetworkImage(imageUrl), // Use the provided image URL
          backgroundColor: Colors.grey[200], // Placeholder color
        ),
      ),
    );
  }
}
