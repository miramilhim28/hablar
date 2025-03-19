import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/controllers/recents_controller.dart';

class CallsScreen extends StatelessWidget {
  final CallsController controller = Get.put(CallsController());

  CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              final call = controller.filteredCalls[index];
                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: utils.pinkLilac,
                                      child: Text(call.name.isNotEmpty
                                          ? call.name[0]
                                          : '?'), 
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
                                          call.callType == "audio"
                                              ? Icons.call
                                              : Icons.videocam,
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
                                      call.callTime,
                                      style: TextStyle(color: utils.darkGrey),
                                    ),
                                  ),
                                  Divider(thickness: 1, color: utils.darkGrey),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
