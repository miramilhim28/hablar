import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/services/firestore_service.dart';

class CallSignallingController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  var isCallActive = false.obs;
  String? currentUserId;
  String? remoteUserId;

  @override
  void onInit() {
    super.onInit();
  }

  // Initialize peer connection
  Future<void> _initializePeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': 'turn:your-turn-server.com',
          'username': 'user',
          'credential': 'pass',
        },
      ],
    });

    _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (var track in _localStream!.getAudioTracks()) {
      _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate.candidate != null && remoteUserId != null) {
        await _firestoreService.updateWebRTCInfo(remoteUserId!, {
          'werbRtcInfo': {
            'iceCandidates': FieldValue.arrayUnion([
              {
                'candidate': candidate.candidate,
                'sdpMid': candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
              },
            ]),
          },
        });
      }
    };
  }

  // Start Call
  Future<Map<String, dynamic>> createOffer({
  required String myUserId,
  required String remoteUserId,
}) async {
  if (myUserId.isEmpty || remoteUserId.isEmpty) {
    throw Exception("Caller ID or Callee Id is missing.");
  }

  await _initializePeerConnection();
  isCallActive.value = true;

  // Create the offer
  RTCSessionDescription offer = await _peerConnection!.createOffer();
  await _peerConnection!.setLocalDescription(offer);

  // Store the offer in Firestore under the recipient's document
  DocumentReference userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(remoteUserId);

  await userRef.update({
    'werbRtcInfo': {
      'offerSDP': offer.sdp,
      'callerId': myUserId,
      'status': 'initiated',
      'iceCandidates': [],
    },
  });

  // Return the offer SDP for further use
  return {'offerSDP': offer.sdp};
}


  // Answer Call
  Future<void> answerCall(String calleeId) async {
    currentUserId = calleeId;

    DocumentSnapshot snapshot =
        await _firestoreService.getUserRef(calleeId).get();
    var data = snapshot.data() as Map<String, dynamic>;

    if (!data.containsKey('werbRtcInfo') ||
        !data['werbRtcInfo'].containsKey('offerSDP')) {
      Get.snackbar("Error", "No incoming call found");
      return;
    }

    remoteUserId = data['werbRtcInfo']['callerId'];

    await _initializePeerConnection();
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(data['werbRtcInfo']['offerSDP'], 'offer'),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _firestoreService.updateWebRTCInfo(remoteUserId!, {
      'werbRtcInfo': {
        'answerSDP': answer.sdp,
        'status': 'answered',
      },
    });

    listenForCallChanges(remoteUserId!);
  }

  // Listen for Call Changes
  void listenForCallChanges(String userId) {
    _firestoreService.listenToWebRTCChanges(userId).listen((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;

      if (data.containsKey('werbRtcInfo')) {
        var werbRtcInfo = data['werbRtcInfo'];

        if (werbRtcInfo.containsKey('answerSDP')) {
          _peerConnection!.setRemoteDescription(
            RTCSessionDescription(werbRtcInfo['answerSDP'], 'answer'),
          );
        }

        if (werbRtcInfo.containsKey('iceCandidates')) {
          for (var candidate in werbRtcInfo['iceCandidates']) {
            _peerConnection!.addCandidate(
              RTCIceCandidate(
                candidate['candidate'],
                candidate['sdpMid'],
                candidate['sdpMLineIndex'],
              ),
            );
          }
        }
      }
    });
  }

  // End Call
  void endCall() {
    if (currentUserId != null) {
      _firestoreService.clearWebRTCInfo(currentUserId!);
    }
    if (remoteUserId != null) {
      _firestoreService.clearWebRTCInfo(remoteUserId!);
    }
    _peerConnection?.close();
    _localStream?.dispose();
    _peerConnection = null;
    isCallActive.value = false;
    currentUserId = null;
    remoteUserId = null;
  }
}
