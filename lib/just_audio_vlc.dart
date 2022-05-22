import 'dart:async';

import 'package:flutter/services.dart';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:just_audio_platform_interface/method_channel_just_audio.dart';
import 'package:dart_vlc/dart_vlc.dart';

import 'src/vlc_audio_player.dart';

class JustAudioVlcPlugin extends JustAudioPlatform {
  final Map<String, VlcAudioPlayer> players = {};

  static void registerWith() {
    JustAudioPlatform.instance = JustAudioVlcPlugin();
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    print('Initialize vlc');
    DartVLC.initialize();
    print('Vlc initialized...');
    if (players.containsKey(request.id)) {
      throw PlatformException(
          code: "error",
          message: "Platform player ${request.id} already exists");
    }
    final player = VlcAudioPlayer(request.id)..init();
    players[request.id] = player;
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    assert(players[request.id] != null);
    players[request.id]!.dispose(DisposeRequest());
    players.remove(request.id);
    return DisposePlayerResponse();
  }
}