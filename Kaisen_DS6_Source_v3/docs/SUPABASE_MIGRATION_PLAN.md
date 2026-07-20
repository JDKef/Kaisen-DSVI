# Plan de migración de Kaisen a Supabase

Estado: propuesta para revisión. No se implementa código, no se actualizan
dependencias y no se tocan las pantallas en esta fase.

## Objetivo

Conservar las ocho pantallas actuales y su comportamiento visible en línea,
pero mover la autoridad de autenticación, productos, stock e historial a
Supabase. SQLite queda temporalmente como caché o apoyo de migración. PHP/MySQL
no se elimina todavía y no recibe escrituras duales automáticas.

## No objetivos

- No añadir ni quitar pantallas.
- No rediseñar la UI.
- No hacer una sincronización bidireccional offline.
- No mantener dos autoridades de stock.
- No cambiar dependencias Flutter antes de aprobar interfaces y fases.
- No borrar SQLite ni legacy_api durante esta fase.

## Estado objetivo

| Flujo visible | Autoridad después de la migración |
|---|---|
| Registro/login | Supabase Auth + profiles |
| Catálogo, búsqueda y código de barras | products mediante ProductRepository |
| Crear/editar producto | RPC de producto con versionado |
| Eliminar producto | archive_product; sigue siendo baja lógica |
| Registrar venta | create_sale RPC idempotente y transaccional |
| Descontar stock | products dentro de create_sale |
| Historial/ganancias | sale_history |
| Icono actual de sincronización | refresh remoto/cache, no subida y bajada de cambios |
| SQLite | Caché de lectura y apoyo de importación; no fuente de verdad |
| PHP | Solo compatibilidad, exportación y rollback durante la ventana acordada |

Las pantallas permanecen: LoginScreen, RegisterScreen, DashboardScreen,
CatalogoScreen, ProductoDetalleScreen, RegistroVentaScreen, ScannerScreen y
HistorialVentasScreen.

## Interfaces de repositorio propuestas

Estas interfaces son contrato de diseño, no código para añadir ahora.

~~~text
AuthRepository
  register(username, password) -> AuthUser
  signIn(username, password) -> AuthUser
  signOut()
  currentUser() -> AuthUser?

ProductRepository
  listActive(search, category) -> List<Product>
  findByBarcode(barcode) -> Product?
  create(command) -> Product
  update(id, expectedVersion, command) -> Product
  archive(id, expectedVersion) -> Product

SaleRepository
  createSale(operationId, items, occurredAt) -> SaleReceipt
  listHistory(category, order) -> List<SaleLine>

CacheStore
  readProducts() -> List<Product>
  writeProducts(snapshot)
  readSaleHistory() -> List<SaleLine>
  writeSaleHistory(snapshot)
  retainUncertainOperation(operationId, payloadHash)
  clearOperation(operationId)

RemoteRefreshRepository
  refreshProducts()
  refreshSales()
~~~

Los providers conservarán su responsabilidad de estado y loading, pero dejarán
de conocer sqflite o HTTP. La pantalla seguirá leyendo los mismos modelos o
adaptadores equivalentes.

## Compatibilidad de modelos e IDs

Durante la transición:

- Producto.id continúa siendo la clave de la fila SQLite de caché.
- Producto.idRemoto pasa a ser products.id bigint y es el único ID que viaja a
  Supabase.
- Venta.idRemoto se mapea a sale_items.id para conservar una fila numérica por
  línea del historial. SaleReceipt también conserva sales.id.
- No se usa el id local como fallback si falta un ID remoto.
- client_operation_id es UUID, no sustituye el ID numérico de la venta.
- Dart int es suficiente para los bigint actuales en Android, pero la
  serialización debe validar que el JSON no convierta IDs a double.

El repository debe construir objetos completos al editar, incluyendo
idRemoto/version. La pérdida del vínculo detectada en
mobile/lib/screens/producto_detalle_screen.dart:60-69 no se debe trasladar al
adaptador nuevo.

## Estrategia de SQLite

SQLite se conserva inicialmente por tres motivos:

1. Mostrar el último snapshot si una lectura remota falla.
2. Permitir una migración progresiva de datos locales.
3. Retener una operación de venta con respuesta incierta hasta repetir la misma
   clave idempotente o marcarla resuelta.

