import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/services/message_formatter_service.dart';
import 'package:messageai/models/formatted_message.dart';

/// Panel for formatting long messages
class MessageFormatterPanel extends ConsumerStatefulWidget {
  final String originalMessage;
  final Function(String) onFormatted;

  const MessageFormatterPanel({
    super.key,
    required this.originalMessage,
    required this.onFormatted,
  });

  @override
  ConsumerState<MessageFormatterPanel> createState() => 
      _MessageFormatterPanelState();
}

class _MessageFormatterPanelState extends ConsumerState<MessageFormatterPanel> {
  late final MessageFormatterService formatterService;
  
  bool condense = false;
  bool chunk = false;
  bool addTldr = false;
  bool addStructure = false;
  
  FormattedMessage? formattedResult;
  bool isFormatting = false;

  @override
  void initState() {
    super.initState();
    formatterService = MessageFormatterService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 600),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_fix_high, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Message Formatter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Original: ${widget.originalMessage.length} characters',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Make your message more digestible',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Formatting options
            CheckboxListTile(
              title: const Text('Condense', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Reduce length while keeping key points (50-70% shorter)',
                style: TextStyle(fontSize: 11),
              ),
              value: condense,
              dense: true,
              onChanged: (value) => setState(() => condense = value!),
            ),
            CheckboxListTile(
              title: const Text('Break into Chunks', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Add sections with headers for easier reading',
                style: TextStyle(fontSize: 11),
              ),
              value: chunk,
              dense: true,
              onChanged: (value) => setState(() => chunk = value!),
            ),
            CheckboxListTile(
              title: const Text('Add TL;DR', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Brief 1-2 sentence summary at the top',
                style: TextStyle(fontSize: 11),
              ),
              value: addTldr,
              dense: true,
              onChanged: (value) => setState(() => addTldr = value!),
            ),
            CheckboxListTile(
              title: const Text('Add Structure', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Headings, bullets, and emphasis for clarity',
                style: TextStyle(fontSize: 11),
              ),
              value: addStructure,
              dense: true,
              onChanged: (value) => setState(() => addStructure = value!),
            ),

            const SizedBox(height: 16),

            // Format button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFormatting ? null : _formatMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: isFormatting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Format Message'),
              ),
            ),

            // Result preview
            if (formattedResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Formatted Result',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${formattedResult!.getSavingsPercentage().toStringAsFixed(0)}% shorter',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formattedResult!.characterCount} chars • ${formattedResult!.estimatedReadTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Text(
                          formattedResult!.formattedMessage,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Show full preview
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Formatted Message'),
                                  content: SingleChildScrollView(
                                    child: Text(formattedResult!.formattedMessage),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Preview Full', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onFormatted(formattedResult!.formattedMessage);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text('Use This', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _formatMessage() async {
    if (!condense && !chunk && !addTldr && !addStructure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one formatting option')),
      );
      return;
    }

    setState(() => isFormatting = true);

    try {
      final result = await formatterService.formatMessage(
        message: widget.originalMessage,
        condense: condense,
        chunk: chunk,
        addTldr: addTldr,
        addStructure: addStructure,
      );

      if (mounted) {
        setState(() {
          formattedResult = result;
          isFormatting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isFormatting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error formatting message: $e')),
        );
      }
    }
  }
}

