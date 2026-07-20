# Plan de pruebas de Kaisen

Estado: estrategia de pruebas para la migración; no se añadieron tests en esta
fase.

## Situación actual

El único test Dart presente es mobile/test/widget_test.dart y verifica que la
pantalla inicial muestre Kaisen, Usuario e Iniciar sesión. El baseline
docs/BASELINE.md.txt reporta flutter analyze sin problemas, pero declara no
probadas las operaciones de sincronización, dos dispositivos, pérdida de red y
pruebas automatizadas de negocio.

Por tanto, el test actual prueba una entrada visual, no la integridad de
inventario, ventas, stock, errores, autenticación remota ni concurrencia.

## Principios

- Probar el contrato del dominio antes de probar widgets.
- Ejecutar pruebas SQL contra una base Supabase local/staging con el mismo
  esquema y RLS de producción.
- No usar service_role en las pruebas del cliente.
- Sembrar datos mínimos y borrar por namespace de prueba.
- Probar siempre el camino de éxito, el fallo y el retry.
- Los tests de migración deben conservar evidencia de conteos, hashes y
  conflictos resueltos.

## Pirámide de pruebas

### 1. Unitarias de modelos y adaptadores

Casos mínimos:

- Producto serializa precio, stock, categoría, barcode, activo, id local e
  idRemoto sin perder nulls.
- Producto editado conserva el idRemoto y la version que recibió del servidor.
- Venta convierte numeric/timestamps sin truncamiento y conserva snapshots.
- SaleHistoryRow se convierte en una Venta por línea usando sale_items.id.
- La normalización de username es determinista y distingue colisiones.
- El hash de idempotencia es igual para el mismo carrito ordenado y cambia si
  cambia cantidad o producto.
- Los importes se calculan con decimal/numeric, no con comparaciones de
  floating point en el servidor.

### 2. Contratos de repositorios

Cada implementación debe probarse contra el mismo contrato:

| Contrato | Casos |
|---|---|
| AuthRepository | registro, login válido, password inválida, usuario duplicado, cierre y sesión restaurada |
| ProductRepository | listar activos, buscar barcode, crear, editar con version correcta, conflicto con version vieja, archive |
| SaleRepository | carrito vacío, producto inexistente, cantidad inválida, stock suficiente, stock insuficiente, éxito y retry |
| CacheStore | snapshot válido, snapshot vacío, invalidación, operación incierta conservada y limpiada |
| RemoteRefreshRepository | actualización completa, timeout, respuesta parcial rechazada y cache no corrompida |

### 3. SQLite de transición

Mientras SQLite exista:

- Probar lectura/escritura de la versión 4 actual.
- Probar importación de usuarios sin exportar password_hash a Supabase.
- Probar que la caché no se considere fuente de stock después de una respuesta
  remota.
- Probar que una operación incierta conserve la misma clave y payload hash.
- Probar que no se cree una cola de cambios offline.
- Probar que los datos incompatibles o corruptos no borren el snapshot válido.

No se prueba como comportamiento objetivo la subida automática de productos o
ventas desde una tabla sincronizada = 0; esa ruta debe quedar fuera del
repository nuevo.

## Pruebas PostgreSQL/RLS

Estas pruebas deben correr antes del piloto, idealmente con pgTAP o un runner SQL
equivalente y una base Supabase local.

### Esquema y constraints

- precio y stock negativos son rechazados.
- cantidad cero o negativa es rechazada.
- barcode activo duplicado dentro del mismo negocio es rechazado.
- el mismo barcode puede quedar en un producto archivado según la política
  acordada, pero nunca en dos activos del mismo negocio.
- las referencias de sale_items impiden borrar productos con historia.
- cada sale_item pertenece al mismo negocio que sales y products.
- version aumenta exactamente una vez por actualización aceptada.

### RLS

- anon no puede leer ni ejecutar funciones de escritura.
- un usuario autenticado sin membership no ve businesses, products ni sales.
- un operador ve productos y ventas de su negocio, no de otro.
- un operador no puede insertar directamente sales, sale_items o movimientos.
- un operador puede ejecutar create_sale solo para su negocio.
- un usuario de otro negocio no puede pasar un product_id ajeno al RPC.
- un admin puede ejecutar archive/update según la política, pero no puede leer
  contraseñas ni datos de Auth.
- una vista de historial respeta el membership de las tablas subyacentes.

## Pruebas del RPC de ventas

### Éxito y atomicidad

1. Sembrar dos productos con stock conocido.
2. Crear un carrito con ambos.
3. Ejecutar create_sale.
4. Verificar un sales, las dos sale_items, dos movimientos negativos y stock
   reducido exactamente.
5. Verificar que los snapshots y total usan el servidor.

Fallo:

- hacer que un producto no exista, esté archivado o no tenga stock;
- verificar que no haya sales, sale_items, movements ni decremento parcial.

### Idempotencia

- Ejecutar la misma solicitud dos veces con la misma
  client_operation_id: una venta, un decremento, respuesta replayed en la
  segunda llamada.
- Repetir con el mismo ID y distinto payload: conflicto, sin cambios.
- Simular timeout después de commit y ejecutar el retry: el resultado es el
  mismo.
- Ejecutar dos requests iguales concurrentes: la constraint y el flujo del RPC
  deben terminar en una única venta.

### Concurrencia de stock

