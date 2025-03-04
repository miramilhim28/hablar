import 'package:get/get.dart';
import 'package:hablar_clone/models/contact.dart';
import 'package:hablar_clone/models/favorite.dart';

class FavoritesController extends GetxController{
  var search = ''.obs;
  var selectedIndex = 0;
  var contacts = <Favorite>[].obs;

  RxList<Favorite> get filteredContacts =>
      search.value.isEmpty
          ? contacts
          : contacts
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
}