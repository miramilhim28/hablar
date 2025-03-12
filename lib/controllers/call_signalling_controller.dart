import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/services/firestore_service.dart';

class CallSignallingController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive variables for state management
  RxBool isCallActive = false.obs;
  RxList<RTCIceCandidate> iceCandidates = <RTCIceCandidate>[].obs;
  RxString remoteSDP = ''.obs;
  Rx<MediaStream?> localStream = Rxn<MediaStream>();
  Rx<MediaStream?> remoteStream = Rxn<MediaStream>();

  RTCPeerConnection? _peerConnection;
  String? currentUserId;
  String? remoteUserId;
  String? roomId;

  @override
  void onInit() {
    super.onInit();
    // Initialize the peer connection when the controller is initialized
    _initializePeerConnection();
  }

  // Initialize Peer Connection
  Future<void> _initializePeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    // Handle ICE Candidate
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        iceCandidates.add(candidate);
      }
    };

    // Handle incoming remote stream
    _peerConnection!.onAddStream = (MediaStream stream) {
      remoteStream.value = stream;
      update();
    };
  }

  // Create an Offer SDP for initiating a call
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

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      return {
        'offerSDP': offer.sdp,
        'iceCandidates': iceCandidates.map((c) => c.toMap()).toList(),
      };
    } catch (e) {
      Get.snackbar("Error", "Failed to create offer: ${e.toString()}");
      rethrow;
    }
  }

  // Create an Answer SDP to accept a call
  Future<Map<String, dynamic>> createAnswer(
    String offerSDP,
    List<dynamic> remoteIceCandidates,
  ) async {
    try {
      await _initializePeerConnection();
      remoteSDP.value = offerSDP;
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerSDP, 'offer'),
      );

      for (var candidate in remoteIceCandidates) {
        _peerConnection!.addCandidate(
          RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ),
        );
      }

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send the answer and ICE candidates back to the remote peer
      return {
        'answerSDP': answer.sdp,
        'iceCandidates': iceCandidates.map((c) => c.toMap()).toList(),
      };
    } catch (e) {
      Get.snackbar("Error", "Failed to create answer: ${e.toString()}");
      rethrow;
    }
  }

  // Listen for changes in the call
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

  // End the call
  void endCall() {
    _peerConnection?.close();
    _peerConnection = null;
    isCallActive.value = false;
    iceCandidates.clear();
    remoteSDP.value = '';
  }

  // Hang Up the call
  Future<void> hangUp() async {
    endCall();
  }

  // Store ICE candidates in Firestore
  Future<void> storeIceCandidates(
    String remoteUserId,
    List<RTCIceCandidate> candidates,
  ) async {
    try {
      await _firestoreService.storeIceCandidates(remoteUserId, candidates);
    } catch (e) {
      Get.snackbar("Error", "Failed to store ICE candidates: ${e.toString()}");
    }
  }

  // Store the WebRTC offer in Firestore
  Future<void> storeOffer(
    String remoteUserId,
    RTCSessionDescription offer,
    String callerId,
  ) async {
    try {
      await _firestoreService.storeOffer(remoteUserId, offer, callerId);
    } catch (e) {
      Get.snackbar("Error", "Failed to store offer: ${e.toString()}");
    }
  }

  // Store the WebRTC answer in Firestore
  Future<void> storeAnswer(
    String remoteUserId,
    RTCSessionDescription answer,
  ) async {
    try {
      await _firestoreService.storeAnswer(remoteUserId, answer);
    } catch (e) {
      Get.snackbar("Error", "Failed to store answer: ${e.toString()}");
    }
  }
}
