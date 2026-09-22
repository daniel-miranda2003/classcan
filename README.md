# ClasScan

Aplicación Flutter 100% offline para el control de asistencia escolar:
cursos, estudiantes (matriculados por curso), pase de lista, tareas,
exámenes y notas. Funciona en Android, iOS y Web con base de datos
local SQLite (IndexedDB en Web).

## Requisitos

- Flutter SDK ^3.12 (con Dart incluido)
- Android Studio (para Android) o Xcode (para iOS)
- Google Chrome (para Web)
- Git

Verifica tu instalación con:

```powershell
flutter doctor
```

## Instalación y ejecución

```powershell
git clone https://github.com/daniel-miranda2003/classcan.git
cd classcan
flutter pub get
```

Conecta un dispositivo, abre un emulador o usa Chrome, y corre:

```powershell
flutter run
```

Para elegir destino explícito:

```powershell
flutter devices
flutter run -d windows
flutter run -d chrome
```

## Usuario inicial

Al crear la base de datos se registra automáticamente:

- Usuario: `classcan`
- Contraseña: `classcan`
- Rol: `Profesor`

## Compilar release

```powershell
flutter build apk --release --split-per-abi
flutter build appbundle
```

El APK queda en `build/app/outputs/flutter-apk/`.

## Estructura

```
lib/
  core/         # base de datos, inyección, tema, seguridad
  features/     # auth, courses, students, attendance, assessments, grades
  shared/       # shell de navegación y widgets compartidos
```

## Notas

- Los binarios web de SQLite (`web/sqflite_sw.js`, `web/sqlite3.wasm`)
  ya están incluidos; si los borras, regenéralos con
  `flutter pub run sqflite_common_ffi_web:setup`.
- No se requieren permisos del sistema: todo se guarda localmente.
