import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/drive_utils.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/pdf_viewer_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/image_viewer_screen.dart';
import '../providers/pyq_providers.dart';
import 'drive_file_tile.dart';

class DriveExplorerTab extends ConsumerStatefulWidget {
  final String title;
  final String? driveLink;

  const DriveExplorerTab({
    super.key,
    required this.title,
    required this.driveLink,
  });

  @override
  ConsumerState<DriveExplorerTab> createState() => _DriveExplorerTabState();
}

class _DriveExplorerTabState extends ConsumerState<DriveExplorerTab> {
  Future<void> openItem(Map item) async {
    final isFolder = item["mimeType"] == "application/vnd.google-apps.folder";

    if (isFolder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(
                item["name"],
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
            body: SafeArea(
              child: DriveExplorerTab(
                title: item["name"],
                driveLink: "https://drive.google.com/drive/folders/${item["id"]}",
              ),
            ),
          ),
        ),
      );
    } else {
      final fileId = item["id"] as String? ?? '';
      final name = item["name"] as String? ?? 'File';
      final mimeType = item["mimeType"] as String? ?? '';
      final webViewLink = item["webViewLink"] as String? ?? '';

      if (mimeType.contains("pdf") && fileId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: "https://drive.google.com/uc?export=download&id=$fileId",
              title: name,
              webViewLink: webViewLink,
            ),
          ),
        );
      } else if (mimeType.startsWith("image/") && fileId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(
              imageUrl: "https://drive.google.com/uc?export=view&id=$fileId",
              title: name,
              webViewLink: webViewLink,
            ),
          ),
        );
      } else {
        if (webViewLink.isNotEmpty) {
          final messenger = ScaffoldMessenger.of(context);
          final Uri url = Uri.parse(webViewLink);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not open the file link.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content;

    if (widget.driveLink == null || widget.driveLink!.isEmpty) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/owl.png', height: 130),
                const SizedBox(height: 16),
                Text(
                  "No Drive folder linked.",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final folderId = extractFolderId(widget.driveLink!);
      final filesAsync = ref.watch(driveFolderContentsProvider(folderId));

      content = filesAsync.when(
        data: (data) {
          final List<dynamic> sortedData = List<dynamic>.from(data)
            ..sort((a, b) {
              final aFolder = a["mimeType"] == "application/vnd.google-apps.folder";
              final bFolder = b["mimeType"] == "application/vnd.google-apps.folder";
              if (aFolder == bFolder) return 0;
              return aFolder ? -1 : 1;
            });

          if (sortedData.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/sleepy-shark.png', height: 130),
                    const SizedBox(height: 16),
                    Text(
                      "This folder is empty.",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final item = sortedData[index];
              return DriveFileTile(
                item: item,
                onTap: () => openItem(item),
              );
            },
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                "Fetching files from Google Drive...",
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/sad_raccoon.png', height: 130),
                  const SizedBox(height: 16),
                  Text(
                    "Something went wrong",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(driveFolderContentsProvider(folderId));
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.driveLink != null && widget.driveLink!.isNotEmpty) {
      final folderId = extractFolderId(widget.driveLink!);
      content = RefreshIndicator(
        onRefresh: () async {
          final _ = await ref.refresh(driveFolderContentsProvider(folderId).future);
        },
        child: content,
      );
    }

    return Container(
      decoration: isDark
          ? const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/darktheme_bg.png'),
                fit: BoxFit.cover,
              ),
            )
          : null,
      child: content,
    );
  }
}
