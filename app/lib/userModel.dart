class User {
  String? id;
  String? name;

  User({this.id, this.name});

  static User fromJson(json) => User(
        id: json['id'],
        name: json['name'],
      );
}
