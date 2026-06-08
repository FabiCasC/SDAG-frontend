enum AppRole {
  passenger,
  driver,
  admin,
}

extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.passenger:
        return 'Pasajero';
      case AppRole.driver:
        return 'Conductor';
      case AppRole.admin:
        return 'Administrador';
    }
  }
}

