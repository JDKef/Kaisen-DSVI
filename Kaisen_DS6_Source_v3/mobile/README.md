# Kaisen — Gestión de inventario y ventas

App móvil en Flutter para gestionar el inventario y las ventas de un negocio pequeño, con
escaneo de código de barras y sincronización opcional contra un servidor propio (API en PHP +
MySQL). Este documento explica cómo levantar el proyecto en tu propia computadora para
ejecutarlo y probarlo.

## 1. Requisitos previos

Instala esto antes de empezar:

- **Flutter SDK** (canal estable) — https://docs.flutter.dev/get-started/install
- **Android Studio**, con el plugin de Flutter instalado
- **XAMPP** (Apache + MySQL) — https://www.apachefriends.org/ — solo si vas a probar la
  sincronización con el servidor (ver sección 4). Si solo quieres correr la app y probar el
  inventario/ventas localmente, puedes saltarte esta parte.
- Un teléfono Android con **depuración USB activada**, o un emulador de Android Studio

Verifica que todo esté bien instalado con:
```
flutter doctor
```

## 2. Obtener el proyecto

Copia la carpeta completa del proyecto (`kaisen/`) a tu computadora, por ejemplo dentro de
`AndroidStudioProjects/`. Si el equipo lo está compartiendo por Git, clónalo normalmente.

La carpeta de la API (`kaisen_api/`) se comparte por separado — ver sección 4.

## 3. Instalar dependencias y ejecutar la app

Desde la carpeta del proyecto:
```
flutter pub get
```

Con tu teléfono conectado por USB (o un emulador abierto), verifica que Flutter lo detecte:
```
flutter devices
```

Y ejecútalo:
```
flutter run
```

En este punto la app ya funciona completamente en modo local (con SQLite): puedes crear una
cuenta, agregar productos, escanear códigos y registrar ventas sin necesitar ningún servidor.
El botón de sincronizar seguirá dando error hasta completar la sección 4 — eso es normal.

## 4. Levantar tu propia API (para probar la sincronización)

Cada persona del equipo debe correr **su propia copia** de la API en su computadora — no
depende de la PC de nadie más ni de estar en la misma red. Es la forma más confiable: ya
comprobamos que las redes públicas (como la de una biblioteca) bloquean la comunicación directa
entre el teléfono y la PC de otra persona.

**4.1. Copia la carpeta de la API**

Pide la carpeta `kaisen_api/` (contiene `db.php`, `productos.php`, `ventas.php`, `schema.sql`) y
cópiala dentro de `xampp/htdocs/kaisen_api/` en tu computadora.

**4.2. Crea la base de datos**

Abre XAMPP, inicia **Apache** y **MySQL**. Luego, desde una terminal:
```
"C:\xampp\mysql\bin\mysql.exe" -u root < "C:\xampp\htdocs\kaisen_api\schema.sql"
```
(Si tu MySQL corre en un puerto distinto al 3306 —revísalo en `xampp-control.exe`—, edita el
puerto en `kaisen_api/db.php`, variable `$port`.)

**4.3. Conecta el teléfono a tu API por USB (recomendado)**

Esta es la forma que mejor nos funcionó hoy, porque evita depender de la red WiFi:

1. Conecta el teléfono por USB con depuración activada
2. Ejecuta:
   ```
   adb reverse tcp:80 tcp:80
   ```
3. Confirma con `adb reverse --list` que aparezca `UsbFfs tcp:80 tcp:80`

Este comando hay que repetirlo **cada vez que reconectas el cable** (se olvida al desconectar).
Si te resulta tedioso, corre `scripts/mantener_conexion_kaisen.bat` (doble clic) — reactiva el
puente solo cada pocos segundos mientras dejas esa ventana abierta.

**4.4. Verifica la configuración de la app**

En `lib/services/api_service.dart`, la constante `baseUrl` ya está puesta en
`http://localhost/kaisen_api` — **no la cambies** si vas a usar el método de USB de arriba
(cada quien prueba contra su propio `localhost`, gracias al `adb reverse`). Solo tendrías que
cambiarla por una IP de red si en vez de USB prefieres probar por WiFi (ver nota abajo).

**4.5. Prueba la sincronización**

Abre la app, entra al Dashboard y toca el ícono de sincronizar. Si todo está bien, no debería
dar error.

> **Nota sobre WiFi:** en teoría se puede sincronizar por la misma red WiFi en vez de USB,
> cambiando `baseUrl` por la IP local de tu PC (`ipconfig` → "Dirección IPv4"). En la práctica,
> hoy comprobamos que muchas redes públicas/institucionales bloquean la comunicación
> directa entre dispositivos por seguridad ("aislamiento de clientes"), lo cual rompe esto sin
> ningún aviso claro. Si tu WiFi es una red doméstica normal (no institucional), sí debería
> funcionar. Si no, usa el método de USB.

## 5. Primer uso

1. Abre la app → **Regístrate** con cualquier usuario/contraseña (es una cuenta compartida del
   negocio, no hace falta coordinarse con el equipo)
2. Desde el Dashboard, crea un producto de prueba (con o sin código de barras)
3. Ve a **Registrar venta** → escanea o usa el producto creado → confirma la venta
4. Revisa que el stock se haya descontado y que aparezca en el Historial de ventas

## 6. Problemas comunes

| Problema | Solución |
|---|---|
| `flutter devices` no muestra el teléfono | Revisa que la depuración USB esté activada y que hayas aceptado el diálogo "¿Permitir depuración USB?" en el teléfono. |
| El teléfono aparece como `unauthorized` | Vuelve a revisar el teléfono — el diálogo de autorización pudo aparecer de nuevo tras reconectar el cable. |
| Sincronizar da "Connection refused" | El puente `adb reverse` se perdió (pasa cada vez que desconectas el cable). Repite el comando de la sección 4.3. |
| Sincronizar da otro error de red | Verifica que Apache y MySQL sigan corriendo en el panel de XAMPP. |
| La cámara no escanea | Revisa que el permiso de cámara esté concedido en Ajustes del teléfono → Apps → Kaisen → Permisos. |
| `flutter pub get` falla | Corre `flutter doctor` y resuelve lo que marque en rojo antes de continuar. |

## 7. Estructura del proyecto

Ver el documento **"Mapa completo del proyecto Kaisen"** (auditoría técnica, Fase 4) para el
detalle de carpetas, arquitectura y flujos de cada módulo.
