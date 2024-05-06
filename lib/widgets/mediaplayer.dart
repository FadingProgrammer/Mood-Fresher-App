import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';

class MediaPlayer {
  static Widget fileVideo(File file, {bool autoPlay = false}) {
    final flickManager = FlickManager(
        autoPlay: autoPlay,
        videoPlayerController: VideoPlayerController.file(file));
    return FlickVideoPlayer(
      flickManager: flickManager,
      flickVideoWithControls: const FlickVideoWithControls(
        videoFit: BoxFit.contain,
        controls: FlickPortraitControls(),
      ),
    );
  }

  static Widget urlVideo(String url, {bool autoPlay = false}) {
    final flickManager = FlickManager(
        autoPlay: autoPlay,
        videoPlayerController:
            VideoPlayerController.networkUrl(Uri.parse(url)));
    return FlickVideoPlayer(
      flickManager: flickManager,
      flickVideoWithControls: const FlickVideoWithControls(
        videoFit: BoxFit.contain,
        controls: FlickPortraitControls(),
      ),
    );
  }
}
