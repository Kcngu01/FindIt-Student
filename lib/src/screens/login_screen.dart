import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  // const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoggingIn = false;
  late LoginProvider _loginProvider;

  @override
  void initState() {
    super.initState();
    _loginProvider = Provider.of<LoginProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoggingIn = true;
      });

      try {
        await _loginProvider.login(_emailController.text, _passwordController.text);
        
        // Check if email is verified
        final isVerified = await _loginProvider.checkEmailVerification();
        
        if (!mounted) return;
        
        if (!isVerified) {
          // Show verification required dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Email Verification Required'),
              content: const Text(
                'Please verify your email address before continuing.'
                'Check your inbox for a verification link.'
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      // Clear any existing snackbars
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      
                      // Show a loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sending verification email...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Resend verification email
                      await _loginProvider.resendVerificationEmail();
                      
                      print("Email verification sent successfully, preparing to navigate");
                      
                      // Clear the loading snackbar
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification email resent successfully'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Add a tiny delay to let the user see the success message
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Skip closing the dialog and navigate directly
                      // This prevents the context disposal issues
                      print("Navigating to email verification screen");
                      
                      // Navigate directly to the verification screen, replacing all screens
                      // This automatically closes all dialogs
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/email_verification',
                        // removes all previous routes from the stack. This effectively clears the entire navigation history, making the new route (/email_verification) the only one in the stack, preventing the user from going back to previous screens.
                        (route) => false, 
                      );
                      
                    } catch (e) {
                      print("Error resending verification email: $e");
                      
                      // Clear any existing snackbars
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to resend verification email: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Resend Verification Email'),
                ),
                TextButton(
                  onPressed: () { 
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/email_verification',
                        (route) => false, 
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        // Email is verified, proceed to home screen
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
          });
        }
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
                    'Welcome back',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
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
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to forgot password screen
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sign In Button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  // Sign Up Link
                  TextButton(
                    onPressed: () {
                      // Handle sign up navigation
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text("Don't have an account? Sign up"),
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