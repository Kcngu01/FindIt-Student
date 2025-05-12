import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/characteristic.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/login_provider.dart';
import '../services/item_service.dart';
import 'edit_item_screen.dart';

class MyItemDetailsScreen extends StatefulWidget {
  final int itemId;

  const MyItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  @override
  _MyItemDetailsScreenState createState() => _MyItemDetailsScreenState();
}

class _MyItemDetailsScreenState extends State<MyItemDetailsScreen> {
  final ItemService _itemService = ItemService();
  Characteristic? _category;
  Characteristic? _color;
  Characteristic? _location;

  bool _loadingAdditionalDetails = false;
  String? _errorLoadingDetails;

  @override
  void initState() {
    super.initState();

    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadItemDetails();
      }
    });
  }

  // Load the item details sequentially with proper error handling
  Future<void> _loadItemDetails() async {
    try {
      // First, load the base item information
      await Provider.of<ItemProvider>(context, listen: false)
          .loadItemDetails(widget.itemId);

      // Then, load additional details if item was loaded successfully
      if (mounted) {
        await _loadAdditionalDetails();
      }
    } catch (e) {
      print('Error in item details loading sequence: $e');
      // Error is already handled in the provider
    }
  }

  Future<void> _loadAdditionalDetails() async {
    if (!mounted) return;

    setState(() {
      _loadingAdditionalDetails = true;
      _errorLoadingDetails = null;
    });

    try {
      // Get the item from provider
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final item = itemProvider.currentItem;

      // Check if the item exists before proceeding
      if (item == null) {
        setState(() {
          _errorLoadingDetails = 'Item not available';
          _loadingAdditionalDetails = false;
        });
        return;
      }

      // Load all the related data in parallel with proper error handling
      final results = await Future.wait<dynamic>([
        _itemService.getCategoryById(item.categoryId).catchError((e) {
          print('Error loading category: $e');
          return null;
        }),
        _itemService.getColorById(item.colorId).catchError((e) {
          print('Error loading color: $e');
          return null;
        }),
        _itemService.getLocationById(item.locationId).catchError((e) {
          print('Error loading location: $e');
          return null;
        }),
      ]);

      if (mounted) {
        setState(() {
          _category = results[0] as Characteristic?;
          _color = results[1] as Characteristic?;
          _location = results[2] as Characteristic?;
          _loadingAdditionalDetails = false;
        });
      }
    } catch (e) {
      print('Error loading additional details: $e');
      if (mounted) {
        setState(() {
          _errorLoadingDetails = 'Failed to load item details: $e';
          _loadingAdditionalDetails = false;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    try {
      // Show confirmation dialog before deleting
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ) ?? false;
      
      // If user cancels, don't proceed with deletion
      if (!confirmDelete) {
        return;
      }
      
      await Provider.of<ItemProvider>(context, listen: false).deleteItem(widget.itemId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
      // Add a slight delay before navigation to ensure the user sees the message
      await Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamed(context, '/my_items');
        }
      });
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }
  
  // Future<void> _claimItem() async {
  //   try {
  //     final loginProvider = Provider.of<LoginProvider>(context, listen: false);
  //     final currentStudentId = loginProvider.student?.id;

  //     if (currentStudentId == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //             content: Text('You must be logged in to claim an item')),
  //       );
  //       return;
  //     }

  //     await _itemService.claimItem(widget.itemId, currentStudentId);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Item claimed successfully')),
  //     );

  //     // Refresh the item details
  //     _loadItemDetails();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to claim item: $e')),
  //     );
  //   }
  // }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        final item = itemProvider.currentItem;
        final isLoading = itemProvider.isLoadingItemDetails;
        final errorMessage = itemProvider.itemDetailsError;

        return Scaffold(
          appBar: AppBar(
            title: Text(item?.name ?? 'Item Details'),
            leading: BackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage))
                  : item != null
                      ? _buildItemDetails(item)
                      : const Center(child: Text('Item not found')),
        );
      },
    );
  }

  Widget _buildItemDetails(Item item) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image with placeholder and FadeInImage for smoother loading
            Center(
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: item.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: FadeInImage.assetNetwork(
                          placeholder:
                              'images/placeholder.png', // Add a placeholder image to your assets
                          image:
                              ApiConfig.getItemImageUrl(item.image!, item.type),
                          fit: BoxFit.contain,
                          imageErrorBuilder: (context, error, stackTrace) {
                            print("Image error: $error");
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          fadeInDuration: const Duration(milliseconds: 300),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Section
            const Text(
              'Descriptions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description ?? 'No description provided',
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
            const Divider(height: 32),

            // Loading indicator for characteristics if they're still loading
            if (_loadingAdditionalDetails)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading details...'),
                  ],
                ),
              ),

            // Error message if characteristics failed to load
            if (_errorLoadingDetails != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(height: 8),
                    Text(_errorLoadingDetails!,
                        style: TextStyle(color: Colors.red)),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadAdditionalDetails,
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              ),

            // Item information sections in rows
            if (!_loadingAdditionalDetails && _errorLoadingDetails == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Characteristics row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoSection(
                          title: 'Category',
                          value: _category?.name ?? 'Unknown',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoSection(
                          title: 'Color',
                          value: _color?.name ?? 'Unknown',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type and Status row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoSection(
                          title: 'Type',
                          value:
                              item.type == 'found' ? 'Found Item' : 'Lost Item',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoSection(
                          title: 'Status',
                          value: item.status ?? 'Unknown',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location and Date row
                  _buildInfoSection(
                    title: 'Location',
                    value: _location?.name ?? 'Unknown',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: 'Date Reported',
                    value: _formatDate(item.createdAt),
                  ),
                  const Divider(height: 32),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to edit screen
                            Navigator.pushNamed(
                              context,
                              '/edit_item',
                              arguments: item.id,
                            )
                                .then((_) {
                              // Refresh item details when we return from edit screen
                              _loadItemDetails();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Edit Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: item.type == 'found' ? _deleteItem : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Delete Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
