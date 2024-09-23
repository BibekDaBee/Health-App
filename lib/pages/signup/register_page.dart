import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController(); // Optional phone number

  String _message = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    _ageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose(); // Dispose of phone controller
    super.dispose();
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return; // Trigger form validation

    setState(() {
      _message = '';
      _isLoading = true;
    });

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get user UID
      String uid = userCredential.user!.uid;

      // Add user details to Firestore
      await addUserDetails(
        uid,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _emailController.text.trim(),
        int.parse(_ageController.text.trim()),
        _phoneController.text.trim(), // Pass the phone number
      );

      // Show success message
      setState(() {
        _message = 'Registration successful!';
      });

      // Clear inputs
      _formKey.currentState!.reset();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'An error occurred. Please try again.';
      });
    } catch (e) {
      setState(() {
        _message = 'An unexpected error occurred. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addUserDetails(
    String uid, String firstName, String lastName, String email, int age, String phone) async {
    // Add phone number to Firestore if provided
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'first name': firstName,
      'last name': lastName,
      'email': email,
      'age': age,
      if (phone.isNotEmpty) 'phone': phone, // Optional field
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 114, 222, 204),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hello There!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Register below with your details!',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Registration form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        buildTextField(_firstNameController, 'First Name'),
                        const SizedBox(height: 10),
                        buildTextField(_lastNameController, 'Last Name'),
                        const SizedBox(height: 10),
                        buildTextField(
                          _ageController,
                          'Age',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your age';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Age must be a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        buildTextField(
                          _emailController,
                          'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!EmailValidator.validate(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        buildTextField(
                          _passwordController,
                          'Password',
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        buildTextField(
                          _confirmpasswordController,
                          'Confirm Password',
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Optional phone number field
                        buildTextField(
                          _phoneController,
                          'Phone Number (Optional)',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !RegExp(r'^[0-9]{10,}$').hasMatch(value)) {
                              return 'Enter a valid phone number';
                            }
                            return null; // Allow empty phone number
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Sign Up Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : buildSignUpButton(),

                  const SizedBox(height: 25),

                  // Message display
                  if (_message.isNotEmpty)
                    Text(
                      _message,
                      style: TextStyle(
                        color: _message.contains('success') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 25),

                  // Switch to Login
                  buildLoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // build text fields with validation
  Widget buildTextField(TextEditingController controller, String hintText,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  // Sign Up Button
  Widget buildSignUpButton() {
    return ElevatedButton(
      onPressed: signUp,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(15),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Sign Up',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }

  // Login prompt
  Widget buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('I am a member!', style: TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: widget.showLoginPage,
          child: const Text(
            ' Login now',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
