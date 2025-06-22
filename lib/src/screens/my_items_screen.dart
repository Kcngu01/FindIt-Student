import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/login_provider.dart';
import '../providers/item_provider.dart';
import '../services/item_service.dart';
import '../config/api_config.dart';

class MyItemsScreen extends StatefulWidget {
  final bool isInTabNavigator;

  const MyItemsScreen({
    super.key,
    this.isInTabNavigator = false,
  });

  @override
  _MyItemsScreenState createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> with AutomaticKeepAliveClientMixin {
  final ItemService _itemService = ItemService();
  String _filterType = 'lost'; // Default filter type: 'lost' or 'found'
  bool _isFirstLoad = true;
  bool _isVisible = false;

  @override
  bool get wantKeepAlive => true; // Keep the state when switching tabs

  @override
  void initState() {
    super.initState();
    
    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isFirstLoad = false;
        _loadMyItems();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if this screen is currently visible
    final bool isCurrentlyVisible = ModalRoute.of(context)?.isCurrent ?? false;
    
    // If the screen becomes visible and wasn't visible before, reload data
    if (isCurrentlyVisible && !_isVisible && !_isFirstLoad) {
      _isVisible = true;
      
      // Use post-frame callback to avoid build-time state changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadMyItems();
        }
      });
    } 
    
    // else if block runs when the user navigates away from this screen to another screen
    // This allows the component to track when the user has left the screen, updating the internal visibility state accordingly.
    // If the screen is no longer visible (!isCurrentlyVisible) but was visible before (_isVisible), it updates the visibility state to false
    else if (!isCurrentlyVisible && _isVisible) {
      _isVisible = false;
    }
  }

  // Load items belonging to the current user using ItemProvider
  void _loadMyItems() {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final studentId = loginProvider.student?.id;
    
    if (studentId == null) {
      // Handle the case where user is not logged in
      return;
    }
    
    // Use ItemProvider to load user's items
    Provider.of<ItemProvider>(context, listen: false).loadUserItems(studentId, type:_filterType);
  }

  // Update filter type and reload items
  void _updateFilterType(String type) {
    if (_filterType != type) {
      setState(() {
        _filterType = type;
      });
    }
    _loadMyItems();
  }

  // Get image URL for an item
  String? _getItemImageUrl(Item item) {
    if (item.image == null || item.image!.isEmpty) {
      return null;
    }
    
    return ApiConfig.getItemImageUrl(item.image!, item.type);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Item'),
        leading: widget.isInTabNavigator 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          // Lost/Found toggle buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateFilterType('lost'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _filterType == 'lost' ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: _filterType == 'lost'
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Lost',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _filterType == 'lost' ? Colors.black : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateFilterType('found'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _filterType == 'found' ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: _filterType == 'found'
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Found',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _filterType == 'found' ? Colors.black : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Item list
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, itemProvider, child) {
                // Get filtered items by type
                final filteredItems = itemProvider.userItems;
                
                if (itemProvider.isLoadingUserItems) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (itemProvider.userItemsError != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(itemProvider.userItemsError!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMyItems,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_filterType == 'lost' ? 'lost' : 'found'} items',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/my_item_details',
                          arguments: item.id,
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item image
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8.0),
                                  bottomLeft: Radius.circular(8.0),
                                ),
                                image: _getItemImageUrl(item) != null
                                    ? DecorationImage(
                                        image: NetworkImage(_getItemImageUrl(item)!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _getItemImageUrl(item) == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.image, size: 40, color: Colors.grey),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No Image',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            
                            // Item details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 6.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(16.0),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      item.description ?? 'No description',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 