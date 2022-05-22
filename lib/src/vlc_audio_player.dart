import 'dart:developer' as dev;
import 'dart:math';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:dart_vlc/dart_vlc.dart';

class VlcAudioPlayer extends AudioPlayerPlatform {
  VlcAudioPlayer(String id) : super(id);

  late final Player player;

  bool _isPlaying = false;

	// TODO: just_audio uses uuid for id, but dart_vlc uses int!!!
  void init() {
    player = Player(id: Random().nextInt(1000));
  }

  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(
      AudioEffectSetEnabledRequest request) async {
    // TODO: implement audioEffectSetEnabled
    return super.audioEffectSetEnabled(request);
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
      ConcatenatingInsertAllRequest request) async {
    // TODO: implement concatenatingInsertAll
    return super.concatenatingInsertAll(request);
  }

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
      ConcatenatingMoveRequest request) async {
    // TODO: implement concatenatingMove
    return super.concatenatingMove(request);
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
      ConcatenatingRemoveRangeRequest request) async {
    // TODO: implement concatenatingRemoveRange
    return super.concatenatingRemoveRange(request);
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    // TODO: verify the `rate` and `speed` do the same thing
    player.setRate(request.speed);
    return SetSpeedResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    player.dispose();
    return DisposeResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    print('Position: ${request.position}, index: ${request.index}');
    if (request.index != null) {
      player.jump(request.index!);
    }
    if (request.position != null) {
      player.seek(request.position!);
    }
    return SeekResponse();
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    // TODO: implement load
    final _audioSourceMessage = request.audioSourceMessage;

    if (_isPlaying) {
      player.pause();
    }
    if (_audioSourceMessage is UriAudioSourceMessage) {
      player.open(
        Media.network(_audioSourceMessage.uri),
        autoStart: false,
      );
      if (request.initialIndex != null) {
        player.jump(request.initialIndex!);
      }
      if (request.initialPosition != null) {
        player.seek(request.initialPosition!);
      }
      player.play();
      return LoadResponse(duration: request.initialPosition);
    } else if (_audioSourceMessage is ConcatenatingAudioSourceMessage) {
      var _playlist = Playlist(medias: []);

      _audioSourceMessage.children.forEach((message) {});
      throw UnimplementedError();
    } else {
      throw UnimplementedError();
    }
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    if (_isPlaying) {
      return PlayResponse();
    } else {
      player.play();
      _isPlaying = true;
      return PlayResponse();
    }
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    if (_isPlaying) {
      player.pause();
      _isPlaying = false;
      return PauseResponse();
    } else {
      return PauseResponse();
    }
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    player.setVolume(request.volume);
    return SetVolumeResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    // TODO: verify what the hell these playlistmode mean
    switch (request.loopMode) {
      case LoopModeMessage.one:
        player.setPlaylistMode(PlaylistMode.single);
        break;
      case LoopModeMessage.off:
        player.setPlaylistMode(PlaylistMode.loop);
        break;
      case LoopModeMessage.all:
        player.setPlaylistMode(PlaylistMode.repeat);
        break;
      default:
        dev.log('Loopmode unimplemented', error: request.loopMode);
        throw UnimplementedError();
    }

    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
      SetShuffleModeRequest request) async {
    // TODO: implement setShuffleMode
    // throw UnimplementedError();
    return SetShuffleModeResponse();
  }
}