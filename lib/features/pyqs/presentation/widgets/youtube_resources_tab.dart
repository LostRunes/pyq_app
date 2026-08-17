import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class YoutubeResourcesTab extends StatelessWidget {
  final List<String> ytLinks;

  const YoutubeResourcesTab({super.key, required this.ytLinks});

  String? _extractVideoId(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.group(2) != null && match.group(2)!.length == 11) {
      return match.group(2);
    }
    return null;
  }

  String? _extractPlaylistId(String url) {
    final regExp = RegExp(r'[&?]list=([^#\&\?]+)');
    final match = regExp.firstMatch(url);
    if (match != null && match.group(1) != null) {
      return match.group(1);
    }
    return null;
  }

  void _launchVideo(BuildContext context, String url, bool isPlaylist, int index) {
    Navigator.pushNamed(
      context,
      '/youtube_resource',
      arguments: {
        'url': url,
        'title': isPlaylist ? 'Lecture Playlist #${index + 1}' : 'Lecture Video #${index + 1}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: ytLinks.length,
        itemBuilder: (context, index) {
          final url = ytLinks[index];
          final videoId = _extractVideoId(url);
          final playlistId = _extractPlaylistId(url);
          final isPlaylist = playlistId != null;
          final thumbnailUrl = videoId != null
              ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
              : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 1,
              ),
            ),
            color: isDark ? const Color(0xFF1F1B3E) : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _launchVideo(context, url, isPlaylist, index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (thumbnailUrl != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.video_library,
                                    size: 48,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPlaylist ? Icons.featured_play_list_outlined : Icons.video_library_outlined,
                              size: 44,
                              color: Colors.redAccent,
                            ),
                            if (isPlaylist) ...[
                              const SizedBox(width: 10),
                              Text(
                                "PLAYLIST",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPlaylist ? 'Lecture Playlist #${index + 1}' : 'Lecture Video #${index + 1}',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          url,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
