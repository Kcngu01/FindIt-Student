import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isCheckingStatus = false;
  bool _isResendingEmail = false;
  String? _errorMessage;
  
  // Resend cooldown variables
  int _resendCooldown = 0; // Seconds remaining in cooldown
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Check if we need to restore cooldown from previous state
    _startCooldownTimerIfNeeded();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Start the cooldown timer if needed
  void _startCooldownTimerIfNeeded() {
    if (_resendCooldown > 0 && _cooldownTimer == null) {
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _resendCooldown = 0;
            _cooldownTimer?.cancel();
            _cooldownTimer = null;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
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
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Check Verification Status Button
              ElevatedButton.icon(
                onPressed: _isCheckingStatus || _isResendingEmail 
                    ? null 
                    : _checkVerificationStatus,
                icon: _isCheckingStatus 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isCheckingStatus 
                    ? 'Checking...' 
                    : 'Check Verification Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: const Size(250, 50),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Resend Email Button with cooldown
              TextButton.icon(
                onPressed: (_isResendingEmail || _isCheckingStatus || _resendCooldown > 0)
                    ? null
                    : _resendVerificationEmail,
                icon: _isResendingEmail
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isResendingEmail
                    ? 'Sending...'
                    : _resendCooldown > 0
                      ? 'Resend available in ${_resendCooldown}s'
                      : 'Didn\'t receive the email? Resend'
                ),
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.disabled)) {
                        return _resendCooldown > 0 
                          ? Colors.grey.shade600 // Less faded when in cooldown
                          : Colors.grey; // Standard disabled color
                      }
                      return Theme.of(context).primaryColor; // Enabled color
                    }
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              const SizedBox(height: 16),
              
              // Logout option
              TextButton(
                onPressed: _logout,
                child: const Text('Log out and try again later'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isCheckingStatus = true;
      _errorMessage = null;
    });

    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final isVerified = await loginProvider.checkEmailVerification();
      
      if (isVerified) {
        if (!mounted) return;
        
        // Show success message before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home page after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        });
      } else {
        setState(() {
          _errorMessage = 'Your email is not verified yet. Please check your inbox and click the verification link.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking verification status: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return; // Safety check
    
    setState(() {
      _isResendingEmail = true;
      _errorMessage = null;
    });

    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      await loginProvider.resendVerificationEmail();
      
      if (!mounted) return;
      
      // Start the 60-second cooldown
      setState(() {
        _resendCooldown = 60;
        _startCooldownTimerIfNeeded();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending verification email: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  void _logout() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    await loginProvider.logout();
    
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }
} 