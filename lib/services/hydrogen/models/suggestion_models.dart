/// 건의사항
class Suggestion {
  final int id;
  final String content;
  final DateTime createdAt;

  Suggestion({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
