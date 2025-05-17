import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/item.dart';
import 'login_service.dart';
import '../models/characteristic.dart';
import '../config/api_config.dart';
import 'image_service.dart';

class ItemService {
  static const String baseUrl = ApiConfig.itemsEndpoint;
  static const String baseUrlCategories = ApiConfig.categoriesEndpoint;
  static const String baseUrlColours = ApiConfig.coloursEndpoint;
  static const String baseUrlLocations = ApiConfig.locationsEndpoint;

  final LoginService _loginService = LoginService();

  Future<List<Item>> getItems({int? categoryId, int? colorId, int? locationId, String? searchQuery}) async {
    return _getItemsByType(null, categoryId: categoryId, colorId: colorId, locationId: locationId, searchQuery: searchQuery);
  }
  
  Future<List<Item>> getFoundItems({int? categoryId, int? colorId, int? locationId, String? searchQuery}) async {
    return _getItemsByType('found', categoryId: categoryId, colorId: colorId, locationId: locationId, searchQuery: searchQuery);
  }
  
  Future<List<Item>> getLostItems({int? categoryId, int? colorId, int? locationId, String? searchQuery}) async {
    return _getItemsByType('lost', categoryId: categoryId, colorId: colorId, locationId: locationId, searchQuery: searchQuery);
  }
  
  Future<List<Item>> getRecoveredItems({int? categoryId, int? colorId, int? locationId, String? searchQuery}) async {
    return _getItemsByType('recovered', categoryId: categoryId, colorId: colorId, locationId: locationId, searchQuery: searchQuery);
  }
  
