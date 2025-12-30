import 'package:flutter/material.dart';
import 'package:gogreen_admin/models/job_template.dart';
import 'package:gogreen_admin/services/supabase_service.dart';

class EstimateMakerPage extends StatefulWidget {
  final String interactionId;

  const EstimateMakerPage({
    super.key,
    required this.interactionId,
  });

  @override
  State<EstimateMakerPage> createState() => _EstimateMakerPageState();
}

class _EstimateMakerPageState extends State<EstimateMakerPage> {
  final SupabaseService _service = SupabaseService();
  final List<String> _selectedJobs = [];
  JobTemplate? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.85,
        constraints: const BoxConstraints(
          minWidth: 600,
          minHeight: 500,
          maxWidth: 900,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Jobs',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedJobs.isEmpty ? null : _saveJobs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Row(
                children: [
                  // Left: Template Selection
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Job Templates',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: JobTemplates.getTemplates().map((template) {
                              final isSelected = _selectedTemplate?.id == template.id;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTemplate = template;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.primary 
                                            : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          template.name,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Job'),
                            onPressed: _selectedTemplate != null ? _addJob : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Right: Selected Jobs
                  Expanded(
                    child: _selectedJobs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 48,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No jobs added yet',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select a template and click "Add Job"',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              ..._selectedJobs.asMap().entries.map((entry) {
                                final index = entry.key;
                                final jobName = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          jobName,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedJobs.removeAt(index);
                                          });
                                        },
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addJob() {
    if (_selectedTemplate == null) return;
    
    setState(() {
      if (!_selectedJobs.contains(_selectedTemplate!.name)) {
        _selectedJobs.add(_selectedTemplate!.name);
      }
    });
  }

  Future<void> _saveJobs() async {
    try {
      // Create a single task entry for each job (just the job title)
      for (var jobName in _selectedJobs) {
        await _service.createTask({
          'interaction_id': widget.interactionId,
          'category': 'Other',
          'task_type': jobName,
          'quantity': 1,
          'description': jobName,
          'purchase_price': 0.0,
          'sell_price': 0.0,
          'is_completed': false,
        });
      }
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate refresh needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedJobs.length} job(s) added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving jobs: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
