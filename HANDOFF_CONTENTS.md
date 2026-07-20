# Contenido de la entrega de Kaisen DS6

## Archivos empaquetados

Una vez que `scripts/package_handoff.ps1` se ejecuta correctamente, `dist/` contiene:

- `Kaisen_DS6_v3.apk`: un APK universal de Android compilado con valores de tiempo de ejecución `--dart-define`. El modo de compilación predeterminado es *release* (producción).
- `Kaisen_DS6_Source_v3.zip`: una instantánea limpia del código fuente, creada a partir del contenido confirmado en Git pero sin el historial de Git.
- `SETUP_GROUP.md`: configuración de la estación de trabajo, Android, Flutter y el cliente de Supabase.
- `GROUP_RUN_ARGS.example.txt`: solo argumentos de tiempo de ejecución de ejemplo (marcadores de posición).
- `DEMO_CHECKLIST.md`: flujo acordado para la demostración del grupo.
- `HANDOFF_CONTENTS.md`: este inventario.
- `FLUTTER_VERSION.txt`: versión exacta del SDK de Flutter utilizada para la validación.

## Estructura del archivo de código fuente

- `mobile/`: la aplicación Flutter, el proyecto Android, el archivo de bloqueo (*lockfile*) y las pruebas.
- `supabase/`: migraciones de esquema existentes, notas de configuración y material para pruebas de humo (*smoke tests*).
- `legacy_api/`: material histórico y de reversión conservado de la era PHP/SQLite.
- `docs/`: documentos sobre arquitectura, línea base (*baseline*), pruebas, migración e interfaz de usuario (UI) aprobada.
- `scripts/`: scripts reutilizables para validación y empaquetado.

Los archivos `README.md` y `SETUP_GROUP.md` de la raíz son los puntos de entrada actuales de la entrega.
El archivo `mobile/README.md` (más antiguo) describe el flujo de trabajo local/PHP heredado y no debe prevalecer sobre las instrucciones de Supabase contenidas en los documentos raíz de la entrega.

## Elementos excluidos intencionadamente del paquete

- Historial de Git y metadatos del repositorio local.
- `build/`, `.dart_tool/`, cachés de Gradle, cachés del IDE y capturas del dispositivo.
- `dist/` de cualquier ejecución anterior.
- Argumentos reales de ejecución de Supabase, archivos de entorno, claves de firma, contraseñas de base de datos y tokens de acceso.
- Salida de `FLUTTER_DOCTOR_JOSE.txt` específica de la máquina.
- El APK de línea base (*baseline*) bajo control de versiones, que permanece en el repositorio como material de reversión pero no forma parte del archivo de código fuente limpio.
- El archivo de bloqueo temporal de Office bajo control de versiones en `mobile/docs/`. - Maquetas industriales experimentales, capturas de pantalla e informes de diseños descartados.

## Antes de compartir

El script de empaquetado requiere un repositorio limpio y con los cambios confirmados (*committed*), ya que `git archive` solo puede empaquetar contenido que haya sido confirmado. Un mantenedor debe revisar y confirmar primero los cambios de la entrega. La tarea de preparación en sí no realiza confirmaciones ni envíos (*push*).