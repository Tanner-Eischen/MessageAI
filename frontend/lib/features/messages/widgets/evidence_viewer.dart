import 'package:flutter/material.dart';
import 'package:messageai/models/ai_analysis.dart';

/// Widget showing evidence that supports the tone analysis
class EvidenceViewer extends StatefulWidget {
  final List<Evidence> evidence;

  const EvidenceViewer({super.key, required this.evidence});

  @override
  State<EvidenceViewer> createState() => _EvidenceViewerState();
}

class _EvidenceViewerState extends State<EvidenceViewer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.evidence.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No specific evidence found in message',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evidence (${widget.evidence.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Text(
              'Specific evidence supporting this analysis:',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            
            // Evidence items
            ...widget.evidence.map((evidence) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EvidenceItem(evidence: evidence),
            )),
          ],
        ],
      ),
    );
  }
}

class _EvidenceItem extends StatelessWidget {
  final Evidence evidence;

  const _EvidenceItem({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(evidence.type);
    final typeIcon = _getTypeIcon(evidence.type);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and quote
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(typeIcon, size: 16, color: typeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        evidence.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '"${evidence.quote}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // What it supports
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Supports: ${evidence.supports}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Reasoning
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              evidence.reasoning,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'keyword':
        return Colors.blue;
      case 'punctuation':
        return Colors.orange;
      case 'emoji':
        return Colors.pink;
      case 'length':
        return Colors.purple;
      case 'pattern':
        return Colors.teal;
      case 'timing':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'keyword':
        return Icons.text_fields;
      case 'punctuation':
        return Icons.format_quote;
      case 'emoji':
        return Icons.emoji_emotions;
      case 'length':
        return Icons.straighten;
      case 'pattern':
        return Icons.pattern;
      case 'timing':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }
}

