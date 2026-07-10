import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    final urlWithAuth = _appendAuthUser(url);
    try {
      launchUrl(
        Uri.parse(urlWithAuth),
        mode: LaunchMode.inAppBrowserView,
      ).then((launched) {
        if (!launched) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not open handout link.')),
          );
        }
      }).catchError((e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error opening handout link: $e')),
        );
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error opening handout link: $e')),
      );
    }
  }

  static String _appendAuthUser(String url) {
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null || email.isEmpty) return url;
      
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['authuser'] = email;
      
      return uri.replace(queryParameters: queryParams).toString();
    } catch (_) {
      return url;
    }
  }
}
