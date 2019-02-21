class Item {
  String _name;
  String _description;
  bool _type; // true = tool, false = leisure
  String _id; // doc id for firestore

  Item(this._name, this._description, this._type, this._id);

  String get name => _name;

  String get description => _description;

  bool get type => _type;

  String get id => _id;

  set name(String newName) {
      this._name = newName;
  }

  set description(String newDescription) {
      this._description = newDescription;
  }

  set type(bool newType) {
    this._type = newType;
  }

  set id(String newId) {
    this._id = newId;
  }
}