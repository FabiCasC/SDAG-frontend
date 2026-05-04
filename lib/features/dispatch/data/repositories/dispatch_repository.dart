class DispatchRepository {
  Future<void> activateDriver(String driverId) async {
    // Simulación local: sin Firebase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> deactivateDriver(String driverId) async {
    // Simulación local: sin Firebase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> logAuditAlert({
    required String driverId,
    required String plate,
    required List<String> expiredDocs,
  }) async {
    // Simulación local: sin Firebase
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
