import 'dart:async';

import 'package:amseekbar/amseekbar.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:amseekbar/amseekbar.dart';


// source: https://stackoverflow.com/questions/57004220/how-to-get-all-mp3-files-from-internal-as-well-as-external-storage-in-flutter
Future<List<List<String>>> getSongs() async {
  var dir = await getExternalStorageDirectory();
//  String mp3Path = dir.path + "/";
  List<FileSystemEntity> _files;
//  List<FileSystemEntity> _songs = [];
  List<String> songsPaths = [];
  List<String> songsNames = [];
  List<String> songsArtists = [];
  _files = dir.listSync(recursive: true, followLinks: false);
  for(FileSystemEntity entity in _files) {
    String path = entity.path;
    if(path.endsWith('.mp3')) {
      songsPaths.add(path);
      var songName = path
          .split("/")
          .last;
      songName = songName.split(".mp3")[0];
      var songSplittedNames = songName.split("-");
      songsNames.add(songSplittedNames[0].trimRight().trimLeft());
      songsArtists.add(songSplittedNames[1].trimRight().trimLeft());
    }
  }
  return [songsPaths, songsNames, songsArtists];
}

// global variables
List<String> localSongsPaths = [];
List<String> localSongsNames = [''];
List<String> localSongsArtists = [''];
int _currentIndex = 0;
double _currentTime = 0.0;
double _totalDuration = 0.0;
Timer _progressTimer;
int _maxIndexes = localSongsNames.length - 1;
bool isPlaying = false;

//audioPlayer
AudioPlayer audioPlugin = new AudioPlayer();
AudioPlayerState playerState = AudioPlayerState.STOPPED;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  getSongs().then((val) {
    localSongsPaths = val[0];
    localSongsNames = val[1];
    localSongsArtists = val[2];
  });

  runApp(
      MaterialApp(
        home: MusicListView(),
      )
  );
}

class MusicListView extends StatefulWidget {
  @override
  _MusicListViewState createState() => _MusicListViewState();
}

class _MusicListViewState extends State<MusicListView> {
  Future<void> play(audioPlayer, playerState, path) async {
    await audioPlayer.play(path);
  }


  Future<void> pause(audioPlayer, playerState) async {
    await audioPlayer.pause();
  }

  Future<void> stop(audioPlayer, playerState) async {
    await audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "WidgetX Музыка Ойнатқышы"
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {// 'assets/gifs/current_song.gif'
                return ListTile(
                  leading: _currentIndex == index
                  ? Icon(Icons.arrow_forward_ios)
                  : Text(''),
                  title: Text(
                    localSongsNames[index],
                  ),
                  subtitle: Text(
                    localSongsArtists[index],
                  ),
                  onTap: () {
                    if (_currentIndex == index) {
                      if (isPlaying) {
                        pause(audioPlugin, playerState);
                      } else {
                        play(audioPlugin, playerState, localSongsPaths[index]);
                      }
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                    } else {
                      stop(audioPlugin, playerState);
                      play(audioPlugin, playerState, localSongsPaths[index]);
                      debugPrint("Duration");
                      debugPrint(audioPlugin.duration.toString());
                      setState(() {
                        _currentIndex = index;
                        isPlaying = true;
                      });
                    }
                  },

                );
              },
              itemCount: localSongsNames.length,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange[400],
              border: Border.all(
                color: Colors.blueAccent,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35.0),
                topRight: Radius.circular(35.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(
                    Icons.music_note
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        localSongsNames[_currentIndex]
                    ),
                    Text(
                      localSongsArtists[_currentIndex],
                      style: TextStyle(
                          color: Colors.black54
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.skip_previous),
                      onPressed: () {
                        // play previous song
                        if(_currentIndex > 0) {
                          setState(() {
                            _currentIndex--;
                          });
                        } else {
                          setState(() {
                            _currentIndex = _maxIndexes;
                          });
                        }
                        setState(() {
                          isPlaying = true;
                          stop(audioPlugin, playerState);
                          play(audioPlugin, playerState, localSongsPaths[_currentIndex]);
                        });
                      },
                    ),
                    IconButton(
                      icon: isPlaying
                          ? Icon(Icons.pause)
                          : Icon(Icons.play_arrow),
                      onPressed: () {
                        if(isPlaying) {
                          pause(
                            audioPlugin,
                            playerState,
                          );
                        } else {
                          play(
                            audioPlugin,
                            playerState,
                            localSongsPaths[_currentIndex],
                          );
                        }
                        setState(() {
                          isPlaying = !isPlaying;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next),
                      onPressed: () {
                        // play next song
                        if(_currentIndex < _maxIndexes) {
                          setState(() {
                            _currentIndex++;
                          });
                        } else {
                          setState(() {
                            _currentIndex = 0;
                          });
                        }
                        setState(() {
                          isPlaying = true;
                          stop(audioPlugin, playerState);
                          play(audioPlugin, playerState, localSongsPaths[_currentIndex]);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          MusicSeekBar(),
        ],
      ),
    );
  }
}

class MusicSeekBar extends StatefulWidget {
  @override
  _MusicSeekBarState createState() => _MusicSeekBarState();
}

class _MusicSeekBarState extends State<MusicSeekBar> {
  @override
  void initState() {
    setState(() {
      var tempDuration = audioPlugin.duration.toString();
      print(tempDuration);
    });
    _resumeProgressTimer();
    super.initState();
  }

  _resumeProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      setState(() {
        _currentTime += 1;

        if (_currentTime >= _totalDuration) {
          _currentTime = _totalDuration;
          _progressTimer.cancel();
          isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SeekBar(
      currentTime: _currentTime,
      durationTime: _totalDuration,
      onStartTrackingTouch: () {
        if (isPlaying) {
          _progressTimer?.cancel();
        }
      },
      onProgressChanged: (value) {
        _currentTime = value * _totalDuration;
      },
      onStopTrackingTouch: () {
        if (isPlaying) {
          _resumeProgressTimer();
        }
      },
    );
  }
}
