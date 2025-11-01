import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/utils/colors.dart';

import '../../../screens/detail/widgets/video_feature.dart';
import '../config/background_config.dart';

class HomeBackground extends StatelessWidget {
  final BackgroundConfig? config;

  const HomeBackground({required this.config});

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return const SizedBox();
    }

    final size = MediaQuery.sizeOf(context);
    final height = size.height * config!.height;
    final width = size.width;
    final image = config?.image;
    final video = config?.video;
    final color = config?.color != null
        ? HexColor(config!.color)
        : Theme.of(context).colorScheme.surface;

    if (video != null && video.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        color: color,
        child: FeatureVideoPlayer.fullScreen(
          video,
          autoPlay: true,
          tapToPlayPause: false,
          enableLoop: true,
          isSoundOn: false,
          showLoading: false,
          backgroundColor: color,
        ),
      );
    }

    if (image != null && image.isNotEmpty) {
      return Container(
        height: height,
        color: color,
        child: FluxImage(
          imageUrl: image,
          fit: config?.fit ?? BoxFit.cover,
          width: width,
        ),
      );
    }

    return Container(
      color: config!.color != null ? HexColor(config!.color) : null,
      height: height,
    );
  }
}
