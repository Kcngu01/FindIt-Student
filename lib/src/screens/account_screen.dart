import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';
import 'change_password_screen.dart';
import 'change_username_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = false;

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _logout(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<LoginProvider>(context, listen: false).logout();
      // Navigate to login screen after logout
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<LoginProvider>(
        builder: (context, loginProvider, child) {
          final student = loginProvider.student;
          
          if (student == null) {
            return const Center(
              child: Text('You are not logged in'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Info Card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            student.name ?? 'Student',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            student.email ?? 'No email provided',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.school),
                          title: const Text('Matric Number'),
                          subtitle: Text(student.matricNo?.toString() ?? 'Not provided'),
                          dense: true,
                        ),
                        ListTile(
                          leading: const Icon(Icons.verified_user),
                          title: const Text('Email Verified'),
                          subtitle: Text(
                            student.emailVerified == true ? 'Yes' : 'No',
                          ),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Account Actions
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Account Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Change Username'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ChangeUsernameScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        trailing: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isLoading
                            ? null
                            : () => _showLogoutConfirmation(context),
                      ),
                    ],
                  ),
                ),
                
                // App Info
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 