Límites obligatorios:

- No crear ventas nuevas offline.
- No aplicar cambios de productos localmente esperando una subida posterior.
- No mantener listas de productos o ventas pendientes para sincronización
  bidireccional.
- No calcular stock autorizado desde SQLite.
- La caché se invalida o reemplaza después de una lectura remota exitosa.

Una vez terminada la ventana de estabilización, se decidirá si la caché SQLite
se mantiene como read-through cache. Su eliminación es una fase posterior y no
forma parte de este plan aprobado.

## Fases de migración

### Fase 0: congelar y medir el baseline

Entrada:

- baseline de Android aceptado.
- inventario y ventas locales identificados por dispositivo.
- responsables de reconciliación definidos.

Acciones:

- Exportar cada SQLite kaisen.db sin modificarlo.
- Exportar productos y ventas de MySQL.
- Registrar APK, commit y configuración de la API.
- Congelar cambios de negocio mientras se reconcilian datos.
- Corregir la documentación del nombre del baseline en una tarea separada si se
  aprueba; no renombrarlo automáticamente en esta fase.

Salida:

- Inventario de fuentes, conteos, rangos de fechas y checksum de exportaciones.
- Lista de conflictos por barcode, id remoto, nombre normalizado y stock.

Rollback: restaurar el uso actual; no hay escrituras nuevas en Supabase.

### Fase 1: fundación Supabase sin conectar la aplicación

Acciones:

- Crear Auth, profiles, businesses y business_members.
- Crear products, sales, sale_items e inventory_movements.
- Crear índices, constraints, triggers de versionado y vista sale_history.
- Crear RLS y grants.
- Crear funciones de producto y create_sale.
- Ejecutar pruebas SQL en un proyecto local o de staging.

Salida:

- Un proyecto de staging aislado.
- Pruebas verdes de RLS, conflictos, rollback transaccional e idempotencia.
- Ninguna pantalla ni provider de producción apunta todavía a Supabase.

Rollback: borrar/recrear staging o revertir migraciones antes de importar datos.

### Fase 2: importación y reconciliación

Fuentes:

- PHP/MySQL se considera una fuente histórica disponible, no autoridad
  automática, porque el baseline no verificó la sincronización.
- Cada SQLite puede contener productos y ventas no presentes en PHP.

Proceso:

1. Importar a tablas privadas de staging con source_system, source_device y
   source_id.
2. Normalizar códigos de barras, nombres, categorías, fechas y decimales.
3. Unificar productos por id_remoto válido, luego por barcode, luego por una
   decisión manual de negocio.
4. Preservar el ID numérico PHP cuando no colisione; para colisiones, asignar
   un ID nuevo y guardar el mapa origen-destino privado.
5. Elegir un stock inicial por producto. No sumar stocks de dispositivos:
   representan snapshots potencialmente divergentes.
6. Importar ventas históricas como ventas completadas sin volver a descontar
   stock. El stock inicial ya es un snapshot reconciliado.
7. Generar client_operation_id determinista para cada venta importada usando
   origen, dispositivo, ID local y hash de contenido.
8. Deduplificar ventas con el mismo origen/ID o la misma huella aprobada.
9. Conservar productos inactivos necesarios para las referencias históricas.

Salida:

- Conteos de productos activos/inactivos y ventas.
- Registro de cada conflicto resuelto.
- Diferencia cero entre el inventario aprobado y products.stock.

Rollback: restaurar el staging y repetir la importación; no ejecutar down
migrations destructivas después de la carga productiva.

### Fase 3: abstracción de acceso en Flutter

Esta es la primera fase que requerirá código, pero solo después de aprobar este
plan.

Acciones futuras:

- Introducir los repositorios detrás de los providers actuales.
- Mantener los nombres y entradas visibles de las pantallas.
- Implementar AuthRepository sobre Supabase Auth con el alias interno de
  username.
- Implementar ProductRepository con RPC y lecturas RLS.
- Implementar SaleRepository con create_sale.
- Hacer que el ícono actual de sincronización invoque refresh remoto, sin
  subir cambios locales.
- Escribir cache snapshots solo después de respuestas remotas válidas.
- Mantener una bandera de despliegue para volver al adaptador anterior durante
  pruebas.

Salida:

