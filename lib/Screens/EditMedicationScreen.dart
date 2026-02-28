// Screens/EditMedicationScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Colors/theme.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../services/session_manager.dart';
import '../widgets/LoadingIndicator.dart';

class EditMedicationScreen extends StatefulWidget {
  final Medication medication;

  const EditMedicationScreen({super.key, required this.medication});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _tabletsController;
  late TextEditingController _dosageController;
  late TextEditingController _daysController;
  late TextEditingController _notesController;

  bool _isLoading = false;
  bool _isGuest = false;
  String? _imagePath;

  final ImagePicker _imagePicker = ImagePicker();
  final MedicationService _medicationService = MedicationService();
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkUserType();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.medication.name);
    _tabletsController = TextEditingController(
      text: widget.medication.numberOfTablets.toString(),
    );
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _daysController = TextEditingController(
      text: widget.medication.numberOfDays.toString(),
    );
    _notesController = TextEditingController(text: widget.medication.notes ?? '');
    _imagePath = widget.medication.imagePath;
  }

  Future<void> _checkUserType() async {
    final isGuest = await _sessionManager.isGuestMode();
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

  Future<void> _updateMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedMedication = Medication(
          id: widget.medication.id,
          name: _nameController.text.trim(),
          numberOfTablets: int.parse(_tabletsController.text.trim()),
          dosage: _dosageController.text.trim(),
          numberOfDays: int.parse(_daysController.text.trim()),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: widget.medication.createdAt,
          userId: widget.medication.userId,
          imagePath: _imagePath,
          isActive: widget.medication.isActive,
        );

        await _medicationService.updateMedication(updatedMedication);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Medication updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating medication: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Medication',
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
            ? const LoadingIndicator(message: 'Updating medication...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Edit Medication Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Medication Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Medication Name',
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
                          prefixIcon: const Icon(Icons.format_list_numbered),
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

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
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

                      // Image (for registered users)
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
                                      ? 'Change Image'
                                      : 'Add Medicine Image',
                                ),
                                subtitle: _imagePath != null
                                    ? const Text('Tap to change')
                                    : const Text('Take a photo of the medicine'),
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

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _updateMedication,
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'UPDATE MEDICATION',
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