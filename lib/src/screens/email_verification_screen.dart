import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  final int _checkInterval = 5; // seconds
  int _resendCooldown = 0; // seconds

  @override
  void initState() {
    super.initState();
    
    // Add a short delay before starting verification check
    // This ensures the widget is fully mounted before checking
    print("Email verification screen: initializing");
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        print("Email verification screen: starting verification check");
        _startVerificationCheck();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Start periodic check for email verification
  void _startVerificationCheck() {
    _checkVerification(); // Check immediately on load
    
    // Set up periodic check
    _timer = Timer.periodic(Duration(seconds: _checkInterval), (timer) {
      _checkVerification();
      
      // Update resend cooldown
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown -= _checkInterval;
          if (_resendCooldown < 0) _resendCooldown = 0;
        });
      }
    });
  }

  // Check if email has been verified
  Future<void> _checkVerification() async {
    if (_isLoading) return; // Prevent multiple simultaneous checks
    
    setState(() {
      _isLoading = true;
    });
    
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    try {
      final isVerified = await loginProvider.checkEmailVerification();
      
      if (isVerified) {
        // Email is verified, navigate to home screen
        _timer?.cancel(); // Stop checking
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
        
        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/home',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Handle error silently to avoid bothering the user with periodic check errors
      print('Error checking verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Resend verification email
  Future<void> _resendVerificationEmail() async {
    if (_isResending || _resendCooldown > 0) return;
    
    setState(() {
      _isResending = true;
    });
    
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    try {
      await loginProvider.resendVerificationEmail();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email resent successfully!')),
      );
      
      // Set cooldown for resend button (60 seconds)
      setState(() {
        _resendCooldown = 60;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend verification email: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                const Text(
                  'Waiting for verification...',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resendCooldown > 0 || _isResending ? null : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: _isResending
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(_resendCooldown > 0 
                        ? 'Resend Email (${_resendCooldown}s)' 
                        : 'Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Cancel verification check and log out
                  _timer?.cancel();
                  final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                  loginProvider.logout().then((_) {
                    Navigator.pushReplacementNamed(context, '/login');
                  });
                },
                child: const Text('Cancel and Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 