import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/characteristic.dart';
import '../services/item_service.dart';
import '../providers/login_provider.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/item_provider.dart';
import '../widgets/zoomable_image_viewer.dart';

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
  
  // Matching lost item for recovered found items
  Item? _matchingLostItem;
  bool _loadingMatchingItem = false;
  String? _errorLoadingMatchingItem;
  Characteristic? _matchingCategory;
  Characteristic? _matchingColor;
  Characteristic? _matchingLocation;
  String? _matchingReporterEmail;
  String? _similarityScore;

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
        
        // Load matching information for recovered found items
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        final item = itemProvider.currentItem;
        if (item != null && item.type == 'found' && item.status == 'resolved') {
          await _loadMatchingLostItem(item);
        }
      }
    } catch (e) {
      print('Error in item details loading sequence: $e');
      // Error is already handled in the provider
    }
  }
  
  // New method to load the matching lost item for a recovered found item
  Future<void> _loadMatchingLostItem(Item foundItem) async {
    if (!mounted) return;
    
    setState(() {
      _loadingMatchingItem = true;
      _errorLoadingMatchingItem = null;
    });
    
    try {
      print("Loading matching lost item for found item ID: ${foundItem.id}");
      
      // Get the matching lost item and similarity score
      final result = await _itemService.getMatchingLostItemWithScore(foundItem.id);
      
      // Debug prints to help diagnose the issue
      print("API Response: $result");
      
      final matchingItem = result['lost_item'] as Item?;
      final similarityScore = result['similarity_score'] as String?;
      
      print("Matching item: ${matchingItem?.name ?? 'null'}");
      print("Similarity score: ${similarityScore ?? 'null'}");
      
      if (matchingItem != null) {
        // Load the matching item's additional details
        final matchingCategory = await _itemService.getCategoryById(matchingItem.categoryId)
          .catchError((e) {
            print('Error loading matching category: $e');
            return Characteristic(id: -1, name: 'Unknown');
          });
            
        final matchingColor = await _itemService.getColorById(matchingItem.colorId)
          .catchError((e) {
            print('Error loading matching color: $e');
            return Characteristic(id: -1, name: 'Unknown');
          });
            
        final matchingLocation = await _itemService.getLocationById(matchingItem.locationId)
          .catchError((e) {
            print('Error loading matching location: $e');
            return Characteristic(id: -1, name: 'Unknown');
          });
            
        final matchingReporter = await _itemService.getStudentById(matchingItem.studentId)
          .catchError((e) {
            print('Error loading matching reporter: $e');
            return {'email': 'Unknown'};
          });
        
        if (mounted) {
          setState(() {
            _matchingLostItem = matchingItem;
            _matchingCategory = matchingCategory;
            _matchingColor = matchingColor;
            _matchingLocation = matchingLocation;
            _matchingReporterEmail = matchingReporter['email'];
            _similarityScore = similarityScore;
            _loadingMatchingItem = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _similarityScore = similarityScore;
            _loadingMatchingItem = false;
          });
        }
      }
    } catch (e) {
      print('Error loading matching lost item: $e');
      if (mounted) {
        setState(() {
          _errorLoadingMatchingItem = 'Failed to load matching lost item: $e';
          _loadingMatchingItem = false;
        });
      }
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
    // Check if this is a recovered found item (later used to decide whether to show claim button and matching lost item section)
    final isRecoveredFound = item.type == 'found' && item.status == 'resolved';
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image with placeholder and FadeInImage for smoother loading
            Center(
              child: GestureDetector(
                onTap: item.image != null ? () {
                  showZoomableImage(
                    context, 
                    ApiConfig.getItemImageUrl(item.image!, item.type),
                    item.type
                  );
                } : null,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: item.image != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Center(
                                child: FadeInImage.assetNetwork(
                                  placeholder: 'images/placeholder.png', // Add a placeholder image to your assets
                                  image: ApiConfig.getItemImageUrl(item.image!, item.type),
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
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
                              ),
                            ),
                            // Add a small zoom icon indicator
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
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
            ),
            const SizedBox(height: 16),
            
            // For recovered found items, show a recovered badge with similarity score
            if (isRecoveredFound && widget.similarityScore == null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
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
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recovered Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This item has been matched with its owner',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Add similarity score if available
                    // different from widget.similarityScore because this is for recovered found items
                    if (_similarityScore != null && _similarityScore!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.assessment, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Similarity Score:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _similarityScore!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Add a progress indicator based on the score percentage
                          Builder(
                            builder: (context) {
                              // Extract numeric value from score (removing '%' if present)
                              final scoreText = _similarityScore!;
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
                              
                              return LinearProgressIndicator(
                                value: scoreValue,
                                backgroundColor: Colors.grey[200],
                                color: Colors.green,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            
            // Display similarity score if available (for potential matches)
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
                  
                  // Action buttons (hide claim button for recovered items)
                  if (!isRecoveredFound && item.type=='found')
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
              
            // Matching Lost Item Section for recovered found items
            if (isRecoveredFound && widget.similarityScore == null) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Matched Lost Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_loadingMatchingItem)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Loading matching item...'),
                        ],
                      ),
                    )
                  else if (_errorLoadingMatchingItem != null)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(height: 8),
                          Text(_errorLoadingMatchingItem!, style: TextStyle(color: Colors.red)),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _loadMatchingLostItem(item),
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  else if (_matchingLostItem != null)
                    _buildMatchingItemDetails()
                  else
                    const Center(child: Text('No matching lost item found. The owner claim the item without reporting it as lost')),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  // New widget to show matching lost item details
  Widget _buildMatchingItemDetails() {
    if (_matchingLostItem == null) return const SizedBox.shrink();
    
    final lostItem = _matchingLostItem!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lost Item image
            if (lostItem.image != null)
              Center(
                child: GestureDetector(
                  onTap: () {
                    showZoomableImage(
                      context, 
                      ApiConfig.getItemImageUrl(lostItem.image!, lostItem.type),
                      lostItem.type
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Center(
                            child: Image.network(
                              ApiConfig.getItemImageUrl(lostItem.image!, lostItem.type),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print("Image error: $error");
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          )
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        )
                      ],
                    )
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Lost Item Name with Lost badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    lostItem.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LOST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lost Item Description
            Text(
              lostItem.description ?? 'No description provided',
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Lost Item Details grid
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoSection(
                        title: 'Category',
                        value: _matchingCategory?.name ?? 'Unknown',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoSection(
                        title: 'Color',
                        value: _matchingColor?.name ?? 'Unknown',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Location',
                  value: _matchingLocation?.name ?? 'Unknown',
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Reporter Email',
                  value: _matchingReporterEmail ?? 'Unknown',
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Date Reported',
                  value: _formatDate(lostItem.createdAt),
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