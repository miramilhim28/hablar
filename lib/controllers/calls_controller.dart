import 'package:get/get.dart';
import 'package:hablar_clone/models/recent_calls.dart';

class CallsController extends GetxController {
  var selectedIndex = 1;
  var selectedFilter = 'All'.obs;

  final calls =
      <RecentCalls>[
        RecentCalls(name: 'Person X', callType: 'Voice', callTime: '12:33'),
        RecentCalls(name: 'Person Y', callType: 'Voice', callTime: '12:00'),
        RecentCalls(name: 'Person Z', callType: 'Video', callTime: '11:00', isMissed: true),
        RecentCalls(name: 'Person X', callType: 'Voice', callTime: 'Yesterday'),
        RecentCalls(name: 'Person Y', callType: 'Voice', callTime: 'Sunday'),
      ].obs;

      RxList<RecentCalls> get filteredCalls => selectedFilter.value == 'All' ? calls : calls.where((RecentCalls) => RecentCalls.isMissed).toList().obs;

      void updateSelectedIndex(int index) {
        selectedIndex = index;
      }

      void updateFilter(String filter) {
        selectedFilter.value = filter;
      }
}
