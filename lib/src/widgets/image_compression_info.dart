import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

class ImageCompressionInfo extends StatelessWidget {
  final File? originalImage;
  final File? compressedImage;
  final Function(bool)? onToggleCompression;
  final bool isCompressed;
  final bool showToggle;

  const ImageCompressionInfo({
    super.key,
    required this.originalImage,
    this.compressedImage,
    this.onToggleCompression,
    this.isCompressed = false,
    this.showToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (originalImage == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<int>(
      future: originalImage!.length(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final originalSize = snapshot.data!;
        final bool isLarge = originalSize > ImageService.maxFileSize;

        if (!isLarge && compressedImage == null) {
          return const SizedBox.shrink(); // Don't show anything if image is small and not compressed
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isLarge ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: isLarge ? Colors.amber.shade800 : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLarge 
                          ? 'Your image is larger than 2MB' 
                          : 'Image size is acceptable',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLarge ? Colors.amber.shade800 : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Original image size: ${_formatFileSize(originalSize)}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (compressedImage != null)
                  FutureBuilder<int>(
                    future: compressedImage!.length(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text(
                          'Compressed image size: Calculating...',
                          style: TextStyle(fontSize: 12),
                        );
                      }
                      
                      final compressedSize = snapshot.data!;
                      final savings = originalSize - compressedSize;
                      final savingsPercent = (savings / originalSize * 100).round();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compressed image size: ${_formatFileSize(compressedSize)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Space saved: ${_formatFileSize(savings)} ($savingsPercent%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (isLarge && showToggle)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Your image will be automatically compressed to under 5MB before upload to meet server requirements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
} 