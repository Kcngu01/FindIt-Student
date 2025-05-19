import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/characteristic.dart';
import '../services/item_service.dart';
import '../providers/login_provider.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/item_provider.dart';

class ItemDetailsScreen extends StatefulWidget {
  final int itemId;
  final VoidCallback? onBack;
  final String? similarityScore;
  final int? matchId;
  final int? lostItemId;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
    this.onBack,
    this.similarityScore,
    this.matchId,
    this.lostItemId,
  });

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final ItemService _itemService = ItemService();
  Characteristic? _category;
  Characteristic? _color;
  Characteristic? _location;
  String? _reporterEmail;
  final TextEditingController _justificationController = TextEditingController();

  bool _loadingAdditionalDetails = false;
  String? _errorLoadingDetails;
  bool _hasClaimedItem = false;
  bool _checkingClaimStatus = false;

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

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  // Load the item details sequentially with proper error handling
  Future<void> _loadItemDetails() async {
    try {
      // First, load the base item information
      await Provider.of<ItemProvider>(context, listen: false).loadItemDetails(widget.itemId);
      
      // Then, load additional details if item was loaded successfully
      if (mounted) {
        await _loadAdditionalDetails();
        await _checkClaimStatus();
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
        _itemService.getCategoryById(item.categoryId)
            .catchError((e) {
              print('Error loading category: $e');
              return Characteristic(id: -1, name: 'Unknown');
            }),
        _itemService.getColorById(item.colorId)
            .catchError((e) {
              print('Error loading color: $e');
              return Characteristic(id: -1, name: 'Unknown');
            }),
        _itemService.getLocationById(item.locationId)
            .catchError((e) {
              print('Error loading location: $e');
              return Characteristic(id: -1, name: 'Unknown');
            }),
        _itemService.getStudentById(item.studentId)
            .catchError((e) {
              print('Error loading reporter: $e');
              return {'email': 'Unknown'};
            }),
      ]);
      
      if (mounted) {
        setState(() {
          _category = results[0] as Characteristic?;
          _color = results[1] as Characteristic?;
          _location = results[2] as Characteristic?;
          _reporterEmail = results[3] != null ? (results[3] as Map<String, dynamic>)['email'] as String? : null;
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

  // Check if current user has claimed this item
  Future<void> _checkClaimStatus() async {
    if (!mounted) return;
    
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final currentStudentId = loginProvider.student?.id;
    
    // If not logged in, we can't check claim status
    if (currentStudentId == null) {
      setState(() {
        _hasClaimedItem = false;
        _checkingClaimStatus = false;
      });
      return;
    }
    
    setState(() {
      _checkingClaimStatus = true;
    });
    
    try {
      final hasClaimed = await _itemService.hasClaimedItem(widget.itemId, currentStudentId);
      
      if (mounted) {
        setState(() {
          _hasClaimedItem = hasClaimed;
          _checkingClaimStatus = false;
        });
      }
    } catch (e) {
      print('Error checking claim status: $e');
      if (mounted) {
        setState(() {
          _hasClaimedItem = false;
          _checkingClaimStatus = false;
        });
      }
    }
  }

  Future<void> _claimItem() async {
    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final currentStudentId = loginProvider.student?.id;
      
      if (currentStudentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to claim an item')),
        );
        return;
      }
      
      // Check if user has already claimed this item
      if (_hasClaimedItem) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already claimed this item')),
        );
        return;
      }
      
      final TextEditingController justificationController = TextEditingController();
      String? justification = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          bool isJustificationValid = false;
          
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Justification'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Please provide a justification for claiming this item.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: justificationController,
                      decoration: InputDecoration(
                        hintText: 'Enter your justification here',
                        border: const OutlineInputBorder(),
                        errorText: justificationController.text.isEmpty && !isJustificationValid
                            ? 'Justification cannot be empty'
                            : null,
                      ),
                      maxLines: 4,
                      onChanged: (value) {
                        setState(() {
                          isJustificationValid = value.isNotEmpty;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (justificationController.text.isEmpty) {
                        setState(() {
                          isJustificationValid = false;
                        });
                      } else {
                        Navigator.of(context).pop(justificationController.text);
                      }
                    },
                    child: const Text('Claim'),
                  ),
                ],
              );
            }
          );
        },
      );

      if (justification != null && justification.isNotEmpty) {
        // If we have similarityScore, matchId, and lostItemId, this is a potential match claim
        if (widget.similarityScore != null && widget.matchId != null && widget.lostItemId != null) {
          await _itemService.claimMatchItem(
            foundItemId: widget.itemId,
            studentId: currentStudentId,
            matchId: widget.matchId!,
            lostItemId: widget.lostItemId!,
            status: 'pending',
            justification: justification,
          );
        } else {
          // Regular item claim if not from potential matches
          await _itemService.claimItem(
            itemId: widget.itemId, 
            studentId: currentStudentId, 
            status: 'pending', 
            justification: justification
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item claimed successfully')),
          );
        
          // Set claimed status to true and refresh the item details
          setState(() {
            _hasClaimedItem = true;
          });
          _loadItemDetails();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to claim item: $e')),
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
        
        return PopScope(
          canPop: widget.onBack == null,
          onPopInvoked: (didPop) {
            if (!didPop && widget.onBack != null) {
              widget.onBack!();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(item?.name ?? 'Item Details'),
              leading: BackButton(
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage))
                    : item != null 
                        ? _buildItemDetails(item) 
                        : const Center(child: Text('Item not found')),
          ),
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
                          placeholder: 'images/placeholder.png', // Add a placeholder image to your assets
                          image: ApiConfig.getItemImageUrl(item.image!, item.type),
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
            
            // Display similarity score immediately after the image if available
            if (widget.similarityScore != null)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assessment, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Similarity Score',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.similarityScore!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Add a progress indicator based on the score percentage
                        Builder(
                          builder: (context) {
                            // Extract numeric value from score (removing '%' if present)
                            final scoreText = widget.similarityScore!;
                            double scoreValue = 0.0;
                            
                            try {
                              // Try to parse the score value
                              if (scoreText.contains('%')) {
                                scoreValue = double.parse(scoreText.replaceAll('%', '').trim()) / 100;
                              } else {
                                scoreValue = double.parse(scoreText) / 100;
                              }
                              // Clamp value between 0 and 1
                              scoreValue = scoreValue.clamp(0.0, 1.0);
                            } catch (e) {
                              // Fallback to 0 if parsing fails
                              scoreValue = 0.0;
                            }
                            
                            // Determine color based on score
                            Color progressColor;
                            if (scoreValue >= 0.7) {
                              progressColor = Colors.green;
                            } else if (scoreValue >= 0.4) {
                              progressColor = Colors.orange;
                            } else {
                              progressColor = Colors.red;
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: scoreValue,
                                  backgroundColor: Colors.grey[200],
                                  color: progressColor,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      scoreValue >= 0.7 ? Icons.check_circle : 
                                      scoreValue >= 0.4 ? Icons.info : Icons.warning,
                                      color: progressColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      scoreValue >= 0.7 ? 'High match probability' : 
                                      scoreValue >= 0.4 ? 'Moderate match probability' : 'Low match probability',
                                      style: TextStyle(
                                        color: progressColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This indicates how closely this item matches your lost item',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                ],
              ),
            
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
              const Center(
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
                    Text(_errorLoadingDetails!, style: TextStyle(color: Colors.red)),
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
                          value: item.type == 'found' ? 'Found Item' : 'Lost Item',
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
                    title: 'Reporter Email',
                    value: _reporterEmail ?? 'Unknown',
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
                        width: 200,
                        child: ElevatedButton(
                          onPressed: (item.type == 'found' && !_hasClaimedItem && !_checkingClaimStatus) ? _claimItem : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              _hasClaimedItem ? 'Already Claimed' : 'Claim Item',
                              style: const TextStyle(
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