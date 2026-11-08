// =============================================
// MODEL BÀI TẬP - JSON & SQLite Serialization
// (Bài 6 P1: JSON Serialize/Deserialize + SQLite)
// =============================================

class Exercise {
  final String id;
  final String title;
  final String category; // 'Tăng cơ', 'Cardio', 'Thể lực'
  final int sets;
  final int reps;
  final int calories;
  final String dayOfWeek;
  final String notes;
  final String imagePath; // Đường dẫn ảnh asset (Bài 3 - Image.asset)
  final String createdAt;
  bool isCompleted;

  Exercise({
    required this.id,
    required this.title,
    required this.category,
    required this.sets,
    required this.reps,
    required this.calories,
    required this.dayOfWeek,
    this.notes = 'Khởi động kỹ 5 phút trước khi tập, hít thở đều.',
    this.imagePath = '',
    this.isCompleted = false,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // ---- JSON Serialization (Bài 6 P1) ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'sets': sets,
        'reps': reps,
        'calories': calories,
        'dayOfWeek': dayOfWeek,
        'notes': notes,
        'imagePath': imagePath,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        category: json['category'] ?? 'Tăng cơ',
        sets: json['sets'] ?? 3,
        reps: json['reps'] ?? 12,
        calories: json['calories'] ?? 100,
        dayOfWeek: json['dayOfWeek'] ?? 'Hôm nay',
        notes: json['notes'] ?? 'Khởi động kỹ 5 phút trước khi tập.',
        imagePath: json['imagePath'] ?? '',
        isCompleted: json['isCompleted'] == true || json['isCompleted'] == 1,
        createdAt: json['createdAt'],
      );

  // ---- SQLite Serialization (Bài 6 P1 - sqflite) ----

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'sets': sets,
        'reps': reps,
        'calories': calories,
        'dayOfWeek': dayOfWeek,
        'notes': notes,
        'imagePath': imagePath,
        'isCompleted': isCompleted ? 1 : 0,
        'createdAt': createdAt,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id']?.toString() ?? '',
        title: map['title'] ?? '',
        category: map['category'] ?? 'Tăng cơ',
        sets: map['sets'] ?? 3,
        reps: map['reps'] ?? 12,
        calories: map['calories'] ?? 100,
        dayOfWeek: map['dayOfWeek'] ?? 'Hôm nay',
        notes: map['notes'] ?? 'Khởi động kỹ 5 phút trước khi tập.',
        imagePath: map['imagePath'] ?? '',
        isCompleted: map['isCompleted'] == 1,
        createdAt: map['createdAt'],
      );

  // ---- Copy with (tạo bản sao có chỉnh sửa) ----

  Exercise copyWith({
    String? id,
    String? title,
    String? category,
    int? sets,
    int? reps,
    int? calories,
    String? dayOfWeek,
    String? notes,
    String? imagePath,
    bool? isCompleted,
    String? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      calories: calories ?? this.calories,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Lấy đường dẫn ảnh mặc định theo category
  String get displayImage {
    if (imagePath.isNotEmpty) return imagePath;
    switch (category) {
      case 'Tăng cơ':
        return 'assets/images/tang_co.jpg';
      case 'Cardio':
        return 'assets/images/cardio.jpg';
      case 'Thể lực':
        return 'assets/images/the_luc.jpg';
      default:
        return 'assets/images/default_exercise.jpg';
    }
  }
}
