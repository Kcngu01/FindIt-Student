// lib/src/providers/item_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/item.dart';
import '../models/potential_match.dart';
import '../models/characteristic.dart';
import '../models/claim.dart';
import '../models/claim_by_match.dart';
import '../services/item_service.dart';
import '../services/claim_service.dart';

class ItemProvider extends ChangeNotifier {
  final ItemService _itemService = ItemService();
  final ClaimService _claimService = ClaimService();
  
  // Items for Home Screen
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  String _filterType = 'found'; // 'lost', 'found', 'recovered'
  String? _statusMessage;
  
  // Filter state variables
  int? _filterCategoryId;
  int? _filterColorId;
  int? _filterLocationId;
  String? _searchQuery;
  
  // User Items for My Items Screen
  List<Item> _userItems = [];
  bool _isLoadingUserItems = false;
  String? _userItemsError;
  
  // Item Details
  Item? _currentItem;
  bool _isLoadingItemDetails = false;
  String? _itemDetailsError;
  
  // Potential Matches
  List<PotentialMatch> _potentialMatches = [];
  bool _isLoadingPotentialMatches = false;
  String? _potentialMatchesError;
  
  // Characteristics for filters
  List<Characteristic> _categories = [];
  List<Characteristic> _colors = [];
  List<Characteristic> _locations = [];
  bool _loadingCharacteristics = false;
  
  // Claims
  List<Claim> _claims = [];
  List<ClaimByMatch> _claimsByMatch = [];
  bool _isLoadingClaims = false;
  String? _claimsError;
  
  // Getters for Home Screen
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterType => _filterType;
  int? get filterCategoryId => _filterCategoryId;
  int? get filterColorId => _filterColorId;
  int? get filterLocationId => _filterLocationId;
  String? get searchQuery => _searchQuery;
  
  // Getters for My Items Screen
  List<Item> get userItems => _userItems;
  bool get isLoadingUserItems => _isLoadingUserItems;
  String? get userItemsError => _userItemsError;
  String? get statusMessage => _statusMessage;
  
  // Getters for Item Details
  Item? get currentItem => _currentItem;
  bool get isLoadingItemDetails => _isLoadingItemDetails;
  String? get itemDetailsError => _itemDetailsError;
  
  // Getters for Potential Matches
  List<PotentialMatch> get potentialMatches => _potentialMatches;
  bool get isLoadingPotentialMatches => _isLoadingPotentialMatches;
  String? get potentialMatchesError => _potentialMatchesError;
  
  // Getters for Characteristics
  List<Characteristic> get categories => _categories;
  List<Characteristic> get colors => _colors;
  List<Characteristic> get locations => _locations;
  bool get loadingCharacteristics => _loadingCharacteristics;
  
  // Getters for Claims
  List<Claim> get claims => _claims;
  List<ClaimByMatch> get claimsByMatch => _claimsByMatch;
  bool get isLoadingClaims => _isLoadingClaims;
  String? get claimsError => _claimsError;
  
  // Methods for Home Screen
  
  // Load items based on current filters
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Item> loadedItems;
      switch (_filterType) {
        case 'found':
          loadedItems = await _itemService.getFoundItems(
            categoryId: _filterCategoryId,
            colorId: _filterColorId,
            locationId: _filterLocationId,
            searchQuery: _searchQuery,
          );
          break;
        case 'lost':
          loadedItems = await _itemService.getLostItems(
            categoryId: _filterCategoryId,
            colorId: _filterColorId,
            locationId: _filterLocationId,
            searchQuery: _searchQuery,
          );
          break;
        case 'recovered':
          loadedItems = await _itemService.getRecoveredItems(
            categoryId: _filterCategoryId,
            colorId: _filterColorId,
            locationId: _filterLocationId,
            searchQuery: _searchQuery,
          );
          break;
        default:
          loadedItems = await _itemService.getFoundItems(
            categoryId: _filterCategoryId,
            colorId: _filterColorId,
            locationId: _filterLocationId,
            searchQuery: _searchQuery,
          );
      }
      
      _items = loadedItems;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update filter type
  void updateFilterType(String type) {
    if (_filterType != type) {
      _filterType = type;
      notifyListeners();
      loadItems();
    }
  }
  
