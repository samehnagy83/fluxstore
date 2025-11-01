import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../common/config.dart' show kLoadingWidget;
import '../../../common/constants.dart';
import '../../../common/extensions/string_ext.dart';
import '../../../common/theme/index.dart';
import '../../../routes/flux_navigate.dart';
import '../../../screens/detail/widgets/video_placeholder.dart';
import '../../../services/index.dart';

class FeatureVideoPlayer extends StatefulWidget {
  final String url;
  final bool? autoPlay;
  final double? aspectRatio;
  final bool enableTimeIndicator;
  final bool tapToPlayPause;
  final bool holdToPlayPause;
  final bool isSoundOn;
  final bool isPlaying;
  final bool isFullScreen;
  final bool doubleTapToFullScreen;
  final Duration? startAt;
  final bool showVolumeButton;
  final bool showFullScreenButton;
  final FeatureVideoController? controller;
  final ValueChanged<int?>? durationCallback;
  final bool enableLoop;
  final bool showLoading;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final Color? backgroundColor;

  const FeatureVideoPlayer(
    this.url, {
    Key? key,
    this.autoPlay,
    this.aspectRatio,
    this.enableTimeIndicator = false,
    this.tapToPlayPause = true,
    this.holdToPlayPause = false,
    this.isSoundOn = false,
    this.isPlaying = false,
    this.doubleTapToFullScreen = false,
    this.startAt,
    this.showVolumeButton = false,
    this.showFullScreenButton = false,
    this.controller,
    this.durationCallback,
    this.enableLoop = true,
    this.showLoading = true,
    this.onStart,
    this.onEnd,
    this.backgroundColor,
  }) : isFullScreen = false;

  const FeatureVideoPlayer.fullScreen(
    this.url, {
    Key? key,
    this.autoPlay,
    this.aspectRatio,
    this.enableTimeIndicator = false,
    this.tapToPlayPause = true,
    this.holdToPlayPause = false,
    this.isSoundOn = false,
    this.isPlaying = false,
    this.doubleTapToFullScreen = false,
    this.startAt,
    this.showVolumeButton = false,
    this.showFullScreenButton = false,
    this.controller,
    this.durationCallback,
    this.enableLoop = false,
    this.showLoading = true,
    this.onStart,
    this.onEnd,
    this.backgroundColor,
  }) : isFullScreen = true;

  @override
  State<FeatureVideoPlayer> createState() => _FeatureVideoPlayerState();
}

