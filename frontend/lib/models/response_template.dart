/// Model for response templates
class ResponseTemplate {
  final String id;
  final String name;
  final String situation;
  final String template;
  final String tone; // polite, casual, direct, apologetic
  final List<String> context;
  final bool neurodivergentFriendly;
  final List<String>? customizableFields;

  ResponseTemplate({
    required this.id,
    required this.name,
    required this.situation,
    required this.template,
    required this.tone,
    required this.context,
    required this.neurodivergentFriendly,
    this.customizableFields,
  });

  factory ResponseTemplate.fromJson(Map<String, dynamic> json) {
    return ResponseTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      situation: json['situation'] as String,
      template: json['template'] as String,
      tone: json['tone'] as String,
      context: (json['context'] as List<dynamic>).map((e) => e as String).toList(),
      neurodivergentFriendly: json['neurodivergent_friendly'] as bool,
      customizableFields: (json['customizable_fields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'situation': situation,
      'template': template,
      'tone': tone,
      'context': context,
      'neurodivergent_friendly': neurodivergentFriendly,
      if (customizableFields != null) 'customizable_fields': customizableFields,
    };
  }

  /// Fill in customizable fields in the template
  String fillTemplate(Map<String, String> values) {
    String result = template;
    if (customizableFields != null) {
      for (final field in customizableFields!) {
        final value = values[field] ?? '{$field}';
        result = result.replaceAll('{$field}', value);
      }
    }
    return result;
  }

  /// Check if template has unfilled fields
  bool hasUnfilledFields(String text) {
    return text.contains(RegExp(r'\{[^}]+\}'));
  }

  @override
  String toString() {
    return 'ResponseTemplate(id: $id, name: $name, tone: $tone)';
  }
}