  // Update search query
  void updateSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
    loadItems();
  }
  
  // Update category filter
  void updateCategoryFilter(int? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
    loadItems();
  }
  
  // Update color filter
  void updateColorFilter(int? colorId) {
    _filterColorId = colorId;
    notifyListeners();
    loadItems();
  }
  
  // Update location filter
  void updateLocationFilter(int? locationId) {
    _filterLocationId = locationId;
    notifyListeners();
    loadItems();
  }
  
  // Clear all filters
  void clearFilters() {
    _filterCategoryId = null;
    _filterColorId = null;
    _filterLocationId = null;
    notifyListeners();
    loadItems();
  }
  
  // Load filter characteristics
  Future<void> loadFilterCharacteristics() async {
    if (_categories.isNotEmpty && _colors.isNotEmpty && _locations.isNotEmpty) {
      return; // Already loaded
    }
    
    _loadingCharacteristics = true;
    notifyListeners();
    
    try {
      final results = await Future.wait([
        _itemService.getCategories(),
        _itemService.getColours(),
        _itemService.getLocations(),
      ]);
      
      _categories = results[0];
      _colors = results[1];
      _locations = results[2];
      _loadingCharacteristics = false;
      notifyListeners();
    } catch (e) {
      print('Error loading filter characteristics: $e');
      _loadingCharacteristics = false;
      notifyListeners();
    }
  }
  
  // Methods for My Items Screen
  
  // Load items for specific user
  Future<void> loadUserItems(int studentId, {String? type = 'lost'}) async {
    _isLoadingUserItems = true;
    _userItemsError = null;
    notifyListeners();
    
    try {
      // Use the _getMyItemsByStudentId method from ItemService
      _userItems = await _itemService.getMyItemsByStudentId(studentId, type ?? 'lost');
      
      _isLoadingUserItems = false;
      notifyListeners();
    } catch (e) {
      _userItemsError = e.toString();
      _isLoadingUserItems = false;
      notifyListeners();
    }
  }
  
  // Methods for Item Details Screen
  
  // Load details for a specific item
  Future<void> loadItemDetails(int itemId) async {
    _isLoadingItemDetails = true;
    _itemDetailsError = null;
    _currentItem = null;
    notifyListeners();
    
    try {
      final item = await _itemService.getItemById(itemId);
      _currentItem = item;
      _isLoadingItemDetails = false;
      notifyListeners();
    } catch (e) {
      _itemDetailsError = e.toString();
      _isLoadingItemDetails = false;
      notifyListeners();
    }
  }
  
  // Update an existing item
  Future<void> updateItem({
    required int itemId,
    String? name,
    String? description,
    int? categoryId,
    int? colorId,
    int? locationId,
    File? imageFile,
    String? type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print(name);
      print(description);
      print(categoryId);
      print(colorId);
      print(locationId);
      print(imageFile);
      _statusMessage = await _itemService.updateItem(
        id: itemId,
        name: name,
        description: description,
        categoryId: categoryId,
        colorId: colorId,
        locationId: locationId,
        imageFile: imageFile,
        type: type,
      );
      
      // Reload the item details to get the updated information
      await loadItemDetails(itemId);
      
      // If the item is in the user items list, update it there as well
      final index = _userItems.indexWhere((item) => item.id == itemId);
      if (index != -1 && _currentItem != null) {
        _userItems[index] = _currentItem!;
        notifyListeners();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(int itemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statusMessage = await _itemService.deleteItem(itemId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      // Rethrow the exception so it can be caught in my_item_details_screen
      rethrow;
    } 
  }
  
  // Helper methods
  
  // Get filtered user items by type
  List<Item> getUserItemsByType(String type) {
    return _userItems.where((item) => item.type == type).toList();
  }
  
  // Helper methods for characteristics
  String getCategoryName(int id) {
    final category = _categories.firstWhere(
      (c) => c.id == id, 
      orElse: () => Characteristic(id: id, name: 'Unknown')
    );
    return category.name;
  }
  
  String getColorName(int id) {
    final color = _colors.firstWhere(
      (c) => c.id == id, 
      orElse: () => Characteristic(id: id, name: 'Unknown')
    );
    return color.name;
  }
  
  String getLocationName(int id) {
    final location = _locations.firstWhere(
      (l) => l.id == id, 
      orElse: () => Characteristic(id: id, name: 'Unknown')
    );
    return location.name;
  }
  
  // Methods for Potential Matches
  Future<void> loadPotentialMatches(int lostItemId) async {
    _isLoadingPotentialMatches = true;
    _potentialMatchesError = null;
    notifyListeners();
    
    try {
      _potentialMatches = await _itemService.getPotentialMatches(lostItemId);
      _isLoadingPotentialMatches = false;
      notifyListeners();
    } catch (e) {
      _potentialMatchesError = e.toString();
      _isLoadingPotentialMatches = false;
      notifyListeners();
    }
  }
  
  // Methods for Claims
  Future<void> loadStudentClaims(int studentId) async {
    _isLoadingClaims = true;
    _claimsError = null;
    notifyListeners();
    
    try {
      _claims = await _claimService.getStudentClaims(studentId);
      _isLoadingClaims = false;
      notifyListeners();
    } catch (e) {
      _claimsError = e.toString();
      _isLoadingClaims = false;
      notifyListeners();
    }
  }
  
  Future<void> loadLostItemClaims(int studentId, int lostItemId) async {
    _isLoadingClaims = true;
    _claimsError = null;
    notifyListeners();
    
    try {
      _claimsByMatch = await _itemService.getStudentClaimsByPotentialMatches(studentId, lostItemId);
      _isLoadingClaims = false;
      notifyListeners();
    } catch (e) {
      _claimsError = e.toString();
      _isLoadingClaims = false;
      notifyListeners();
    }
  }
}