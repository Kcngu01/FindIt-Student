import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../services/claim_service.dart';
import '../providers/login_provider.dart';
import '../config/api_config.dart';
import 'claim_details_screen.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  _ClaimsScreenState createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  final ClaimService _claimService = ClaimService();
  bool _isLoading = false;
  String? _error;
  List<Claim> _claims = [];

  @override
  void initState() {
    super.initState();
    
    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadClaims();
      }
    });
  }

  Future<void> _loadClaims() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final studentId = loginProvider.student?.id;
    
    if (studentId == null) {
      setState(() {
        _error = 'You must be logged in to view your claims';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final claims = await _claimService.getStudentClaims(studentId);
      
      if (mounted) {
        setState(() {
          _claims = claims;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading claims: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load claims: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
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
        title: const Text('My Claims'),
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
                        onPressed: _loadClaims,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _claims.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No claims found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You haven\'t made any claims yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _claims.length,
                      itemBuilder: (context, index) {
                        final claim = _claims[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/claim_details',
                              arguments: claim.id,
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Image
                                if (claim.image.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                      child: FadeInImage.assetNetwork(
                                        placeholder: 'images/placeholder.png',
                                        image: ApiConfig.getItemImageUrl(claim.image, 'found'),
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
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Center(
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
                                
                                // Item Details
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        claim.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Claim Date: ${_formatDate(claim.createdAt)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(claim.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _getStatusColor(claim.status),
                                              ),
                                            ),
                                            child: Text(
                                              claim.status.toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(claim.status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 