- Producto con stock 1 y dos dispositivos que venden cantidad 1: solo una
  operación tiene éxito.
- Producto con stock N y dos carritos que compiten: la suma aprobada no supera
  N.
- Dos carritos con varios productos en orden inverso: no deben producir deadlock
  no recuperable; el orden de locks debe ser determinista.
- Nunca se acepta stock negativo.
- Una edición de producto con expected_version viejo falla y no restaura stock
  antiguo.

## Pruebas de providers y UI

No se cambian pantallas, pero se deben cubrir sus estados actuales:

- AuthGate muestra LoginScreen sin sesión y DashboardScreen con sesión.
- Registro y login muestran el mismo éxito/error visible.
- Dashboard carga productos e historial y conserva accesos actuales.
- Catálogo busca, filtra y abre el detalle.
- Detalle crea, edita, archiva y regresa al catálogo.
- Scanner devuelve el primer código y maneja permiso/cámara denegada.
- Venta agrega, suma cantidades, limita por stock y confirma.
- Historial muestra categorías, orden y ganancias.
- Refresh/sincronizar actualiza datos remotos sin subir cambios locales.
- Error de conflicto no deja al provider con una versión parcial ni borra la
  lista visible.
- Error de red conserva la última caché válida y permite retry.

Los widgets no deben afirmar solo textos: cuando sea posible deben verificar
también llamadas al repository falso y el modelo que recibió la pantalla.

## Pruebas de regresión para los defectos conocidos

| Defecto | Prueba de regresión |
|---|---|
| Pérdida de idRemoto | Editar un producto vinculado y comprobar que update usa el mismo products.id |
| Eliminación no sincronizada | Archivar producto y comprobar activo = false remoto y ausencia del catálogo |
| Error oculto | Repository devuelve código/conflicto; provider conserva una clase segura y un código accionable |
| Falta de negocio tests | Cada caso de esta tabla debe existir como test automatizado, no solo como paso manual |
| Overwrite remoto | Cliente A actualiza version 1; cliente B intenta version 1; B recibe conflicto y no sobrescribe |
| Venta duplicada | Timeout/retry con misma operación; contar una sola sales y un solo movimiento |
| Stock entre dispositivos | Dos clientes compiten por el último stock; solo uno confirma y ambos ven el resultado tras refresh |

## Pruebas de migración de datos

Antes de cargar producción:

1. Contar filas de cada SQLite y PHP por entidad.
2. Validar que cada producto tenga una decisión: vinculado por id remoto,
   vinculado por barcode, creado nuevo, archivado o conflicto manual.
3. Comparar el stock aprobado con products.stock por producto.
4. Validar ventas importadas por source_system, source_device, source_id y
   client_operation_id generado.
5. Verificar que no se descuente stock por segunda vez al importar historia.
6. Comparar total de ventas y ganancias antes/después con tolerancia decimal
   cero.
7. Probar restauración de la exportación y repetición de la importación en
   staging.

La importación debe fallar cerradamente si quedan productos sin mapeo,
barcodes activos duplicados, fechas inválidas o ventas sin producto histórico.

## Pruebas de red y resiliencia

- timeout antes de enviar: no hay venta.
- timeout después de commit: retry con misma clave devuelve la venta original.
- respuesta 4xx de validación: no se reintenta a ciegas.
- respuesta 409 de version/idempotencia: se recarga el recurso y se muestra un
  error seguro.
- respuesta 5xx: no se crea una operación nueva automáticamente con otro ID.
- pérdida de conectividad durante lectura: se usa la última caché válida solo
  para lectura y se marca internamente como stale.
- cerrar/reabrir la app durante una respuesta incierta: se conserva la clave
  para reconciliarla; no se genera otra venta.

## Pruebas de seguridad y privacidad

- No hay password_hash local en payloads de migración pública.
- No hay service_role, contraseña MySQL ni alias Auth expuesto en logs.
- CORS y credenciales de PHP no son requisitos del cliente nuevo.
- Los errores visibles no incluyen SQL, tokens ni cuerpos sensibles.
- RLS se prueba con usuarios de negocios distintos.
- Los RPC SECURITY DEFINER fijan search_path y validan auth.uid().

## Pruebas manuales de aceptación en Android

El APK piloto debe repetir el flujo que ya fue verificado:

1. Registrar e iniciar sesión.
2. Crear, editar y archivar un producto.
3. Cerrar/reabrir y comprobar persistencia de lectura.
4. Escanear un producto existente y uno inexistente.
5. Crear el producto desde el flujo de código no encontrado.
6. Registrar carrito de uno y varios productos.
7. Confirmar reducción remota de stock.
8. Consultar historial, categoría, orden y ganancias.
9. Repetir una confirmación con timeout controlado.
10. Probar dos teléfonos con el mismo producto de stock limitado.

Estas pruebas manuales complementan, pero no sustituyen, las pruebas SQL y de
repository.

## Gates de salida

No se debe hacer cutover si falla cualquiera de estos puntos:

- flutter analyze y flutter test.
- contrato completo de repositories.
- RLS para lectura y escritura.
- create_sale atómico, idempotente y concurrente.
- migración reconciliada sin stock ambiguo.
- regresiones de las ocho pantallas.
- rollback ensayado y exportación verificable.

El resultado del piloto debe conservar conteos, IDs, errores y latencias para
que cualquier decisión de retirar SQLite o PHP sea posterior y basada en
evidencia.