- La UI online produce el mismo resultado funcional contra staging.
- La aplicación no llama ApiService para operaciones nuevas.
- No hay INSERT local pendiente que deba sincronizarse.

### Fase 4: piloto y cutover

Acciones:

- Publicar una build piloto con Supabase como única autoridad.
- Requerir conexión para crear/editar/archivar productos y confirmar ventas.
- Permitir cache de lectura con una marca interna de antigüedad para soporte,
  sin convertirla en autoridad.
- Monitorizar errores de RPC, conflictos de versión, stock insuficiente,
  tiempos de respuesta, reintentos e idempotencia.
- Mantener PHP congelado y sus exportaciones disponibles.

No se hace dual write a PHP y Supabase: una falla de red entre dos writes
produciría dos autoridades y duplicados difíciles de reconciliar.

Salida:

- Criterios de aceptación de TEST_PLAN.md verdes.
- Sin diferencias no explicadas entre consultas de lectura y cache.
- Sin ventas duplicadas ni stock negativo en las pruebas de concurrencia.

### Fase 5: estabilización y retiro posterior

Después de la ventana de rollback:

- Dejar legacy_api en modo archivado o solo lectura.
- Retirar el botón de infraestructura PHP solo en una tarea futura que revise
  explícitamente la UI; esta fase no lo hace.
- Decidir si SQLite continúa como cache.
- Eliminar tablas/campos locales de sincronización solo cuando no queden builds
  antiguas activas ni operaciones inciertas.

## Cambio de comportamiento deliberadamente aceptado

La experiencia online visible se conserva. Lo que cambia es la autoridad:

- Antes una venta podía confirmarse sin red y quedar pendiente.
- Después una venta requiere red; si la solicitud queda incierta se reintenta
  con la misma client_operation_id.

Este cambio es necesario para no implementar sincronización bidireccional y para
evitar que dos dispositivos vendan el mismo stock desde sus SQLite aislados.
Debe mostrarse como error operativo existente en los mensajes de la pantalla,
sin crear una pantalla nueva.

## Autenticación y cuentas existentes

La tabla usuarios local guarda SHA-256 y no puede transferirse como credencial
de Supabase Auth. El plan de transición es:

1. El usuario escribe su contraseña en el primer login online.
2. El adaptador verifica temporalmente el hash local, si existe.
3. La misma contraseña se usa para crear la identidad Supabase con el alias
   interno; nunca se envía el hash como contraseña.
4. Se marca la cuenta local como migrada en la caché.
5. Si no existe la base local o no se conoce la contraseña, se requiere
   registro/restablecimiento manual.

Los usernames duplicados encontrados entre dispositivos deben resolverse antes
del cutover; no se deben fusionar cuentas automáticamente.

## Rollback

### Antes de que Supabase reciba datos productivos

- Apagar la bandera de staging.
- Continuar con SQLite/PHP.
- Eliminar o recrear el esquema de staging.

### Después del cutover

- Detener confirmaciones nuevas durante una ventana breve.
- Exportar products, stock, sales y sale_items de Supabase.
- Reconciliar los cambios posteriores al corte contra el snapshot PHP/SQLite.
- Solo entonces volver a una build anterior y a PHP.

No se debe cambiar de Supabase a PHP sin exportar primero: perdería ventas o
reintroduciría stock antiguo. Las ventas ya confirmadas en Supabase se deben
marcar en el mapa de reconciliación para no reimportarlas dos veces.

### Fallos dentro de una operación

- Un error de create_sale hace rollback de venta, líneas, movimientos y stock.
- Un retry con la misma clave devuelve el resultado original.
- Un payload distinto con la misma clave se bloquea.
- Un update de producto con version vieja devuelve conflicto y requiere
  recarga; nunca se aplica overwrite silencioso.

### Rollback de migraciones SQL

Antes de importar puede recrearse staging. Después de importar se prefieren
migraciones forward-fix y restauración desde backup; no se ejecutan down
migrations destructivas en producción.

## Criterios para aprobar la implementación futura

- Los cuatro documentos de este plan revisados.
- Esquema y RLS probados en staging.
- Importación reconciliada y firmada.
- Repositorios cubiertos por TEST_PLAN.md.
- Prueba de dos dispositivos con stock límite.
- Prueba de timeout/retry con una sola venta remota.
- Plan de rollback ensayado antes de distribuir la build piloto.
