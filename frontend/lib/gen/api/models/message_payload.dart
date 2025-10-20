class MessagePayload {
  final String id;
  final String conversationId;
  final String? body;

  MessagePayload({
    required this.id,
    required this.conversationId,
    this.body,
  });

  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    return MessagePayload(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        if (body != null) 'body': body,
      };

  @override
  String toString() =>
      'MessagePayload(id: $id, conversationId: $conversationId, body: $body)';
}
