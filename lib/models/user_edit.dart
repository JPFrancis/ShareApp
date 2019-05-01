class UserEdit {
  String id;
  String photoUrl;
  String displayName;

  UserEdit({
    this.id,
    this.photoUrl,
    this.displayName,
  });

  UserEdit.fromMap(Map<String, dynamic> data, String id)
      : this(
          id: id,
          photoUrl: data['imageURL'],
          displayName: data['name'],
        );

  UserEdit.copy(UserEdit other)
      : this(
          id: other.id,
          photoUrl: other.photoUrl,
          displayName: other.displayName,
        );

  bool compare(UserEdit other) {
    return this.id == other.id &&
        this.photoUrl == other.photoUrl &&
        this.displayName == other.displayName;
  }

  UserEdit fromItem(UserEdit other) {
    return new UserEdit(
      id: other.id,
      photoUrl: other.photoUrl,
      displayName: other.displayName,
    );
  }
}
