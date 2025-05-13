import 'package:get/get.dart';
import 'package:hablar_clone/modules/call/screens/recents_screen.dart';
import 'package:hablar_clone/modules/chat/screens/chats_screen.dart';
import 'package:hablar_clone/contact/screens/contacts_screen.dart';
import 'package:hablar_clone/contact/screens/favorites_screen.dart';
import 'package:hablar_clone/modules/settings/screens/settings_screen.dart';

class HomeController extends GetxController {
  var selectedIndex = 2; //default to 'Contacts' screen

  List pages =[
    FavoritesScreen(),
    CallsScreen(),
    ContactScreen(),
    ChatsScreen(),
    SettingsScreen(),
  ];



void updateSelectedIndex(int index) {
    selectedIndex = index; 
    update(); 
  }}