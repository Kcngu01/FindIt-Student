import 'package:flutter/material.dart';
import '../models/Student.dart';
import '../services/login_service.dart';

class LoginProvider extends ChangeNotifier {
  Student? _student;
  String? _error;
  String? _token;
  bool _isLoading = true;
  bool _isVerified = false;

  final LoginService _loginService = LoginService();

  LoginProvider() {
    // Initialize by loading the token and checking verification
    _initializeToken();
  }

  // Public getters
  Student? get student => _student;
  String? get error => _error;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isVerified => _isVerified;

  // Initialize token on startup
  Future<void> _initializeToken() async {
    _isLoading = true;
    _error = null; // Clear previous errors
    notifyListeners();
    
    try {
      _token = await _loginService.token.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timed out. Please check your internet connection.');
        },
      );
      print("Token: $_token");

      if (_token != null) {
        try {
          // Check verification status first
          await _loginService.checkEmailVerification();
          final verifiedStatus = await _loginService.verifiedStatus;
          _isVerified = verifiedStatus ?? false;
          
          if (_isVerified) {
            // Only fetch profile if verified
            _student = await _loginService.fetchStudentProfile().timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Connection timed out while fetching profile. Please check your internet connection.');
              },
            );
          }
        } catch (e) {
          if (e.toString().contains('timed out')) {
            _error = e.toString();
          } else {
            // For other errors, clear token and continue to login
            await _loginService.clearToken();
            _token = null;
          }
        }
      } 
    } catch (e) {
      _error = e.toString();
      print("Error: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _student = null;
    _error = null;
    notifyListeners();
    
    try {
      final student = await _loginService.login(email, password);
      _token = await _loginService.token; // Refresh token after login
      
      // Check verification status
      await _loginService.checkEmailVerification();
      final verifiedStatus = await _loginService.verifiedStatus;
      _isVerified = verifiedStatus ?? false;
      
      if (_isVerified) {
        _student = student;
      }
      
      _error = null;
    } catch (e) {
      print("LoginProvider: Login error: $e");

      _error = e.toString();
      _student = null;
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
      print("LoginProvider: Login process completed, student: $_student, verified: $_isVerified, error: $_error");
    }
  }

  Future<void> register(String name, String email, String password, int matricNo) async {
    _isLoading = true;
    _student = null;
    _error = null;
    _isVerified = false;
    notifyListeners();
    
    try {
      // Register the user - this will also set the token and verification status to false
      await _loginService.register(name, email, password, matricNo);
      _token = await _loginService.token;
      _isVerified = false; // New registrations are not verified
    } catch (e) {
      _error = e.toString();
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final isVerified = await _loginService.checkEmailVerification();
      _isVerified = isVerified;
      
      if (isVerified) {
        // If verified, refresh the student profile
        _student = await _loginService.fetchStudentProfile();
        notifyListeners();
      }
      return isVerified;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      print('LoginProvider: Attempting to resend verification email');
      await _loginService.resendVerificationEmail();
      print('LoginProvider: Verification email resent successfully');
      
      // Force refresh the verification status after resending the email
      // This won't change the status immediately, but ensures the app knows
      // it needs to check again soon
      _isVerified = false;
      notifyListeners();
      
    } catch (e) {
      print('LoginProvider: Error resending verification email: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loginService.clearToken();
      _student = null;
      _token = null;
      _error = null;
      _isVerified = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
// import 'package:flutter/material.dart';
// import '../models/Student.dart';
// import '../services/login_service.dart';

// class LoginProvider extends ChangeNotifier{
//   Student? _student;
//   String? _error;

//   Student? get student => _student;
//   String? get error => _error;

//   Future<void> login(String matricNo, String password) async{
//     _student = null; // Reset student
//     _error = null;   // Reset error
//     try{
//       final service = LoginService();
//       final student = await service.login(matricNo, password);
//       _student = student;
//       _error = null;
//     }catch(e){
//       _error = e.toString();
//       _student = null;
//     }
//     notifyListeners();
//   }
// }
