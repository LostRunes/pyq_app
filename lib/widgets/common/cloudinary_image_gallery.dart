import 'package:flutter/material.dart';

String optimizedImage(String url, {int width = 800}) {
  return url.replaceFirst(
    '/upload/',
    '/upload/w_$width,q_auto,f_webp/',
  );
}

class CloudinaryImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;

  const CloudinaryImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];
          return GestureDetector(
            onTap: () {
              // Full-screen image viewer with zoom/pan
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.zero,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      InteractiveViewer(
                        child: Image.network(
                          imageUrl, // Load higher-quality/original for fullscreen
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  optimizedImage(imageUrl, width: 800), // Automatically optimize!
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
