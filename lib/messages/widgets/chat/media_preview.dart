import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/widgets/common/loading_states.dart';
import 'package:campus_conn/messages/widgets/common/message_timestamp.dart';

/// A beautiful media preview component for images in messages
class MediaPreview extends StatefulWidget {
  /// URL of the media
  final String url;

  /// Caption text (optional)
  final String? caption;

  /// Border radius
  final BorderRadius borderRadius;

  /// Message timestamp (optional)
  final DateTime? timestamp;

  /// Whether this message is sent by the current user
  final bool isMe;

  /// Maximum height constraint
  final double maxHeight;

  /// Constrain width to maxWidth or let it expand to fit content
  final bool constrainWidth;

  /// On tap callback
  final VoidCallback? onTap;

  /// Constructor
  const MediaPreview({
    Key? key,
    required this.url,
    this.caption,
    required this.borderRadius,
    this.timestamp,
    this.isMe = true,
    this.maxHeight = 300,
    this.constrainWidth = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          () {
            // Open image in full screen viewer
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => _FullScreenImageViewer(
                  imageUrl: widget.url,
                  caption: widget.caption,
                ),
              ),
            );
          },
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            // Main image
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.maxHeight,
                maxWidth: widget.constrainWidth
                    ? MediaQuery.of(context).size.width * 0.65
                    : double.infinity,
              ),
              child: CachedNetworkImage(
                imageUrl: widget.url,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return AspectRatio(
                    aspectRatio: 4 / 3,
                    child: MessageLoadingStates.mediaLoading(),
                  );
                },
                errorWidget: (context, url, error) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                  return _buildErrorWidget();
                },
                imageBuilder: (context, imageProvider) {
                  // Schedule state update after current build is complete
                  if (_isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                        _controller.forward();
                      }
                    });
                  }

                  return FadeTransition(
                    opacity: _animation,
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),

            // Overlay with timestamp and caption at bottom
            if (widget.timestamp != null || widget.caption != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Caption
                      if (widget.caption != null && widget.caption!.isNotEmpty)
                        Expanded(
                          child: Text(
                            widget.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Timestamp
                      if (widget.timestamp != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MessageTimestamp(
                              timestamp: widget.timestamp!,
                              color: Colors.white.withOpacity(0.9),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            // Read status if sender
                            if (widget.isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all,
                                size: 12,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load image',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full screen image viewer
class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? caption;

  const _FullScreenImageViewer({
    required this.imageUrl,
    this.caption,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: widget.caption != null && widget.caption!.isNotEmpty
              ? Text(
                  widget.caption!,
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        body: GestureDetector(
          onTap: () {
            _controller.reverse().then((_) {
              Navigator.pop(context);
            });
          },
          child: Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 32),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
