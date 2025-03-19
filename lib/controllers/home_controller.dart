import 'package:get/get.dart';
import 'package:hablar_clone/screens/home_screens/recents_screen.dart';
import 'package:hablar_clone/screens/home_screens/chat_screens/chats_screen.dart';
import 'package:hablar_clone/screens/home_screens/contacts_screen.dart';
import 'package:hablar_clone/screens/home_screens/favorites_screen.dart';
import 'package:hablar_clone/screens/home_screens/settings_screen.dart';

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