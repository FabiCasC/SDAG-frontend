# Guía de instalación — SDAG Frontend (Flutter)

Proyecto **Flutter** (`sdag`) para pasajeros, conductores y administración. Usa **Supabase** (auth y datos), **Google Maps / Places** (mapas y direcciones) y **Culqi** (pagos con tarjeta).

---

## 1. Qué instalar en tu PC

| Aplicación | Para qué sirve |
|------------|----------------|
| **Git** | Clonar el repositorio |
| **Flutter SDK** | Versión compatible con el `environment` del `pubspec.yaml` (SDK **^3.11.5**). Comprueba con `flutter doctor` |
| **Android Studio** | SDK Android, emulador y herramientas de compilación |
| **VS Code** o **Android Studio** (plugin Flutter) | Editar código y depurar |
| **Xcode** (solo macOS) | Compilar y probar en **iOS** / simulador iPhone |

### Comprobar Flutter

```bash
flutter doctor -v
```

Debes tener al menos la toolchain de **Android** resuelta. Para iOS, además la de **Xcode** en Mac.

---

## 2. Obtener el código y dependencias

```bash
git clone <URL-del-repositorio> SDAG-frontend
cd SDAG-frontend
flutter pub get
```

---

## 3. Archivo de configuración `env.json`

La app carga variables al arrancar desde **`env.json`** en la **raíz del proyecto** (está declarado en `pubspec.yaml` como asset).

### 3.1 Crear el archivo

1. Copia el ejemplo:

   ```bash
   copy env.example env.json
   ```

   En macOS/Linux: `cp env.example env.json`

2. Abre `env.json` y rellena los valores (sin comillas en el formato `KEY=valor`).

### 3.2 Variables y credenciales

| Variable | Obligatoria | Descripción |
|----------|-------------|-------------|
| `SUPABASE_URL` | Sí (recomendado) | URL del proyecto Supabase (`https://xxxxx.supabase.co`) |
| `SUPABASE_ANON_KEY` | Sí (recomendado) | Clave **anon** pública del proyecto (Settings → API en el panel de Supabase) |
| `GOOGLE_MAPS_API_KEY` | Opcional en Android* | Clave de API de Google Cloud con **Maps SDK for Android**, **Maps SDK for iOS** (si compilas iOS), **Places API**, **Geocoding API** y restricciones acordes a tu app |
| `CULQI_PUBLIC_KEY` | Opcional** | Clave pública **pk_test_…** o **pk_live_…** de Culqi para tokenizar tarjetas en el flujo de pago |

\* Si no la pones, en el código hay un valor por defecto de desarrollo para REST/Places; en **Android** el mapa nativo usa la clave del `AndroidManifest.xml`. Para producción conviene una sola clave bien restringida y coherente en todos los sitios.

\*\* Si no la pones, el proyecto usa un fallback de prueba en código; para pagos reales debes usar la clave de tu comercio en Culqi.

**Dónde sacar cada credencial (sin pegar secretos en chats públicos):**

- **Supabase**: [Dashboard](https://supabase.com/dashboard) → tu proyecto → **Settings → API** → `Project URL` y `anon` `public`.
- **Google Maps**: [Google Cloud Console](https://console.cloud.google.com/) → **APIs y servicios → Biblioteca** → habilita **Places API**, **Geocoding API** y los SDK de mapas → **Credenciales** → API key con restricciones de app.
- **Culqi**: panel de Culqi → integraciones → clave pública.

> **Importante:** `SUPABASE_ANON_KEY` es una clave de **cliente** (pública en la app). Aun así, no subas `env.json` con datos de producción a repositorios públicos si no quieres exponer el proyecto. La **service_role** de Supabase no debe ir nunca en el frontend.

---

## 4. Android — Google Maps

En `android/app/src/main/AndroidManifest.xml` hay un `meta-data` `com.google.android.geo.API_KEY`. Para desarrollo puede estar ya rellenado; para **release** deberías usar tu propia clave y restricciones (Android package + SHA-1).

Tras cambiar la clave:

```bash
flutter clean
flutter pub get
flutter run
```

---

## 5. iOS — Google Maps

En `ios/Runner/AppDelegate.swift` aparece un placeholder:

```swift
GMSServices.provideAPIKey("__GOOGLE_MAPS_API_KEY__")
```

Sustituye `__GOOGLE_MAPS_API_KEY__` por tu **API key** de Google (la misma o una iOS-restricted) antes de compilar para dispositivo o App Store.

Luego, desde la carpeta del proyecto:

```bash
cd ios
pod install
cd ..
flutter run
```

---

## 6. Deep link / recuperación de contraseña (Supabase)

En Android el `AndroidManifest` declara el esquema **`io.supabase.sdag`** para el host `reset-password`. Debe coincidir con la URL de redirección que configures en **Supabase Auth** (URLs de redirección permitidas).

---

## 7. Ejecutar la app

### Emulador o dispositivo Android

```bash
flutter devices
flutter run
```

### Solo compilar APK (release, ejemplo)

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/`.

---

## 8. Problemas frecuentes

| Síntoma | Qué revisar |
|---------|-------------|
| Pantalla en blanco o sin login | `env.json` existe, `SUPABASE_URL` y `SUPABASE_ANON_KEY` correctos y sin espacios raros |
| Mapas grises en Android | Clave en `AndroidManifest.xml` y facturación en Google Cloud |
| Mapas grises en iOS | `AppDelegate.swift` con API key real y `pod install` |
| Autocompletado de direcciones vacío | Places API habilitada y cuota; `GOOGLE_MAPS_API_KEY` en `env.json` |
| Error al pagar con tarjeta | `CULQI_PUBLIC_KEY` válida y entorno test/live coherente |

---

## 9. Resumen rápido (checklist)

1. Instalar **Flutter**, **Android Studio** (y **Xcode** en Mac si toca iOS).  
2. `git clone` → `cd` al proyecto → `flutter pub get`.  
3. Copiar `env.example` → `env.json` y rellenar **Supabase** (mínimo).  
4. Ajustar **Google Maps** en Android manifest y, si aplica, en `AppDelegate.swift` (iOS).  
5. `flutter run`.

Para más detalle del código (rutas, roles, etc.), revisa `lib/app/router/` y la documentación interna que vaya añadiendo el equipo.
