import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/models/response_template.dart';
import 'package:messageai/models/situation_type.dart';
import 'package:messageai/services/response_template_service.dart';

/// Widget for picking and using response templates
class TemplatePicker extends ConsumerStatefulWidget {
  final SituationType? detectedSituation;
  final Function(String) onTemplateSelected;

  const TemplatePicker({
    super.key,
    this.detectedSituation,
    required this.onTemplateSelected,
  });

  @override
  ConsumerState<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends ConsumerState<TemplatePicker> {
  final templateService = ResponseTemplateService();
  ResponseTemplate? selectedTemplate;
  final Map<String, TextEditingController> _fieldControllers = {};

  @override
  void initState() {
    super.initState();
    templateService.loadTemplates();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.detectedSituation != null
        ? templateService.getTemplatesForSituation(widget.detectedSituation!)
        : templateService.getAllTemplates();

    if (templates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                widget.detectedSituation?.icon ?? Icons.lightbulb,
                color: widget.detectedSituation?.getColor() ?? Colors.blue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Response Templates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          if (widget.detectedSituation != null) ...[
            const SizedBox(height: 8),
            Text(
              'Detected: ${widget.detectedSituation!.displayName}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
          
          const SizedBox(height: 16),

          // Template list
          Expanded(
            child: ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = selectedTemplate?.id == template.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    title: Text(
                      template.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          template.situation,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.template,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Icon(
                      isSelected ? Icons.check_circle : Icons.chevron_right,
                      color: isSelected ? Colors.blue : null,
                    ),
                    onTap: () {
                      setState(() {
                        selectedTemplate = template;
                        // Initialize controllers for this template's fields
                        _fieldControllers.clear();
                        if (template.customizableFields != null) {
                          for (final field in template.customizableFields!) {
                            _fieldControllers[field] = TextEditingController();
                          }
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Customization section (if template selected with fields)
          if (selectedTemplate != null &&
              selectedTemplate!.customizableFields != null &&
              selectedTemplate!.customizableFields!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Fill in the blanks:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedTemplate!.customizableFields!.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _fieldControllers[field],
                  decoration: InputDecoration(
                    labelText: field.replaceAll('_', ' ').toUpperCase(),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              );
            }),
          ],

          // Preview and use button
          if (selectedTemplate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPreviewText(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final filledTemplate = _getPreviewText();
                  widget.onTemplateSelected(filledTemplate);
                  Navigator.pop(context);
                },
                child: const Text('Use This Template'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPreviewText() {
    if (selectedTemplate == null) return '';
    
    final values = <String, String>{};
    for (final entry in _fieldControllers.entries) {
      values[entry.key] = entry.value.text;
    }
    
    return selectedTemplate!.fillTemplate(values);
  }
}

/// Show template picker as bottom sheet
void showTemplatePicker(
  BuildContext context,
  SituationType? detectedSituation,
  Function(String) onTemplateSelected,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: TemplatePicker(
        detectedSituation: detectedSituation,
        onTemplateSelected: onTemplateSelected,
      ),
    ),
  );
}

