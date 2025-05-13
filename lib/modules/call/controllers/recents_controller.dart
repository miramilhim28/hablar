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

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .where('callerId', isEqualTo: currentUserId)
          .get();

      QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
          .collection('calls')
          .where('calleeId', isEqualTo: currentUserId)
          .get();

      List<QueryDocumentSnapshot> allCalls = [
        ...querySnapshot.docs,
        ...querySnapshot2.docs,
      ];

      allCalls.sort((a, b) {
        Timestamp t1 = a['timestamp'];
        Timestamp t2 = b['timestamp'];
        return t2.compareTo(t1);
      });

      calls.value = allCalls.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return RecentCalls(
          name: "Unknown",
          callType: data['callType'] ?? 'Unknown',
          callTime: (data['timestamp'] as Timestamp).toDate(),
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
          await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        call.name = userSnapshot['name'] ?? "Unknown";
      }
    }
    calls.refresh();
  }

  Future<void> deleteCall(RecentCalls call) async {
    try {
      final callsRef = FirebaseFirestore.instance.collection('calls');
      final query = await callsRef
          .where('callerId', isEqualTo: call.callerId)
          .where('calleeId', isEqualTo: call.calleeId)
          .where('timestamp', isEqualTo: Timestamp.fromDate(call.callTime))
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      calls.remove(call);
    } catch (e) {
      print('Error deleting call: $e');
    }
  }

  RxList<RecentCalls> get filteredCalls => selectedFilter.value == 'All'
      ? calls
      : calls.where((call) => call.isMissed).toList().obs;

  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
  }
}