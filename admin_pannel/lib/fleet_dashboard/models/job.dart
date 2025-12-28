class CurrentJob {
  final String id;
  final String type;
  final int progress;
  final String eta;

  CurrentJob({
    required this.id,
    required this.type,
    required this.progress,
    required this.eta,
  });

  factory CurrentJob.fromJson(Map<String, dynamic> json) {
    return CurrentJob(
      id: json['id'] as String,
      type: json['type'] as String,
      progress: json['progress'] as int,
      eta: json['eta'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'progress': progress,
      'eta': eta,
    };
  }
}

class JobCategory {
  final String category;
  final int total;
  final int completed;
  final int pending;
  final String slaStatus; // 'on-track' | 'at-risk' | 'critical'

  JobCategory({
    required this.category,
    required this.total,
    required this.completed,
    required this.pending,
    required this.slaStatus,
  });

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      category: json['category'] as String,
      total: json['total'] as int,
      completed: json['completed'] as int,
      pending: json['pending'] as int,
      slaStatus: json['slaStatus'] as String,
    );
  }
}

class JobCompletionTime {
  final String category;
  final double time;

  JobCompletionTime({
    required this.category,
    required this.time,
  });

  factory JobCompletionTime.fromJson(Map<String, dynamic> json) {
    return JobCompletionTime(
      category: json['category'] as String,
      time: (json['time'] as num).toDouble(),
    );
  }
}
