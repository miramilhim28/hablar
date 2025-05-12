import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hablar_clone/models/profile.dart';

class InfoController extends GetxController {
  var selectedIndex = 5.obs;

  var profile = Profile(name: '', email: '', password: '', bio: '', phone: '').obs;
  var isLoading = false.obs;

  /// Fetch any contact's data using contactId (userId)
  Future<void> fetchContactData(String contactId) async {
    try {
      isLoading.value = true;
      final doc = await FirebaseFirestore.instance.collection('users').doc(contactId).get();

      if (doc.exists) {
        profile.value = Profile(
          name: doc.data()?['name'] ?? '',
          email: doc.data()?['email'] ?? '',
          password: doc.data()?['password'] ?? '',
          phone: doc.data()?['phone'] ?? '',
          bio: doc.data()?['bio'] ?? '',
        );
      } else {
        Get.snackbar('Error', 'Contact not found.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch contact: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateSelectedIndex(int index) {
    selectedIndex.value = index;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
