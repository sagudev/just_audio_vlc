import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:just_audio_vlc/just_audio_vlc.dart';

void main() {
  DartVLC.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    try {
      print('Try set audio source');
      await player.setAudioSource(AudioSource.uri(Uri.parse(
          "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3")));
      print('Audio source complete!');
    } catch (e) {
      print("Error loading audio source: $e");
    }
    player.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  if (isPlaying) {
                    player.pause();
                    setState(() {
                      isPlaying = false;
                    });
                  } else {
                    player.play();
                    setState(() {
                      isPlaying = true;
                    });
                  }
                },
                child: Text(isPlaying ? "Stop" : "Start"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
