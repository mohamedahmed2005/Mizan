import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../theme/theme_toggle_button.dart';
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
    if (_habits[index].isDone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Habit already completed!')));
      return;
    }
    setState(() => _habits[index].isDone = true);
    final checks = _habits.map((h) => h.isDone).toList();
    await StorageService.saveHabitChecks(_today, checks);
    // Record habit history
    await StorageService.recordHabitHistory(
        _today, StorageService.getHabitDefinitions(), checks);
    final allDone = _habits.every((h) => h.isDone);
    if (allDone) {
      await StorageService.addPoints(20);
      await StorageService.unlockAchievement('all_habits');
    }
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Habit',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary),
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: 'Habit Name',
                    prefixIcon: Icon(Icons.star_outline, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Pick an icon:',
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
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        final defs = StorageService.getHabitDefinitions();
                        if (defs.any((d) => (d['name'] as String).toLowerCase() == name.toLowerCase())) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Habit already exists!')));
                          return;
                        }
                        defs.add(
                            {'name': name, 'icon': selectedIcon});
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
        title: Text('New Task',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'What do you need to do?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() => _tasks.add(DailyTask(text: text)));
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
    if (_tasks[index].isDone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task already completed!')));
      return;
    }
    setState(() => _tasks[index].isDone = true);
    await _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    setState(() => _tasks.removeAt(index));
    await _saveTasks();
  }

  void _showHabitHistory() {
    final history = StorageService.getHabitHistory();
    final sortedDates = history.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('📅 Habit History',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            Divider(color: AppColors.border),
            Expanded(
              child: sortedDates.isEmpty
                  ? Center(
                      child: Text('No history yet',
                          style:
                              TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: sortedDates.length,
                      itemBuilder: (_, i) {
                        final date = sortedDates[i];
                        final completed = history[date]!;
                        final dt = DateTime.parse(date);
                        final label =
                            DateFormat('EEEE, MMMM d, y').format(dt);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(label,
                                      style: TextStyle(
                                          color: AppColors.teal,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.green
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                        '✓ ${completed.length} done',
                                        style: TextStyle(
                                            color: AppColors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              if (completed.isNotEmpty) ...
                                [
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: completed.map((name) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.teal
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.teal
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Text(name,
                                            style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 12)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                            ],
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _tabButton('Habits 🌱', 0),
                          const SizedBox(width: 10),
                          _tabButton('Daily Plan 📋', 1),
                        ],
                      ),
                      Row(
                        children: [
                          if (_selectedTab == 0)
                            IconButton(
                              icon: Icon(Icons.history_rounded,
                                  color: AppColors.textSecondary),
                              onPressed: _showHabitHistory,
                              tooltip: 'Habit History',
                            ),
                          const ThemeToggleButton(),
                        ],
                      ),
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
                          AlwaysStoppedAnimation(AppColors.green),
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
                          AlwaysStoppedAnimation(AppColors.purple),
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
                      Icon(Icons.delete_outline, color: AppColors.red),
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
