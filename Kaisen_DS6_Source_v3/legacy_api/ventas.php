<?php
require __DIR__ . '/db.php';

$pdo = conectar();
$metodo = $_SERVER['REQUEST_METHOD'];

function normalizarVenta(array $venta): array {
    $venta['id'] = (int) $venta['id'];
    $venta['producto_id'] = (int) $venta['producto_id'];
    $venta['cantidad'] = (int) $venta['cantidad'];
    $venta['precio_unitario'] = (float) $venta['precio_unitario'];
    return $venta;
}

switch ($metodo) {
    case 'GET':
        $stmt = $pdo->query('SELECT * FROM ventas ORDER BY fecha DESC');
        $ventas = array_map('normalizarVenta', $stmt->fetchAll(PDO::FETCH_ASSOC));
        echo json_encode($ventas);
        break;

    case 'POST':
        // Recibe un carrito completo: [{producto_id, producto_nombre, categoria, cantidad, precio_unitario, fecha}, ...]
        $items = cuerpoJson();
        if (empty($items)) {
            http_response_code(400);
            echo json_encode(['error' => 'El carrito está vacío.']);
            exit;
        }

        $stmt = $pdo->prepare(
            'INSERT INTO ventas (producto_id, producto_nombre, categoria, cantidad, precio_unitario, fecha)
             VALUES (?, ?, ?, ?, ?, ?)'
        );

        $idsCreados = [];
        $pdo->beginTransaction();
        try {
            foreach ($items as $item) {
                $stmt->execute([
                    $item['producto_id'],
                    $item['producto_nombre'],
                    $item['categoria'] ?? 'Sin categoría',
                    $item['cantidad'],
                    $item['precio_unitario'],
                    $item['fecha'],
                ]);
                $idsCreados[] = (int) $pdo->lastInsertId();
            }
            $pdo->commit();
        } catch (Exception $e) {
            $pdo->rollBack();
            http_response_code(500);
            echo json_encode(['error' => 'No se pudo registrar la venta.']);
            exit;
        }

        http_response_code(201);
        // ids[i] corresponde al item enviado en la posición i del arreglo original.
        echo json_encode(['ok' => true, 'ids' => $idsCreados]);
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido.']);
}
