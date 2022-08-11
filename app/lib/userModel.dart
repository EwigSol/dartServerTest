class User {
  String? name;
  String? id;

  User({
    this.name,
    this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        name: json["name"],
        id: json["id"],
      );

  Map<String, dynamic> asMap() => {
        'name': name,
        'id': id,
      };
}
