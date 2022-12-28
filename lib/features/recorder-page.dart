import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../amplifyconfiguration.dart';



class RecorderAudioPage extends StatefulWidget {
  const RecorderAudioPage({Key? key}) : super(key: key);

  @override
  State<RecorderAudioPage> createState() => _RecorderAudioPageState();
}

class _RecorderAudioPageState extends State<RecorderAudioPage> {
  final recoder = FlutterSoundRecorder();
  bool isRecoderReady = false;

  late PermissionStatus isPermisMicro;
  late PermissionStatus isPermissStorage;
  late PermissionStatus isPermissMedia;
  late PermissionStatus isPermissExternalStorage;

  final _folderPath = Directory('/storage/emulated/0/Recordings/');
  String _currentFilePath = '', _recordedFilePath = '';

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
    _configureAmplify();
    initRecorder();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      final storage = AmplifyStorageS3();
      await Amplify.addPlugins([auth, storage]);

      // call Amplify.configure to use the initialized categories in your app
      await Amplify.configure(amplifyconfig);
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  Future initRecorder() async{
    try{
      isPermisMicro = await Permission.microphone.request();
      if(!isPermisMicro.isGranted){
        throw 'Microphone permission not grannted';
      }
      isPermissStorage = await Permission.storage.request();
      if(!isPermissStorage.isGranted){
        throw 'Storage permission not grannted';
      }
      isPermissMedia = await Permission.accessMediaLocation.request();
      if(!isPermissMedia.isGranted){
        throw 'accessMediaLocation permission not grannted';
      }
      isPermissExternalStorage = await Permission.manageExternalStorage.request();
      if(!isPermissExternalStorage.isGranted){
        throw 'manageExternalStorage permission not grannted';
      }
    }catch(e){
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await recoder.openRecorder();
    isRecoderReady = true;
    recoder.setSubscriptionDuration(const Duration(milliseconds: 500));

  }

  Future record() async{
    if(!isRecoderReady){
      return;
    }
    if (!(await _folderPath.exists())) {
      _folderPath.create();
    }
    final _fileName = 'DEMO_${DateTime.now().millisecondsSinceEpoch.toString()}.aac';
    _currentFilePath = '${_folderPath.path}$_fileName';
    setState(() {});
    recoder!.startRecorder(toFile: _currentFilePath,codec: Codec.aacADTS).then((value) {
      setState(() {
      });
    });

    print("_currentFilePath = $_currentFilePath \n\n");
  }

  Future stop() async{
    if(!isRecoderReady){
      return;
    }
    final path = await recoder.stopRecorder();
    final audioFile = File(path!);

    try {
      final UploadFileResult result = await Amplify.Storage.uploadFile(
          local: audioFile,
          key: audioFile.toString(),
          onProgress: (progress) {
            safePrint('Fraction completed: ${progress.getFractionCompleted()}');
          }
      );
      safePrint('Successfully uploaded file: ${result.key}');
      print("upload file successfully \n\n");
    } on StorageException catch (e) {
      safePrint('Error uploading file: $e');
    }

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
