class Item {
  final int? id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status; // 'lost', 'found', 'claimed'
  final int userId;
  final String? imagePath;
  final String? contactInfo;
  final DateTime createdAt;

  Item({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.userId,
    this.imagePath,
    this.contactInfo,
    required this.createdAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? '',
      userId: map['userId'] ?? 0,
      imagePath: map['imagePath'],
      contactInfo: map['contactInfo'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'status': status,
      'userId': userId,
      'imagePath': imagePath,
      'contactInfo': contactInfo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? status,
    int? userId,
    String? imagePath,
    String? contactInfo,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
