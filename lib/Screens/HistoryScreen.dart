// Screens/HistoryScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Colors/theme.dart';
import '../services/medication_service.dart';
import '../services/session_manager.dart';
import '../services/sqflite_service.dart';
import '../models/medication.dart';
import '../widgets/LoadingIndicator.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final MedicationService _medicationService = MedicationService();
  final SessionManager _sessionManager = SessionManager();
  final DatabaseService _dbService = DatabaseService();
  
  bool _isLoading = true;
  bool _isGuest = false;
  String _userId = '';
  
  // Date filter options
  final List<String> _filterOptions = ['Today', 'This Week', 'This Month', 'Custom'];
  String _selectedFilter = 'This Week';
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _customEndDate = DateTime.now();
  
  // History data
  List<Map<String, dynamic>> _historyEntries = [];
  Map<String, dynamic> _adherenceStats = {};
  
  // For date picker
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkUserType();
    await _loadHistoryData();
  }

  Future<void> _checkUserType() async {
    final isGuest = await _sessionManager.isGuestMode();
    final userId = await _medicationService.getCurrentUserId();
    setState(() {
      _isGuest = isGuest;
      _userId = userId;
    });
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime startDate;
      DateTime endDate = DateTime.now();
      
      switch (_selectedFilter) {
        case 'Today':
          startDate = DateTime(endDate.year, endDate.month, endDate.day);
          break;
        case 'This Week':
          startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'This Month':
          startDate = DateTime(endDate.year, endDate.month, 1);
          break;
        case 'Custom':
          startDate = _customStartDate;
          endDate = _customEndDate;
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      await _loadHistoryEntries(startDate, endDate);
      _calculateAdherenceStats();
      
    } catch (e) {
      print('Error loading history data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistoryEntries(DateTime startDate, DateTime endDate) async {
    // This would typically come from a database
    // For now, we'll generate sample data based on actual medications
    
    final allMeds = await _medicationService.getMedications();
    final entries = <Map<String, dynamic>>[];
    
    // Generate history entries for the date range
    int days = endDate.difference(startDate).inDays + 1;
    
    for (int i = 0; i < days; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dateString = _dateFormat.format(currentDate);
      
      for (var med in allMeds) {
        if (!med.isActive) continue;
        
        // Check if medication was supposed to be taken on this day
        final medStartDate = DateTime(
          med.createdAt.year, 
          med.createdAt.month, 
          med.createdAt.day
        );
        final medEndDate = medStartDate.add(Duration(days: med.numberOfDays - 1));
        
        if (!currentDate.isBefore(medStartDate) && !currentDate.isAfter(medEndDate)) {
          // Check if it was taken
          final key = 'taken_${med.id}_$dateString';
          final status = await _sessionManager.getUserPreference(key);
          final isTaken = status == 'true';
          
          // Generate random time if taken (in real app, this would be stored)
          final takenTime = isTaken ? _generateRandomTime(currentDate) : null;
          
          entries.add({
            'id': '${med.id}_$dateString',
            'medicationId': med.id,
            'medicationName': med.name,
            'dosage': med.dosage,
            'date': currentDate,
            'dateString': dateString,
            'isTaken': isTaken,
            'takenTime': takenTime,
          });
        }
      }
    }
    
    // Sort by date descending (most recent first)
    entries.sort((a, b) => b['date'].compareTo(a['date']));
    
    setState(() {
      _historyEntries = entries;
    });
  }

  DateTime? _generateRandomTime(DateTime date) {
    // This is just for sample data - in real app, you'd store actual taken times
    // Generate a random time between 6 AM and 10 PM
    final hour = 6 + (DateTime.now().millisecond % 16);
    final minute = DateTime.now().millisecond % 60;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _calculateAdherenceStats() {
    if (_historyEntries.isEmpty) {
      setState(() {
        _adherenceStats = {
          'total': 0,
          'taken': 0,
          'missed': 0,
          'percentage': 0,
        };
      });
      return;
    }

    final total = _historyEntries.length;
    final taken = _historyEntries.where((entry) => entry['isTaken']).length;
    final missed = total - taken;
    final percentage = total > 0 ? (taken / total * 100).round() : 0;

    setState(() {
      _adherenceStats = {
        'total': total,
        'taken': taken,
        'missed': missed,
        'percentage': percentage,
      };
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _customStartDate,
        end: _customEndDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = 'Custom';
      });
      await _loadHistoryData();
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning_amber, color: Colors.red, size: 40),
        content: const Text(
          'Are you sure you want to clear all history?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // In a real app, you would delete all history entries from the database
        // For now, we'll just clear the local list
        await Future.delayed(const Duration(seconds: 1)); // Simulate deletion
        
        setState(() {
          _historyEntries = [];
          _adherenceStats = {};
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing history: ${e.toString()}'),
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

  Future<void> _deleteHistoryEntry(String entryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.delete_outline, color: Colors.red, size: 40),
        content: const Text('Delete this history entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _historyEntries.removeWhere((entry) => entry['id'] == entryId);
        _calculateAdherenceStats();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatEntryTime(Map<String, dynamic> entry) {
    if (!entry['isTaken']) return 'missed';
    
    final takenTime = entry['takenTime'] as DateTime?;
    if (takenTime != null) {
      return 'taken – ${_timeFormat.format(takenTime)}';
    }
    return 'taken';
  }

  Color _getEntryColor(bool isTaken) {
    return isTaken ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medication History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoryData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
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
            ? const LoadingIndicator(message: 'Loading history...')
            : Column(
                children: [
                  // Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filterOptions.map((filter) {
                              final isSelected = _selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(filter),
                                  selected: isSelected,
                                  onSelected: (selected) async {
                                    if (filter == 'Custom') {
                                      await _selectCustomDateRange();
                                    } else {
                                      setState(() {
                                        _selectedFilter = filter;
                                      });
                                      await _loadHistoryData();
                                    }
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: AppColors.accentLight,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        // Custom date range display
                        if (_selectedFilter == 'Custom') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.date_range, size: 16, color: AppColors.accentLight),
                                const SizedBox(width: 8),
                                Text(
                                  '${_displayDateFormat.format(_customStartDate)} - ${_displayDateFormat.format(_customEndDate)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Adherence Stats and Pie Chart
                  if (_historyEntries.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Adherence',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedFilter.toLowerCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${_adherenceStats['percentage']}%',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: _getAdherenceColor(_adherenceStats['percentage']),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_adherenceStats['taken']} of ${_adherenceStats['total']} doses',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Pie Chart
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: _adherenceStats['taken'].toDouble(),
                                        title: '${_adherenceStats['taken']}',
                                        color: Colors.green,
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: _adherenceStats['missed'].toDouble(),
                                        title: '${_adherenceStats['missed']}',
                                        color: Colors.red,
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                    startDegreeOffset: -90,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem('Taken', Colors.green, _adherenceStats['taken']),
                              _buildLegendItem('Missed', Colors.red, _adherenceStats['missed']),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // History List
                  Expanded(
                    child: _historyEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No history available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Medications you take will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _historyEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _historyEntries[index];
                              final isTaken = entry['isTaken'];
                              final color = _getEntryColor(isTaken);
                              
                              return GestureDetector(
                                onLongPress: () => _deleteHistoryEntry(entry['id']),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isTaken ? Icons.check_circle : Icons.cancel,
                                          color: color,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        entry['medicationName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${entry['dosage']} • ${_formatEntryTime(entry)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Text(
                                        DateFormat('MMM d').format(entry['date']),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      isThreeLine: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _getAdherenceColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}