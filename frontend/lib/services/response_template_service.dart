import 'package:messageai/models/response_template.dart';
import 'package:messageai/models/situation_type.dart';

/// Service for managing response templates
class ResponseTemplateService {
  static final ResponseTemplateService _instance = 
      ResponseTemplateService._internal();
  factory ResponseTemplateService() => _instance;
  ResponseTemplateService._internal();

  // In-memory template storage (loaded from backend)
  final Map<String, ResponseTemplate> _templates = {};
  final Map<SituationType, List<String>> _templatesBySituation = {};
  bool _initialized = false;

  /// Initialize templates (call on app start)
  Future<void> loadTemplates() async {
    if (_initialized) return;
    
    // TODO: Load from backend or local storage
    // For now, using hardcoded templates
    _initializeHardcodedTemplates();
    _initialized = true;
  }

  /// Get template by ID
  ResponseTemplate? getTemplate(String id) {
    return _templates[id];
  }

  /// Get templates for a situation type
  List<ResponseTemplate> getTemplatesForSituation(SituationType situation) {
    final templateIds = _templatesBySituation[situation] ?? [];
    return templateIds
        .map((id) => _templates[id])
        .whereType<ResponseTemplate>()
        .toList();
  }

  /// Get all templates
  List<ResponseTemplate> getAllTemplates() {
    return _templates.values.toList();
  }

