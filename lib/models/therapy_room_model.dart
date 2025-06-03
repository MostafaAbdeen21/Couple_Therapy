class TherapyMessage {
  final String userId;
  final String message;
  final String type;

  TherapyMessage({
    required this.userId,
    required this.message,
    required this.type,
  });

  factory TherapyMessage.fromMap(Map<String, dynamic> data) {
    return TherapyMessage(
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'user',
    );
  }
}