import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/claim.dart';
import '../services/claim_service.dart';
import '../widgets/zoomable_image_viewer.dart';

class ClaimDetailsScreen extends StatefulWidget {
  final int claimId;
  final String? similarityScore;
  final bool fromMyItemDetails;

  const ClaimDetailsScreen({
    super.key,
    required this.claimId,
    this.similarityScore,
    this.fromMyItemDetails = false,
  });

  @override
  _ClaimDetailsScreenState createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  final ClaimService _claimService = ClaimService();
  bool _isLoading = true;
  String? _error;
  Claim? _claim;

  @override
  void initState() {
    super.initState();
    
    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadClaimDetails();
      }
    });
  }

  Future<void> _loadClaimDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final claim = await _claimService.getClaimDetails(widget.claimId);
      
      if (mounted) {
        setState(() {
          _claim = claim;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading claim details: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load claim details: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('M/d/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Details'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClaimDetails,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _claim == null
                  ? const Center(child: Text('Claim not found'))
                  : _buildClaimDetails(),
    );
  }

  Widget _buildClaimDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Center(
              child: GestureDetector(
                onTap: _claim!.image.isNotEmpty ? () {
                  showZoomableImage(
                    context, 
                    ApiConfig.getItemImageUrl(_claim!.image, _claim!.type),
                    _claim!.type
                  );
                } : null,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _claim!.image.isNotEmpty
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Center(
                                child: FadeInImage.assetNetwork(
                                  placeholder: 'images/placeholder.png',
                                  image: ApiConfig.getItemImageUrl(_claim!.image, _claim!.type),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Similarity Score if available (from My Claims tab)
            if (widget.fromMyItemDetails && widget.similarityScore != null)
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
                  ],
                ),
              ),
            
            // Claim ID
            Center(
              child: Text(
                'Claim ID: ${_claim!.id}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Description
            _buildSectionHeader('Descriptions'),
            Text(
              _claim!.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            
            const Divider(),
            
            // Type and Status
            _buildRowSection(
              label1: 'Type',
              value1: _claim!.type,
              label2: 'Status',
              value2: _claim!.status,
              valueColor2: _getStatusColor(_claim!.status),
            ),
            
            const Divider(),
            
            // Category and Color
            _buildRowSection(
              label1: 'Category',
              value1: _claim!.category,
              label2: 'Color',
              value2: _claim!.color,
            ),
            
            const Divider(),
            
            // Date Reported and Date Requested
            _buildRowSection(
              label1: 'Date Reported',
              value1: _formatDate(_claim!.foundItemDate),
              label2: 'Date Requested',
              value2: _formatDate(_claim!.createdAt),
            ),
            
            const Divider(),
            
            // Location and Reviewed by
            _buildRowSection(
              label1: 'Location',
              value1: _claim!.location,
              label2: 'Reviewed by',
              value2: _claim!.adminName,
            ),
            
            const Divider(),
            
            // Claim Location (only for found items)
            if (_claim!.type == 'found' && _claim!.claimLocation != null && _claim!.claimLocation.isNotEmpty) ...[
              _buildSectionHeader('Claim Location (Faculty)'),
              Text(
                _claim!.claimLocation,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              const Divider(),
            ],
            
            // Reporter Contact
            _buildSectionHeader('Reporter Contact'),
            Text(
              _claim!.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            
            const Divider(),
            
            // Student Justification
            _buildSectionHeader('Student Justification'),
            Text(
              _claim!.studentJustification,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            
            const Divider(),
            
            // Admin Justification (if present)
            if (_claim!.adminJustification.isNotEmpty) ...[
              _buildSectionHeader('Admin Justification'),
              Text(
                _claim!.adminJustification,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              const Divider(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRowSection({
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    Color? valueColor1,
    Color? valueColor2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // First column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value1,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor1 ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          
          // Second column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor2 ?? Colors.grey[800],
                    fontWeight: valueColor2 != null ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 