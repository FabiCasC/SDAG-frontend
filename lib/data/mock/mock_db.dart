import '../models/app_role.dart';

class MockDb {
  MockDb._();

  static const farePerPassenger = 15.0;
  static const routes = <String>[
    'San Isidro → Chosica',
    'Chosica → San Isidro',
  ];

  static const vehicleSeatOptions = <int>[4, 6, 8, 12];

  static const demoUsers = <MockUser>[
    MockUser(email: 'pasajero@sdag.pe', role: AppRole.passenger),
    MockUser(email: 'conductor@sdag.pe', role: AppRole.driver),
    MockUser(email: 'admin@sdag.pe', role: AppRole.admin),
  ];
}

class MockUser {
  const MockUser({required this.email, required this.role});

  final String email;
  final AppRole role;
}

