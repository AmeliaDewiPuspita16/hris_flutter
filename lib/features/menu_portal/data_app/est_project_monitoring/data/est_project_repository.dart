import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../domain/est_available_worker.dart';
import '../domain/est_form_worker.dart';
import '../domain/est_mandor.dart';
import '../domain/est_substitute_candidate.dart';
import '../domain/exec_project_full.dart';
import '../domain/executive_dashboard.dart';
import '../domain/project_worker.dart';

/// Pintu ke API EST Project Monitoring (`/api/est/*`) untuk peran executive.
/// Semua method memakai varian `*Json` ApiClient: badan balasan dibaca utuh,
/// persis seperti aplikasi DW. Gagal dilempar sebagai `ApiException`.
class EstProjectRepository {
  EstProjectRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ExecutiveDashboardModel> fetchExecutiveDashboard() async {
    final json = await _apiClient.getJson(ApiConfig.estExecutiveDashboard);
    return ExecutiveDashboardModel.fromJson(json);
  }

  Future<void> openSession(int projectId) async {
    await _apiClient.postJson(
      ApiConfig.estOpenSession(projectId),
      body: <String, dynamic>{},
    );
  }

  /// Tanpa foto dikirim JSON (`auto_clock_out` bool); dengan foto dikirim
  /// multipart (`auto_clock_out` '1'/'0', berkas di field `photos[]`).
  Future<void> closeSession(
    int projectId, {
    required String description,
    required bool autoClockOut,
    List<String> photoPaths = const [],
  }) async {
    final path = ApiConfig.estCloseSession(projectId);
    if (photoPaths.isEmpty) {
      await _apiClient.postJson(
        path,
        body: {'description': description, 'auto_clock_out': autoClockOut},
      );
    } else {
      await _apiClient.postMultipartJson(
        path,
        fields: {
          'description': description,
          'auto_clock_out': autoClockOut ? '1' : '0',
        },
        files: {'photos[]': photoPaths},
      );
    }
  }

  Future<ExecProjectFullModel> fetchProjectDetail(int projectId) async {
    final json = await _apiClient.getJson(ApiConfig.estProject(projectId));
    return ExecProjectFullModel.fromJson(json);
  }

  Future<List<ProjectWorkerModel>> fetchProjectWorkers(int projectId) async {
    final json =
        await _apiClient.getJson(ApiConfig.estProjectWorkers(projectId));
    final raw = json['data'] as List? ?? [];
    return raw
        .map((e) => ProjectWorkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mengembalikan seluruh balasan; pemanggil membaca `message`.
  Future<Map<String, dynamic>> assignWorkers(
    int projectId,
    List<int> workerIds,
  ) {
    return _apiClient.postJson(
      ApiConfig.estAssignTeam(projectId),
      body: {'worker_ids': workerIds},
    );
  }

  /// `reason` hanya dikirim bila diisi, sama seperti DW.
  Future<Map<String, dynamic>> transferWorkers(
    int projectId, {
    required int targetProjectId,
    required List<int> workerIds,
    String? reason,
  }) {
    return _apiClient.postJson(
      ApiConfig.estTransferWorkers(projectId),
      body: {
        'worker_ids': workerIds,
        'target_project_id': targetProjectId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<void> requestCloseProject(int projectId) async {
    await _apiClient.postJson(
      ApiConfig.estCloseProject(projectId),
      body: <String, dynamic>{},
    );
  }

  /// [body] disusun pemanggil: `role`, `substitute_for`, `substitute_reason`,
  /// lalu `user_id` (mandor) atau `worker_id` (worker).
  Future<void> assignSubstitute(
    int projectId,
    Map<String, dynamic> body,
  ) async {
    await _apiClient.postJson(ApiConfig.estSubstitute(projectId), body: body);
  }

  Future<void> endSubstitute(int projectId, int assignmentId) async {
    await _apiClient.deleteJson(
      ApiConfig.estEndSubstitute(projectId, assignmentId),
    );
  }

  Future<List<EstMandor>> fetchMandors() async {
    final json = await _apiClient.getJson(ApiConfig.estMandors);
    final raw = json['data'] as List? ?? [];
    return raw
        .map((e) => EstMandor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [query] mis. `project_id` dan `search`, disusun pemanggil.
  Future<List<EstAvailableWorker>> fetchAvailableWorkers({
    Map<String, String>? query,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.estAvailableWorkers,
      query: query,
    );
    return _workers(json);
  }

  /// Daftar pilih worker di form project: endpoint dan query sama dengan
  /// [fetchAvailableWorkers], tetapi parsing ketat ke bentuk lengkap DW.
  Future<List<EstFormWorker>> fetchFormWorkers({
    Map<String, String>? query,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.estAvailableWorkers,
      query: query,
    );
    final raw = json['data'] as List;
    return raw
        .map((e) => EstFormWorker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EstAvailableWorker>> fetchAllWorkers({
    Map<String, String>? query,
  }) async {
    final json =
        await _apiClient.getJson(ApiConfig.estAllWorkers, query: query);
    return _workers(json);
  }

  /// Daftar proyek untuk sheet pindah worker; DW membaca `data`, lalu
  /// `projects` bila `data` tidak ada. Penyaringan proyek asal oleh pemanggil.
  Future<List<ExecutiveProjectModel>> fetchActiveProjects() async {
    final json = await _apiClient.getJson(ApiConfig.estProjects);
    final raw = (json['data'] as List?) ?? (json['projects'] as List?) ?? [];
    return raw
        .map((e) => ExecutiveProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kandidat sheet substitusi: mandor bila [mandor], selain itu semua worker.
  /// Parsing longgar seperti DW, beda dari [fetchMandors]/[fetchAllWorkers].
  Future<List<EstSubstituteCandidate>> fetchSubstituteCandidates({
    required bool mandor,
  }) async {
    final json = await _apiClient.getJson(
      mandor ? ApiConfig.estMandors : ApiConfig.estAllWorkers,
    );
    final raw = (json['data'] as List?) ?? [];
    return raw
        .map((e) => EstSubstituteCandidate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createProject(Map<String, dynamic> body) async {
    await _apiClient.postJson(ApiConfig.estProjects, body: body);
  }

  Future<void> updateProject(int id, Map<String, dynamic> body) async {
    await _apiClient.putJson(ApiConfig.estProject(id), body: body);
  }

  List<EstAvailableWorker> _workers(Map<String, dynamic> json) {
    final raw = json['data'] as List? ?? [];
    return raw
        .map((e) => EstAvailableWorker.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
