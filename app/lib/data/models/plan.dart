import 'package:flutter/foundation.dart';

/// One exercise as it appears inside a plan: the movement plus the prescription.
@immutable
class PlanItem {
  const PlanItem({
    required this.exerciseId,
    required this.sets,
    required this.repLow,
    required this.repHigh,
    required this.restSeconds,
    required this.role,
    this.note,
  });

  final String exerciseId;
  final int sets;
  final int repLow;
  final int repHigh;
  final int restSeconds;

  /// Why this is in the session. Shown to the user, because "do 3 sets of 10"
  /// without a reason is how people stop caring about the plan.
  final PlanRole role;
  final String? note;

  String get repRange => repLow == repHigh ? '$repLow' : '$repLow-$repHigh';

  /// Rough time cost, used for the session estimate.
  ///
  /// Warm-ups and stretches are prescribed by duration rather than by reps, so
  /// costing them as `reps × 3s` would price a five-minute bike warm-up at three
  /// seconds and quietly understate every session by several minutes.
  int get estimatedSeconds => switch (role) {
    PlanRole.warmup => 300,
    PlanRole.cooldown => 60, // 30 seconds, usually both sides
    _ => sets * (repHigh * 3 + restSeconds),
  };

  PlanItem copyWith({
    String? exerciseId,
    int? sets,
    int? repLow,
    int? repHigh,
    int? restSeconds,
    PlanRole? role,
    String? note,
  }) => PlanItem(
    exerciseId: exerciseId ?? this.exerciseId,
    sets: sets ?? this.sets,
    repLow: repLow ?? this.repLow,
    repHigh: repHigh ?? this.repHigh,
    restSeconds: restSeconds ?? this.restSeconds,
    role: role ?? this.role,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'repLow': repLow,
    'repHigh': repHigh,
    'restSeconds': restSeconds,
    'role': role.name,
    'note': note,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    exerciseId: json['exerciseId'] as String,
    sets: json['sets'] as int,
    repLow: json['repLow'] as int,
    repHigh: json['repHigh'] as int,
    restSeconds: json['restSeconds'] as int,
    role: PlanRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => PlanRole.main,
    ),
    note: json['note'] as String?,
  );
}

enum PlanRole {
  warmup('Warm-up', 'Raise your temperature'),
  main('Main lift', 'The session is built around these'),
  secondary('Secondary', 'Backs up the main lifts'),
  accessory('Accessory', 'Fills in the gaps'),
  cooldown('Cool-down', 'Bring your heart rate down');

  const PlanRole(this.label, this.blurb);
  final String label;
  final String blurb;
}

@immutable
class PlanDay {
  const PlanDay({
    required this.index,
    required this.title,
    required this.focus,
    required this.items,
  });

  final int index;
  final String title;

  /// Short human summary: "Chest, shoulders and triceps".
  final String focus;
  final List<PlanItem> items;

  List<PlanItem> get workingItems => items
      .where((i) => i.role != PlanRole.warmup && i.role != PlanRole.cooldown)
      .toList();

  int get estimatedMinutes =>
      (items.fold<int>(0, (sum, i) => sum + i.estimatedSeconds) / 60).round();

  PlanDay copyWith({String? title, String? focus, List<PlanItem>? items}) =>
      PlanDay(
        index: index,
        title: title ?? this.title,
        focus: focus ?? this.focus,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
    'index': index,
    'title': title,
    'focus': focus,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
    index: json['index'] as int,
    title: json['title'] as String,
    focus: json['focus'] as String,
    items: (json['items'] as List)
        .map((i) => PlanItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}

@immutable
class Plan {
  const Plan({
    required this.name,
    required this.description,
    required this.days,
    required this.generatedAt,
  });

  final String name;
  final String description;
  final List<PlanDay> days;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'days': days.map((d) => d.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    name: json['name'] as String,
    description: json['description'] as String,
    days: (json['days'] as List)
        .map((d) => PlanDay.fromJson(d as Map<String, dynamic>))
        .toList(),
    generatedAt:
        DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
        DateTime.now(),
  );
}
