class ExecutiveNotClockedOutModel {
  final int id;
  final String name;
  final String clockIn;

  const ExecutiveNotClockedOutModel({
    required this.id,
    required this.name,
    required this.clockIn,
  });

  factory ExecutiveNotClockedOutModel.fromJson(Map<String, dynamic> json) =>
      ExecutiveNotClockedOutModel(
        id: json['id'] as int,
        name: json['name'] as String,
        clockIn: json['clock_in'] as String,
      );
}

class ExecutiveSummaryModel {
  final int activeProjects;
  final int totalWorkerToday;
  final int hoursUsedPct;

  const ExecutiveSummaryModel({
    required this.activeProjects,
    required this.totalWorkerToday,
    required this.hoursUsedPct,
  });

  factory ExecutiveSummaryModel.fromJson(Map<String, dynamic> json) =>
      ExecutiveSummaryModel(
        activeProjects: json['active_projects'] as int,
        totalWorkerToday: json['total_worker_today'] as int,
        hoursUsedPct: json['hours_used_pct'] as int,
      );
}

class ExecutiveProjectModel {
  final int id;
  final String name;
  final String? jobNumber;
  final String location;
  final int budgetHours;
  final double usedHours;
  final double remainingHours;
  final int progressPercent;
  final String status;
  final String startDate;
  final String targetEndDate;
  final String sessionStatus; // "open" | "closed" | "no_session"
  final int? sessionId;
  final String? sessionOpenedAt;
  final int notClockedOut;
  final List<ExecutiveNotClockedOutModel> notClockedOutList;

  const ExecutiveProjectModel({
    required this.id,
    required this.name,
    required this.jobNumber,
    required this.location,
    required this.budgetHours,
    required this.usedHours,
    required this.remainingHours,
    required this.progressPercent,
    required this.status,
    required this.startDate,
    required this.targetEndDate,
    required this.sessionStatus,
    this.sessionId,
    this.sessionOpenedAt,
    required this.notClockedOut,
    required this.notClockedOutList,
  });

  factory ExecutiveProjectModel.fromJson(Map<String, dynamic> json) =>
      ExecutiveProjectModel(
        id: json['id'] as int,
        name: json['name'] as String,
        jobNumber: json['job_number'] as String?,
        location: json['location'] as String,
        budgetHours: json['budget_hours'] as int,
        usedHours: (json['used_hours'] as num).toDouble(),
        remainingHours: (json['remaining_hours'] as num).toDouble(),
        progressPercent: json['progress_percent'] as int,
        status: json['status'] as String,
        startDate: json['start_date'] as String,
        targetEndDate: json['target_end_date'] as String,
        sessionStatus: (json['session_status'] as String?) ?? 'no_session',
        sessionId: json['session_id'] as int?,
        sessionOpenedAt: json['session_opened_at'] as String?,
        notClockedOut: (json['not_clocked_out'] as int?) ?? 0,
        notClockedOutList: (json['not_clocked_out_list'] as List?)
                ?.map(
                  (e) => ExecutiveNotClockedOutModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
      );

  bool get isOpen => sessionStatus == 'open';

  double get progress =>
      budgetHours > 0 ? (usedHours / budgetHours).clamp(0.0, 1.0) : 0.0;

  String _formatNum(double n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n % 1 == 0 ? n.toInt().toString() : n.toString();
  }

  String get usedHoursLabel => _formatNum(usedHours);
  String get budgetHoursLabel => _formatNum(budgetHours.toDouble());
}

class ExecutiveDashboardModel {
  final ExecutiveSummaryModel summary;
  final List<ExecutiveProjectModel> projects;

  const ExecutiveDashboardModel({
    required this.summary,
    required this.projects,
  });

  factory ExecutiveDashboardModel.fromJson(Map<String, dynamic> json) =>
      ExecutiveDashboardModel(
        summary: ExecutiveSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
        projects: (json['projects'] as List)
            .map(
              (e) => ExecutiveProjectModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}
