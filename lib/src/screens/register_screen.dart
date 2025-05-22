import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  // Password strength variables
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Password is empty';
  Color _passwordStrengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    //  every time the text in the password field changes, this function will be called.
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.dispose();
    super.dispose();
  }
  
  // Check password strength and update UI accordingly
  void _checkPasswordStrength() {
    final password = _passwordController.text;
    double strength = 0.0;
    String strengthText = 'Very Weak';
    Color strengthColor = Colors.red;
    
    if (password.isEmpty) {
      strengthText = 'Password is empty';
      strengthColor = Colors.grey;
    } else {
      // Base level just for having some characters
      strength += 0.2;
      
      // Increase strength for longer passwords, up to 0.2 more for 12+ chars
      if (password.length >= 8) strength += 0.2;
      
      // Check for uppercase letters
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
      
      // Check for lowercase letters
      if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
      
      // Check for numbers
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
      
      // Check for special characters
      if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) strength += 0.15;
      
      // Determine text and color based on strength
      if (strength <= 0.2) {
        strengthText = 'Very Weak';
        strengthColor = Colors.red;
      } else if (strength <= 0.4) {
        strengthText = 'Weak';
        strengthColor = Colors.orange;
      } else if (strength <= 0.55) {
        strengthText = 'Good';
        strengthColor = Colors.yellow.shade700;
      } else {
        strengthText = 'Strong';
        strengthColor = Colors.green;
      }
    }
    
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      try {
        // Extract matric number from email
        String email = _emailController.text;
        int matricNo = int.parse(email.split('@')[0]);

        // Register the user
        await loginProvider.register(_nameController.text, email, _passwordController.text, matricNo);

        if(!mounted) return;
        
        setState(() {
          _isLoading = false;
        });

        // After registration, navigate to email verification screen instead of home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please verify your email.')),
        );
            
        // Navigate to email verification screen
        Navigator.pushReplacementNamed(
          context,
          '/email_verification'
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Placeholder
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      'images/logo.png', // Replace with your logo asset path
                      height: 100,
                      width: 100,
                    ),
                  ),
                  const Text(
                    'Hello.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create an account',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'yourstudentid@siswa.unimas.my',
                      errorMaxLines: 3,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }

                      // Check if it's a valid email format and specifically a UNIMAS email
                      final emailRegex = RegExp(r'^[0-9]+@siswa\.unimas\.my$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid UNIMAS email (matric_no@siswa.unimas.my)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      helperText: 'Password must have at least 8 characters, including uppercase, lowercase, number, and special character',
                      helperMaxLines: 3,
                      errorMaxLines: 4,
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      
                      // Check for uppercase letters
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      
                      // Check for lowercase letters
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'Password must contain at least one lowercase letter';
                      }
                      
                      // Check for numbers
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Password must contain at least one number';
                      }
                      
                      // Check for special characters
                      final specialCharPattern = RegExp(r'[^a-zA-Z0-9]');
                      if (!specialCharPattern.hasMatch(value)) {
                        return 'Password must contain at least one special character';
                      }
                      
                      return null;
                    },
                  ),
                  
                  // Password strength indicator
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          backgroundColor: Colors.grey[200],
                          color: _passwordStrengthColor,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _passwordStrengthText,
                        style: TextStyle(
                          color: _passwordStrengthColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  // Sign Up Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                        ),
                  const SizedBox(height: 20),
                  // Sign In Link
                  TextButton(
                    onPressed: () {
                      // Handle sign in navigation
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text("Already have an account? Sign in"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}