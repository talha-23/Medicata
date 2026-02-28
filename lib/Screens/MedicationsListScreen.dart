// Screens/MedicationsListScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../widgets/LoadingIndicator.dart';
import 'AddMedicationScreen.dart';

class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  final MedicationService _medicationService = MedicationService();
  List<Medication> _medications = [];
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final isGuest = await _medicationService.isGuest();
    setState(() {
      _isGuest = isGuest;
    });
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meds = await _medicationService.getMedications();
      print('Loaded ${meds.length} medications');
      setState(() {
        _medications = meds;
      });
    } catch (e) {
      print('Error loading medications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medications: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _medicationService.deleteMedication(medication.id);
        await _loadMedications();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medication.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleActiveStatus(Medication medication) async {
    try {
      await _medicationService.toggleMedicationStatus(
        medication.id,
        !medication.isActive,
      );
      await _loadMedications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            medication.isActive
                ? '${medication.name} marked as inactive'
                : '${medication.name} marked as active',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating medication: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedications,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
          if (result == true) {
            _loadMedications();
          }
        },
        backgroundColor: AppColors.accentLight,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, Colors.white],
          ),
        ),
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading medications...')
            : _medications.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _medications.length,
                itemBuilder: (context, index) {
                  final medication = _medications[index];
                  return _buildMedicationCard(medication);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'No Medications Added',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the + button to add your first medication',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    // Calculate days remaining
    final daysRemaining = medication.isActive
        ? (medication.createdAt
              .add(Duration(days: medication.numberOfDays))
              .difference(DateTime.now())
              .inDays)
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: !medication.isActive
              ? Border.all(color: Colors.grey, width: 1)
              : daysRemaining < 0
              ? Border.all(color: Colors.red, width: 2)
              : daysRemaining <= 2
              ? Border.all(color: Colors.orange, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: medication.isActive
                          ? AppColors.accentLight.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      medication.isActive
                          ? Icons.medication
                          : Icons.medication_outlined,
                      color: medication.isActive
                          ? AppColors.accentLight
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: medication.isActive
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          '${medication.dosage} • ${medication.numberOfTablets} tablet(s) per dose',
                          style: TextStyle(
                            color: medication.isActive
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteMedication(medication);
                      } else if (value == 'toggle') {
                        _toggleActiveStatus(medication);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              medication.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: medication.isActive
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              medication.isActive
                                  ? 'Mark Inactive'
                                  : 'Mark Active',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Course details
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: '${medication.numberOfDays} days',
                    color: medication.isActive
                        ? AppColors.accentLight
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.date_range,
                    label: 'Started: ${_formatDate(medication.createdAt)}',
                    color: medication.isActive
                        ? AppColors.accentLight
                        : Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status and remaining days
              Row(
                children: [
                  if (medication.isActive) ...[
                    _buildInfoChip(
                      icon: Icons.timer,
                      label: daysRemaining >= 0
                          ? '$daysRemaining days remaining'
                          : 'Course completed',
                      color: daysRemaining < 0
                          ? Colors.red
                          : daysRemaining <= 2
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ] else ...[
                    _buildInfoChip(
                      icon: Icons.pause_circle_outline,
                      label: 'Inactive',
                      color: Colors.grey,
                    ),
                  ],
                ],
              ),

              // Notes
              if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medication.notes!,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Image for registered users
              if (!_isGuest && medication.imagePath != null) ...[
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(medication.imagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
