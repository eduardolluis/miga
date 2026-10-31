class GroceryItem {
  const GroceryItem(this.name, {this.checked = false});

  final String name;
  final bool checked;

  Map<String, Object> toJson() => {'name': name, 'checked': checked};

  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      GroceryItem(json['name'] as String, checked: json['checked'] as bool);
}
