import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/characteristic.dart';
import '../models/claim.dart';
import '../models/claim_by_match.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/login_provider.dart';
import '../services/item_service.dart';
import 'edit_item_screen.dart';

class MyItemDetailsScreen extends StatefulWidget {
  final int itemId;
  final int? initialTabIndex;

  const MyItemDetailsScreen({
    super.key,
    required this.itemId,
    this.initialTabIndex,
  });

  @override
  _MyItemDetailsScreenState createState() => _MyItemDetailsScreenState();
}

class _MyItemDetailsScreenState extends State<MyItemDetailsScreen> with TickerProviderStateMixin {
  final ItemService _itemService = ItemService();
  Characteristic? _category;
  Characteristic? _color;
  Characteristic? _location;

  bool _loadingAdditionalDetails = false;
  String? _errorLoadingDetails;
  
  // Tab controller
  TabController? _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize selected tab index from widget parameter if provided
    if (widget.initialTabIndex != null) {
      _selectedTabIndex = widget.initialTabIndex!;
    }
    
    // We'll initialize the TabController once we know how many tabs we need
    // based on the item type
    
    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadItemDetails();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Initialize tab controller based on item type
  void _initTabController(String? itemType) {
    if (_tabController != null) {
      _tabController!.dispose();
    }
    
    // If item is lost, we need 3 tabs, otherwise just 1
    final tabCount = itemType == 'lost' ? 3 : 1;
    
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: _selectedTabIndex < tabCount ? _selectedTabIndex : 0,
    );
    
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController!.index;
        });
      }
    });
  }

  // Load the item details sequentially with proper error handling
  Future<void> _loadItemDetails() async {
    try {
      // First, load the base item information
      await Provider.of<ItemProvider>(context, listen: false)
          .loadItemDetails(widget.itemId);

      // Get the current item
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final item = itemProvider.currentItem;
      
      if (mounted) {
        // Initialize tab controller based on item type
        _initTabController(item?.type);
        
        // If item is lost, load additional data for the other tabs
        if (item?.type == 'lost') {
          // Load potential matches for the lost item
          itemProvider.loadPotentialMatches(widget.itemId);
          
          // Load claims for this lost item (instead of student claims)
          itemProvider.loadLostItemClaims(loginProvider.student?.id ?? 0, widget.itemId);
        }
      }

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
            bottom: _tabController != null && item?.type == 'lost' ? TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Item Details'),
                Tab(text: 'Potential Matches'),
                Tab(text: 'My Claims'),
              ],
            ) : null,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage))
                  : item != null
                      ? item.type == 'lost' && _tabController != null
                          ? TabBarView(
                              controller: _tabController,
                              children: [
                                _buildItemDetails(item),
                                _buildPotentialMatches(),
                                _buildMyClaims(),
                              ],
                            )
                          : _buildItemDetails(item)
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

  Widget _buildPotentialMatches() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoadingPotentialMatches) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (itemProvider.potentialMatchesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(itemProvider.potentialMatchesError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => itemProvider.loadPotentialMatches(widget.itemId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final matches = itemProvider.potentialMatches;
        
        if (matches.isEmpty) {
          return const Center(
            child: Text('No potential matches found for your item'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            // Use different status for demonstration (in a real app, would come from the API)
            // final statusOptions = ['Dismissed', 'Rejected', 'Pending'];
            // final status = statusOptions[index % statusOptions.length];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/potential_match_details',
                    arguments: {
                      'foundItemId': match.foundItemId,
                      'lostItemId': widget.itemId,
                      'tabIndex': _tabController?.index ?? 1,
                      'similarityScore': match.similarityScore,
                      'matchId': match.id,
                    },
                  );
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image placeholder
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: match.image != null && match.image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      ApiConfig.getItemImageUrl(match.image!, match.type),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Item details in a simple format
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  match.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  match.description ?? 'No description',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Similarity Score',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  match.similarityScore,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: match.matchStatus == 'pending' 
                              ? Colors.grey[300]
                              : match.matchStatus == 'rejected'
                                  ? Colors.red[100]
                                  : match.matchStatus == 'approved'
                                      ? Colors.green[100]
                                      : match.matchStatus == 'dismissed'
                                          ? Colors.orange[100]
                                          : match.matchStatus == 'available'
                                              ? Colors.blue[100]
                                              : Colors.grey[300], // available
                          borderRadius: BorderRadius.circular(12),
                        ),
                            child: Text(
                          match.matchStatus.substring(0, 1).toUpperCase() + match.matchStatus.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: match.matchStatus == 'pending' 
                                ? Colors.black87
                                : match.matchStatus == 'rejected'
                                    ? Colors.red[800]
                                    : match.matchStatus == 'approved'
                                        ? Colors.green[800]
                                        : match.matchStatus == 'dismissed'
                                            ? Colors.orange[800]
                                            : match.matchStatus == 'available'
                                              ? Colors.blue[800]
                                              : Colors.black87// available
                            ),
                          ),
                        ),
                      ),
                    ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyClaims() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoadingClaims) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (itemProvider.claimsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(itemProvider.claimsError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                    itemProvider.loadLostItemClaims(loginProvider.student?.id ?? 0, widget.itemId);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final claims = itemProvider.claimsByMatch;
        
        if (claims.isEmpty) {
          return const Center(
            child: Text('No claims have been submitted for this item'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (context, index) {
            final claim = claims[index];
            
            // Get colors and status text based on claim status
            Color statusBgColor;
            Color statusTextColor;
            
            switch (claim.status.toLowerCase()) {
              case 'approved':
                statusBgColor = Colors.green[100]!;
                statusTextColor = Colors.green[800]!;
                break;
              case 'rejected':
                statusBgColor = Colors.red[100]!;
                statusTextColor = Colors.red[800]!;
                break;
              case 'pending':
              default:
                statusBgColor = Colors.orange[100]!;
                statusTextColor = Colors.orange[800]!;
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to claim details with similarity score
                  Navigator.pushNamed(
                    context,
                    '/claim_details',
                    arguments: {
                      'claimId': claim.id,
                      'similarityScore': claim.similarityScore,
                      'fromMyItemDetails': true,
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Item image on the left
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: claim.image.isNotEmpty
                                  ? Image.network(
                                      ApiConfig.getItemImageUrl(claim.image, claim.type),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[400],
                                            size: 32,
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Claim details on the right
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status badge in the top right
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Claim ID',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        claim.status.substring(0, 1).toUpperCase() + claim.status.substring(1).toLowerCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  claim.id.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Name
                                Text(
                                  'Name',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  claim.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                
                                // Similarity Score
                                Text(
                                  'Similarity Score',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  claim.similarityScore,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Date Reported
                                Text(
                                  'Claim Date',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatDate(claim.createdAt), // Using reportDate instead of createdAt
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;
    
    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        text = 'Approved';
        break;
      case 'rejected':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      case 'pending':
      default:
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.hourglass_empty;
        text = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
