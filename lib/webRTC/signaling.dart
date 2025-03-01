import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCSignaling {
  RTCPeerConnection? _peerConnection;
  List<RTCIceCandidate> _iceCandidates = [];

  Future<void> _initializePeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}, // STUN server
        {'urls': 'turn:your-turn-server.com', 'username': 'user', 'credential': 'pass'}, // Optional TURN server
      ],
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _iceCandidates.add(candidate);
      }
    };
  }

  /// Create Offer SDP
  Future<Map<String, dynamic>> createOffer() async {
    await _initializePeerConnection();

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    return {
      'offerSDP': offer.sdp,
      'iceCandidates': _iceCandidates.map((c) => c.toMap()).toList(),
    };
  }

  /// Create Answer SDP and collect ICE candidates
  Future<Map<String, dynamic>> createAnswer(String offerSDP, List<dynamic> remoteIceCandidates) async {
    await _initializePeerConnection();

    // Set remote offer SDP
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerSDP, 'offer'),
    );

    // Add remote ICE candidates
    for (var candidate in remoteIceCandidates) {
      _peerConnection!.addCandidate(RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ));
    }

    // Generate answer SDP
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    return {
      'answerSDP': answer.sdp,
      'iceCandidates': _iceCandidates.map((c) => c.toMap()).toList(),
    };
  }
}





