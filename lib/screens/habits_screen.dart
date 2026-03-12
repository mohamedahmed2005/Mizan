import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../services/storage_service.dart';
import '../services/app_state.dart';
import '../models/habit_model.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  List<DailyTask> _tasks = [];
  late String _today;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  void _loadData() {
    final defs = StorageService.getHabitDefinitions();
    final checks = StorageService.getHabitChecks(_today, defs.length);
    final taskMaps = StorageService.getTasks(_today);
    setState(() {
      _habits = List.generate(
          defs.length, (i) => Habit.fromMaps(defs[i], checks[i]));
      _tasks = taskMaps.map((m) => DailyTask.fromMap(m)).toList();
    });
  }

  Future<void> _toggleHabit(int index) async {
    setState(() => _habits[index].isDone = !_habits[index].isDone);
    final checks = _habits.map((h) => h.isDone).toList();
    await StorageService.saveHabitChecks(_today, checks);
    final allDone = _habits.every((h) => h.isDone);
    if (allDone) {
      await StorageService.addPoints(20);
      await StorageService.unlockAchievement('all_habits');
    }
    // Notify Dashboard to update habits counter in real-time
    AppState.instance.notify();
  }

  Future<void> _addHabit() async {
    final nameCtrl = TextEditingController();
    String selectedIcon = '⭐';
    final icons = ['💧', '🏋️', '📚', '📖', '🧘', '🚶', '🍎', '✏️', '🎯', '⭐'];

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Habit',
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
                  labelText: 'Habit Name',
                  prefixIcon: Icon(Icons.star_outline, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Pick an icon:',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: icons.map((icon) {
                  final selected = icon == selectedIcon;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.teal.withValues(alpha: 0.2)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected ? AppColors.teal : AppColors.border),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
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
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      final defs = StorageService.getHabitDefinitions();
                      defs.add(
                          {'name': nameCtrl.text.trim(), 'icon': selectedIcon});
                      await StorageService.saveHabitDefinitions(defs);
                      await StorageService.saveHabitChecks(
                          _today,
                          List.generate(
                              defs.length,
                              (i) =>
                                  i < _habits.length ? _habits[i].isDone : false));
                      _loadData();
                      AppState.instance.notify();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add Habit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    final ctrl = TextEditingController();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Task',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'What do you need to do?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() => _tasks.add(DailyTask(text: ctrl.text.trim())));
                  await _saveTasks();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _saveTasks() async {
    await StorageService.saveTasks(
        _today, _tasks.map((t) => t.toMap()).toList());
  }

  Future<void> _toggleTask(int index) async {
    setState(() => _tasks[index].isDone = !_tasks[index].isDone);
    await _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    setState(() => _tasks.removeAt(index));
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final pad = R.pd(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTab == 0 ? 'Habit Tracker' : "Today's Plan",
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: R.sp(context, 28),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: R.sp(context, 14)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _tabButton('Habits 🌱', 0),
                      const SizedBox(width: 10),
                      _tabButton('Daily Plan 📋', 1),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0 ? _buildHabits() : _buildTasks(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedTab == 0 ? _addHabit : _addTask,
        backgroundColor:
            _selectedTab == 0 ? AppColors.teal : AppColors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tabButton(String label, int tab) {
    final selected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (tab == 0 ? AppColors.teal : AppColors.purple)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? Colors.transparent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: R.sp(context, 13),
          ),
        ),
      ),
    );
  }

  Widget _buildHabits() {
    final pad = R.pd(context);
    final done = _habits.where((h) => h.isDone).length;
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: pad),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text('🌱', style: TextStyle(fontSize: R.sp(context, 24))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$done / ${_habits.length} habits done today',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: R.sp(context, 15),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _habits.isEmpty ? 0 : done / _habits.length,
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.green),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._habits.asMap().entries.map((e) => _buildHabitTile(e.key, e.value)),
      ],
    );
  }

  Widget _buildHabitTile(int index, Habit habit) {
    return GestureDetector(
      onTap: () => _toggleHabit(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: habit.isDone
              ? AppColors.green.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: habit.isDone
                  ? AppColors.green.withValues(alpha: 0.5)
                  : AppColors.border),
        ),
        child: Row(
          children: [
            Text(habit.icon, style: TextStyle(fontSize: R.sp(context, 28))),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  color: habit.isDone
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: R.sp(context, 15),
                  fontWeight: FontWeight.w500,
                  decoration: habit.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.isDone ? AppColors.green : Colors.transparent,
                border: Border.all(
                    color: habit.isDone
                        ? AppColors.green
                        : AppColors.textMuted,
                    width: 2),
              ),
              child: habit.isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasks() {
    final pad = R.pd(context);
    final done = _tasks.where((t) => t.isDone).length;
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: pad),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text('📋', style: TextStyle(fontSize: R.sp(context, 24))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$done / ${_tasks.length} tasks done',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: R.sp(context, 15),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _tasks.isEmpty ? 0 : done / _tasks.length,
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.purple),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                children: [
                  Text('📝', style: TextStyle(fontSize: R.sp(context, 48))),
                  const SizedBox(height: 12),
                  Text('No tasks yet — add one!',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: R.sp(context, 15))),
                ],
              ),
            ),
          ),
        ..._tasks.asMap().entries.map(
              (e) => Dismissible(
                key: Key(e.value.text + e.key.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteTask(e.key),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14)),
                  child:
                      const Icon(Icons.delete_outline, color: AppColors.red),
                ),
                child: GestureDetector(
                  onTap: () => _toggleTask(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: e.value.isDone
                          ? AppColors.purple.withValues(alpha: 0.08)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: e.value.isDone
                              ? AppColors.purple.withValues(alpha: 0.4)
                              : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: e.value.isDone
                                ? AppColors.purple
                                : Colors.transparent,
                            border: Border.all(
                                color: e.value.isDone
                                    ? AppColors.purple
                                    : AppColors.textMuted,
                                width: 2),
                          ),
                          child: e.value.isDone
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            e.value.text,
                            style: TextStyle(
                              color: e.value.isDone
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontSize: R.sp(context, 14),
                              decoration: e.value.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
