import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../services/storage_service.dart';
import '../services/app_state.dart';
import '../models/study_model.dart';
import 'package:intl/intl.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<Subject> _subjects = [];
  late String _today;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadSubjects();
  }

  void _loadSubjects() {
    final raw = StorageService.getSubjects();
    setState(() {
      _subjects = raw.map((m) => Subject.fromMap(m)).toList();
    });
  }

  Future<void> _saveSubjects() async {
    await StorageService.saveSubjects(_subjects.map((s) => s.toMap()).toList());
    for (final s in _subjects) {
      if (s.hoursStudied >= s.targetHours) {
        await StorageService.addPoints(30);
        await StorageService.unlockAchievement('study_goal_${s.name}');
      }
    }
    final totalHours = _subjects.fold(0.0, (sum, s) => sum + s.hoursStudied);
    final prayers = StorageService.getPrayers(_today).where((p) => p).length;
    await StorageService.recordDayStats(_today, prayers, totalHours);

    // Notify Dashboard to update study progress in real-time
    AppState.instance.notify();
  }

  void _addSubject() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '5');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Subject',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                prefixIcon: Icon(Icons.book_outlined, color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Target Hours',
                prefixIcon:
                    Icon(Icons.timer_outlined, color: AppColors.purple),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _subjects.add(Subject(
                        name: nameCtrl.text.trim(),
                        targetHours: double.tryParse(targetCtrl.text) ?? 5.0,
                      ));
                    });
                    _saveSubjects();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Subject',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editHours(int index) {
    final ctrl =
        TextEditingController(text: _subjects[index].hoursStudied.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Hours – ${_subjects[index].name}',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Hours studied',
            prefixIcon: Icon(Icons.access_time, color: AppColors.teal),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final val = double.tryParse(ctrl.text);
                if (val != null && val >= 0) {
                  setState(() => _subjects[index].hoursStudied = val);
                  _saveSubjects();
                }
                Navigator.pop(context);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  void _deleteSubject(int index) {
    setState(() => _subjects.removeAt(index));
    _saveSubjects();
  }

  double get _totalHours =>
      _subjects.fold(0.0, (sum, s) => sum + s.hoursStudied);

  @override
  Widget build(BuildContext context) {
    final pad = R.pd(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Study Tracker',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: R.sp(context, 28),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      'Total today: ${_totalHours.toStringAsFixed(1)} hours',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: R.sp(context, 14))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _summaryChip('📚 ${_subjects.length}', 'Subjects'),
                      const SizedBox(width: 12),
                      _summaryChip(
                          '⏱ ${_totalHours.toStringAsFixed(1)}h', 'Studied'),
                      const SizedBox(width: 12),
                      _summaryChip(
                          '🎯 ${_subjects.where((s) => s.hoursStudied >= s.targetHours).length}',
                          'Goals Met'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _subjects.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: _subjects.length,
                      itemBuilder: (_, i) => _buildSubjectCard(i),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubject,
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _summaryChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: R.sp(context, 15),
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: R.sp(context, 10))),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(int index) {
    final s = _subjects[index];
    final isComplete = s.hoursStudied >= s.targetHours;
    final Color accentColor = [
      AppColors.teal,
      AppColors.purple,
      AppColors.blue,
      AppColors.orange,
      AppColors.green,
    ][index % 5];

    return Dismissible(
      key: Key(s.name + index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteSubject(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isComplete
                  ? accentColor.withValues(alpha: 0.6)
                  : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.name,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: R.sp(context, 16),
                          fontWeight: FontWeight.w600)),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('✓ Done',
                        style: TextStyle(
                            color: AppColors.green,
                            fontSize: R.sp(context, 11),
                            fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editHours(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: accentColor, size: 14),
                        const SizedBox(width: 3),
                        Text('Log',
                            style: TextStyle(
                                color: accentColor,
                                fontSize: R.sp(context, 12),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 8,
              percent: s.progress,
              backgroundColor: AppColors.border,
              progressColor: accentColor,
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
              animation: true,
              animationDuration: 600,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${s.hoursStudied.toStringAsFixed(1)} / ${s.targetHours.toStringAsFixed(1)} hours',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: R.sp(context, 12))),
                Text('${(s.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: accentColor,
                        fontSize: R.sp(context, 12),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📚', style: TextStyle(fontSize: R.sp(context, 64))),
          const SizedBox(height: 16),
          Text('No subjects yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: R.sp(context, 20),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the button below to add one',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: R.sp(context, 14))),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
