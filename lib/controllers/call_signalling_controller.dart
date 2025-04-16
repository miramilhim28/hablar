import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
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
  webrtc.RTCVideoRenderer? _remoteAudioRenderer;
  MediaStream? localStream;
  Rx<MediaStream?> remoteStream = Rx<MediaStream?>(null);
  RxBool isCallActive = false.obs;
  String? roomId;

  @override
  void onInit() {
    super.onInit();
    initializePeerConnection();

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      listenForIncomingCalls(userId);
    }
  }

  /// **Initialize WebRTC Peer Connection**
  Future<void> initializePeerConnection() async {
    peerConnection = await createPeerConnection(configuration);

    // ✅ ICE Candidate Debug
    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print("🧊 ICE Candidate: ${candidate.candidate}");

      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('candidates')
          .add(candidate.toMap());
    };

    // ✅ ICE Connection State Debug
    peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print("🔄 ICE State: $state");
    };

    // ✅ Setup & store renderer early
    _remoteAudioRenderer = webrtc.RTCVideoRenderer();
    await _remoteAudioRenderer!.initialize();

    // ✅ Stream Handling
    /*peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream.value = event.streams.first;
        print("📥 Track received: ${event.track.kind}");

        if (event.track.kind == 'video') {
          print("🎥 Remote video track received");
        } else if (event.track.kind == 'audio') {
          print("🔊 Remote audio track received");
        }
      } else {
        print("⚠️ Track received without stream");
      }
    };*/

    print("✅ Peer Connection Initialized!");
  }

  // Open user media
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

    // Optional debug
    localStream?.getTracks().forEach((track) {
      print("🎥 Local track: ${track.kind}, enabled: ${track.enabled}");
    });
  }

  //Create a room and store WebRTC Offer
  Future<String> createRoom() async {
    await openUserMedia();

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    // Add local tracks
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        peerConnection?.addTrack(track, localStream!);
      }
    }

    // ✅ Create offer with media constraints
    final offer = await peerConnection!.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
      'optional': [],
    });

    // ✅ Set local description
    await peerConnection!.setLocalDescription(offer);

    // ✅ Store offer in Firestore
    await roomRef.set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'callStatus': 'calling',
    });

    roomId = roomRef.id;

    // ✅ Listen for the answer (callee response)
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;

      if (peerConnection!.getRemoteDescription() == null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await peerConnection!.setRemoteDescription(answer);
        print("✅ Answer SDP Set Successfully");
      }
    });

    return roomId!;
  }

  // Join an existing room (SDP answer)
  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteRenderer) async {
    await openUserMedia(video: true);

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('calls').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection ??= await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      // Add local tracks
      if (localStream != null) {
        for (var track in localStream!.getTracks()) {
          peerConnection?.addTrack(track, localStream!);
        }
      }

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];

      // ✅ Make sure this completes successfully
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      print("✅ Remote description set!");

      // ✅ Now it's safe to create the answer
      final answer = await peerConnection!.createAnswer({
        'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
        'optional': [],
      });

      await peerConnection!.setLocalDescription(answer);

      print("✅ Answer SDP Generated: ${answer.sdp}");

      await roomRef.update({
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      });

      peerConnection?.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          final remote = event.streams.first;

          remoteStream.value = remote;
          remoteRenderer.srcObject = remote;

          print("✅ Remote stream assigned to renderer");

          remote.getVideoTracks().forEach((track) {
            print(
              "🎥 Remote video track: ${track.id}, enabled: ${track.enabled}",
            );
          });

          remote.getAudioTracks().forEach((track) {
            track.enabled = true;
            print(
              "🔊 Remote audio track: ${track.id}, enabled: ${track.enabled}",
            );
          });
        } else {
          print("⚠️ Received track without stream.");
        }
      };
    }
  }

  void listenForIncomingCalls(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists &&
                snapshot.data()!.containsKey('incomingCall')) {
              var callData = snapshot.data()!['incomingCall'];

              String callId = callData['callId'];
              String callerId = callData['callerId'];
              String callType = callData['callType'];

              print("📞 Incoming call detected for user $userId");

              if (Get.currentRoute != '/IncomingCallScreen') {
                print("📞 Navigating to Incoming Call Screen");

                Get.to(
                  () => IncomingCallScreen(
                    callId: callId,
                    callerId: callerId,
                    calleeId: userId,
                    callerName: "Caller",
                    callType: callType,
                  ),
                );
              }
            }
          },
          onError: (error) {
            print("❌ Error listening for incoming calls: $error");
          },
        );
  }

  Future<void> acceptCall(String callId) async {
    try {
      RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
      await remoteRenderer.initialize();

      if (peerConnection == null) {
        print("⚠️ Peer Connection is NULL, initializing...");
        await initializePeerConnection();
      }

      if (localStream == null) {
        print("⚠️ Local stream is NULL, opening user media...");
        await openUserMedia();
      }

      DocumentSnapshot callSnapshot =
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(callId)
              .get();

      if (!callSnapshot.exists) {
        throw Exception("Call document not found in Firestore.");
      }

      var callData = callSnapshot.data() as Map<String, dynamic>;

      // 🔹 Join room before setting SDP
      await joinRoom(callId, remoteRenderer);

      // 🔹 Check if PeerConnection is in 'stable' state
      if (peerConnection!.signalingState ==
          RTCSignalingState.RTCSignalingStateStable) {
        print(
          "✅ Peer Connection is already stable, skipping setRemoteDescription.",
        );
      } else {
        // 🔹 Set Remote Description only if not stable
        var answerSDP = RTCSessionDescription(
          callData['answer']['sdp'],
          callData['answer']['type'],
        );

        await peerConnection!.setRemoteDescription(answerSDP);
        print("✅ Remote Description set successfully!");
      }

      // 🔹 Update Firestore call status to 'answered'
      await FirebaseFirestore.instance.collection('calls').doc(callId).update({
        'callStatus': 'answered',
      });

      // 🔹 Attach Remote Stream
      if (remoteStream.value != null) {
        remoteRenderer.srcObject = remoteStream.value;
        print("✅ Remote Audio & Video Stream Attached!");
      } else {
        print("⚠️ Remote stream is NULL!");
      }

      // 🔹 Navigate to the appropriate screen
      String callType = callData['callType'];
      if (callType == "video") {
        Get.off(
          () => VideoCallScreen(
            callerId: callData['callerId'],
            calleeId: callData['calleeId'],
            callId: callId,
          ),
        );
      } else {
        Get.off(
          () => AudioCallScreen(
            callerId: callData['callerId'],
            calleeId: callData['calleeId'],
            callId: callId,
          ),
        );
      }
    } catch (e) {
      print("❌ Error in acceptCall: $e");
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
    peerConnection?.onTrack = (event) {
      print("📥 Track received: ${event.track.kind}, ID: ${event.track.id}");

      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        remoteStream.value = stream;

        if (event.track.kind == 'video') {
          print("🎥 Remote video track received!");
          _remoteAudioRenderer?.srcObject = stream;
        }

        if (event.track.kind == 'audio') {
          print("🔊 Remote audio track received.");
        }
      } else {
        print("⚠️ Received track without stream.");
      }
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state changed: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state changed: $state');
    };
  }
}