class _FeatureVideoPlayerState extends State<FeatureVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  bool initialized = false;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  bool get isPlaying => _controller?.value.isPlaying ?? false;

  Duration? get videoDuration => _controller?.value.duration;

  double? aspectRatio;
  bool isSoundOn = false;
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  bool isVideoAvailable = true;

  YoutubePlayerController? _youtubeController;

  bool get isYoutube => widget.url.isYoutubeLink();
  bool get showVideoPlaceholder => isDesktop || ServerConfig().isBuilder;

  Timer? _timer;

  void _cancelTimer() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _cancelTimer();

    _timer = Timer(const Duration(milliseconds: 100), () async {
      if (isYoutube) {
        final playerState = await _youtubeController?.playerState;
        if (playerState == PlayerState.playing) {
          await _youtubeController?.pauseVideo();
        }
      } else {
        if (_controller?.value.isPlaying == true) {
          await _controller?.pause();
        }
      }
    });
  }

  Future<void> initVideoController() async {
    if (widget.url.startsWith('http')) {
      final uri = Uri.parse(widget.url);
      _controller = VideoPlayerController.networkUrl(uri);
    } else {
      _controller = VideoPlayerController.asset(widget.url);
    }

    await _controller?.initialize().then((value) {
      if (mounted) {
        // Ensure the first frame is shown after the video is initialized, even
        // before the play button has been pressed.
        setState(() {
          initialized = true;
        });
      }
    });
    widget.durationCallback?.call(_controller?.value.duration.inSeconds);
    await _controller?.setLooping(widget.enableLoop).then(
      (_) {
        if (mounted) {
          setState(() {
            initialized = true;
            aspectRatio = widget.aspectRatio ?? _controller?.value.aspectRatio;
          });
          if (widget.autoPlay == true && widget.startAt == null) {
            _controller?.play();
            return;
          }
          if (widget.startAt != null && widget.isPlaying) {
            _controller?.play();
          } else {
            _controller?.pause();
          }
        }
      },
    );
    await _controller?.seekTo(widget.startAt ?? Duration.zero);
    setVolume(widget.isSoundOn);
  }

  Future _togglePlayPause() async {
    if (!showVideoPlaceholder) {
      if (isYoutube) {
        var playerState = await _youtubeController?.playerState;

        if (playerState == PlayerState.playing) {
          await _youtubeController?.pauseVideo();
        } else {
          await _youtubeController?.playVideo();
        }
      } else {
        if (_controller?.value.isPlaying == true) {
          await _controller?.pause();
        } else {
          await _controller?.play();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    widget.controller?.togglePlayPause = _togglePlayPause;

    if (!showVideoPlaceholder) {
      if (isYoutube) {
        final videoId = YoutubePlayerController.convertUrlToId(widget.url);

        if (videoId == null) {
          isVideoAvailable = false;
          if (mounted) {
            setState(() {});
          }
          return;
        }

        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: widget.autoPlay ?? true,
          params: YoutubePlayerParams(
            showControls: false,
            strictRelatedVideos: true,
            pointerEvents: PointerEvents.none,
            loop: widget.enableLoop,
            showFullscreenButton: false,
            showVideoAnnotations: false,
            enableCaption: false,
          ),
        );

        widget.durationCallback
            ?.call(_youtubeController?.metadata.duration.inSeconds);
        return;
      }

      // Video player supports web version but I still disable it
      initVideoController();
      _controller?.addListener(_listener);
    }
  }

  void _listener() async {
    final currentPosition = _controller?.value.position;

    if (mounted) {
      if (isInitialized && currentPosition == Duration.zero && isPlaying) {
        widget.onStart?.call();
      }

      // Dont use `videoPlayerValue.isCompleted` because it does not update if video is looping
      if (isInitialized && currentPosition == videoDuration) {
        widget.onEnd?.call();
      }
    }
  }

  void setVolume(bool value) {
    if (mounted) {
      setState(() {
        isSoundOn = value;
      });
    }

    isSoundOn ? _controller?.setVolume(1.0) : _controller?.setVolume(0.0);
  }

  void setIsPlaying(bool status) {
    status == true ? _controller?.play() : _controller?.pause();
  }

  @override
  void dispose() {
    if (isYoutube) {
      _youtubeController?.close();
    } else {
      _controller?.removeListener(_listener);
      _controller?.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
  }

  void updateSystemUIOverlayStyle() {
    final isDarkTheme = widget.isFullScreen == true ||
        Theme.of(context).brightness == Brightness.dark;

    // If fullscreen video mode, always set light status bar
    context.updateSystemUiOverlay(isDarkTheme);
  }

  @override
  void didChangeDependencies() {
    updateSystemUIOverlayStyle();
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      updateSystemUIOverlayStyle();
    }
  }

  Widget playPauseButton(bool isPlaying) {
    return isPlaying
        ? const SizedBox.shrink()
        : Container(
            color: Colors.black26,
            child: const Center(
              child: Icon(
                CupertinoIcons.play_arrow_solid,
                color: Colors.white,
                size: 50.0,
                semanticLabel: 'Play',
              ),
            ),
          );
  }

  void updateVideoStatus() {
    if (widget.holdToPlayPause == false) {
      if (isYoutube) {
        // TODO: Implement for youtube
      } else {
        _controller?.value.isPlaying == true
            ? _controller?.pause()
            : _controller?.play();
      }
    }
  }

  void onTapVolume() {
    if (mounted) {
      setState(() {
        isSoundOn = !isSoundOn;
        // If the sound button is pressed, the video widget is also pressed (change isPlaying value)
        updateVideoStatus();
        isSoundOn ? _controller?.setVolume(1.0) : _controller?.setVolume(0.0);
      });
    }
  }

  void onTapFullScreen() async {
    // If fullScreen button is pressed, the video widget is also pressed (change isPlaying value)
    updateVideoStatus();

    final previousStatus = await FluxNavigate.push(
      MaterialPageRoute(
        builder: (_) => FeatureVideoPlayer.fullScreen(
          widget.url,
          isSoundOn: isSoundOn,
          isPlaying: _controller?.value.isPlaying == true,
          startAt: _controller?.value.position,
          aspectRatio: widget.aspectRatio,
          autoPlay: widget.autoPlay,
          enableTimeIndicator: widget.enableTimeIndicator,
          doubleTapToFullScreen: widget.doubleTapToFullScreen,
          showVolumeButton: widget.showVolumeButton,
          showFullScreenButton: widget.showFullScreenButton,
          holdToPlayPause: widget.holdToPlayPause,
          tapToPlayPause: widget.tapToPlayPause,
        ),
      ),
      context: context,
    );
    if (previousStatus != null) {
      setIsPlaying(previousStatus[0] ?? false);
      setVolume(previousStatus[2] ?? false);
      await _controller?.seekTo(previousStatus[1] ?? Duration.zero);
      updateSystemUIOverlayStyle();
    }
  }

  void onTapExitFullScreen() {
    // If the exit fullScreen button is pressed, the video widget is also pressed (change isPlaying value)
    updateVideoStatus();
    Navigator.pop(context,
        [_controller?.value.isPlaying, _controller?.value.position, isSoundOn]);
  }

  double _mathScale(Size size, double aspectRatio) {
    var maxH = 0.0;
    var maxW = 0.0;
    var minH = 0.0;
    var minW = 0.0;
    final sizeScreen = size;

    minH = sizeScreen.height;
    minW = minH * aspectRatio;
    maxW = sizeScreen.width;
    maxH = maxW / aspectRatio;

    if (minW > maxW) {
      final tempW = minW;
      minW = maxW;
      maxW = tempW;

      final tempH = minH;
      minH = maxH;
      maxH = tempH;
    }

    return maxH / minH;
  }

  @override
  Widget build(BuildContext context) {
    if (showVideoPlaceholder) {
      return const VideoPlaceholder();
    }

    if (!isVideoAvailable) {
      return VideoPlaceholder(message: S.of(context).canNotPlayVideo);
    }

    if (isYoutube == false) {
      final body = LayoutBuilder(
        builder: (_, constraints) {
          return VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo info) {
              if (info.visibleFraction == 0) {
                _controller?.pause();
              } else if (widget.autoPlay == true) {
                _controller?.play();
              }
            },
            key: ValueKey('mp4_player_iframe-${widget.url}'),
            child: Container(
              color: widget.backgroundColor ??
                  (widget.isFullScreen ? Colors.black : Colors.transparent),
              child: Center(
                child: Listener(
                  onPointerDown: (_) {
                    if (widget.holdToPlayPause) {
                      _startTimer();
                    }
                  },
                  onPointerUp: (_) {
                    var now = DateTime.now().millisecondsSinceEpoch;
                    if (widget.doubleTapToFullScreen) {
                      // https://api.flutter.dev/flutter/gestures/kDoubleTapTimeout-constant.html
                      if (now - lastTap < 300) {
                        _cancelTimer();
                        lastTap = now;
                        if (widget.isFullScreen) {
                          onTapExitFullScreen();
                        } else {
                          onTapFullScreen();
                        }
                        return;
                      }
                    }
                    if (widget.holdToPlayPause) {
                      _cancelTimer();
                      _controller?.play();
                    }
                    if (widget.tapToPlayPause) {
                      if (_controller?.value.isPlaying == true) {
                        _controller?.pause();
                      } else {
                        _controller?.play();
                      }
                    }
                    lastTap = now;
                  },
                  child: Stack(
                    children: [
                      if (isInitialized) ...[
                        Hero(
                          tag: 'video-$hashCode',
                          transitionOnUserGestures: true,
                          child: Builder(builder: (context) {
                            if (_controller!.value.aspectRatio > 0.6) {
                              return Center(
                                child: AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                ),
                              );
                            }

                            final failedLoadList = [null, double.infinity];
                            final size = MediaQuery.sizeOf(context);
                            final sizeScreen = Size(
                              failedLoadList.contains(constraints.maxWidth)
                                  ? size.width
                                  : constraints.maxWidth,
                              failedLoadList.contains(constraints.maxHeight)
                                  ? size.height
                                  : constraints.maxHeight,
                            );

                            final scaleVideo = _mathScale(
                              sizeScreen,
                              _controller!.value.aspectRatio,
                            );

                            return Center(
                              child: Transform.scale(
                                scale: scaleVideo,
                                child: AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (widget.tapToPlayPause && _controller != null)
                          ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _controller!,
                            builder: (context, value, child) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 50),
                                reverseDuration:
                                    const Duration(milliseconds: 200),
                                child: playPauseButton(
                                  value.isPlaying == true,
                                ),
                              );
                            },
                          ),
                        if (widget.enableTimeIndicator)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                            ),
                          ),
                        PositionedDirectional(
                          bottom: 0,
                          end: 0,
                          child: Row(
                            children: [
                              if (widget.showVolumeButton)
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: onTapVolume,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      isSoundOn
                                          ? Icons.volume_up
                                          : Icons.volume_off,
                                      color: Colors.white,
                                      size: 25.0,
                                    ),
                                  ),
                                ),
                              if (widget.showFullScreenButton)
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: widget.isFullScreen
                                      ? onTapExitFullScreen
                                      : onTapFullScreen,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      widget.isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                      size: 25.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ] else if (widget.showLoading)
                        Center(
                          child: kLoadingWidget(context),
                        )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (widget.isFullScreen) {
        return WillPopScopeWidget(
          allowExitApp: false,
          onWillPop: () async {
            context.updateSystemUiOverlay();

            return true;
          },
          child: body,
        );
      }

      return body;
    }

    return VisibilityDetector(
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          _youtubeController?.pauseVideo();
        } else if (widget.autoPlay == true) {
          _youtubeController?.playVideo();
        }
      },
      key: ValueKey('youtube_player_iframe-${widget.url}'),
      child: Listener(
        onPointerDown: (_) {
          if (widget.holdToPlayPause) {
            _startTimer();
          }
        },
        onPointerUp: (_) async {
          // TODO: Implement for youtube
          // var now = DateTime.now().millisecondsSinceEpoch;
          // if (widget.doubleTapToFullScreen) {
          //   // https://api.flutter.dev/flutter/gestures/kDoubleTapTimeout-constant.html
          //   if (now - lastTap < 300) {
          //     _cancelTimer();
          //     lastTap = now;
          //     if (!widget.isFullScreen) {
          //       onTapFullScreen();
          //     } else {
          //       onTapExitFullScreen();
          //     }
          //     return;
          //   }
          // }
          if (widget.holdToPlayPause) {
            _cancelTimer();
            await _youtubeController?.playVideo();
          }
          if (widget.tapToPlayPause) {
            var playerState = await _youtubeController?.playerState;
            if (playerState == PlayerState.playing) {
              await _youtubeController?.pauseVideo();
            } else {
              await _youtubeController?.playVideo();
            }
          }
          // lastTap = now;
        },
        child: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
          if (_youtubeController == null) {
            return _LoadingWidget(
              backgroundColor: widget.backgroundColor,
            );
          }

          final size = MediaQuery.sizeOf(context);
          final width = size.width;
          final height = size.height;

          if (orientation == Orientation.landscape) {
            return SizedBox(
              height: height,
              width: width,
              child: YoutubePlayer(
                controller: _youtubeController!,
                aspectRatio: aspectRatio ?? 16 / 9,
              ),
            );
          }

          return SizedBox(
            height: width * 0.8,
            width: width,
            child: YoutubePlayerControllerProvider(
              controller: _youtubeController!,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                      aspectRatio: aspectRatio ?? 16 / 9,
                    ),
                  ),
                  if (widget.tapToPlayPause)
                    Positioned.fill(
                      child: YoutubeValueBuilder(
                        builder: (context, value) {
                          return playPauseButton(
                            value.playerState == PlayerState.playing,
                          );
                        },
                      ),
                    ),
                  if (widget.enableTimeIndicator)
                    const Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: VideoPositionSeeker(),
                    )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({this.backgroundColor});

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = width * 0.8;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: backgroundColor ?? Colors.black),
      child: Center(
        child: kLoadingWidget(context),
      ),
    );
  }
}

class VideoPositionSeeker extends StatelessWidget {
  const VideoPositionSeeker({super.key});

  @override
  Widget build(BuildContext context) {
    var value = 0.0;

    return StreamBuilder<Duration>(
      // fixme: getCurrentPositionStream
      // stream: context.ytController.getCurrentPositionStream(),
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final position = snapshot.data?.inSeconds ?? 0;
        final duration = context.ytController.metadata.duration.inSeconds;

        value = position == 0 || duration == 0 ? 0 : position / duration;

        return StatefulBuilder(
          builder: (context, setState) {
            return Slider(
              activeColor: const Color.fromRGBO(255, 0, 0, 0.7),
              value: value,
              onChanged: (positionFraction) {
                value = positionFraction;
                setState(() {});

                context.ytController.seekTo(
                  seconds: (value * duration).toDouble(),
                  allowSeekAhead: true,
                );
              },
              min: 0,
              max: 1,
            );
          },
        );
      },
      stream: null,
    );
  }
}

class FeatureVideoController {
  Future<void> Function()? togglePlayPause;
}
