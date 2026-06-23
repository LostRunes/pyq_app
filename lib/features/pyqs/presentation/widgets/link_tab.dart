import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/pdf_viewer_screen.dart';

class LinkTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final String? link;
  final String imagePath;
  final String subjectName;

  const LinkTab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    this.link,
    required this.imagePath,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(32.0),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 180),
              const SizedBox(height: 32),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (link != null && link!.isNotEmpty)
                      ? () {
                          openCourseHandout(context, link!, subjectName);
                        }
                      : null,
                  icon: Icon(icon),
                  label: Text(buttonLabel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void openCourseHandout(BuildContext context, String url, String title) {
    if (url.contains("drive.google.com")) {
      String? id;
      final fileIdRegExp = RegExp(r'/file/d/([^/]+)');
      final match = fileIdRegExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        id = match.group(1);
      } else {
        final idRegExp = RegExp(r'[?&]id=([^&]+)');
        final matchId = idRegExp.firstMatch(url);
        if (matchId != null && matchId.groupCount >= 1) {
          id = matchId.group(1);
        }
      }
      if (id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: "https://drive.google.com/uc?export=download&id=$id",
              title: title,
              webViewLink: url,
            ),
          ),
        );
        return;
      }
    }

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((
      e,
    ) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open handout link: $e')),
        );
      }
      return false;
    });
  }
}
