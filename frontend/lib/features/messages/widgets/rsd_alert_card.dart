import 'package:flutter/material.dart';
import 'package:messageai/models/ai_analysis.dart';

/// Alert card for RSD triggers
class RSDAlertCard extends StatelessWidget {
  final List<RSDTrigger> triggers;

  const RSDAlertCard({super.key, required this.triggers});

  @override
  Widget build(BuildContext context) {
    if (triggers.isEmpty) return const SizedBox.shrink();

    final highSeverity = triggers.any((t) => t.isHighSeverity);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highSeverity 
            ? Colors.orange.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highSeverity 
              ? Colors.orange.withOpacity(0.5)
              : Colors.blue.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                highSeverity ? Icons.warning_amber : Icons.info_outline,
                color: highSeverity ? Colors.orange : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RSD Alert: This might not be what it seems',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highSeverity ? Colors.orange : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Triggers
          ...triggers.map((trigger) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📌 "${trigger.pattern}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚠️ ${trigger.explanation}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trigger.reassurance,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

