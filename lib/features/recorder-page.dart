import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class RecorderAudioPage extends StatefulWidget {
  const RecorderAudioPage({Key? key}) : super(key: key);

  @override
  State<RecorderAudioPage> createState() => _RecorderAudioPageState();
}

class _RecorderAudioPageState extends State<RecorderAudioPage> {
  final recoder = FlutterSoundRecorder();
  bool isRecoderReady = false;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    recoder.closeRecorder();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initRecorder();
  }

  Future initRecorder() async{
    final status = await Permission.microphone.request();

    if(status != PermissionStatus.granted){
      throw 'Microphone permission not grannted';
    }
    await recoder.openRecorder();
    isRecoderReady = true;
    recoder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future record() async{
    if(!isRecoderReady){
      return;
    }
    String pathToAudio = '/sdcard/Download/audio.wav';
    await recoder.startRecorder(toFile: pathToAudio ,codec: Codec.pcm16WAV );

  }

  Future stop() async{
    if(!isRecoderReady){
      return;
    }
    final path = await recoder.stopRecorder();
    final audioFile = File(path!);
    print("Recorded audio : $audioFile");
  }

  String convert2digits(int num){
    return  num.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Demo audio recoder")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<RecordingDisposition>(
                stream: recoder.onProgress,
                builder: (context,snapshot){
              final duration = snapshot.hasData ? snapshot.data!.duration : Duration.zero;
              final twoDigitMinutes = convert2digits(duration.inMinutes.remainder(60));
              final twoDigitSecond = convert2digits(duration.inSeconds.remainder(60));

              return Text('$twoDigitMinutes:${twoDigitSecond}s', style: TextStyle(color: Colors.black87,fontSize: 60,fontWeight: FontWeight.bold),);
            }),
            const SizedBox( height : 32),
            ElevatedButton(
              child: Icon(
                recoder.isRecording ? Icons.stop : Icons.mic,
                size: 80,
              ),
              onPressed: () async{
                if(recoder.isRecording){
                   await stop();
                }else{
                   await record();
                }
                setState(() {
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
