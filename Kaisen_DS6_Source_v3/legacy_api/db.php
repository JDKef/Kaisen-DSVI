<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function conectar(): PDO {
    $host = '127.0.0.1';
    $port = '3307';
    $db = 'kaisen_db';
    $user = 'root';
    $pass = '';

    try {
        return new PDO(
            "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4",
            $user,
            $pass,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'No se pudo conectar a la base de datos.']);
        exit;
    }
}

function cuerpoJson(): array {
    $datos = json_decode(file_get_contents('php://input'), true);
    return is_array($datos) ? $datos : [];
}

// PDO devuelve las columnas numéricas como strings; esto las convierte a
// number antes de json_encode para que el cliente no tenga que adivinar el tipo.
function normalizarProducto(?array $producto): ?array {
    if ($producto === null) return null;
    $producto['id'] = (int) $producto['id'];
    $producto['precio'] = (float) $producto['precio'];
    $producto['stock'] = (int) $producto['stock'];
    $producto['activo'] = (int) $producto['activo'];
    return $producto;
}
