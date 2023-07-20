import 'dart:developer';
import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:video_chat/pages/videocall_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  final _channelController = TextEditingController();
  late bool _validateError = false;
  late ClientRole _role = ClientRole.Broadcaster;
  // @override
  // void initState() {
  //   FirebaseMessaging.onMessage.listen(
  //     (RemoteMessage message) {
  //       debugPrint("onMessage:");
  //       log("onMessage: $message");
  //       final snackBar =
  //           SnackBar(content: Text(message.notification?.title ?? ""));
  //       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //     },
  //   );
  //   super.initState();
  // }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Chat"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Image.network("https://tinyurl.com/2p889y4k"),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                errorText: _validateError ? 'channel name is mandatory' : null,
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(width: 1),
                ),
                hintText: "channel name",
              ),
            ),
            RadioListTile(
              title: const Text("Broadcaster"),
              onChanged: (ClientRole? value) {
                setState(() {
                  _role = value!;
                });
              },
              value: ClientRole.Broadcaster,
              groupValue: _role,
            ),
            RadioListTile(
              title: const Text("Audience"),
              onChanged: (ClientRole? value) {
                setState(() {
                  _role = value!;
                });
              },
              value: ClientRole.Audience,
              groupValue: _role,
            ),
            ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40)),
              child: const Text("Join"),
            )
          ],
        ),
      )),
    );
  }

  Future<void> onJoin() async {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: ((context) => VideoCall(
                    channelName: _channelController.text,
                    role: _role,
                  ))));
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}
