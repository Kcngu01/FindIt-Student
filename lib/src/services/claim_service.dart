import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/claim.dart';
import 'login_service.dart';
import '../config/api_config.dart';

class ClaimService {
  static const String baseUrl = ApiConfig.showAllClaimsEndpoint;
  
  final LoginService _loginService = LoginService();

  Future<List<Claim>> getStudentClaims(int studentId) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.showAllClaimsEndpoint}/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      
      print("Claims API response status: ${response.statusCode}");
      print("Claims API response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("Parsed response data: $data");
        
        if (data['success'] == true && data.containsKey('claims')) {
          print("Claims data: ${data['claims']}");
          
          if (data['claims'] is List) {
            List<Claim> claims = (data['claims'] as List)
                .map((claimJson) {
                  print("Processing claim: $claimJson");
                  return Claim.fromJson(claimJson);
                })
                .toList();

            // List<Claim> claims = [];
            
            // for (var claimJson in data['claims']) {
            //   try {
            //     print("Processing claim: $claimJson");
            //     if (claimJson != null) {
            //       claims.add(Claim.fromJson(claimJson));
            //     }
            //   } catch (e) {
            //     print("Error processing individual claim: $e");
            //     print("Problematic claim JSON: $claimJson");
            //     // Continue processing other claims even if one fails
            //   }
            // }
            return claims;
          } else {
            print("'claims' is not a List: ${data['claims'].runtimeType}");
            return [];
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to get claims');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Claims not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to view these claims');
      } else {
        throw Exception('Failed to get claims with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting claims: $e");
      throw Exception('Failed to get claims: $e');
    }
  }

  Future<Claim> getClaimDetails(int claimId) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      // First try the dedicated endpoint for claim details
      var response = await http.get(
        Uri.parse('${ApiConfig.showClaimDetailsEndpoint}/$claimId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      
      // If that fails with a 404, try the alternative endpoint format
      // if (response.statusCode == 404) {
      //   print("First endpoint attempt failed, trying alternative endpoint");
      //   response = await http.get(
      //     Uri.parse('${ApiConfig.baseApiUrl}/claim/$claimId'),
      //     headers: {
      //       'Content-Type': 'application/json',
      //       'Authorization': 'Bearer $token',
      //     },
      //   ).timeout(const Duration(seconds: 5));
      // }
      
      print("Claim Details API response status: ${response.statusCode}");
      print("Claim Details API response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("Parsed response data: $data");
        
        if (data['success'] == true && data.containsKey('claim')) {
          print("Claims data: ${data['claim']}");
          return Claim.fromJson(data['claim']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get claim');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Claim not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to view this claim');
      } else {
        throw Exception('Failed to get claim with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting claim: $e");
      // Add more context to the error message
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Network error when getting claim. Please check your connection.');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Error parsing claim data from server. Please contact support.');
      } else {
        throw Exception('Failed to get claim: $e');
      }
    }
  }
}
