// Screens/HistoryScreen.dart
import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../widgets/FeatureGate.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
      child: FeatureGate(
        featureName: 'history',
        child: _HistoryContent(),
        fallback: const _HistoryContent(), // For now, show limited history for guests
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Medication History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildHistoryCard(
          'Paracetamol',
          '500mg - Twice daily',
          'Yesterday at 10:30 AM',
          Icons.check_circle,
          Colors.green,
        ),
        _buildHistoryCard(
          'Vitamin D',
          '1000 IU - Once daily',
          'Yesterday at 8:00 AM',
          Icons.check_circle,
          Colors.green,
        ),
        _buildHistoryCard(
          'Ibuprofen',
          '400mg - As needed',
          '2 days ago',
          Icons.cancel,
          Colors.red,
        ),
        _buildHistoryCard(
          'Amoxicillin',
          '250mg - Three times daily',
          '3 days ago',
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildHistoryCard(String medication, String dosage, String time, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(medication, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dosage),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}