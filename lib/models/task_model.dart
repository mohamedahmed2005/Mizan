class DailyTask {
  String text;
  bool isDone;

  DailyTask({required this.text, this.isDone = false});

  Map<String, dynamic> toMap() => {'text': text, 'done': isDone};

  factory DailyTask.fromMap(Map<String, dynamic> map) =>
      DailyTask(text: map['text'] ?? '', isDone: map['done'] ?? false);
}
