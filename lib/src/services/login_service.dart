import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/Student.dart';
import '../config/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class LoginService {
  static const String baseUrl = ApiConfig.loginEndpoint;
  static const String registerUrl = ApiConfig.registerEndpoint;
  static const String logoutUrl = ApiConfig.logoutEndpoint;
  static const String _tokenKey = 'auth_token';
  static const String _verifiedKey = 'verified_status';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> get token async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> setVerificationStatus(bool status) async {
    await _secureStorage.write(key: _verifiedKey, value: status.toString());
  }

  Future<bool?> get verifiedStatus async {
    final status = await _secureStorage.read(key: _verifiedKey);
    return status != null ? bool.parse(status) : null;
  }

  Future<void> setToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: _tokenKey);
    } else {
      await _secureStorage.write(key: _tokenKey, value: token);
    }
  }

  Future<void> clearToken() async {
    final token = await this.token;
    
    // First make the API call to logout
    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse(logoutUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          }
        );
        
        print("Logout response: ${response.statusCode}, ${response.body}");
        
        // Check response (this is just for debugging)
        if (response.statusCode == 200) {
          print("Logout successful on server");
        } else {
          print("Logout failed on server: ${response.statusCode}");
        }
      } catch (e) {
        print("Error during API logout: $e");
        // Continue with local logout even if API call fails
      }
    }
    
    // Then clear the local storage regardless of API response
    await _secureStorage.delete(key: _tokenKey);
  }


  Future<Student> register(String name, String email, String password, int matricNo) async {
    final response = await http.post(
      Uri.parse(registerUrl),
      headers:{
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Add this line
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'matric_no': matricNo,
        'password': password,
      })
    );

    if(response.statusCode == 201){
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('token')) {
        await setToken(responseData['token']);
        // Set verification status to false for new registrations
        await setVerificationStatus(false);
        print("LoginService: Token saved, verification status set to false");
      }
      return Student.fromJson(responseData);
    }else{
      throw Exception('Failed to register with status: ${response.statusCode}');
    }
  }

  Future<Student> login(String email, String password) async {
    // final response = await HttpUtil.makeAuthenticatedRequest(
    //   '$baseUrl',
    //   null,
    //   method: 'POST',
    //   body: {'matricNo': email, 'password': password},
    // );
    print("LoginService: Attempting login with email: $email");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    print("LoginService: Received response with status: ${response.statusCode}");
    print("LoginService: Response body: ${response.body}");
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('token')) {
        await setToken(responseData['token']);
              print("LoginService: Token saved");
      }

      // Create the student object from the response first
      final student = Student.fromJson(responseData);

      // Try to register FCM token but don't let it block login if it fails
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await registerFcmToken(
            fcmToken, 
            Platform.isAndroid ? 'android' : 'ios'
          );
        }
      } catch (e) {
        // Log the error but don't throw it to prevent login failure
        print("Warning: FCM token registration failed: $e");
        // Continue with login process regardless of FCM registration result
      }
      
      return student;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid credentials');
    } else {
      throw Exception('Failed to login with status: ${response.statusCode}');
    }
  }

  Future<Student> fetchStudentProfile() async {
    final token = await this.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }
    
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Check for HTML response first
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Profile API response: ${response.statusCode}, ${response.body}");
        return Student.fromJson(responseData);
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to fetch profile with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format: Server may be returning HTML instead of JSON');
      }
      rethrow;
    }
  }

  Future<bool> checkEmailVerification() async {
    final token = await this.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.verifyEmailCheckEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final isVerified = responseData['verified'] ?? false;
      await setVerificationStatus(isVerified);
      return isVerified;
    } else if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Unauthorized: Token expired or invalid');
    } else {
      throw Exception('Failed to check email verification status');
    }
  }

  Future<void> resendVerificationEmail() async {
    final token = await this.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final response = await http.post(
      Uri.parse(ApiConfig.verifyEmailResendEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to resend verification email,${response.statusCode}');
      }
    }
  }

  // Add a method to check if user is verified and get their profile
  Future<Student?> getVerifiedProfile() async {
    try {
      // First check if email is verified
      await checkEmailVerification();
      final verificationStatus = await verifiedStatus;
      
      if (verificationStatus == true) {
        // If verified, fetch and return the profile
        return await fetchStudentProfile();
      } else {
        // If not verified, return null to indicate verification needed
        return null;
      }
    } catch (e) {
      print("Error checking verification status: $e");
      throw Exception('Failed to get verified profile: $e');
    }
  }

  Future<void> registerFcmToken(String token, String deviceType) async {
    final authToken = await this.token;
    if (authToken == null) {
      throw Exception('No authentication token available');
    }
    
    try {
      print("Attempting to register FCM token with server. URL: ${ApiConfig.fcmTokenEndpoint}");
      print("FCM token: $token, Device type: $deviceType");
      
      final response = await http.post(
        Uri.parse(ApiConfig.fcmTokenEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'device_token': token,
          'device_type': deviceType,
        }),
      );
      
      print("FCM token registration response: Status ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode != 200) {
        throw Exception('Failed to register FCM token: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print("Error registering FCM token: $e");
      throw Exception('Failed to register FCM token: $e');
    }
  }
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/Student.dart';

// class LoginService{
//   static const String baseUrl = 'http://127.0.0.1:8000/api/login';
//   String? _token;

//   LoginService({this._token});

//   Future<Student> login(String matricNo, String password) async{
//     final response = await http.post(
//       Uri.parse(baseUrl),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({'matricNo': matricNo, 'password': password}),
//     );

//     if(response.statusCode == 200){
//       final responseData= jsonDecode(response.body);
//       if(responseData.containsKey('token')){
//         _token = responseData['token'];
//       }
//       return Student.fromJson(responseData);
//     }else{
//       throw Exception('Failed to login');
//     }

//   }
// }
