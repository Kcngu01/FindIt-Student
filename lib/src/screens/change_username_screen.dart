import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Initialize with current username
    final student = Provider.of<LoginProvider>(context, listen: false).student;
    if (student != null) {
      _usernameController.text = student.name;
    }
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
  
  Future<void> _changeUsername() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final newUsername = _usernameController.text;
      
      await Provider.of<LoginProvider>(context, listen: false)
          .changeUsername(newUsername);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username changed successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Username'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'New Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _changeUsername,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change Username'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 