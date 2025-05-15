import 'package:hive/hive.dart';
part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdDate;

  @HiveField(5)
  int priority;

  @HiveField(6)
  int? serverId; // Store the API-assigned ID

  @HiveField(7)
  DateTime? lastSynced; // Track when this task was last synced

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdDate,
    required this.priority,
    this.serverId,
    this.lastSynced,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdDate,
    int? priority,
    int? serverId,
    DateTime? lastSynced,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      priority: priority ?? this.priority,
      serverId: serverId ?? this.serverId,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': serverId ?? id,
      'title': title,
      'description': description,
      'completed': isCompleted,
      'createdDate': createdDate.toIso8601String(),
      'priority': priority,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['localId'] as int? ?? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF,
      serverId: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['completed'] as bool? ?? false,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : DateTime.now(),
      priority: json['priority'] as int? ?? 1,
      lastSynced: DateTime.now(),
    );
  }
}