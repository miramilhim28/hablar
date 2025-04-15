import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/controllers/recents_controller.dart';
import 'package:hablar_clone/models/recent_calls.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/join_screen.dart';

class CallsScreen extends StatelessWidget {
  final CallsController controller = Get.put(CallsController());

  CallsScreen({super.key});

  String formatCallTime(DateTime callTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDay = DateTime(callTime.year, callTime.month, callTime.day);
    final difference = today.difference(callDay).inDays;

    if (difference == 0) {
      return DateFormat('h:mm a').format(callTime);
    } else if (difference < 7) {
      return DateFormat('EEEE').format(callTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(callTime);
    }
  }

  void _recallCall(RecentCalls call) {
    Get.to(() => JoinScreen(
          callerId: FirebaseAuth.instance.currentUser!.uid,
          calleeId: call.callerId == FirebaseAuth.instance.currentUser!.uid
              ? call.calleeId
              : call.callerId,
          callType: call.callType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Recents',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: utils.darkGrey,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.updateFilter('All'),
                        child: Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: controller.selectedFilter.value == 'All'
                                  ? utils.darkPurple
                                  : utils.purpleLilac,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'All',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: controller.selectedFilter.value == 'All'
                                      ? utils.white
                                      : utils.darkGrey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.updateFilter('Missed'),
                        child: Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: controller.selectedFilter.value == 'Missed'
                                  ? utils.darkPurple
                                  : utils.purpleLilac,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'Missed',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: controller.selectedFilter.value == 'Missed'
                                      ? utils.white
                                      : utils.darkGrey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(
                    () => controller.filteredCalls.isEmpty
                        ? Center(
                            child: Text(
                              "No recent calls",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: utils.darkGrey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: controller.filteredCalls.length,
                            itemBuilder: (context, index) {
                              final RecentCalls call = controller.filteredCalls[index];
                              return Dismissible(
                                key: ValueKey(call.hashCode),
                                background: Container(
                                  color: Colors.green,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Icon(
                                    call.callType == "video" ? Icons.videocam : Icons.call,
                                    color: Colors.white,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    _recallCall(call);
                                    return false;
                                  } else if (direction == DismissDirection.endToStart) {
                                    await controller.deleteCall(call);
                                    return true;
                                  }
                                  return false;
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: utils.pinkLilac,
                                    child: Text(
                                      call.name.isNotEmpty ? call.name[0] : '?',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        color: utils.darkGrey,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    call.name,
                                    style: TextStyle(
                                      color: call.isMissed ? Colors.red : utils.darkGrey,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        call.callType == "audio" ? Icons.call : Icons.videocam,
                                        size: 16,
                                        color: call.isMissed ? Colors.red : utils.darkGrey,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        call.callType.capitalizeFirst!,
                                        style: TextStyle(color: utils.darkGrey),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    formatCallTime(call.callTime),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: utils.darkGrey,
                                    ),
                                  ),
                                ),
                              );
                            },
                  ),
                ),
              ),
          )],
          ),
        ),
      ),
    );
  }
}