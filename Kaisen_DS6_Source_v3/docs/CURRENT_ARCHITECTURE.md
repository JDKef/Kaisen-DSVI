# Arquitectura actual de Kaisen

Estado: análisis estático del repositorio al 15 de julio de 2026. Este documento no
implementa cambios.

## Alcance y evidencia

La revisión cubrió:

- Todo el código Dart de mobile/lib, los tests presentes y la configuración de
  mobile/pubspec.yaml.
- La configuración Android relevante para cámara, red y actividad Flutter.
- legacy_api/db.php, legacy_api/productos.php, legacy_api/ventas.php y
  legacy_api/schema.sql.
- El baseline entregado y el directorio supabase/migrations.

Hay dos diferencias de nombre que deben quedar registradas:

1. El baseline presente es docs/BASELINE.md.txt, no docs/BASELINE.md.
2. docs/BASELINE.md.txt aparece como archivo no rastreado en el estado de Git.

El baseline reporta que el APK compila y que el flujo local fue verificado en un
teléfono Android. También reporta como no probado el uso de PHP/XAMPP, dos
dispositivos, pérdida de conexión y pruebas automatizadas de negocio. Supabase no
tiene migraciones en este checkout y Flutter no tiene una dependencia ni un
servicio Supabase configurado.

## Resumen ejecutivo

La aplicación es un monolito Flutter pequeño con cuatro providers
ChangeNotifier. SQLite es la autoridad de las operaciones normales; el backend
PHP/MySQL es un destino opcional de sincronización manual. La sincronización
intenta subir cambios locales y después descargar registros remotos, pero no
tiene versiones, conflictos, eliminaciones pendientes ni una clave de
idempotencia para ventas.

La navegación funciona con MaterialPageRoute. Los campos routeName de las
pantallas son constantes informativas: no existe un mapa routes en MaterialApp.
El arranque selecciona LoginScreen o DashboardScreen según un objeto de usuario
en memoria, mediante AuthGate.

## Mapa de capas

