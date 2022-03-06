import 'dart:core';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nyimbo_za_injili_flutter/dataStore.dart';
import 'package:nyimbo_za_injili_flutter/uploadSong.dart';

class FloatingAudioPlayer extends StatefulWidget {
  final Function onPaused;
  FloatingAudioPlayer({required this.onPaused});
  @override
  _FloatingAudioPlayerState createState() => _FloatingAudioPlayerState();
}

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer> {
  late Duration _duration;
  late AudioPlayer _audioPlayer;

  bool waitForSong = false;

  bool pauseButtonVisible = false;
  bool playButtonVisible = true;


  Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      // Vertically center the widget inside the column
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

        Align(
        alignment: Alignment.centerRight,
        child:FloatingActionButton(
        onPressed: () {
            setState(() {
              //isPlayerOpened = true;
            });

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => uploadSong()),
            );
          },
          child: Icon(Icons.upload_file_outlined),
          ),
        ),



     Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 35),
        Container(
          height: 95,
          width: 325,
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: StreamBuilder(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print(snapshot.data.toString());
                if (_audioPlayer.processingState == ProcessingState.completed) {
                  _audioPlayer.stop();
                  //Future.delayed(Duration(seconds: 0), widget.onPaused);

                  //waiting (),
                }



                   return Row(

                          mainAxisAlignment: MainAxisAlignment.center, //Center Column contents vertically,
                          crossAxisAlignment: CrossAxisAlignment.center, //Center Column contents horizontally,
                      children: [


                        Container(
                          height: double.infinity,
                          width: 80,
                          color: Colors.amber,
                          child: Center(

                            child: Column(
                            // Vertically center the widget inside the column
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [


                              if(_audioPlayer.processingState == ProcessingState.loading ||
                                  _audioPlayer.processingState == ProcessingState.buffering ||
                                  _audioPlayer.processingState == ProcessingState.idle)
                                waiting ()

                              else if (_audioPlayer.playerState.playing)
                                pauseButton()
                              else if(_audioPlayer.processingState == ProcessingState.ready)
                                  playButton(),


                            ],
                          ),


                          ),
                        ),



                        Expanded(child: progressSlider(parseDuration(snapshot.data.toString()))),
                           ],
                      );


              }

              return Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    ),

   ]);
  }

  Widget playButton() {
    //waitForSong = true;
    playButtonVisible = true;
    //pauseButtonVisible = false;

    return Visibility(child: IconButton(
      icon: Icon(Icons.play_arrow_outlined),
      onPressed:  () => playAudio(),
      //onPressed: initAudio(),
      iconSize: 34,
      color: Colors.white,
    ),visible:playButtonVisible);
  }

  Widget pauseButton() {
    //playButtonVisible = false;
    pauseButtonVisible = true;

    return Visibility(child: IconButton(
      icon: Icon(Icons.pause_outlined),
      onPressed: pause,
      iconSize: 34,
      color: Colors.white,
    ),visible:pauseButtonVisible);
  }

  Widget waiting (){
    waitForSong = true;

    return Visibility(child: SizedBox(
      child: CircularProgressIndicator(
        valueColor:AlwaysStoppedAnimation<Color>(Colors.white),
      ),
      height: 20.0,
      width: 20.0,

    ),visible: waitForSong);

  }

  pause() {
    _audioPlayer.pause();

    //playButtonVisible = true;
    //pauseButtonVisible = false; _audioPlayer.processingState

    print(playButtonVisible);
    print(_audioPlayer.processingState );
    //Future.delayed(Duration(milliseconds: 500), widget.onPaused);
  }

  Widget progressSlider(Duration position) {
    const textStyle = TextStyle(color: Colors.white);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //Text:text(""),
        //waiting (),

        SizedBox(height: 5),
        Text(dataStore.currentSongName, style: textStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(position.toString().substring(2, 7), style: textStyle),
              Text(_duration.toString().substring(2, 7), style: textStyle),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          height: 25,
          child: Slider(
            min: 0,
            max: _duration.inMilliseconds.toDouble(),
            value: position.inMilliseconds.toDouble(),
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
            onChanged: (value) {
              _audioPlayer.seek(Duration(milliseconds: value.floor()));
            },
          ),
        )
      ],
    );
  }


  @override
  void initState() {
    super.initState();
    print("THIS IS CALLED");
    _duration = parseDuration("5:00:00.000000");
    print(dataStore.currentSongSource);
    initAudio();
    waitForSong = true;

    print(_audioPlayer.processingState );
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
  }

  initAudio() async {
    waitForSong = true;
    _audioPlayer = AudioPlayer();
    final duration = await _audioPlayer.setUrl(dataStore.currentSongSource);

    print(duration.toString());
    setState(() {
      _duration = duration!;
    });
    if(_duration != null){
      playAudio();
    }

  }

  playAudio() {

    _audioPlayer.play();
  }

  void playAudioX() async {

    if(_duration != null){
      _audioPlayer.stop();
      _audioPlayer.dispose();
    }
    //playButtonVisible = true;
    pauseButtonVisible = true;
    waitForSong = true;
    //_duration = parseDuration("0:00:00.000000");

    _audioPlayer = AudioPlayer();
    final duration = await _audioPlayer.setUrl(
      'https://www.zimaapps.com/APPS/NYIMBOZAINJILI/NYIMBOZAINJILI/nyimbo/'+dataStore.currentSongSource,
    );

    print("XXXXXXXX  "+duration.toString());
    setState(() {
      _duration = duration!;

      playAudio();
    });



  }





}
