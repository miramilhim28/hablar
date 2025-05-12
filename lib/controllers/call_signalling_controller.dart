import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/video_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/incoming_call_screen.dart';

class CallSignallingController extends GetxController {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Rx<MediaStream?> remoteStream = Rx<MediaStream?>(null);
  RxBool isCallActive = false.obs;
  String? roomId;

  @override
  void onInit() {
    super.onInit();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) listenForIncomingCalls(userId);
  }

  Future<void> initializePeerConnection({
    RTCVideoRenderer? remoteRenderer,
  }) async {
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners(remoteRenderer: remoteRenderer);

    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        peerConnection?.addTrack(track, localStream!);
      }
    }
  }

  Future<void> openUserMedia({bool video = false}) async {
    var micStatus = await Permission.microphone.request();
    var camStatus = await Permission.camera.request();

    if (!micStatus.isGranted || (video && !camStatus.isGranted)) {
      Get.snackbar("Permission Denied", "Media permissions are required.");
      return;
    }

    localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });

    localStream?.getTracks().forEach((track) {
      track.enabled = true;
    });
  }

  Future<String> createRoom() async {
    await openUserMedia(video: true);

    localStream?.getAudioTracks().forEach((track) {
      print("📤 Caller Audio Track: ID=${track.id}, ENABLED=${track.enabled}, MUTED=${track.muted}");
    });

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc();
    roomId = roomRef.id;

    await initializePeerConnection();

    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        peerConnection?.addTrack(track, localStream!);
      }
    }

    final offer = await peerConnection!.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
      'optional': [],
    });

    await peerConnection!.setLocalDescription(offer);

    await roomRef.set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'callStatus': 'calling',
    });

    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection!.getRemoteDescription() == null && data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection!.setRemoteDescription(answer);
      }
    });

    return roomId!;
  }

  Future<void> joinRoom(String callId, RTCVideoRenderer remoteRenderer) async {
    await openUserMedia(video: true);

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc(callId);
    var roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) return;

    await initializePeerConnection(remoteRenderer: remoteRenderer);

    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        peerConnection?.addTrack(track, localStream!);
      }
    }

    var data = roomSnapshot.data() as Map<String, dynamic>;
    var offer = data['offer'];
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer = await peerConnection!.createAnswer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
      'optional': [],
    });

    await peerConnection!.setLocalDescription(answer);
    await roomRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
    });
  }

  void listenForIncomingCalls(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('incomingCall')) {
        var callData = snapshot.data()!['incomingCall'];
        Get.to(() => IncomingCallScreen(
              callId: callData['callId'],
              callerId: callData['callerId'],
              calleeId: userId,
              callerName: "Caller",
              callType: callData['callType'],
            ));
      }
    });
  }

  Future<void> acceptCall(String callId) async {
    RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    await openUserMedia(video: true);
    await joinRoom(callId, remoteRenderer);

    var callSnapshot =
        await FirebaseFirestore.instance.collection('calls').doc(callId).get();
    var callData = callSnapshot.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      'callStatus': 'answered',
    });

    if (remoteStream.value != null) {
      remoteRenderer.srcObject = null;
      remoteRenderer.srcObject = remoteStream.value;
    }

    if (callData['callType'] == "video") {
      Get.off(() => VideoCallScreen(
            callerId: callData['callerId'],
            calleeId: callData['calleeId'],
            callId: callId,
          ));
    } else {
      Get.off(() => AudioCallScreen(
            callerId: callData['callerId'],
            calleeId: callData['calleeId'],
            callId: callId,
          ));
    }
  }

  Future<void> declineCall(String callId) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      'callStatus': 'declined',
    });
    hangUp();
    Get.back();
  }

  Future<void> hangUp() async {
    if (roomId == null) return;

    var roomRef = FirebaseFirestore.instance.collection('calls').doc(roomId);
    await roomRef.update({'callStatus': 'ended'});

    await roomRef.collection('calleeCandidates').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    await roomRef.collection('callerCandidates').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    localStream?.dispose();
    remoteStream.value?.dispose();
    peerConnection?.close();
  }

  void registerPeerConnectionListeners({RTCVideoRenderer? remoteRenderer}) {
    peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        remoteStream.value = stream;

        for (var track in stream.getTracks()) {
          track.enabled = true;
          print("✅ Forcing remote track enabled: ${track.kind}");
        }

        stream.getAudioTracks().forEach((track) {
          print("🔊 Remote Audio Track: ID=${track.id}, ENABLED=${track.enabled}, MUTED=${track.muted}");
        });

        if (remoteRenderer != null) {
          remoteRenderer.srcObject = null;
          remoteRenderer.srcObject = stream;
          print("✅ Remote renderer assigned");
        }

        print("📥 Track received: ${event.track.kind}, ID: ${event.track.id}");
      } else {
        print("⚠️ Received track without stream.");
      }
    };

    peerConnection?.onIceCandidate = (candidate) {
      if (roomId != null) {
        FirebaseFirestore.instance
            .collection('calls')
            .doc(roomId)
            .collection('candidates')
            .add(candidate.toMap());
      }
    };

    peerConnection?.onConnectionState = (state) {
      print('🔗 Connection state: $state');
    };

    peerConnection?.onSignalingState = (state) {
      print('📶 Signaling state: $state');
    };

    peerConnection?.onIceGatheringState = (state) {
      print('❄️ ICE gathering state: $state');
    };
  }
}
