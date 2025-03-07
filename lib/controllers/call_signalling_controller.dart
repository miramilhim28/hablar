import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class CallSignallingController extends GetxController {
  RTCPeerConnection? _peerConnection;
  var iceCandidates = <RTCIceCandidate>[].obs;
  var isCallActive = false.obs;
  var remoteSDP = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePeerConnection();
  }

  Future<void> _initializePeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}, // STUN server
        {'urls': 'turn:your-turn-server.com', 'username': 'user', 'credential': 'pass'}, // Optional TURN server
      ],
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        iceCandidates.add(candidate);
      }
    };
  }

  /// Create an Offer SDP for initiating a call
  Future<Map<String, dynamic>> createOffer() async {
    await _initializePeerConnection();
    isCallActive.value = true;
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    return {
      'offerSDP': offer.sdp,
      'iceCandidates': iceCandidates.map((c) => c.toMap()).toList(),
    };
  }

  /// Create an Answer SDP to accept a call
  Future<Map<String, dynamic>> createAnswer(String offerSDP, List<dynamic> remoteIceCandidates) async {
    await _initializePeerConnection();
    remoteSDP.value = offerSDP;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerSDP, 'offer'),
    );

    for (var candidate in remoteIceCandidates) {
      _peerConnection!.addCandidate(RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ));
    }

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    return {
      'answerSDP': answer.sdp,
      'iceCandidates': iceCandidates.map((c) => c.toMap()).toList(),
    };
  }

  /// End the call
  void endCall() {
    _peerConnection?.close();
    _peerConnection = null;
    isCallActive.value = false;
    iceCandidates.clear();
    remoteSDP.value = '';
  }
}

