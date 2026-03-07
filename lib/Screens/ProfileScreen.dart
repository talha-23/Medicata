// Screens/ProfileScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Colors/theme.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import '../services/medication_service.dart';
import '../models/medication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Screens/Signup.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  const ProfileScreen({super.key, required this.isGuest});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  final MedicationService _medicationService = MedicationService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isEditing = false;
  
  // User data
  String? _userEmail;
  String? _userName;
  String? _profileImagePath;
  String? _profileImageUrl;
  
  // Profile fields
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  // Stats
  int _totalMedications = 0;
  int _activeMedications = 0;
  int _adherenceRate = 0;
  
  // Gender options
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    print('========== PROFILE SCREEN INIT ==========');
    print('widget.isGuest: ${widget.isGuest}');
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (!widget.isGuest) {
        // Registered user
        print('Loading registered user data');
        final user = _authService.currentUser;
        if (user != null) {
          _userEmail = user.email;
          _profileImageUrl = user.photoURL;
          
          final userData = await _authService.getUserData(user.uid);
          if (userData != null) {
            _userName = userData['username'] ?? user.displayName ?? 'User';
            _nameController.text = userData['name'] ?? _userName ?? '';
            _ageController.text = userData['age'] ?? '';
            _genderController.text = userData['gender'] ?? '';
            _conditionsController.text = userData['conditions'] ?? '';
            _emergencyNameController.text = userData['emergencyName'] ?? '';
            _emergencyRelationshipController.text = userData['emergencyRelationship'] ?? '';
            _emergencyPhoneController.text = userData['emergencyPhone'] ?? '';
            _profileImagePath = userData['profileImage'];
          }
        }
      } else {
        // Guest user
        print('Loading guest user data');
        final guestData = await _sessionManager.getGuestData();
        _userName = guestData?['name'] ?? 'Guest User';
        _userEmail = 'guest@medicata.local';
        print('Guest name: $_userName');
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final medications = await _medicationService.getMedications();
      final active = medications.where((m) => m.isActive).length;
      
      // Calculate adherence (simplified version)
      int taken = 0;
      int total = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (var med in medications) {
        if (med.isActive) {
          total++;
          final key = 'taken_${med.id}_${today.toIso8601String().split('T')[0]}';
          final status = await _sessionManager.getUserPreference(key);
          if (status == 'true') taken++;
        }
      }
      
      setState(() {
        _totalMedications = medications.length;
        _activeMedications = active;
        _adherenceRate = total > 0 ? ((taken / total) * 100).round() : 0;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        
        if (!widget.isGuest) {
          final user = _authService.currentUser;
          if (user != null) {
            // You'll need to implement this in AuthService
            // await _authService.updateUserProfileImage(user.uid, image.path);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = _authService.currentUser;
        if (user != null) {
          final profileData = {
            'name': _nameController.text.trim(),
            'age': _ageController.text.trim(),
            'gender': _genderController.text.trim(),
            'conditions': _conditionsController.text.trim(),
            'emergencyName': _emergencyNameController.text.trim(),
            'emergencyRelationship': _emergencyRelationshipController.text.trim(),
            'emergencyPhone': _emergencyPhoneController.text.trim(),
            'profileImage': _profileImagePath,
            'updatedAt': DateTime.now().toIso8601String(),
          };
          
          // You'll need to implement this in AuthService
          // await _authService.updateUserProfile(user.uid, profileData);
        }

        setState(() => _isEditing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('========== PROFILE SCREEN BUILD ==========');
    print('widget.isGuest: ${widget.isGuest}');
    print('_isLoading: $_isLoading');
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accentLight),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, Colors.white],
        ),
      ),
      child: widget.isGuest ? _buildGuestProfile() : _buildRegisteredProfile(),
    );
  }

  // ========== REGISTERED USER PROFILE ==========
  Widget _buildRegisteredProfile() {
    print('Building Registered Profile');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Profile Header with Edit Button
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.accentLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile Image
                  _profileImagePath != null
                      ? Image.file(
                          File(_profileImagePath!),
                          fit: BoxFit.cover,
                        )
                      : _profileImageUrl != null
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.accentLight.withOpacity(0.3),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.accentLight.withOpacity(0.3),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                  
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Profile Info Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userEmail != null)
                          Text(
                            _userEmail!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Edit Button
                  if (!_isEditing)
                    Positioned(
                      top: 40,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(Icons.edit, color: AppColors.accentLight),
                          onPressed: () => setState(() => _isEditing = true),
                        ),
                      ),
                    ),
                  
                  // Cancel Edit Button
                  if (_isEditing)
                    Positioned(
                      top: 40,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _isEditing = false),
                        ),
                      ),
                    ),
                  
                  // Camera Button for editing
                  if (_isEditing)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: CircleAvatar(
                        backgroundColor: AppColors.accentLight,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Stats Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Health Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Meds',
                        '$_totalMedications',
                        Icons.medication,
                        AppColors.accentLight,
                      ),
                      _buildStatItem(
                        'Active',
                        '$_activeMedications',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Adherence',
                        '$_adherenceRate%',
                        Icons.trending_up,
                        _adherenceRate >= 80 ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Profile Form (Editable or View)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _isEditing ? _buildEditForm() : _buildProfileInfo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Name', _nameController.text.isEmpty ? 'Not set' : _nameController.text),
            _buildInfoRow(Icons.cake, 'Age', _ageController.text.isEmpty ? 'Not set' : '${_ageController.text} years'),
            _buildInfoRow(Icons.wc, 'Gender', _genderController.text.isEmpty ? 'Not set' : _genderController.text),
            
            const Divider(height: 32),
            
            const Text(
              'Medical Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.medical_services,
              'Conditions',
              _conditionsController.text.isEmpty ? 'No conditions listed' : _conditionsController.text,
              multiline: true,
            ),
            
            const Divider(height: 32),
            
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Name', _emergencyNameController.text.isEmpty ? 'Not set' : _emergencyNameController.text),
            _buildInfoRow(Icons.family_restroom, 'Relationship', _emergencyRelationshipController.text.isEmpty ? 'Not set' : _emergencyRelationshipController.text),
            _buildInfoRow(Icons.phone, 'Phone', _emergencyPhoneController.text.isEmpty ? 'Not set' : _emergencyPhoneController.text),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            child: Icon(icon, size: 20, color: AppColors.accentLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _genderController.text.isNotEmpty ? _genderController.text : null,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _genderController.text = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Medical Conditions
              TextFormField(
                controller: _conditionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Medical Conditions / Diseases',
                  hintText: 'List any conditions (separate with commas)',
                  prefixIcon: Icon(Icons.medical_services, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              
              const Divider(height: 32),
              
              const Text(
                'Emergency Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Emergency Contact Name
              TextFormField(
                controller: _emergencyNameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Relationship
              TextFormField(
                controller: _emergencyRelationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.family_restroom, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone Number
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: AppColors.accentLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== GUEST USER PROFILE ==========
  Widget _buildGuestProfile() {
    print('Building Guest Profile');
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile Header
        Center(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentLight, width: 3),
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userName ?? 'Guest User',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail ?? 'guest@medicata.local',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Guest Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Stats Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGuestStatItem(
                      'Total',
                      '$_totalMedications',
                      Icons.medication,
                      AppColors.accentLight,
                    ),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    _buildGuestStatItem(
                      'Active',
                      '$_activeMedications',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Register Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentLight, AppColors.secondaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.person_add, color: Colors.white, size: 50),
              const SizedBox(height: 12),
              const Text(
                'Create Your Free Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Medicata to unlock all premium features',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SecondScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.accentLight,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'REGISTER NOW',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Premium Features Showcase
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Premium Features',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.cloud_done, 'Cloud backup & sync across devices'),
                _buildFeatureItem(Icons.notifications_active, 'Smart medication reminders'),
                _buildFeatureItem(Icons.health_and_safety, 'AI Health Assistant chatbot'),
                _buildFeatureItem(Icons.analytics, 'Detailed health analytics & reports'),
                _buildFeatureItem(Icons.emergency, 'Emergency contact storage'),
                _buildFeatureItem(Icons.medical_information, 'Medical conditions tracker'),
                _buildFeatureItem(Icons.camera_alt, 'Upload medication photos'),
                _buildFeatureItem(Icons.history, 'Complete medication history'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        
        // Login Link
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecondScreen()),
              );
            },
            child: Text(
              'Already have an account? Sign in',
              style: TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _conditionsController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}