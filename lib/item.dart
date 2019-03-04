class Item {
  String id; // doc id for firestore
  String name;
  String description;
  int price;
  bool type; // true = tool, false = leisure

  Item({
    this.id,
    this.name,
    this.description,
    this.price,
    this.type});

  Item.fromMap(Map<String, dynamic> data, String id)
      : this(
    id: id,
    name: data['name'],
    description: data['description'],
    price: data['price'],
    type: data['type'],
  );
}