| Capa | Archivos principales | Responsabilidad actual | Autoridad real |
|---|---|---|---|
| Arranque y composición | mobile/lib/main.dart:1-48 | Crea MaterialApp y los cuatro providers | Ninguna |
| Pantallas/widgets | mobile/lib/screens, mobile/lib/widgets | Formularios, navegación, escáner, carrito y presentación | Providers |
| Estado | auth_provider.dart, inventario_provider.dart, venta_provider.dart, sync_provider.dart | Coordina lecturas, escrituras, mensajes y loading | SQLite, salvo SyncProvider |
| Modelos | mobile/lib/models/*.dart | Producto, Usuario, Venta e ItemCarrito; serialización local/HTTP | Estructuras Dart |
| Persistencia local | mobile/lib/services/database_service.dart | SQLite kaisen.db, consultas y transacción local de venta | SQLite |
| HTTP opcional | mobile/lib/services/api_service.dart | Cliente REST contra localhost/kaisen_api | PHP/MySQL |
| Backend legado | legacy_api/*.php y schema.sql | CRUD de productos y altas/listado de ventas | MySQL cuando se usa |
| Futuro | supabase/migrations | Directorio vacío; no hay implementación | No existe aún |

Dependencias directas de la aplicación:

- provider para ChangeNotifier.
- sqflite y path para persistencia local.
- http para PHP.
- mobile_scanner para cámara y códigos.
- crypto para SHA-256 de contraseñas locales.
- flutter_test solo tiene un test de widget.

La configuración Android declara cámara y usa cleartext HTTP; el permiso INTERNET
está en el manifest de debug. El manifest apunta a
com.example.kaisen.MainActivity. También existe una MainActivity Kotlin en
com.kaisen.kaisen que no es la actividad referenciada por ese manifest. Es una
observación de configuración, no una condición para diseñar la migración de datos.

## Pantallas y rutas efectivas

| Pantalla | routeName declarado | Entrada efectiva | Dependencias |
|---|---|---|---|
| LoginScreen | /login | home de AuthGate cuando no hay usuario | AuthProvider |
| RegisterScreen | /register | push desde LoginScreen | AuthProvider |
| DashboardScreen | /dashboard | home de AuthGate cuando hay usuario | AuthProvider, InventarioProvider, VentaProvider, SyncProvider |
| CatalogoScreen | /catalogo | push desde Dashboard o detalle de venta fallida | InventarioProvider |
| ProductoDetalleScreen | /producto-detalle | push desde Dashboard, catálogo o producto no encontrado | InventarioProvider |
| RegistroVentaScreen | /registro-venta | push desde Dashboard | VentaProvider, InventarioProvider |
| ScannerScreen | /scanner | push únicamente desde RegistroVentaScreen | mobile_scanner |
| HistorialVentasScreen | /historial-ventas | push desde Dashboard | VentaProvider |

No se propone añadir, eliminar, renombrar ni fusionar estas pantallas.

## Providers y servicios

### AuthProvider

AuthProvider consulta y escribe la tabla local usuarios. Calcula
sha256(password) dentro del dispositivo, compara el hash local y guarda
Usuario en memoria. No hay sesión persistida ni autenticación remota. Los catch
de registrar e iniciarSesion convierten cualquier excepción en un mensaje
genérico: mobile/lib/providers/auth_provider.dart:28-72.

### InventarioProvider

InventarioProvider usa exclusivamente DatabaseService para cargar, buscar,
filtrar, crear, editar y dar de baja productos. Sus errores de base de datos se
reemplazan por mensajes genéricos en
mobile/lib/providers/inventario_provider.dart:30-94.

### VentaProvider

El carrito vive en memoria. confirmarVenta delega toda la operación a
DatabaseService, limpia el carrito y vuelve a cargar el historial. La
transacción local y la reducción de stock están en
mobile/lib/services/database_service.dart:286-324. Para un error que no sea
StateError, el provider incluye el detalle técnico en el texto visible:
mobile/lib/providers/venta_provider.dart:124-141.

### SyncProvider

La acción manual del icono de Dashboard ejecuta cinco pasos secuenciales:

1. Busca productos activos sin id_remoto y los crea o intenta vincular por
   código de barras.
2. Envía un PUT para cada producto activo que ya tiene id_remoto.
3. Envía todas las ventas locales con sincronizada = 0 en un único POST.
4. Descarga productos remotos cuyo id no está en la caché local.
5. Descarga ventas remotas cuyo id no está en la caché local.

La implementación está en mobile/lib/providers/sync_provider.dart:47-167.
La operación no tiene cursor, versión, timestamp de cliente confiable, conflicto
explícito ni tombstone remoto.

## Modelos y correspondencia de IDs

| Modelo | Campos significativos | Persistencia actual |
|---|---|---|
| Usuario | id local, nombreUsuario, passwordHash | SQLite usuarios |
| Producto | id local, idRemoto, nombre, precio, stock, categoria, codigoBarras, activo | SQLite productos; idRemoto intenta representar MySQL productos.id |
| Venta | id local, idRemoto, productoId, snapshots de nombre/categoría/precio, cantidad, fecha, sincronizada | SQLite ventas; idRemoto intenta representar MySQL ventas.id |
| ItemCarrito | Producto y cantidad | Solo memoria durante la venta |

Producto.toApiJson solo incluye id si idRemoto no es null:
mobile/lib/models/producto.dart:71-81. Venta.toApiJson no incluye id local,
idRemoto ni una clave de operación: mobile/lib/models/venta.dart:55-64.

El formulario de edición crea un Producto nuevo con id local, pero omite
idRemoto en mobile/lib/screens/producto_detalle_screen.dart:60-69. Como
DatabaseService.updateProducto escribe todo el mapa del producto
mobile/lib/services/database_service.dart:105-113, ese campo puede quedar null.

## SQLite

DatabaseService abre kaisen.db en la versión 4:
mobile/lib/services/database_service.dart:20-24.

| Tabla | Columnas | Uso |
|---|---|---|
| usuarios | id, nombre_usuario UNIQUE, password_hash | Registro e inicio de sesión local |
| productos | id, id_remoto, nombre, precio, stock, categoria, codigo_barras, activo | Inventario y baja lógica |
| ventas | id, id_remoto, producto_id, snapshots, cantidad, precio_unitario, fecha, sincronizada | Historial local y cola implícita de subida |

Las migraciones locales son acumulativas: versión 2 añade id_remoto a productos
y sincronizada a ventas; versión 3 añade categoria a ventas; versión 4 añade
id_remoto a ventas. No se observa una columna de versión de negocio,
updated_at, clave de idempotencia o registro de operaciones. Aunque ventas
declara una foreign key, no se observa PRAGMA foreign_keys = ON.

Las consultas de sincronización filtran productos por activo = 1:
mobile/lib/services/database_service.dart:190-206. Las ventas pendientes se
definen únicamente por sincronizada = 0:
mobile/lib/services/database_service.dart:240-243.

La venta local sí es atómica respecto a ese dispositivo: primero valida stock,
actualiza productos e inserta las líneas dentro de una transacción SQLite. Esa
atomicidad no se extiende a otro teléfono ni al servidor PHP.

## API PHP/MySQL

### db.php

legacy_api/db.php configura CORS *, permite GET/POST/PUT/DELETE/OPTIONS, usa
127.0.0.1:3307, la base kaisen_db, usuario root y contraseña vacía. No existe
autenticación, autorización, tenant ni token. La función normalizarProducto
convierte tipos numéricos, pero no agrega versión ni control de concurrencia.

### productos.php

| Método | Entrada | Resultado |
|---|---|---|
| GET | Sin query | Lista productos activos ordenados por nombre |
| GET | codigo | Un producto activo por código de barras |
| POST | nombre, precio, stock, categoria y código opcional | INSERT y retorno del producto con id |
| PUT | id y todos los campos visibles | UPDATE incondicional por id |
| DELETE | id en query | Baja lógica activo = 0 |

PUT no recibe expected_version ni compara actualizado_en.
DELETE existe en PHP, pero ApiService no tiene un método de borrado y
SyncProvider nunca lo invoca.

### ventas.php

| Método | Entrada | Resultado |
|---|---|---|
| GET | Ninguna | Lista todas las filas de ventas por fecha descendente |
| POST | Arreglo de líneas del carrito | Inserta cada línea dentro de una transacción MySQL y retorna ids |

El POST de ventas no actualiza productos.stock. La transacción solo agrupa los
INSERT de ventas: legacy_api/ventas.php:31-60. schema.sql tampoco declara una
foreign key desde ventas.producto_id a productos.id ni una clave de
idempotencia: legacy_api/schema.sql:4-23.

## Flujos de negocio actuales

### Registro e inicio de sesión

1. AuthGate muestra LoginScreen.
2. RegisterScreen llama AuthProvider.registrar.
3. AuthProvider crea usuarios en SQLite y deja el usuario en memoria.
4. LoginScreen llama AuthProvider.iniciarSesion.
5. El cierre de la aplicación no restaura una sesión remota ni local
   automáticamente; el usuario queda fuera del flujo hasta volver a iniciar
   sesión.

### Producto

Dashboard o CatalogoScreen abre ProductoDetalleScreen. El provider escribe
SQLite. La pantalla muestra solo activo = 1. Eliminar significa baja lógica
local, no borrado físico.

### Venta

1. RegistroVentaScreen abre ScannerScreen.
2. El código se busca en SQLite, no en PHP.
3. El producto se agrega al carrito; las cantidades no superan el stock local.
4. DatabaseService valida todos los productos dentro de una transacción.
5. Descuenta el stock local e inserta una fila de ventas por ítem.
6. HistorialVentasScreen lee SQLite y calcula ganancias en memoria.

### Sincronización

Dashboard llama SyncProvider solo al pulsar el icono. El servidor PHP se usa
como destino opcional. Tras la sincronización se vuelven a cargar productos y
ventas desde SQLite; no existe una lectura remota como fuente principal de la
pantalla.

## Confirmación de defectos críticos

| Defecto | Evidencia | Confirmación e impacto |
|---|---|---|
| Editar puede perder idRemoto | ProductoDetalleScreen omite idRemoto al construir el objeto; updateProducto persiste el mapa completo | Confirmado. El vínculo local-remoto puede quedar null y el siguiente sync puede tratar el registro como nuevo o vincularlo de forma peligrosa |
| Eliminados no se sincronizan | eliminarProducto solo cambia activo; las consultas de sync solo consideran activo = 1; no hay ApiService.delete | Confirmado. El producto puede seguir activo en MySQL |
| Providers ocultan errores originales | AuthProvider e InventarioProvider capturan e y devuelven textos genéricos; ApiService solo conserva status code | Confirmado para esos flujos. VentaProvider expone un detalle técnico en una rama, pero no entrega un error tipado ni el body HTTP |
| No hay pruebas automatizadas de negocio | mobile/test/widget_test.dart solo verifica la pantalla de login; el baseline reporta negocio no automatizado | Confirmado |
| Sync puede sobrescribir datos remotos más nuevos | SyncProvider hace PUT de todos los productos activos vinculados; PHP actualiza sin versión ni comparación | Confirmado. Un local stale puede ganar sin resolución de conflicto |
| Ventas pueden duplicarse al reintentar | Venta.toApiJson no contiene clave estable; ventas.php siempre hace INSERT; la marca local ocurre después del POST | Confirmado. Un timeout después del commit deja la venta local pendiente y un retry vuelve a insertar |
| Stock no es transaccional entre dispositivos | SQLite solo bloquea su propia base; ventas.php no decrementa stock y no existe RPC/lock remoto | Confirmado, y el backend legado además no aplica la reducción remota |

## Conclusión para la migración

La migración debe reemplazar la autoridad, no envolver el SyncProvider actual:

- Supabase debe servir productos, historial y operaciones de venta.
- El stock solo debe cambiar dentro de una operación transaccional del servidor.
- El PUT ciego debe sustituirse por RPC de producto con versionado optimista.
- DELETE debe permanecer como archive/soft delete y ser visible para la
  reconciliación, aunque la pantalla siga mostrando solo activos.
- SQLite puede sobrevivir temporalmente como caché o apoyo de importación, pero
  no como cola offline ni como segunda autoridad.
- PHP debe quedar congelado para rollback y exportación durante la ventana de
  transición; no debe recibir dual writes automáticos.
