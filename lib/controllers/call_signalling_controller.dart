import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/video_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/incoming_call_screen.dart';
import 'package:hablar_clone/services/firestore_service.dart';

class CallSignallingController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

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
  String? roomId;
  RxBool isCallActive = false.obs;
  RxList<RTCIceCandidate> iceCandidates = <RTCIceCandidate>[].obs;
  Rx<MediaStream?> remoteStream = Rx<MediaStream?>(null);
  RxString remoteSDP = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializePeerConnection();
  }

  Future<void> initializePeerConnection() async {
  peerConnection = await createPeerConnection({
    'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
  });

  peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
    if (candidate.candidate != null) {
      iceCandidates.add(candidate);
    }
  };

  peerConnection!.onAddStream = (MediaStream stream) {
    remoteStream.value = stream;
    update();
  };
}

  /// **Create a New Call Room (Caller)**
  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc();
    
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Store ICE Candidates
    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap());
    };

    // Create SDP Offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await roomRef.set({'offer': offer.toMap()});
    roomId = roomRef.id;
    
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;

      if (peerConnection?.getRemoteDescription() == null && data['answer'] != null) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await peerConnection?.setRemoteDescription(answer);
      }
    });

    // Listen for ICE candidates
    roomRef.collection('iceCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        var data = change.doc.data() as Map<String, dynamic>;
        peerConnection!.addCandidate(
          RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
        );
      }
    });

    return roomId!;
  }

  /// **Join an Existing Call Room (Callee)**
  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Store ICE Candidates
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      // Retrieve Offer & Create Answer
      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      await roomRef.update({
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      });

      // Listen for ICE Candidates
      roomRef.collection('iceCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          var data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
          );
        }
      });
    }
  }

  /// **Start a Call (Audio or Video)**
  Future<void> startCall({
    required String callerId,
    required String calleeId,
    required String callType,
  }) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc();

    Map<String, dynamic> newCall = {
      'callId': roomRef.id,
      'callerId': callerId,
      'calleeId': calleeId,
      'callType': callType,
      'callStatus': "calling",
      'callTime': FieldValue.serverTimestamp(),
    };

    await roomRef.set(newCall);
    navigateToCallScreen(roomRef.id);
  }

  /// **Navigate to the Correct Call Screen**
  Future<void> navigateToCallScreen(String callId) async {
    DocumentSnapshot callSnapshot =
        await FirebaseFirestore.instance.collection('calls').doc(callId).get();

    if (callSnapshot.exists) {
      String callType = callSnapshot['callType'] ?? 'audio';

      if (callType == 'video') {
        Get.to(() => VideoCallScreen(
              callerId: callSnapshot['callerId'],
              calleeId: callSnapshot['calleeId'],
              callId: callSnapshot['callId'],
              offer: callSnapshot['offer'],
            ));
      } else {
        Get.to(() => AudioCallScreen(
              callerId: callSnapshot['callerId'],
              calleeId: callSnapshot['calleeId'],
              callId: callSnapshot['callId'],
              offer: callSnapshot['offer'],
            ));
      }
    }
  }

  /// **End Call & Clean Up**
  Future<void> hangUp() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc(roomId);

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

    await roomRef.delete();

    localStream?.dispose();
    remoteStream.value?.dispose();
    peerConnection?.close();
  }

  /// **Register WebRTC Events**
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
