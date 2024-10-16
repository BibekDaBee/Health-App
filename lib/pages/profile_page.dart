import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/read_data/get_user_data.dart';
import 'package:health/pages/signup/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  UserData? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Fetch user data
  Future<void> fetchUserData() async {
    final data = await GetUserData.fetchUserData(user.uid);
    setState(() {
      userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined, 
              size: 36, // Adjust the size of the icon
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 173, 238, 227),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: userData == null
              ? const CircularProgressIndicator()
              : userData!.firstName == 'Error'
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error fetching user data.'),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: fetchUserData,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Here are your details:',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Display first name
                          buildDataRow(Icons.person, 'First Name', userData!.firstName),
                          const SizedBox(height: 10),

                          // Display last name
                          buildDataRow(Icons.person_outline, 'Last Name', userData!.lastName),
                          const SizedBox(height: 10),

                          // Display age
                          buildDataRow(Icons.cake, 'Age', userData!.age),
                          const SizedBox(height: 10),

                          // Display phone
                          buildDataRow(Icons.phone, 'Phone', userData!.phone),
                          const SizedBox(height: 10),

                          // Display email
                          buildDataRow(Icons.email, 'Email', userData!.email),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  // Create a formatted data row
  Widget buildDataRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.deepPurple[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // Confirm sign out
  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(showRegisterPage: () {})),
          (route) => route.isFirst,
        );
      }
    }
  }
}
