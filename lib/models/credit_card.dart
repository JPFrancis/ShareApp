class CreditCard {
  String userID;
  String name;
  String number;
  String month;
  String year;
  String cvv;
  String zip;

  CreditCard({
    this.userID,
    this.name,
    this.number,
    this.month,
    this.year,
    this.cvv,
    this.zip,
  });

  CreditCard.fromMap(String id, Map<String, dynamic> data)
      : this(
          userID: id,
          name: data['name'],
          number: data['number'],
          month: data['month'],
          year: data['year'],
          cvv: data['cvv'],
          zip: data['zip'],
        );

  CreditCard.copy(CreditCard other)
      : this(
          userID: other.userID,
          name: other.name,
          number: other.number,
          month: other.month,
          year: other.year,
          cvv: other.cvv,
          zip: other.zip,
        );

  bool compare(CreditCard other) {
    return this.userID == other.userID &&
        this.name == other.name &&
        this.number == other.number &&
        this.month == other.month &&
        this.year == other.year &&
        this.cvv == other.cvv &&
        this.zip == other.zip;
  }

  Map<String, dynamic> toMap() => {
        'userID': this.userID,
        'name': this.name,
        'number': this.number,
        'month': this.month,
        'year': this.year,
        'cvv': this.cvv,
        'zip': this.zip,
      };
}
