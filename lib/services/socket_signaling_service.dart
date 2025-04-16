import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketSignalingService {
  IO.Socket? socket;

  Future<void> connect(String roomId) async {
  final completer = Completer<void>();

  socket = IO.io('http://172.16.32.25:3000', {
    'transports': ['websocket'],
    'autoConnect': false,
  });

  socket!.connect();

  socket!.onConnect((_) {
    print("✅ Connected to signaling server!");
    socket!.emit('join', roomId);
    completer.complete(); // ✅ now connected
  });

  socket!.onConnectError((err) {
    print("❌ Connection error: $err");
    completer.completeError(err);
  });

  socket!.onDisconnect((_) {
    print("❌ Disconnected from server");
  });

  return completer.future;
}

  void sendOffer(String roomId, Map<String, dynamic> offer) {
    if (socket?.connected == true) {
      socket!.emit('offer', {
        'roomId': roomId,
        'offer': offer,
      });
    } else {
      print("❌ Socket not connected. Cannot send offer.");
    }
  }

  void sendAnswer(String roomId, Map<String, dynamic> answer) {
    if (socket?.connected == true) {
      socket!.emit('answer', {
        'roomId': roomId,
        'answer': answer,
      });
    } else {
      print("❌ Socket not connected. Cannot send answer.");
    }
  }

  void sendIceCandidate(String roomId, Map<String, dynamic> candidate) {
    if (socket?.connected == true) {
      socket!.emit('ice-candidate', {
        'roomId': roomId,
        'candidate': candidate,
      });
    } else {
      print("❌ Socket not connected. Cannot send ICE candidate.");
    }
  }

  void disconnect() {
    socket?.disconnect();
    print("👋 Socket disconnected manually.");
  }
}
