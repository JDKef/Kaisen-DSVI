<?php
require __DIR__ . '/db.php';

$pdo = conectar();
$metodo = $_SERVER['REQUEST_METHOD'];

switch ($metodo) {
    case 'GET':
        // GET productos.php            -> lista completa (activos)
        // GET productos.php?codigo=XXX -> busca por código de barras
        if (!empty($_GET['codigo'])) {
            $stmt = $pdo->prepare('SELECT * FROM productos WHERE codigo_barras = ? AND activo = 1 LIMIT 1');
            $stmt->execute([$_GET['codigo']]);
            $producto = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(normalizarProducto($producto ?: null));
        } else {
            $stmt = $pdo->query('SELECT * FROM productos WHERE activo = 1 ORDER BY nombre ASC');
            $productos = array_map('normalizarProducto', $stmt->fetchAll(PDO::FETCH_ASSOC));
            echo json_encode($productos);
        }
        break;

    case 'POST':
        $datos = cuerpoJson();
        $requeridos = ['nombre', 'precio', 'stock', 'categoria'];
        foreach ($requeridos as $campo) {
            if (!isset($datos[$campo])) {
                http_response_code(400);
                echo json_encode(['error' => "Falta el campo '$campo'."]);
                exit;
            }
        }

        $stmt = $pdo->prepare(
            'INSERT INTO productos (nombre, precio, stock, categoria, codigo_barras, activo)
             VALUES (?, ?, ?, ?, ?, 1)'
        );
        $stmt->execute([
            $datos['nombre'],
            $datos['precio'],
            $datos['stock'],
            $datos['categoria'],
            $datos['codigo_barras'] ?? null,
        ]);

        $id = (int) $pdo->lastInsertId();
        $stmt = $pdo->prepare('SELECT * FROM productos WHERE id = ?');
        $stmt->execute([$id]);
        http_response_code(201);
        echo json_encode(normalizarProducto($stmt->fetch(PDO::FETCH_ASSOC)));
        break;

    case 'PUT':
        $datos = cuerpoJson();
        if (empty($datos['id'])) {
            http_response_code(400);
            echo json_encode(['error' => "Falta el campo 'id'."]);
            exit;
        }

        $stmt = $pdo->prepare(
            'UPDATE productos
             SET nombre = ?, precio = ?, stock = ?, categoria = ?, codigo_barras = ?
             WHERE id = ?'
        );
        $stmt->execute([
            $datos['nombre'],
            $datos['precio'],
            $datos['stock'],
            $datos['categoria'],
            $datos['codigo_barras'] ?? null,
            $datos['id'],
        ]);

        $stmt = $pdo->prepare('SELECT * FROM productos WHERE id = ?');
        $stmt->execute([$datos['id']]);
        $producto = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$producto) {
            http_response_code(404);
            echo json_encode(['error' => 'Producto no encontrado.']);
            exit;
        }
        echo json_encode(normalizarProducto($producto));
        break;

    case 'DELETE':
        // Baja lógica: DELETE productos.php?id=5
        if (empty($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => "Falta el parámetro 'id'."]);
            exit;
        }
        $stmt = $pdo->prepare('UPDATE productos SET activo = 0 WHERE id = ?');
        $stmt->execute([$_GET['id']]);
        echo json_encode(['ok' => true]);
        break;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Método no permitido.']);
}
