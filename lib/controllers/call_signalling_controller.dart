import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
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

  // Open user media
  Future<void> openUserMedia() async {
    localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });
  }

  //Create a eoom and store WebRTC Offer
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

  // Join an existing room (SDP answer)
  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteRenderer) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentReference roomRef = db.collection('calls').doc(roomId);
  var roomSnapshot = await roomRef.get();

  if (roomSnapshot.exists) {
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    // Add local stream to peer connection
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Store ICE candidates
    var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      calleeCandidatesCollection.add(candidate.toMap());
    };

    // Retrieve offer and create answer
    var data = roomSnapshot.data() as Map<String, dynamic>;
    var offer = data['offer'];
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    // Generate and Store answer SDP
    var answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    print("✅ Answer SDP Generated: ${answer.sdp}");

    await roomRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp}
    });

    //Listen for ICE candidates
    roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        var data = change.doc.data() as Map<String, dynamic>;
        peerConnection!.addCandidate(
          RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
        );
      }
    });
  }
}


  void listenForIncomingCalls(String userId, {required String calleeId}) {
  FirebaseFirestore.instance
      .collection('calls')
      .where('calleeId', isEqualTo: userId) 
      .where('callStatus', isEqualTo: 'calling')
      .snapshots()
      .listen((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      var callData = snapshot.docs.first.data();
      String callId = callData['callId'];
      String callerId = callData['callerId'];
      String callType = callData['callType'];
      String callerName = "Unknown Caller";

      if (Get.currentRoute != '/IncomingCallScreen') {
        Get.to(() => IncomingCallScreen(
              callId: callId,
              callerId: callerId,
              calleeId: userId,
              callerName: callerName,
              callType: callType,
            ));
      }
    }
  }, onError: (error) {
    print("Error listening for incoming calls: $error");
  });
}





  Future<void> acceptCall(String callId) async {
  try {
    RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    await joinRoom(callId, remoteRenderer);

    await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
      'callStatus': 'answered',
    });

    DocumentSnapshot callSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(callId)
        .get();

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
  } catch (e) {
    Get.snackbar("Error", "Failed to accept call: ${e.toString()}");
  }
}


  Future<void> declineCall(String callId) async {
    await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
      'callStatus': 'declined',
    });

    hangUp();
    Get.back();
  }

  Future<void> hangUp() async {
  if (roomId == null) return;
  
  FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentReference roomRef = db.collection('calls').doc(roomId);

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
