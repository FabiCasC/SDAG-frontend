class HistoryRepository {
  Stream<List<Map<String, dynamic>>> getAuditLogs() {
    // Simulación local vacía: sin Firebase
    return Stream.value([]);
  }
}