  Future<List<Item>> _getItemsByType(String? type, {int? categoryId, int? colorId, int? locationId, String? searchQuery}) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      // Build the URL with type and other filters
      var queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (colorId != null) queryParams['color_id'] = colorId.toString();
      if (locationId != null) queryParams['location_id'] = locationId.toString();
      if (searchQuery != null) queryParams['search'] = searchQuery;
      
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      
      print("Items API response: ${uri.toString()} - ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('items')) {
          List<Item> items = (data['items'] as List)
              .map((itemJson) => Item.fromJson(itemJson))
              .toList();
          return items;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to load items with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching items of type $type: $e");
      throw Exception('Failed to load items: $e');
    }
  }
  
  Future <List<Item>> getMyItemsByStudentId(int studentId, String type) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.myItemsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'student_id': studentId, 'type': type}),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('items')) {
          List<Item> items = (data['items'] as List)
              .map((itemJson) => Item.fromJson(itemJson))
              .toList();
          return items;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load items with status: ${response.statusCode}');
      }  
    } catch(e){
      print("Error fetching items of type $type: $e");
      throw Exception('Failed to load items: $e');
    }
  }

  Future<List<Characteristic>> getCategories() async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrlCategories),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      ).timeout(const Duration(seconds: 10));

      print("Categories API response: ${response.statusCode}, ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('categories')) {
          List<Characteristic> categories = (data['categories'] as List)
              .map((categoryJson) => Characteristic.fromJson(categoryJson))
              .toList();
          return categories;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to load categories with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching categories: $e");
      throw Exception('Failed to fetch categories: $e');
    }
  }
  
  Future<List<Characteristic>> getColours() async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrlColours),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      ).timeout(const Duration(seconds: 10));

      print("Colours API response: ${response.statusCode}, ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('colours')) {
          List<Characteristic> colours = (data['colours'] as List)
              .map((colourJson) => Characteristic.fromJson(colourJson))
              .toList();
          return colours;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to load colours with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching colours: $e");
      throw Exception('Failed to fetch colours: $e');
    }
  }
  
  Future<List<Characteristic>> getLocations() async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrlLocations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      ).timeout(const Duration(seconds: 10));

      print("Locations API response: ${response.statusCode}, ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('locations')) {
          List<Characteristic> locations = (data['locations'] as List)
              .map((locationJson) => Characteristic.fromJson(locationJson))
              .toList();
          return locations;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to load locations with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching locations: $e");
      throw Exception('Failed to fetch locations: $e');
    }
  }
  
  
  Future<void> createItem({
    required String name,
    String? description,
    required String type,
    required int categoryId,
    required int colourId,
    required int locationId,
    required int studentId,
    File? imageFile,
  }) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      // Compress image if provided and larger than 5MB
      File? processedImageFile = imageFile;
      if (imageFile != null) {
        //processedImageFile is a compressed image file
        processedImageFile = await ImageService.compressImageIfNeeded(imageFile);
      }
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl),
      );
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add text fields
      request.fields.addAll({
        'name': name,
        'type': type,
        'status': 'active',
        'category_id': categoryId.toString(),
        'color_id': colourId.toString(),
        'location_id': locationId.toString(),
        'student_id': studentId.toString(),
      });
      
      // Add description if provided
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      // Add image if provided
      if (processedImageFile != null) {
        final fileName = processedImageFile.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Print file sizes for debugging
        if (imageFile != processedImageFile) {
          print("Original image size: ${await imageFile!.length()} bytes");
          print("Compressed image size: ${await processedImageFile.length()} bytes");
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            processedImageFile.path,
            contentType: MediaType('image', fileExtension),
          ),
        );
      }
      
      // Send the request
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print("Create Item API response: ${response.statusCode}, ${response.body}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data.containsKey('similarity_matches') && data['similarity_matches'] > 0) {
            // Show match information to the user
            print("Found ${data['similarity_matches']} potential matches!");
          }
          return; // Success
        } else {
          throw Exception(data['message'] ?? 'Failed to create item');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final errors = data['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
            .join('; ');
        throw Exception('Validation error: $errorMessages');
      } else {
        throw Exception('Failed to create item with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error creating item: $e");
      throw Exception('Failed to create item: $e');
    }
  }

  Future<String> updateItem({
    required int id,
    String? name,
    String? description,
    int? categoryId,
    int? locationId,
    int? colorId,
    String? type,
    File? imageFile,
  }) async {
    print(name);
    print(description);
    print(categoryId);
    print(locationId);
    print(colorId);
    print(imageFile);
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      // Compress image if provided and larger than 5MB
      File? processedImageFile = imageFile;
      if (imageFile != null) {
        processedImageFile = await ImageService.compressImageIfNeeded(imageFile);
      }
      
      final uri = Uri.parse('${ApiConfig.editItemsEndpoint}/$id');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add fields if provided
      if (name != null) {
        request.fields['name'] = name;
      }
      
      if (description != null) {
        request.fields['description'] = description;
        print(description);
      }

      if (type != null) {
        request.fields['type'] = type;
        print(type);
      }
      
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      
      if (locationId != null) {
        request.fields['location_id'] = locationId.toString();
      }
      
      if (colorId != null) {
        request.fields['color_id'] = colorId.toString();
      }
      
      // Add image if provided
      if (processedImageFile != null) {
        final fileName = processedImageFile.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Print file sizes for debugging
        if (imageFile != processedImageFile) {
          print("Original image size: ${await imageFile!.length()} bytes");
          print("Compressed image size: ${await processedImageFile.length()} bytes");
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            processedImageFile.path,
            contentType: MediaType('image', fileExtension),
          ),
        );
      }
      
      // Send the request
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print("Update Item API response: ${response.statusCode}, ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['message']; // Success
        } else {
          throw Exception(data['message'] ?? 'Failed to update item');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else if (response.statusCode == 404) {
        throw Exception('Item not found');
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final errors = data['errors'] ?? {};
        final errorMessages = errors.entries
            .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
            .join('; ');
        throw Exception('Validation error: $errorMessages');
      } else {
        throw Exception('Failed to update item with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error updating item: $e");
      throw Exception('Failed to update item: $e');
    }
  }

  Future<String> deleteItem(int id) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.deleteItemsEndpoint}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        }
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if(data['success'] == true){
          return data['message'];
        }
        else{
          throw Exception(data['message'] ?? 'Failed to delete item');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to delete item with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<Item> getItemById(int id) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('item')) {
          print('Item: ${data['item']}  ');
          return Item.fromJson(data['item']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Item not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to load item with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching item: $e");
      throw Exception('Failed to load item: $e');
    }
  }

  Future<Characteristic> getCategoryById(int id) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrlCategories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('category')) {
          return Characteristic.fromJson(data['category']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('Failed to load category with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching category: $e");
      throw Exception('Failed to load category: $e');
    }
  }

  Future<Characteristic> getColorById(int id) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrlColours/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('colour')) {
          return Characteristic.fromJson(data['colour']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Color not found');
      } else {
        throw Exception('Failed to load color with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching color: $e");
      throw Exception('Failed to load color: $e');
    }
  }

  Future<Characteristic> getLocationById(int id) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrlLocations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('location')) {
          return Characteristic.fromJson(data['location']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Location not found');
      } else {
        throw Exception('Failed to load location with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching location: $e");
      throw Exception('Failed to load location: $e');
    }
  }

  Future<Map<String, dynamic>> getStudentById(int id) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.studentsEndpoint}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('student')) {
          return data['student'];
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Student not found');
      } else {
        throw Exception('Failed to load student with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching student: $e");
      throw Exception('Failed to load student: $e');
    }
  }

  Future<void> claimItem({required int itemId, required int studentId, required String status, required String justification}) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.claimItemsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'found_item_id': itemId,
          'student_id': studentId,
          'status': status,
          'student_justification':justification,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return; // Success
        } else {
          throw Exception(data['message'] ?? 'Failed to claim item');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Item not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to claim this item');
      } else {
        throw Exception('Failed to claim item with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error claiming item: $e");
      throw Exception('Failed to claim item: $e');
    }
  }
  
  // Check if the student has already claimed this item
  Future<bool> hasClaimedItem(int itemId, int studentId) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.claimItemsEndpoint}/check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'found_item_id': itemId,
          'student_id': studentId,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['claimed'] == true;
      } else {
        // If there's an error, we'll assume not claimed for safety
        return false;
      }
    } catch (e) {
      print("Error checking claim status: $e");
      return false;
    }
  }
} 