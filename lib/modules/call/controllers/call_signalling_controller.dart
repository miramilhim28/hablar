import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:hablar_clone/modules/call/screens/video_call_screen.dart';
import 'package:hablar_clone/modules/call/screens/incoming_call_screen.dart';

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
  bool isInitiator = false;

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
      'video':
          video
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

  Future<String> createRoom({bool video = true}) async {
    await openUserMedia(video: video);
    isInitiator = true;

    localStream?.getAudioTracks().forEach((track) {
      print(
        "📤 Caller Audio Track: ID=${track.id}, ENABLED=${track.enabled}, MUTED=${track.muted}",
      );
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
      'callId': roomId,
      'callerId': FirebaseAuth.instance.currentUser!.uid,
      'calleeId': "",
      'callType': video ? 'video' : 'audio',
      'callStatus': 'calling',
      'timestamp': FieldValue.serverTimestamp(),
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });

    // Listen for candidates
    peerConnection!.onIceCandidate = (candidate) {
      if (roomId != null) {
        FirebaseFirestore.instance
            .collection('calls')
            .doc(roomId)
            .collection('callerCandidates')
            .add(candidate.toMap());
      }
    };

    // Listen for answer
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;

      if (peerConnection?.getRemoteDescription() == null &&
          data['answer'] != null) {
        print("🔄 Received answer from callee");
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection!.setRemoteDescription(answer);
      }
    });

    // Listen for callee candidates
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          print("🧊 Adding callee ICE candidate");
          await peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return roomId!;
  }

  Future<void> joinRoom(String callId, RTCVideoRenderer remoteRenderer) async {
    await openUserMedia(video: true);
    isInitiator = false;
    roomId = callId;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc(callId);
    var roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      print("❌ Room doesn't exist");
      return;
    }

    await initializePeerConnection(remoteRenderer: remoteRenderer);

    // Collect ICE candidates
    peerConnection!.onIceCandidate = (candidate) {
      if (roomId != null) {
        FirebaseFirestore.instance
            .collection('calls')
            .doc(roomId)
            .collection('calleeCandidates')
            .add(candidate.toMap());
      }
    };

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
      'callStatus': 'answered',
    });

    // Listen for caller candidates
    roomRef.collection('callerCandidates').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          print("🧊 Adding caller ICE candidate");
          await peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
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
            Get.to(
              () => IncomingCallScreen(
                callId: callData['callId'],
                callerId: callData['callerId'],
                calleeId: userId,
                callerName: "Caller",
                callType: callData['callType'],
              ),
            );
          }
        });
  }

  Future<void> acceptCall(String callId) async {
    RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    await openUserMedia(video: true);
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      'calleeId': FirebaseAuth.instance.currentUser!.uid,
    });
    await joinRoom(callId, remoteRenderer);

    var callSnapshot =
        await FirebaseFirestore.instance.collection('calls').doc(callId).get();
    var callData = callSnapshot.data() as Map<String, dynamic>;

    if (callData['callType'] == "video") {
      Get.off(
        () => VideoCallScreen(
          callerId: callData['callerId'],
          calleeId: callData['calleeId'],
          callId: callId,
          callType: callData['callType'],
        ),
      );
    }
  }

  Future<void> declineCall(String callId) async {
  if (callId.isEmpty) return;

  var roomRef = FirebaseFirestore.instance.collection('calls').doc(callId);

  await roomRef.update({'callStatus': 'declined'});

  // Clean up streams and connection
  if (localStream != null) {
    localStream!.getTracks().forEach((track) => track.stop());
    localStream!.dispose();
    localStream = null;
  }

  if (remoteStream.value != null) {
    remoteStream.value!.getTracks().forEach((track) => track.stop());
    remoteStream.value!.dispose();
    remoteStream.value = null;
  }

  if (peerConnection != null) {
    peerConnection!.close();
    peerConnection = null;
  }

  roomId = null;
  isInitiator = false;
}

  Future<void> hangUp() async {
    if (roomId == null) return;

    var roomRef = FirebaseFirestore.instance.collection('calls').doc(roomId);
    await roomRef.update({'callStatus': 'ended'});

    // Clean up streams and connection
    if (localStream != null) {
      localStream!.getTracks().forEach((track) => track.stop());
      localStream!.dispose();
      localStream = null;
    }

    if (remoteStream.value != null) {
      remoteStream.value!.getTracks().forEach((track) => track.stop());
      remoteStream.value!.dispose();
      remoteStream.value = null;
    }

    if (peerConnection != null) {
      peerConnection!.close();
      peerConnection = null;
    }

    roomId = null;
    isInitiator = false;
  }

  void registerPeerConnectionListeners({RTCVideoRenderer? remoteRenderer}) {
    peerConnection?.onIceConnectionState = (state) {
      print('❄ ICE connection state: $state');
    };

    peerConnection?.onTrack = (event) {
      print("📥 Track received: ${event.track.kind}, ID: ${event.track.id}");

      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        remoteStream.value = stream;

        // Force enable all tracks
        stream.getTracks().forEach((track) {
          track.enabled = true;
          print("✅ Remote track enabled: ${track.kind}, ID: ${track.id}");
        });

        stream.getAudioTracks().forEach((track) {
          print(
            "🔊 Remote Audio Track: ID=${track.id}, ENABLED=${track.enabled}, MUTED=${track.muted}",
          );
        });

        stream.getVideoTracks().forEach((track) {
          print(
            "🎥 Remote Video Track: ID=${track.id}, ENABLED=${track.enabled}",
          );
        });

        // Update the renderer if provided
        if (remoteRenderer != null) {
          remoteRenderer.srcObject = stream;
          print("🖥 Remote renderer assigned to stream: ${stream.id}");
        }
      } else {
        print("⚠ Received track without stream.");
      }
    };

    peerConnection?.onConnectionState = (state) {
      print('🔗 Connection state: $state');
    };

    peerConnection?.onSignalingState = (state) {
      print('📶 Signaling state: $state');
    };

    peerConnection?.onIceGatheringState = (state) {
      print('❄ ICE gathering state: $state');
    };
  }
}
