import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/sqflite_service.dart';
import '../models/medication.dart';
import 'Signup.dart';
import 'HistoryScreen.dart';
import 'AddMedicationScreen.dart';
import 'ChatBotScreen.dart';
import 'ProfileScreen.dart';
import 'EditMedicationScreen.dart';
import '../widgets/LoadingIndicator.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final SessionManager _sessionManager = SessionManager();
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final isGuest = await _sessionManager.isGuestMode();
    print('User is guest: $isGuest');
    setState(() {
      _isGuest = isGuest;
    });
  }

  static const List<BottomNavigationBarItem> _navBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline, size: 32),
      activeIcon: Icon(Icons.add_circle, size: 32),
      label: 'Add',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  late final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const AddMedicationScreen(),
    const ChatBotScreen(),
    ProfileScreen(isGuest: _isGuest),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    if (_isGuest) {
      await _sessionManager.endGuestSession();
    } else {
      await _authService.signOut();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SecondScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MEDICATA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.textSecondaryDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textSecondaryDark),
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.accentLight,
        unselectedItemColor: AppColors.textSecondaryDark,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryLight,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppColors.primaryLight,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentLight, AppColors.secondaryLight],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _isGuest ? Icons.person_outline : Icons.person,
                      size: 35,
                      color: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isGuest ? 'Guest User' : 'Registered User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isGuest ? 'Limited Features' : 'Full Access',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', 0),
            _buildDrawerItem(Icons.history, 'History', 1),
            _buildDrawerItem(Icons.add_circle, 'Add Medication', 2),
            _buildDrawerItem(Icons.chat, 'AI Chat Bot', 3),
            _buildDrawerItem(Icons.person, 'Profile', 4),
            const Divider(),
            if (_isGuest)
              ListTile(
                leading: Icon(Icons.star, color: Colors.amber),
                title: const Text(
                  'Upgrade Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Get full features'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecondScreen(),
                    ),
                  );
                },
              ),
            _buildDrawerItem(
              Icons.settings,
              'Settings',
              null,
              onTap: () => _showComingSoon('Settings'),
            ),
            _buildDrawerItem(
              Icons.help,
              'Help & Support',
              null,
              onTap: () => _showComingSoon('Help & Support'),
            ),
            _buildDrawerItem(
              Icons.info,
              'About',
              null,
              onTap: () => _showAboutDialog(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    int? index, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondaryDark),
      title: Text(title),
      onTap:
          onTap ??
          () {
            Navigator.pop(context);
            if (index != null) _onItemTapped(index);
          },
    );
  }

  void _showComingSoon(String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAboutDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Medicata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services,
              size: 80,
              color: AppColors.accentLight,
            ),
            const SizedBox(height: 20),
            const Text(
              'Medicata v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your personal medication assistant.\n'
              'Track medications, get reminders, and stay healthy!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ==================== UPDATED HOME SCREEN ====================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicationService _medicationService = MedicationService();
  final SessionManager _sessionManager = SessionManager();
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _dbService = DatabaseService();

  List<Medication> _medications = [];
  Map<DateTime, List<Medication>> _medicationsByDay = {};
  List<DateTime> _nextDays = [];
  bool _isLoading = true;
  bool _isGuest = false;
  String _customQuote = '';
  final Map<String, bool> _takenStatus = {};

  // Motivational quotes for each day of the week
  final Map<int, String> _defaultQuotes = {
    1: "Monday: Start your week strong! Take your medications on time. 💪",
    2: "Tuesday: Your health is your wealth. Stay consistent! 🌟",
    3: "Wednesday: Halfway there! Keep up the good work! 🎯",
    4: "Thursday: Small steps lead to big results. You've got this! ✨",
    5: "Friday: Finish the week strong! Your future self will thank you. 🌈",
    6: "Saturday: Take time for self-care today. You deserve it! 💖",
    7: "Sunday: Reflect on your progress and prepare for the week ahead. 🌅",
  };

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _loadMedicationsByDay();
  }

  Future<void> _initializeScreen() async {
    await _checkUserType();
    await _loadQuote();
    await _checkNotificationPermission();
  }

  Future<void> _checkUserType() async {
    final isGuest = await _sessionManager.isGuestMode();
    setState(() {
      _isGuest = isGuest;
    });
  }

  Future<void> _checkNotificationPermission() async {
    if (!_isGuest) {
      final hasPermission = await _notificationService.isPermissionGranted();
      if (!hasPermission) {
        _showNotificationPermissionDialog();
      }
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Medication reminders work best with notifications enabled. '
          'Would you like to enable them now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _notificationService.requestNotificationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLight,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuote() async {
    if (!_isGuest) {
      final savedQuote = await _sessionManager.getUserPreference(
        'custom_quote',
      );
      if (savedQuote != null && savedQuote.isNotEmpty) {
        setState(() {
          _customQuote = savedQuote;
        });
        return;
      }
    }

    final today = DateTime.now().weekday;
    setState(() {
      _customQuote = _defaultQuotes[today] ?? _defaultQuotes[1]!;
    });
  }

  Future<void> _customizeQuote() async {
    if (_isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create an account to customize quotes!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController quoteController = TextEditingController(
      text: _customQuote,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Your Quote'),
        content: TextField(
          controller: quoteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your motivational quote...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (quoteController.text.trim().isNotEmpty) {
                await _sessionManager.saveUserPreference(
                  'custom_quote',
                  quoteController.text.trim(),
                );
                setState(() {
                  _customQuote = quoteController.text.trim();
                });
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLight,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMedicationsByDay() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allMeds = await _medicationService.getMedications();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Generate next 4 days (today + 3 more days)
      _nextDays = List.generate(4, (index) => today.add(Duration(days: index)));

      // Clear the map
      _medicationsByDay = {};

      // Load taken status for today
      final todayString = DateFormat('yyyy-MM-dd').format(today);

      for (var med in allMeds) {
        if (!med.isActive) continue;

        final startDate = DateTime(
          med.createdAt.year,
          med.createdAt.month,
          med.createdAt.day,
        );
        final endDate = startDate.add(Duration(days: med.numberOfDays - 1));

        // Check each day in our range
        for (var day in _nextDays) {
          // If this day is within the medication's active period
          if (!day.isBefore(startDate) && !day.isAfter(endDate)) {
            // Initialize list if needed
            if (!_medicationsByDay.containsKey(day)) {
              _medicationsByDay[day] = [];
            }

            // For today, check if already taken
            if (day.isAtSameMomentAs(today)) {
              final key = 'taken_${med.id}_$todayString';
              final status = await _sessionManager.getUserPreference(key);
              final isTaken = status == 'true';

              if (!isTaken) {
                _medicationsByDay[day]!.add(med);
              }
              _takenStatus[med.id] = isTaken;
            } else {
              // For future days, add all medications
              _medicationsByDay[day]!.add(med);
            }
          }
        }
      }

      // Sort medications within each day by name
      _medicationsByDay.forEach((day, meds) {
        meds.sort((a, b) => a.name.compareTo(b.name));
      });

      setState(() {
        _medications = allMeds;
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

  Future<void> _toggleMedicationTaken(Medication medication) async {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        content: Text('Have you taken ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Taken'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Save to storage
      final key = 'taken_${medication.id}_$todayString';
      await _sessionManager.saveUserPreference(key, 'true');

      // Record in history
      if (!_isGuest) {
        await _medicationService.recordMedicationTaken(medication.id);
      } else {
        final userId = await _medicationService.getCurrentUserId();
        await _dbService.recordMedicationTaken(
          userId,
          medication.id,
          DateTime.now(),
        );
      }

      // Remove from today's list
      setState(() {
        if (_medicationsByDay.containsKey(today)) {
          _medicationsByDay[today]!.removeWhere(
            (med) => med.id == medication.id,
          );
        }
        _takenStatus[medication.id] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Great job! ${medication.name} recorded as taken'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editMedication(Medication medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicationScreen(medication: medication),
      ),
    );

    if (result == true) {
      await _loadMedicationsByDay();
    }
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning_amber, color: Colors.red, size: 40),
        content: Text(
          'Are you sure you want to delete ${medication.name}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        await _loadMedicationsByDay();

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

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    return DateFormat("EEEE, MMMM d'$suffix', yyyy").format(date);
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (date.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEEE').format(date);
    }
  }

  int _getTodayPendingCount() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return _medicationsByDay[todayDate]?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, Colors.white],
        ),
      ),
      child: _isLoading
          ? const LoadingIndicator(message: 'Loading your medications...')
          : RefreshIndicator(
              onRefresh: _loadMedicationsByDay,
              color: AppColors.accentLight,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Motivational Quote Section
                  Container(
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.format_quote,
                                    color: AppColors.accentLight,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daily Motivation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _customQuote,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isGuest)
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: AppColors.accentLight,
                            ),
                            onPressed: _customizeQuote,
                            tooltip: 'Customize Quote',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Days and Medications
                  ..._nextDays.map((day) {
                    final medications = _medicationsByDay[day] ?? [];
                    final isToday = day.isAtSameMomentAs(
                      DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.accentLight
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getDayLabel(day),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isToday
                                            ? AppColors.accentLight
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMMM d, yyyy').format(day),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${medications.length} ${medications.length == 1 ? 'medication' : 'medications'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isToday
                                      ? AppColors.accentLight
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Medications for this day
                        if (medications.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 50, bottom: 20),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'No medications scheduled',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ...medications
                              .map(
                                (medication) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 50,
                                    bottom: 12,
                                  ),
                                  child: _buildMedicationCard(
                                    medication,
                                    isToday,
                                  ),
                                ),
                              )
                              .toList(),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Pending Total Table - Restored
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Pending Today',
                          '${_getTodayPendingCount()}',
                          Icons.pending,
                          Colors.orange,
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          'Total Active',
                          '${_medications.length}',
                          Icons.medication,
                          AppColors.accentLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

Widget _buildMedicationCard(Medication medication, bool isToday) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isToday ? Colors.white : Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and dosage
            Row(
              children: [
                // Show image thumbnail for registered users if available
                if (!_isGuest && medication.imagePath != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(medication.imagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isToday ? AppColors.accentLight : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: isToday ? AppColors.accentLight : Colors.grey,
                      size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.black : Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${medication.dosage} • ${medication.numberOfTablets} tablet(s)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isToday ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Only show toggle button for today
                if (isToday)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey,
                        size: 24,
                      ),
                      onPressed: () => _toggleMedicationTaken(medication),
                      tooltip: 'Mark as taken',
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),

            // Notes if available
            if (medication.notes != null && medication.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        medication.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Edit and Delete buttons (only for today's medications)
            if (isToday) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editMedication(medication),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.accentLight,
                    ),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _deleteMedication(medication),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red[400],
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
