class Item {
  String id; // doc id for firestore
  String name;
  String description;
  bool type; // true = tool, false = leisure

  Item({
    this.id,
    this.name,
    this.description,
    this.type});

  Item.fromMap(Map<String, dynamic> data, String id)
      : this(
    id: id,
    name: data['name'],
    description: data['description'],
    type: data['type'],
  );
}