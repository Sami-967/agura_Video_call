import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:draggable_widget/draggable_widget.dart';
import 'package:flutter/material.dart';
import 'package:video_chat/utils/setting.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;

class VideoCall extends StatefulWidget {
  const VideoCall({super.key, required this.channelName, this.role});
  final String? channelName;
  final ClientRole? role;

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool viewPanel = false;
  late RtcEngine _engine;
  bool swipeScreen = false;
  static var userScreen;
  static var clientScreen;
  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();

    super.dispose();
  }

  Future<void> initialize() async {
    if (appid.isEmpty) {
      setState(() {
        _infoStrings.add("APP_ID missing,provide your APP_ID in setting.dart");
        _infoStrings.add("Agora Engine is not starting");
      });
      return;
    }
    _engine = await RtcEngine.create(appid);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role!);
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = const VideoDimensions(width: 1920, height: 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(token, widget.channelName!, null, 0);
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = "Error : $code";
          _infoStrings.add(info);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = "join Channel: $channel, uid: $uid";
          _infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add("Leave Channel");
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'User Joined:$uid';
          _infoStrings.add(info);
          _users.add(uid);
        });
      },
      userOffline: (uid, reason) {
        setState(() {
          final info = 'User Offline : $uid';
          _infoStrings.add(info);
          _users.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'First Remote video : $uid ${width}x $height';
          _infoStrings.add(info);
        });
      },
    ));
  }

  Widget _viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      // list.add(const rtc_local_view.SurfaceView());
    }
    for (var uid in _users) {
      list.add(rtc_remote_view.SurfaceView(
          uid: uid, channelId: widget.channelName!));
    }
    final views = list;
    userScreen = const rtc_local_view.SurfaceView();
    return Stack(children: [
      Expanded(child: swipeScreen ? clientScreen : userScreen),
      (views.isNotEmpty ? _draggable(views) : const SizedBox())
    ]);
  }

  Stack _draggable(List<StatefulWidget> views) {
    return Stack(
        children: List.generate(views.length, (index) {
      clientScreen = views[index];
      return Stack(
        children: [
          DraggableWidget(
              bottomMargin: 150,
              topMargin: 15,
              intialVisibility: true,
              horizontalSpace: 5,
              // shadowBorderRadius: 50,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    swipeScreen = !swipeScreen;
                  });
                },
                child: SizedBox(
                    height: 150,
                    width: 150,
                    child: swipeScreen ? userScreen : clientScreen),
              ))
        ],
      );
    }));
  }

  Widget _toolbar() {
    if (widget.role == ClientRole.Audience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                muted = !muted;
              });
              _engine.muteLocalAudioStream(muted);
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.red,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              _engine.switchCamera();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.switch_camera,
              color: Colors.amberAccent,
              size: 20.0,
            ),
          )
        ],
      ),
    );
  }

  Widget _panel() {
    return Visibility(
        visible: viewPanel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: ListView.builder(
                itemCount: _infoStrings.length,
                itemBuilder: (context, index) {
                  if (_infoStrings.isEmpty) {
                    return const Text("null");
                  }
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                    child: Row(
                      children: [
                        Flexible(
                            child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _infoStrings[index],
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ))
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("live video"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  viewPanel = !viewPanel;
                });
              },
              icon: const Icon(Icons.info_outline))
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [_viewRows(), _panel(), _toolbar()],
        ),
      ),
    );
  }
}
