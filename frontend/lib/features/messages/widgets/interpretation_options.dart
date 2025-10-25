import 'package:flutter/material.dart';
import 'package:messageai/models/ai_analysis.dart';

/// Widget showing alternative interpretations for ambiguous messages
class InterpretationOptions extends StatefulWidget {
  final List<MessageInterpretation> interpretations;

  const InterpretationOptions({super.key, required this.interpretations});

  @override
  State<InterpretationOptions> createState() => _InterpretationOptionsState();
}

class _InterpretationOptionsState extends State<InterpretationOptions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.interpretations.isEmpty) return const SizedBox.shrink();

    // Sort by likelihood (highest first)
    final sorted = List<MessageInterpretation>.from(widget.interpretations)
      ..sort((a, b) => b.likelihood.compareTo(a.likelihood));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Alternative Interpretations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Text(
              'This message could be interpreted in multiple ways:',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            
            // Interpretations
            ...sorted.asMap().entries.map((entry) {
              final index = entry.key;
              final interp = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InterpretationCard(
                  interpretation: interp,
                  rank: index + 1,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _InterpretationCard extends StatelessWidget {
  final MessageInterpretation interpretation;
  final int rank;

  const _InterpretationCard({
    required this.interpretation,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    Color likelihoodColor;
    if (interpretation.isLikely) {
      likelihoodColor = Colors.green;
    } else if (interpretation.isPossible) {
      likelihoodColor = Colors.orange;
    } else {
      likelihoodColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: likelihoodColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank and likelihood
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: likelihoodColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: likelihoodColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${interpretation.likelihood}% likely',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: likelihoodColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  interpretation.tone,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Interpretation text
          Text(
            interpretation.interpretation,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          
          // Reasoning
          Text(
            interpretation.reasoning,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          
          // Context clues
          if (interpretation.contextClues.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: interpretation.contextClues.map((clue) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    clue,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

