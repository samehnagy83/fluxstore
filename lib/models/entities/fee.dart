class Fee {
  final String? id;
  final String? name;
  final String? total;
  final String? amount;

  const Fee({
    this.id,
    this.name,
    this.total,
    this.amount,
  });

  factory Fee.fromJson(Map parsedJson) {
    return Fee(
      id: parsedJson['id']?.toString(),
      name: parsedJson['name']?.toString(),
      total: parsedJson['total']?.toString(),
      amount: parsedJson['amount']?.toString(),
    );
  }

  Map toJson() {
    var data = {
      'id': id,
      'name': name,
      'total': total,
      'amount': amount,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
