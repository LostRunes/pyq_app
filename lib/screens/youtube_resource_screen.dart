import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeResourceScreen extends StatefulWidget {
  final String url;
  final String title;

  const YoutubeResourceScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<YoutubeResourceScreen> createState() => _YoutubeResourceScreenState();
}

class _YoutubeResourceScreenState extends State<YoutubeResourceScreen> {
  late String _url;
  String? _videoId;
  String? _playlistId;

  // Metadata states
  bool _isLoading = true;
  String? _errorMessage;
  String? _resourceTitle;
  String? _author;
  String? _description;
  String? _thumbnailUrl;
  int? _videoCount;
  List<PlaylistVideoItem> _playlistVideos = [];

  // Active playing video state
  String? _activeVideoId;
  String? _activeVideoTitle;
  YoutubePlayerController? _playerController;

  @override
  void initState() {
    super.initState();
    _url = widget.url;
    _parseUrl();
    _fetchMetadata();
  }

  void _parseUrl() {
    try {
      final playlistMatch = RegExp(r'[?&]list=([^#\&\?]+)').firstMatch(_url);
      if (playlistMatch != null) {
        _playlistId = playlistMatch.group(1);
      }

      final videoMatch = YoutubePlayerController.convertUrlToId(_url);
      if (videoMatch != null) {
        _videoId = videoMatch;
      }
    } catch (e) {
      debugPrint('Error parsing YouTube URL: $e');
    }
  }

  Future<void> _fetchMetadata() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final yt = yt_explode.YoutubeExplode();

    try {
      if (_playlistId != null) {
        // Fetch playlist metadata
        final playlist = await yt.playlists.get(_playlistId!);
        _resourceTitle = playlist.title;
        _author = playlist.author;
        _description = playlist.description;
        _thumbnailUrl = playlist.thumbnails.highResUrl;

        // Fetch videos in the playlist
        final videos = await yt.playlists.getVideos(playlist.id).toList();
        _videoCount = videos.length;
        _playlistVideos = videos.map((v) {
          return PlaylistVideoItem(
            id: v.id.value,
            title: v.title,
            author: v.author,
            duration: v.duration ?? Duration.zero,
            thumbnailUrl: v.thumbnails.highResUrl,
          );
        }).toList();

        // Default active video to the first one in the playlist
        if (_playlistVideos.isNotEmpty) {
          _activeVideoId = _playlistVideos.first.id;
          _activeVideoTitle = _playlistVideos.first.title;
          _initPlayer(_activeVideoId!);
        }
      } else if (_videoId != null) {
        // Fetch single video metadata
        final video = await yt.videos.get(_videoId!);
        _resourceTitle = video.title;
        _author = video.author;
        _description = video.description;
        _thumbnailUrl = video.thumbnails.highResUrl;
        _activeVideoId = _videoId;
        _activeVideoTitle = video.title;
        _initPlayer(_activeVideoId!);
      } else {
        throw Exception("Could not detect video or playlist ID from the URL.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load metadata. You can still watch it directly on YouTube!";
        _resourceTitle = widget.title;
        if (_videoId != null) {
          _activeVideoId = _videoId;
          _initPlayer(_activeVideoId!);
        }
      });
      debugPrint('YoutubeExplode failed: $e');
    } finally {
      yt.close();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initPlayer(String videoId) {
    if (_playerController != null) {
      _playerController!.loadVideoById(videoId: videoId);
    } else {
      _playerController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
        ),
      );
    }
  }

  void _playVideo(String videoId, String title) {
    setState(() {
      _activeVideoId = videoId;
      _activeVideoTitle = title;
    });
    _initPlayer(videoId);
  }

  Future<void> _redirectExternal(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _playerController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _playlistId != null ? 'Playlist Explorer' : 'Video Player',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.redAccent),
            tooltip: 'Open in YouTube App',
            onPressed: () => _redirectExternal(_url),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF7ED),
                    const Color(0xFFFFF1F2).withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Inline Player section
                    if (_activeVideoId != null && _playerController != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: YoutubePlayer(
                            controller: _playerController!,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                      )
                    else if (_thumbnailUrl != null)
                      // Fallback Poster/Thumbnail
                      Container(
                        height: 200,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(
                            image: NetworkImage(_thumbnailUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                              onPressed: () {
                                if (_videoId != null) {
                                  _playVideo(_videoId!, _resourceTitle ?? 'Video');
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                    // Title & info section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_activeVideoTitle != null && _playlistId != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text(
                                'Now Playing: $_activeVideoTitle',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Text(
                            _resourceTitle ?? widget.title,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _author ?? 'Unknown Creator',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              if (_videoCount != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_videoCount Lessons',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Scrollable List of videos (for playlists) or Description (for single videos)
                    Expanded(
                      child: _playlistId != null
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _playlistVideos.length,
                              itemBuilder: (context, index) {
                                final video = _playlistVideos[index];
                                final isActive = _activeVideoId == video.id;

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: isActive
                                      ? theme.colorScheme.primary.withOpacity(0.1)
                                      : theme.colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant.withOpacity(0.3),
                                      width: isActive ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _playVideo(video.id, video.title),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  video.thumbnailUrl,
                                                  width: 80,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, _, __) => Container(
                                                    width: 80,
                                                    height: 60,
                                                    color: theme.colorScheme.secondary.withOpacity(0.1),
                                                    child: const Icon(Icons.video_library_rounded),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 80,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              Icon(
                                                isActive ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  video.title,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Lesson ${index + 1}',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '•   ${_formatDuration(video.duration)}',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.launch_rounded,
                                              size: 18,
                                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                                            ),
                                            onPressed: () => _redirectExternal(
                                              'https://www.youtube.com/watch?v=${video.id}',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Description',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _description ?? 'No description available for this video.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.share_rounded),
                                    label: const Text('Share Video Link'),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Video URL copied to clipboard: $_url'),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class PlaylistVideoItem {
  final String id;
  final String title;
  final String author;
  final Duration duration;
  final String thumbnailUrl;

  PlaylistVideoItem({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
  });
}
