import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/recent_calls.dart';

class CallsController extends GetxController {
  var selectedIndex = 1;
  var selectedFilter = 'All'.obs;
  var calls = <RecentCalls>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCalls();
  }

  Future<void> fetchCalls() async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('calls')
              .where('callerId', isEqualTo: currentUserId)
              .get();

      QuerySnapshot querySnapshot2 =
          await FirebaseFirestore.instance
              .collection('calls')
              .where('calleeId', isEqualTo: currentUserId)
              .get();

      List<QueryDocumentSnapshot> allCalls = [
        ...querySnapshot.docs,
        ...querySnapshot2.docs,
      ];

      calls.value =
          allCalls.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            return RecentCalls(
              name: "Unknown",
              callType: data['callType'] ?? 'Unknown',
              callTime: _formatTimestamp(data['timestamp']),
              isMissed: data['callStatus'] == 'missed',
              callerId: data['callerId'],
              calleeId: data['calleeId'],
            );
          }).toList();

      await _updateCallNames();
    } catch (e) {
      print("Error fetching calls: $e");
    }
  }

  Future<void> _updateCallNames() async {
    for (var call in calls) {
      String userId = call.callerId;

      if (call.callerId == FirebaseAuth.instance.currentUser?.uid) {
        userId = call.calleeId;
      }

      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        call.name = userSnapshot['name'] ?? "Unknown";
      }
    }

    calls.refresh();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
    return "Unknown";
  }

  RxList<RecentCalls> get filteredCalls =>
      selectedFilter.value == 'All'
          ? calls
          : calls.where((call) => call.isMissed).toList().obs;

  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
  }
}
