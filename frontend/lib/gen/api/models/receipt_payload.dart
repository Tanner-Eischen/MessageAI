enum ReceiptStatus {
  delivered,
  read;

  static ReceiptStatus fromString(String value) {
    return ReceiptStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown status: $value'),
    );
  }

  String toValue() => name;
}

class ReceiptPayload {
  final List<String> messageIds;
  final ReceiptStatus status;

  ReceiptPayload({
    required this.messageIds,
    required this.status,
  });

  factory ReceiptPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptPayload(
      messageIds: List<String>.from(json['message_ids'] as List),
      status: ReceiptStatus.fromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'message_ids': messageIds,
        'status': status.toValue(),
      };

  @override
  String toString() =>
      'ReceiptPayload(messageIds: $messageIds, status: ${status.name})';
}
