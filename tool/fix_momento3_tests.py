#!/usr/bin/env python3
"""Corrige imports y headers en tests Momento 3."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOMENTO3 = ROOT / "test" / "momento3"

HEADER = """import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/core/validators/sdag_validators.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/conductor/utils/qr_security_utils.dart';
import 'package:sdag/features/conductor/utils/trip_message_utils.dart';
import 'package:sdag/features/conductor/utils/manifest_utils.dart';
import 'package:sdag/features/conductor/utils/vehicle_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';
import 'package:sdag/features/reserva/utils/forced_departure_utils.dart';
import 'package:sdag/features/reserva/utils/seat_hold_utils.dart';
import 'package:sdag/shared/maps/waze_service.dart';
import 'package:sdag/core/services/push_notification_utils.dart';
import 'package:sdag/core/services/audit_log_utils.dart';
"""


def main() -> None:
    for f in MOMENTO3.glob("*.dart"):
        text = f.read_text(encoding="utf-8")
        m = __import__("re").search(r"// (RF-\d+:.+)\n// (.+)\n\nvoid main", text)
        if not m:
            continue
        rest = text[text.find("void main") :]
        f.write_text(HEADER + f"\n// {m.group(1)}\n// {m.group(2)}\n\n" + rest, encoding="utf-8")
    print(f"Headers actualizados en {len(list(MOMENTO3.glob('*.dart')))} archivos")


if __name__ == "__main__":
    main()
