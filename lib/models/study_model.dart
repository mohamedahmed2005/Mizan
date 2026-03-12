class Subject {
  String name;
  double hoursStudied;
  double targetHours;

  Subject({
    required this.name,
    this.hoursStudied = 0.0,
    this.targetHours = 5.0,
  });

  double get progress =>
      targetHours == 0 ? 0 : (hoursStudied / targetHours).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'name': name,
        'studied': hoursStudied,
        'target': targetHours,
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        name: map['name'] ?? '',
        hoursStudied: (map['studied'] ?? 0.0).toDouble(),
        targetHours: (map['target'] ?? 5.0).toDouble(),
      );
}
