import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/services/firestore_service.dart';

class CallSignallingController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive variables
  RxBool isCallActive = false.obs;
  Rx<RTCPeerConnection?> peerConnection = Rxn<RTCPeerConnection>();
  Rx<MediaStream?> localStream = Rxn<MediaStream>();
  Rx<MediaStream?> remoteStream = Rxn<MediaStream>();
  
  String? currentUserId;
  String? remoteUserId;

  @override
  void onInit() {
    super.onInit();
    // Initial setup if needed
  }

  // Initialize peer connection
  Future<void> _initializePeerConnection() async {
    peerConnection.value = await createPeerConnection(_getConfiguration());
    await _addLocalTracks();
    _setupPeerConnectionListeners();
  }

  // Peer connection configuration
  Map<String, dynamic> _getConfiguration() {
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
  }

  // Add local media tracks to peer connection
  Future<void> _addLocalTracks() async {
    var stream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    localStream.value = stream;
    peerConnection.value?.addTrack(stream.getAudioTracks().first, stream);
  }

  // Setup peer connection listeners
  void _setupPeerConnectionListeners() {
    peerConnection.value?.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate.candidate != null && remoteUserId != null) {
        await _firestoreService.updateWebRTCInfo(remoteUserId!, {
          'werbRtcInfo': {
            'iceCandidates': FieldValue.arrayUnion([{
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            }]),
          },
        });
      }
    };

    peerConnection.value?.onTrack = (RTCTrackEvent event) {
      remoteStream.value = event.streams[0];
      remoteStream.value?.getTracks().forEach((track) {
        print('Add remote track: $track');
      });
    };
  }

  // Start Call
  Future<Map<String, dynamic>> createOffer({
    required String myUserId,
    required String remoteUserId,
  }) async {
    if (myUserId.isEmpty || remoteUserId.isEmpty) {
      throw Exception("Caller ID or Callee ID is missing.");
    }

    try {
      await _initializePeerConnection();
      isCallActive.value = true;

      RTCSessionDescription offer = await peerConnection.value!.createOffer();
      await peerConnection.value!.setLocalDescription(offer);

      // Store the offer in Firestore
      await _firestoreService.storeOffer(remoteUserId, offer, myUserId);

      return {'offerSDP': offer.sdp};
    } catch (e) {
      Get.snackbar("Error", "Failed to create offer: ${e.toString()}");
      rethrow;
    }
  }

  // Answer Call
  Future<void> answerCall(String calleeId) async {
    try {
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
      await peerConnection.value!.setRemoteDescription(
        RTCSessionDescription(data['werbRtcInfo']['offerSDP'], 'offer'),
      );

      RTCSessionDescription answer = await peerConnection.value!.createAnswer();
      await peerConnection.value!.setLocalDescription(answer);

      await _firestoreService.updateWebRTCInfo(remoteUserId!, {
        'werbRtcInfo': {
          'answerSDP': answer.sdp,
          'status': 'answered',
        },
      });

      listenForCallChanges(remoteUserId!);
    } catch (e) {
      Get.snackbar("Error", "Failed to answer call: ${e.toString()}");
    }
  }

  // Listen for Call Changes
  void listenForCallChanges(String userId) {
    _firestoreService.listenToWebRTCChanges(userId).listen((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;

      if (data.containsKey('werbRtcInfo')) {
        var werbRtcInfo = data['werbRtcInfo'];

        if (werbRtcInfo.containsKey('answerSDP')) {
          peerConnection.value!.setRemoteDescription(
            RTCSessionDescription(werbRtcInfo['answerSDP'], 'answer'),
          );
        }

        if (werbRtcInfo.containsKey('iceCandidates')) {
          for (var candidate in werbRtcInfo['iceCandidates']) {
            peerConnection.value!.addCandidate(
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
  Future<void> endCall() async {
    if (currentUserId != null) {
      await _firestoreService.clearWebRTCInfo(currentUserId!);
    }
    if (remoteUserId != null) {
      await _firestoreService.clearWebRTCInfo(remoteUserId!);
    }
    peerConnection.value?.close();
    localStream.value?.dispose();
    remoteStream.value?.dispose();
    peerConnection.value = null;
    isCallActive.value = false;
    currentUserId = null;
    remoteUserId = null;
  }

  // Hang Up
  Future<void> hangUp() async {
    await endCall();
  }
}
