import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import '../Colors/theme.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../services/session_manager.dart';
import '../services/notification_service.dart';
import '../widgets/LoadingIndicator.dart';
import 'package:uuid/uuid.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tabletsController = TextEditingController();
  final _dosageController = TextEditingController();
  final _daysController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isGuest = false;
  String? _imagePath;
  bool _enableReminders = true; // Default to true
  TimeOfDay? _selectedReminderTime;
  List<TimeOfDay> _selectedReminderTimes = [];

  final ImagePicker _imagePicker = ImagePicker();
  final MedicationService _medicationService = MedicationService();
  final SessionManager _sessionManager = SessionManager();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _checkUserType();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _checkUserType() async {
    final isGuest = await _medicationService.isGuest();
    setState(() {
      _isGuest = isGuest;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.accentLight),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedReminderTimes.add(picked);
      });
    }
  }

  void _removeReminderTime(int index) {
    setState(() {
      _selectedReminderTimes.removeAt(index);
    });
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check notification permission if reminders are enabled
        if (_enableReminders && !_isGuest) {
          final hasPermission = await _notificationService
              .isPermissionGranted();
          if (!hasPermission) {
            final granted = await _notificationService
                .requestNotificationPermission();
            if (!granted) {
              // Show dialog to inform user
              _showPermissionDialog();
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }
        }

        // Get user ID
        final userId = await _medicationService.getCurrentUserId();
        print('Current userId: $userId'); // Debug log

        // Create medication object
        final medication = Medication(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          numberOfTablets: int.parse(_tabletsController.text.trim()),
          dosage: _dosageController.text.trim(),
          numberOfDays: int.parse(_daysController.text.trim()),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: DateTime.now(),
          userId: userId,
          imagePath: _imagePath,
        );

        print('Saving medication: ${medication.toJson()}'); // Debug log

        // Save medication
        await _medicationService.addMedication(medication);

        // Schedule reminders if enabled
        if (_enableReminders) {
          if (_selectedReminderTimes.isNotEmpty) {
            // Schedule multiple reminders at selected times
            for (int i = 0; i < _selectedReminderTimes.length; i++) {
              final time = _selectedReminderTimes[i];
              await _notificationService.scheduleCustomReminder(
                medication,
                hour: time.hour,
                minute: time.minute,
                reminderId: i,
              );
            }
          } else {
            // Schedule default reminders (morning, afternoon, evening)
            await _notificationService.scheduleMultipleReminders(medication);
          }

          // Show confirmation about reminders
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Reminders set for ${_selectedReminderTimes.isEmpty ? 'morning, afternoon, evening' : _selectedReminderTimes.length.toString() + ' time(s)'}',
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Clear form
        _nameController.clear();
        _tabletsController.clear();
        _dosageController.clear();
        _daysController.clear();
        _notesController.clear();
        setState(() {
          _imagePath = null;
          _selectedReminderTimes.clear();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Medication added successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_isGuest) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'You are in guest mode. Sign in to access your medications on other devices.',
                    style: TextStyle(fontSize: 12),
                  ),
                ] else if (_enableReminders) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Reminders have been set for your medication.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: _isGuest ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } catch (e) {
        print('Error saving medication: $e'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding medication: ${e.toString()}'),
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

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission'),
        content: const Text(
          'Medication reminders need notification permission to alert you when it\'s time to take your medicine. '
          'You can enable this in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLight,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Medication',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            ? const LoadingIndicator(message: 'Adding medication...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header
                    const Text(
                      'Add New Medication',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Medication Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Medication Name',
                              hintText: 'e.g., Paracetamol',
                              prefixIcon: const Icon(Icons.medication),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter medication name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Number of Tablets
                          TextFormField(
                            controller: _tabletsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Number of Tablets per Dose',
                              hintText: 'e.g., 1',
                              prefixIcon: const Icon(
                                Icons.format_list_numbered,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of tablets';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (int.parse(value) <= 0) {
                                return 'Number must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Dosage
                          TextFormField(
                            controller: _dosageController,
                            decoration: InputDecoration(
                              labelText: 'Dosage',
                              hintText: 'e.g., 500mg',
                              prefixIcon: const Icon(Icons.speed),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter dosage';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Number of Days
                          TextFormField(
                            controller: _daysController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Number of Days',
                              hintText: 'e.g., 7',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of days';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (int.parse(value) <= 0) {
                                return 'Number must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Notes (Optional)
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'Any additional instructions',
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),

                          // Reminder Settings (only for registered users)
                          if (!_isGuest) ...[
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.notifications_active,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Reminder Settings',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: _enableReminders,
                                        onChanged: (value) {
                                          setState(() {
                                            _enableReminders = value;
                                            if (!value) {
                                              _selectedReminderTimes.clear();
                                            }
                                          });
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                    ],
                                  ),

                                  if (_enableReminders) ...[
                                    const SizedBox(height: 15),
                                    const Text(
                                      'Reminder Times:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Display selected times
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ..._selectedReminderTimes
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              final index = entry.key;
                                              final time = entry.value;
                                              return Chip(
                                                label: Text(
                                                  time.format(context),
                                                ),
                                                onDeleted: () =>
                                                    _removeReminderTime(index),
                                                deleteIconColor: Colors.red,
                                                backgroundColor: Colors.blue
                                                    .withOpacity(0.2),
                                                side: BorderSide.none,
                                              );
                                            })
                                            .toList(),
                                        if (_selectedReminderTimes.length < 5)
                                          ActionChip(
                                            label: const Text('+ Add Time'),
                                            onPressed: _pickReminderTime,
                                            backgroundColor: Colors.blue,
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),

                                    if (_selectedReminderTimes.isEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Default times: 8:00 AM, 2:00 PM, 8:00 PM',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 10),
                                    const Text(
                                      'Reminders will repeat daily during your medication course',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Image picker for registered users only
                          if (!_isGuest) ...[
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _imagePath != null
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  if (_imagePath != null)
                                    Container(
                                      height: 150,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        image: DecorationImage(
                                          image: FileImage(File(_imagePath!)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ListTile(
                                    leading: Icon(
                                      _imagePath != null
                                          ? Icons.image
                                          : Icons.camera_alt,
                                      color: _imagePath != null
                                          ? Colors.green
                                          : AppColors.accentLight,
                                    ),
                                    title: Text(
                                      _imagePath != null
                                          ? 'Image Added'
                                          : 'Add Medicine Image',
                                    ),
                                    subtitle: _imagePath != null
                                        ? const Text('Tap to change')
                                        : const Text(
                                            'Take a photo of the medicine',
                                          ),
                                    trailing: _imagePath != null
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _imagePath = null;
                                              });
                                            },
                                          )
                                        : null,
                                    onTap: _pickImage,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Add Medication Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _saveMedication,
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'ADD MEDICATION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentLight,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      _isGuest
                          ? 'Guest Mode - Local Storage Only'
                          : 'Registered User - Cloud Sync Enabled',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isGuest ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Guest Mode Warning (if applicable)
                    if (_isGuest) ...[
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You are in guest mode. Medications will be saved locally only. '
                                'Sign up to sync across devices and never lose your data!',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabletsController.dispose();
    _dosageController.dispose();
    _daysController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
