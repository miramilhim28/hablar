import 'package:get/get.dart';
import 'package:hablar_clone/models/contact.dart';

class FavoritesController extends GetxController{
  var search = ''.obs;
  var selectedIndex = 0;
  var contacts = <Contact>[
    Contact(name: 'John Doe'),
    Contact(name: 'Person X'),
    Contact(name: 'Person Y'),
    Contact(name: 'Person Z'),
  ].obs;

  RxList<Contact> get filteredContacts =>
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