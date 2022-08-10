class User {
  String? id;
  String? name;

  User({this.id, this.name});

  static User fromJson(json) => User(
        id: json['id'].toString(),
        name: json['name'].toString(),
      );

  static User fromList(jsonData) => User(
        id: jsonData['id'].toString(),
        name: jsonData['name'].toString(),
      );
}
