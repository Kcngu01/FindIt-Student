import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? placeholderPath;
  final String imageType;
  
  const ZoomableImageViewer({
    Key? key,
    required this.imageUrl,
    this.placeholderPath,
    required this.imageType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Image Viewer', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          tightMode: true,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, event) => Center(
            child: Container(
              width: 60.0,
              height: 60.0,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 100),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64.0,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Helper method to show the zoomable image viewer
void showZoomableImage(BuildContext context, String imageUrl, String imageType) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ZoomableImageViewer(
        imageUrl: imageUrl,
        imageType: imageType,
        placeholderPath: 'images/placeholder.png',
      ),
    ),
  );
} 