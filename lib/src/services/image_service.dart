import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class ImageService {
  /// Maximum file size in bytes (2MB)
  static const int maxFileSize = 2 * 1024 * 1024;

  /// Compress an image file if it exceeds the maximum file size (5MB)
  /// Returns the compressed file or the original file if it's already within the size limit
  static Future<File> compressImageIfNeeded(File imageFile) async {
    final int fileSize = await imageFile.length();
    
    // If the file is already smaller than the max size, return it as is
    if (fileSize <= maxFileSize) {
      return imageFile;
    }
    
    return await compressImage(imageFile);
  }

  /// Force compression of an image file
  /// This method always compresses the image regardless of its current size
  static Future<File> compressImage(File imageFile) async {
    final String fileName = path.basename(imageFile.path);
    final String fileExtension = path.extension(fileName).toLowerCase();
    
    // Get temp directory for storing compressed image
    final Directory tempDir = await path_provider.getTemporaryDirectory();
    final String targetPath = path.join(tempDir.path, 'compressed_$fileName');
    
    // Determine compression format based on file extension
    CompressFormat format;
    if (fileExtension == '.png') {
      format = CompressFormat.png;
    } else if (fileExtension == '.webp') {
      format = CompressFormat.webp;
    } else {
      format = CompressFormat.jpeg; // Default to JPEG for other formats
    }
    
    // Calculate initial quality value based on file size
    // Larger files get more aggressive compression
    int quality = _calculateInitialQuality(await imageFile.length());
    
    // Try to compress with the calculated quality
    File? compressedFile = await _compressWithQuality(imageFile, targetPath, quality, format);
    
    // If compression failed or file is still too large, try with lower quality
    if (compressedFile == null || await compressedFile.length() > maxFileSize) {
      // Try with progressively lower quality until we reach the target size
      compressedFile = await _compressToTargetSize(imageFile, targetPath, format);
    }
    
    return compressedFile ?? imageFile;
  }

  /// Calculate initial quality based on file size
  static int _calculateInitialQuality(int fileSize) {
    // For files just above the limit, use higher quality
    if (fileSize < maxFileSize * 1.2) {
      return 90;
    } 
    // For medium sized files
    else if (fileSize < maxFileSize * 2) {
      return 80;
    } 
    // For large files
    else if (fileSize < maxFileSize * 5) {
      return 70;
    } 
    // For very large files
    else {
      return 60;
    }
  }

  /// Try to compress with the given quality
  static Future<File?> _compressWithQuality(
    File imageFile, 
    String targetPath, 
    int quality, 
    CompressFormat format
  ) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        format: format,
        keepExif: false,
      );
      
      //although result return file type but may have exceptions, so to ensure that we always work with a Dart File object (from dart:io), hence we Explicitly reconstructs the File in case the original result has an unexpected type.
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Compress the image with progressively lower quality until it meets the size target
  static Future<File?> _compressToTargetSize(
    File imageFile, 
    String targetPath, 
    CompressFormat format
  ) async {
    // Start with quality 70 and decrease by 10 for each iteration
    for (int quality = 70; quality >= 10; quality -= 10) {
      final result = await _compressWithQuality(imageFile, targetPath, quality, format);
      
      // If compression succeeded and file is now within limits, return it
      if (result != null && await result.length() <= maxFileSize) {
        return result;
      }
    }
    
    // If we reached here, we couldn't compress to the target size
    // Try one final time with the minimum quality
    return await _compressWithQuality(imageFile, targetPath, 5, format);
  }
} 