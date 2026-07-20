# Configuración del grupo Kaisen DS6

## Herramientas requeridas

- Flutter `3.44.6` en el canal estable.
- Dart `3.12.2` (incluido con el SDK de Flutter requerido).
- Android Studio con los plugins de Flutter y Dart.
- Android SDK, Android SDK Platform-Tools, Android SDK Command-line Tools y
  aceptación de las licencias de Android.
- Un teléfono Android con la depuración USB habilitada o un emulador de Android.

La versión exacta y verificada del SDK se registra en `FLUTTER_VERSION.txt`. No ejecutes
`flutter pub upgrade` a la ligera. El repositorio incluye `mobile/pubspec.lock`
para que los miembros del equipo utilicen el conjunto de dependencias probado.

## Verificar la estación de trabajo

Abre PowerShell y ejecuta:

```powershell
flutter doctor
flutter doctor --android-licenses
```

Resuelve los errores de la cadena de herramientas (toolchain) de Android antes de intentar generar un APK. La salida completa
de `flutter doctor` no debe subirse al repositorio (commit), ya que puede contener
rutas personales del equipo y detalles del dispositivo.

## Instalar y validar la aplicación

Desde la raíz del repositorio:

```powershell
Set-Location .\mobile
flutter pub get
flutter analyze
flutter test
flutter devices
```

El script de validación a nivel de repositorio ejecuta los tres primeros comandos de Flutter
y se detiene inmediatamente si alguno falla:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_handoff.ps1
```

Utiliza `-FlutterExecutable "C:\ruta\a\flutter\bin\flutter.bat"` cuando Flutter no esté
en el `PATH`.

## Configurar Supabase de forma segura

Kaisen lee ambos valores de cliente mediante `String.fromEnvironment`. Solicita al
responsable del equipo la URL segura para cliente y la clave pública (publishable key)
del proyecto compartido. No las codifiques directamente (hardcode) en Dart, Gradle, XML,
documentación ni en configuraciones de ejecución guardadas en el repositorio.

Ejecuta desde `mobile/` incluyendo las definiciones de tiempo de ejecución:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

`GROUP_RUN_ARGS.example.txt` contiene únicamente marcadores de posición. Un compañero de equipo puede copiarlo
en `GROUP_RUN_ARGS.txt` y reemplazar los marcadores de posición localmente; ese archivo real
es ignorado por Git y nunca debe compartirse.

Para configurar Android Studio:

1. Abre el directorio `mobile/` en Android Studio.
2. Abre **Run > Edit Configurations**.
3. Selecciona la configuración de ejecución de Flutter.
4. Pega ambos argumentos `--dart-define` (separados por un espacio) en **Additional run
   args**.
5. Mantén los valores reales de forma local. No incluyas en el repositorio (commit) configuraciones de ejecución de `.idea` que contengan credenciales.

Solo la clave pública (publishable key) de Supabase debe incluirse en una aplicación cliente. Los compañeros de equipo
nunca deben utilizar ni solicitar una clave `service_role`, una contraseña de PostgreSQL, un token de acceso al panel de control ni ninguna otra credencial del servidor.
## Reglas para el entorno compartido

- El proyecto de Supabase configurado ya existe. No vuelvas a ejecutar las migraciones
  ubicadas en `supabase/migrations/` sobre dicho proyecto.
- Todos los miembros del equipo se conectan a la misma empresa y base de datos de Kaisen.
- Cada miembro del equipo debe registrar un nuevo usuario de la aplicación en lugar de compartir
  credenciales.
- Las operaciones remotas de autenticación, inventario, ventas e historial requieren
  conexión a internet.
- Los productos y usuarios de prueba deben utilizar nombres identificables (por ejemplo,
  `TEST-JOSE-GUANTES`) para que el grupo pueda reconocer y eliminar de forma segura
  los registros de demostración.

## Ejecución en Android

Inicia un emulador o conecta un dispositivo autorizado y, a continuación, ejecuta lo siguiente desde `mobile/`:

```powershell
flutter devices
flutter run `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Concede el permiso de acceso a la cámara cuando se solicite para permitir el escaneo de códigos de barras.