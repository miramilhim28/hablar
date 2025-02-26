import 'package:get/get.dart';
import 'package:hablar_clone/models/chats.dart';
import 'package:hablar_clone/screens/home_screens/chats_screen.dart';

class ChatsController extends GetxController {
  var search = ''.obs;
  var selectedIndex = 3;
  var chats =
      <Chat>[
        Chat(name: 'John Doe', time:'11:00'),
        Chat(name: 'Person X', time:'9:00'),
        Chat(name: 'Person Y', time:'Yesterday'),
        Chat(name: 'Person Z', time:'Sunday'),
      ].obs;

  RxList<Chat> get filteredChats =>
      search.value.isEmpty
          ? chats
          : chats
              .where(
                (Phone) => Phone.name.toLowerCase().contains(
                  search.value.toLowerCase(),
                ),
              )
              .toList()
              .obs;
  
  void updateSearch(String s){
    search.value = s;
  }

  void updateSelectedIndex(int index){
    selectedIndex = index;
  }

  void goToChatDetails(Chat chat) {
    Get.toNamed(ChatsScreen() as String);
  }
}
