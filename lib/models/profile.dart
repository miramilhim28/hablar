
class Profile{
  final String name;
  final String email;
  final String password;
  final String phone;
  //final String photoUrl;
  final String bio;

  const Profile({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    //required this.photoUrl,
    required this.bio,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    //'photoUrl': photoUrl,
    'bio': bio,
  };

}