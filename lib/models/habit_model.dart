class Habit {
  String name;
  String icon;
  bool isDone;

  Habit({required this.name, required this.icon, this.isDone = false});

  Map<String, dynamic> toDefMap() => {'name': name, 'icon': icon};

  factory Habit.fromMaps(Map<String, dynamic> def, bool done) =>
      Habit(name: def['name'] ?? '', icon: def['icon'] ?? '⭐', isDone: done);
}
