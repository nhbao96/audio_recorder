

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

    recoder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future record() async{
    await recoder.startRecorder(toFile: 'audio');
  }

  Future stop() async{
    await recoder.stopRecorder();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<RecordingDisposition>(
              stream: recoder.onProgress,
              builder: (context,snapshot){
            final duration = snapshot.hasData ? snapshot.data!.duration : Duration.zero;

            return Text('${duration.inSeconds} s');
          }),
          const SizedBox( height : 32),
          ElevatedButton(
            child: Icon(
              recoder.isRecording ? Icons.stop : Icons.mic,
              size: 80,
            ),
            onPressed: () {
              if(recoder.isRecording){
                 stop();
              }else{
                 record();
              }
              setState(() {

              });
            },
          ),
        ],
      ),
    );
  }
}
