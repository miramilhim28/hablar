import 'package:get/get.dart';
import 'package:hablar_clone/models/contact.dart';

class ContactsController extends GetxController{
  var search = ''.obs;
  var selectedIndex = 2;
  var contacts = <Contact>[
    Contact(name: 'A. Omari'),
    Contact(name: 'Ahmad Darawsheh'),
    Contact(name: "Amal's Lounge"),
    Contact(name: 'Baba'),
    Contact(name: 'Babel Studio'),
    Contact(name: 'Coach Emad'),
    Contact(name: 'D. Milhim'),
    Contact(name: 'D. Ayyat PSUT'),
    Contact(name: 'F. Bayyari CS'),
    Contact(name: 'F. Ayyat PSUT'),
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