import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:just_audio_platform_interface/method_channel_just_audio.dart';
import 'package:dart_vlc/dart_vlc.dart';

/// The libvlc implementation of [JustAudioPlatform].
class JustAudioVlcPlugin extends JustAudioPlatform {
  final Map<String, VlcAudioPlayer> players = {};

  /// The entrypoint called by the generated plugin registrant.
  static void registerWith() {
    JustAudioPlatform.instance = JustAudioVlcPlugin();
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    // TODO: this moved in registerWith
    print('Initialize vlc');
    DartVLC.initialize();
    print('Vlc initialized...');
    // standard code as per https://github.com/bdlukaa/just_audio_libwinmedia/blob/main/lib/src/just_audio_libwinmedia_real.dart#L20
    if (players.containsKey(request.id)) {
      throw PlatformException(
          code: "error",
          message: "Platform player ${request.id} already exists");
    }
    final player = VlcAudioPlayer(request.id);
    players[request.id] = player;
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    await players[request.id]?.dispose(DisposeRequest());
    players.remove(request.id);
    return DisposePlayerResponse();
  }
}

// ids per https://github.com/bdlukaa/just_audio_libwinmedia/blob/main/lib/src/just_audio_libwinmedia_real.dart#L40
int _id = 0;

class VlcAudioPlayer extends AudioPlayerPlatform {
  List<StreamSubscription> streamSubscriptions = [];
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  final _dataEventController = StreamController<PlayerDataMessage>.broadcast();
  ProcessingStateMessage _processingState = ProcessingStateMessage.idle;
  Duration _updatePosition = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  Duration? _duration = null;
  int? _currentIndex = null;
  Player player;

  bool _isPlaying = false;

  VlcAudioPlayer(String id)
      : player = Player(
          id: _id,
        ),
        super(id) {
    _id++;

    void _handlePlaybackEvent() {
      broadcastPlaybackEvent();
    }

    final currentStream = player.currentStream.listen((CurrentState state) {
      _currentIndex = state.index;
      //state.media;
      //state.medias;
      //state.isPlaylist;
      _handlePlaybackEvent();
    });
    streamSubscriptions.add(currentStream);

    final positionStream = player.positionStream.listen((PositionState state) {
      _updatePosition = state.position!;
      _duration = state.duration;
      _handlePlaybackEvent();
    });
    streamSubscriptions.add(positionStream);

    final playbackStream = player.playbackStream.listen((PlaybackState state) {
      if (state.isCompleted) {
        _processingState = ProcessingStateMessage.ready;
      }
      _isPlaying = state.isPlaying;
      _handlePlaybackEvent();
    });
    streamSubscriptions.add(playbackStream);

    final generalStream = player.generalStream.listen((GeneralState state) {
      state.volume;
      state.rate;
      _handlePlaybackEvent();
    });
    streamSubscriptions.add(generalStream);

    final bufferingProgressStream =
        player.bufferingProgressStream.listen((buffered) {
      _bufferedPosition = Duration(seconds: buffered.toInt());
      if (buffered != 0) {
        _processingState = ProcessingStateMessage.buffering;
      }
      _handlePlaybackEvent();
    });
    streamSubscriptions.add(bufferingProgressStream);
  }

  /// Broadcasts a playback event from the platform side to the plugin side.
  void broadcastPlaybackEvent() {
    final updateTime = DateTime.now();
    _eventController.add(PlaybackEventMessage(
      processingState: _processingState,
      updatePosition: _updatePosition,
      updateTime: updateTime,
      bufferedPosition: _bufferedPosition,
      // TODO(libwinmedia): Icy Metadata
      icyMetadata: null,
      duration: _duration,
      currentIndex: _currentIndex,
      androidAudioSessionId: null,
    ));
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      _dataEventController.stream;

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
      player.jumpToIndex(request.index!);
    }
    if (request.position != null) {
      player.seek(request.position!);
    }
    return SeekResponse();
  }

  Media _loadAudioMedia(AudioSourceMessage sourceMessage) {
    if (sourceMessage is UriAudioSourceMessage) {
      return Media.network(sourceMessage.uri);
    } else {
      throw UnimplementedError();
    }
  }

  MediaSource _loadAudioSource(AudioSourceMessage sourceMessage) {
    if (sourceMessage is UriAudioSourceMessage) {
      return Media.network(sourceMessage.uri);
    } else if (sourceMessage is ConcatenatingAudioSourceMessage) {
      return Playlist(
          medias: sourceMessage.children.map(_loadAudioMedia).toList());
    } else {
      throw UnimplementedError();
    }
  }

  /// Loads an audio source.
  @override
  Future<LoadResponse> load(LoadRequest request) async {
    // TODO: implement load

    if (_isPlaying) {
      player.pause();
    }
    player.open(
      _loadAudioSource(request.audioSourceMessage),
      autoStart: false,
    );
    if (request.initialIndex != null) {
      player.jumpToIndex(request.initialIndex!);
    }
    if (request.initialPosition != null) {
      player.seek(request.initialPosition!);
    }
    player.play();
    return LoadResponse(duration: request.initialPosition);
  }

  /// Plays the current audio source at the current index and position.
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
