import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String webViewLink;
  final bool preventDownload;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.webViewLink,
    this.preventDownload = false,
  });

  Future<void> _launchExternal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri url = Uri.parse(webViewLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open in browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: preventDownload
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.open_in_browser_rounded),
                  tooltip: 'Open in Browser',
                  onPressed: () => _launchExternal(context),
                ),
              ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.redAccent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image inside the app.',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!preventDownload) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _launchExternal(context),
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Open in Browser'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
