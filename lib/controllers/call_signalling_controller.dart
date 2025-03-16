import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/video_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/incoming_call_screen.dart';

class CallSignallingController extends GetxController {

  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Rx<MediaStream?> remoteStream = Rx<MediaStream?>(null);
  RxBool isCallActive = false.obs;
  String? roomId;

  @override
  void onInit() {
    super.onInit();
    initializePeerConnection();
  }

  /// **Initialize WebRTC Peer Connection**
  Future<void> initializePeerConnection() async {
    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('candidates').add(candidate.toMap());
    };

    peerConnection!.onAddStream = (MediaStream stream) {
      remoteStream.value = stream;
      update();
    };
  }

  /// **Open User Media (Camera & Microphone)**
  Future<void> openUserMedia() async {
    localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });
  }

  /// **Create a Room and Store WebRTC Offer**
  Future<String> createRoom() async {
    await openUserMedia(); 

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await roomRef.set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'callStatus': 'calling'
    });

    roomId = roomRef.id;

    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;

      if (peerConnection!.getRemoteDescription() == null && data['answer'] != null) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await peerConnection!.setRemoteDescription(answer);
      }
    });

    return roomId!;
  }

  /// **Join an Existing Room (Handles SDP Answer)**
  Future<void> joinRoom(String roomId) async {
    await openUserMedia(); // ✅ Open Media Before Joining

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });

      var data = roomSnapshot.data() as Map<String, dynamic>;
      if (data.containsKey('offer')) {
        var offer = data['offer'];
        await peerConnection!.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );
      }

      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      await roomRef.update({'answer': {'type': answer.type, 'sdp': answer.sdp}});
    }
  }

  void listenForIncomingCalls() {
  print("📡 Listening for calls..."); // ✅ Debug Print

  FirebaseFirestore.instance
      .collection('calls') // ✅ Make sure this is the correct collection
      .where('callStatus', isEqualTo: 'calling')
      .snapshots()
      .listen((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      var callData = snapshot.docs.first.data();
      String callId = callData['callId'];
      String callerId = callData['callerId'];
      String calleeId = callData['calleeId'];
      String callType = callData['callType'];
      String callerName = "Unknown Caller";

      print("📞 Incoming call from: $callerId"); // ✅ Debug Print

      if (Get.currentRoute != '/IncomingCallScreen') {
        Get.to(() => IncomingCallScreen(
              callId: callId,
              callerId: callerId,
              calleeId: calleeId,
              callerName: callerName,
              callType: callType,
            ));
      }
    }
  }, onError: (error) {
    print("🚨 Error listening for incoming calls: $error");
  });
}




  /// **Handle Call Answer**
  Future<void> acceptCall(String callId) async {
    await joinRoom(callId);
    await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
      'callStatus': 'answered',
    });

    DocumentSnapshot callSnapshot = await FirebaseFirestore.instance.collection('rooms').doc(callId).get();
    String callType = callSnapshot['callType'];

    if (callType == "video") {
      Get.off(() => VideoCallScreen(
            callerId: callSnapshot['callerId'],
            calleeId: callSnapshot['calleeId'],
            callId: callId,
          ));
    } else {
      Get.off(() => AudioCallScreen(
            callerId: callSnapshot['callerId'],
            calleeId: callSnapshot['calleeId'],
            callId: callId,
          ));
    }
  }

  /// **Decline Call**
  Future<void> declineCall(String callId) async {
    await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
      'callStatus': 'declined',
    });

    hangUp();
    Get.back();
  }

  /// **End Call & Clean Up**
  Future<void> hangUp() async {
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        track.stop();
      }
      localStream!.dispose();
    }

    if (remoteStream.value != null) {
      for (var track in remoteStream.value!.getTracks()) {
        track.stop();
      }
      remoteStream.value!.dispose();
    }

    peerConnection?.close();
    peerConnection = null;

    if (roomId != null) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db.collection('rooms').doc(roomId);

      await roomRef.collection('callerCandidates').get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await roomRef.collection('calleeCandidates').get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await roomRef.delete();
    }
  }

  /// **Register WebRTC Listeners**
  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state changed: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state changed: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      remoteStream.value = stream;
    };
  }
}