  /// Search templates by keywords
  List<ResponseTemplate> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return _templates.values.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
             template.situation.toLowerCase().contains(lowerQuery) ||
             template.context.any((c) => c.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  void _initializeHardcodedTemplates() {
    // Declining templates
    final decliningTemplates = [
      ResponseTemplate(
        id: 'decline_polite',
        name: 'Polite Decline',
        situation: 'When you need to say no professionally',
        template: "Thank you for thinking of me! Unfortunately, I won't be able to {activity} {timeframe}. I appreciate your understanding.",
        tone: 'polite',
        context: ['can you', 'would you', 'invitation'],
        neurodivergentFriendly: true,
        customizableFields: ['activity', 'timeframe'],
      ),
      ResponseTemplate(
        id: 'decline_no_explanation',
        name: 'Direct Decline',
        situation: "When you don't owe an explanation",
        template: "Thanks for the invite, but I'm not able to join this time.",
        tone: 'direct',
        context: ['party', 'event', 'hangout'],
        neurodivergentFriendly: true,
      ),
      ResponseTemplate(
        id: 'decline_with_alternative',
        name: 'Decline with Counter-Offer',
        situation: 'When you want to participate but need different terms',
        template: "I can't {original_request}, but I could {alternative}. Would that work?",
        tone: 'casual',
        context: ['meeting', 'call', 'hangout'],
        neurodivergentFriendly: true,
        customizableFields: ['original_request', 'alternative'],
      ),
      ResponseTemplate(
        id: 'decline_capacity',
        name: 'At Capacity (Mental Health)',
        situation: 'When you need to protect your energy',
        template: "I really appreciate you thinking of me, but I need to be mindful of my capacity right now. I'll have to pass on this one.",
        tone: 'apologetic',
        context: ['favor', 'help', 'support'],
        neurodivergentFriendly: true,
      ),
    ];

    // Boundary templates
    final boundaryTemplates = [
      ResponseTemplate(
        id: 'boundary_time',
        name: 'Time Boundary',
        situation: 'When someone expects 24/7 availability',
        template: "I'm available to discuss this during {your_hours}. Can we schedule a time within those hours?",
        tone: 'direct',
        context: ['urgent', 'right now', 'immediately'],
        neurodivergentFriendly: true,
        customizableFields: ['your_hours'],
      ),
      ResponseTemplate(
        id: 'boundary_communication',
        name: 'Communication Preference',
        situation: "When someone uses a communication method that doesn't work for you",
        template: "I process information better through {preferred_method}. Could we switch to that for this conversation?",
        tone: 'direct',
        context: ['call', 'video', 'meeting'],
        neurodivergentFriendly: true,
        customizableFields: ['preferred_method'],
      ),
      ResponseTemplate(
        id: 'boundary_topic',
        name: 'Topic Boundary',
        situation: "When someone brings up something you don't want to discuss",
        template: "I'm not comfortable discussing {topic}. Let's talk about something else.",
        tone: 'direct',
        context: ['personal', 'private', 'politics'],
        neurodivergentFriendly: true,
        customizableFields: ['topic'],
      ),
    ];

    // Info-dump templates
    final infoDumpTemplates = [
      ResponseTemplate(
        id: 'infodump_intro',
        name: 'Info-Dump with Warning',
        situation: 'When you want to share a lot about something you love',
        template: "I'm really excited about {topic}! Fair warning: I could talk about this for hours 😊 Are you interested in hearing more?",
        tone: 'casual',
        context: ['excited', 'interesting', 'found'],
        neurodivergentFriendly: true,
        customizableFields: ['topic'],
      ),
      ResponseTemplate(
        id: 'infodump_chunked',
        name: 'Info-Dump in Chunks',
        situation: 'When you want to share but keep it digestible',
        template: "Quick version: {short_summary}\n\nWant the details? I can break it down into:\n1. {aspect_1}\n2. {aspect_2}\n3. {aspect_3}\n\nLet me know what interests you!",
        tone: 'casual',
        context: ['explain', 'tell', 'share'],
        neurodivergentFriendly: true,
        customizableFields: ['short_summary', 'aspect_1', 'aspect_2', 'aspect_3'],
      ),
    ];

    // Apologizing templates
    final apologizingTemplates = [
      ResponseTemplate(
        id: 'apology_genuine',
        name: 'Genuine Apology',
        situation: 'When you actually did something wrong',
        template: "I'm sorry for {what_you_did}. I understand that {impact}. Going forward, I'll {corrective_action}.",
        tone: 'apologetic',
        context: ['mistake', 'wrong', 'messed up'],
        neurodivergentFriendly: true,
        customizableFields: ['what_you_did', 'impact', 'corrective_action'],
      ),
      ResponseTemplate(
        id: 'apology_no_need',
        name: 'Replace Unnecessary Apology',
        situation: "When you're apologizing out of habit",
        template: "Thank you for {what_they_did}. I appreciate {specific_thing}.",
        tone: 'polite',
        context: ['sorry for', 'apologies for'],
        neurodivergentFriendly: true,
        customizableFields: ['what_they_did', 'specific_thing'],
      ),
    ];

    // Clarifying templates
    final clarifyingTemplates = [
      ResponseTemplate(
        id: 'clarify_misunderstand',
        name: 'Admit Confusion',
        situation: "When you don't understand something",
        template: "I want to make sure I understand correctly. Are you saying {your_interpretation}?",
        tone: 'direct',
        context: ['confused', 'unclear', 'not sure'],
        neurodivergentFriendly: true,
        customizableFields: ['your_interpretation'],
      ),
      ResponseTemplate(
        id: 'clarify_literal',
        name: 'Ask for Literal Meaning',
        situation: 'When you need things stated directly',
        template: "I'm having trouble reading between the lines. Could you tell me directly what you need from me?",
        tone: 'direct',
        context: ['ambiguous', 'vague', 'hint'],
        neurodivergentFriendly: true,
      ),
    ];

    // Store templates
    final allTemplates = [
      ...decliningTemplates,
      ...boundaryTemplates,
      ...infoDumpTemplates,
      ...apologizingTemplates,
      ...clarifyingTemplates,
    ];
    
    for (final template in allTemplates) {
      _templates[template.id] = template;
    }

    // Index by situation
    _templatesBySituation[SituationType.declining] = 
        decliningTemplates.map((t) => t.id).toList();
    _templatesBySituation[SituationType.boundarySetting] = 
        boundaryTemplates.map((t) => t.id).toList();
    _templatesBySituation[SituationType.infoDumping] = 
        infoDumpTemplates.map((t) => t.id).toList();
    _templatesBySituation[SituationType.apologizing] = 
        apologizingTemplates.map((t) => t.id).toList();
    _templatesBySituation[SituationType.clarifying] = 
        clarifyingTemplates.map((t) => t.id).toList();
  }
}

