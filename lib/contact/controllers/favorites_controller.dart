import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar_clone/models/favorite.dart';

class FavoritesController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var search = ''.obs;
  var selectedIndex = 0;
  var favorites = <Favorite>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchFavorites();
  }

  // Fetch favorites from Firestore
  Future<void> fetchFavorites() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    var userRef = _firestore.collection('users').doc(currentUser.uid);

    try {
      var snapshot = await userRef.get();
      if (!snapshot.exists) return;

      var favoriteList = snapshot.data()?['favorites'] as List<dynamic>? ?? [];

      favorites.value =
          favoriteList
              .map((data) {
                if (data is Map<String, dynamic>) {
                  return Favorite.fromJson(data);
                }
                return null;
              })
              .whereType<Favorite>()
              .toList();
    } catch (e) {
      print("Error fetching favorites: $e");
    }
  }

  // Toggle Favorite Status
  Future<void> toggleFavorite(Favorite contact) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    var userRef = _firestore.collection('users').doc(currentUser.uid);

    try {
      bool isFavorite = favorites.any((c) => c.id == contact.id);

      if (isFavorite) {
        // Remove from Firestore
        await userRef.update({
          'favorites': FieldValue.arrayRemove([contact.toJson()]),
        });
        favorites.removeWhere((c) => c.id == contact.id);
      } else {
        // Add to Firestore
        await userRef.update({
          'favorites': FieldValue.arrayUnion([contact.toJson()]),
        });
        favorites.add(contact);
      }

      favorites.refresh(); 
    } catch (e) {
      print("Error updating favorites: $e");
    }
  }

  // Filter Favorites Based on Search
  RxList<Favorite> get filteredFavorites =>
      search.value.isEmpty
          ? favorites
          : favorites
              .where(
                (fav) =>
                    fav.name.toLowerCase().contains(search.value.toLowerCase()),
              )
              .toList()
              .obs;

  void updateSearch(String s) {
    search.value = s;
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
  }

  bool isFavorite(String id) {
    return favorites.any((fav) => fav.id == id);
  }
}
