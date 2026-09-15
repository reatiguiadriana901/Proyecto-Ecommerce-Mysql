USE AS_TechShop;

-- TABLAS DE APOYO :)
-- Estas tablas no venían en el diseño original, pero varios
-- procedimientos las necesitan para poder guardar información
-- (historial, devoluciones, créditos, notificaciones).


CREATE TABLE Historial_Stock (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha_ajuste TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_producto FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);

CREATE TABLE Devoluciones (
    id_devolucion INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    motivo VARCHAR(255) NULL,
    fecha_devolucion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_devolucion_venta FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta),
    CONSTRAINT fk_devolucion_producto FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);

CREATE TABLE Creditos_Cliente (
    id_credito INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    motivo VARCHAR(255) NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_credito TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_credito_cliente FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

CREATE TABLE Notificaciones (
    id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    mensaje VARCHAR(255) NOT NULL,
    fecha_notificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notificacion_venta FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta)
);



-- 1. sp_RealizarNuevaVenta

DELIMITER $$

CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_stock_actual INT;
    DECLARE v_id_venta INT;
    DECLARE v_existe_cliente INT;

 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

   
    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;


    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad debe ser mayor a cero.';
    END IF;

    START TRANSACTION;

    SELECT precio, stock INTO v_precio, v_stock_actual
    FROM Productos
    WHERE id_producto = p_id_producto
    FOR UPDATE;

    IF v_precio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto indicado no existe.';
    END IF;

    IF v_stock_actual < p_cantidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay suficiente stock disponible.';
    END IF;

    INSERT INTO Ventas (id_cliente, estado, total)
    VALUES (p_id_cliente, 'Pendiente de Pago', v_precio * p_cantidad);

    SET v_id_venta = LAST_INSERT_ID();

    INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad, precio_unitario_congelado)
    VALUES (v_id_venta, p_id_producto, p_cantidad, v_precio);


    UPDATE Productos
    SET stock = stock - p_cantidad
    WHERE id_producto = p_id_producto;

    COMMIT;

    SELECT v_id_venta AS id_venta_generada, 'Venta realizada con éxito' AS mensaje;
END$$

DELIMITER ;

-- 2. sp_AgregarNuevoProducto

DELIMITER $$

CREATE PROCEDURE sp_AgregarNuevoProducto(
    IN p_nombre VARCHAR(150),
    IN p_descripcion TEXT,
    IN p_precio DECIMAL(10,2),
    IN p_costo DECIMAL(10,2),
    IN p_stock INT,
    IN p_sku VARCHAR(50),
    IN p_id_categoria INT,
    IN p_id_provider INT
)
BEGIN
    DECLARE v_existe_categoria INT;
    DECLARE v_existe_proveedor INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_precio <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio debe ser mayor a cero.';
    END IF;

    IF p_costo < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El costo no puede ser negativo.';
    END IF;

    IF p_stock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock no puede ser negativo.';
    END IF;

    SELECT COUNT(*) INTO v_existe_categoria FROM Categorias WHERE id_categoria = p_id_categoria;
    IF v_existe_categoria = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoría indicada no existe.';
    END IF;

    SELECT COUNT(*) INTO v_existe_proveedor FROM Proveedores WHERE id_proveedor = p_id_provider;
    IF v_existe_proveedor = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor indicado no existe.';
    END IF;

    START TRANSACTION;

    INSERT INTO Productos (nombre, descripcion, precio, costo, stock, sku, id_categoria, id_provider)
    VALUES (p_nombre, p_descripcion, p_precio, p_costo, p_stock, p_sku, p_id_categoria, p_id_provider);

    COMMIT;

    SELECT LAST_INSERT_ID() AS id_producto_creado, 'Producto agregado correctamente' AS mensaje;
END$$

DELIMITER ;

-- 3. sp_ActualizarDireccionCliente

DELIMITER $$

CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_id_cliente INT,
    IN p_nueva_direccion TEXT
)
BEGIN
    DECLARE v_existe_cliente INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;

    START TRANSACTION;

    UPDATE Clientes
    SET direccion_envio = p_nueva_direccion
    WHERE id_cliente = p_id_cliente;

    COMMIT;

    SELECT 'Dirección actualizada correctamente' AS mensaje;
END$$

DELIMITER ;


-- 4. sp_ProcesarDevolucion

DELIMITER $$

CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_id_venta INT,
    IN p_id_producto INT,
    IN p_cantidad INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_id_cliente INT;
    DECLARE v_cantidad_comprada INT;
    DECLARE v_precio_unitario DECIMAL(10,2);
    DECLARE v_monto_credito DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver debe ser mayor a cero.';
    END IF;


    SELECT id_cliente INTO v_id_cliente
    FROM Ventas
    WHERE id_venta = p_id_venta;

    IF v_id_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta indicada no existe.';
    END IF;

    SELECT cantidad, precio_unitario_congelado
    INTO v_cantidad_comprada, v_precio_unitario
    FROM Detalle_Ventas
    WHERE id_venta = p_id_venta AND id_producto = p_id_producto;

    IF v_cantidad_comprada IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ese producto no pertenece a la venta indicada.';
    END IF;

    IF p_cantidad > v_cantidad_comprada THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver es mayor a la cantidad comprada.';
    END IF;

    SET v_monto_credito = v_precio_unitario * p_cantidad;

    START TRANSACTION;

  
    INSERT INTO Devoluciones (id_venta, id_producto, cantidad, motivo)
    VALUES (p_id_venta, p_id_producto, p_cantidad, p_motivo);

 
    UPDATE Productos
    SET stock = stock + p_cantidad
    WHERE id_producto = p_id_producto;

   
    INSERT INTO Creditos_Cliente (id_cliente, monto, motivo)
    VALUES (v_id_cliente, v_monto_credito, CONCAT('Devolución venta #', p_id_venta));

    COMMIT;

    SELECT v_monto_credito AS credito_generado, 'Devolución procesada correctamente' AS mensaje;
END$$

DELIMITER ;


-- 5. sp_ObtenerHistorialComprasCliente

DELIMITER $$

CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(
    IN p_id_cliente INT
)
BEGIN
    DECLARE v_existe_cliente INT;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;

    SELECT
        v.id_venta,
        v.fecha_venta,
        v.estado,
        p.nombre AS producto,
        dv.cantidad,
        dv.precio_unitario_congelado,
        (dv.cantidad * dv.precio_unitario_congelado) AS subtotal,
        v.total AS total_venta
    FROM Ventas v
    INNER JOIN Detalle_Ventas dv ON v.id_venta = dv.id_venta
    INNER JOIN Productos p ON dv.id_producto = p.id_producto
    WHERE v.id_cliente = p_id_cliente
    ORDER BY v.fecha_venta DESC;
END$$

DELIMITER ;



-- 6. sp_AjustarNivelStock

DELIMITER $$

CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_id_producto INT,
    IN p_cantidad_nueva INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_stock_anterior INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_cantidad_nueva < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nuevo stock no puede ser negativo.';
    END IF;

    IF p_motivo IS NULL OR p_motivo = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe indicar un motivo para el ajuste.';
    END IF;

    SELECT stock INTO v_stock_anterior
    FROM Productos
    WHERE id_producto = p_id_producto;

    IF v_stock_anterior IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto indicado no existe.';
    END IF;

    START TRANSACTION;

    UPDATE Productos
    SET stock = p_cantidad_nueva
    WHERE id_producto = p_id_producto;

    INSERT INTO Historial_Stock (id_producto, stock_anterior, stock_nuevo, motivo)
    VALUES (p_id_producto, v_stock_anterior, p_cantidad_nueva, p_motivo);

    COMMIT;

    SELECT 'Stock ajustado correctamente' AS mensaje;
END$$

DELIMITER ;

-- 7. sp_EliminarClienteDeFormaSegura
DELIMITER $$

CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(
    IN p_id_cliente INT
)
BEGIN
    DECLARE v_existe_cliente INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;

    START TRANSACTION;

    UPDATE Clientes
    SET nombre = 'Usuario',
        apellido = 'Eliminado',
        email = CONCAT('eliminado_', id_cliente, '@anonimo.com'),
        contrasena = 'CUENTA_ELIMINADA',
        direccion_envio = NULL
    WHERE id_cliente = p_id_cliente;

    COMMIT;

    SELECT 'Cliente anonimizado correctamente. Su historial de compras se conserva.' AS mensaje;
END$$

DELIMITER ;


-- 8. sp_AplicarDescuentoPorCategoria
DELIMITER $$

CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_id_categoria INT,
    IN p_porcentaje_descuento DECIMAL(5,2)
)
BEGIN
    DECLARE v_existe_categoria INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_porcentaje_descuento <= 0 OR p_porcentaje_descuento >= 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El porcentaje de descuento debe estar entre 0 y 100.';
    END IF;

    SELECT COUNT(*) INTO v_existe_categoria FROM Categorias WHERE id_categoria = p_id_categoria;
    IF v_existe_categoria = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoría indicada no existe.';
    END IF;

    START TRANSACTION;

    UPDATE Productos
    SET precio = ROUND(precio - (precio * p_porcentaje_descuento / 100), 2)
    WHERE id_categoria = p_id_categoria;

    COMMIT;

    SELECT ROW_COUNT() AS productos_actualizados, 'Descuento aplicado correctamente' AS mensaje;
END$$

DELIMITER ;



-- 9. sp_GenerarReporteMensualVentas

DELIMITER $$

CREATE PROCEDURE sp_GenerarReporteMensualVentas(
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    IF p_mes < 1 OR p_mes > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El mes debe estar entre 1 y 12.';
    END IF;

   
    SELECT
        COUNT(DISTINCT v.id_venta) AS total_ventas,
        SUM(v.total) AS ingresos_totales,
        SUM(dv.cantidad) AS unidades_vendidas
    FROM Ventas v
    INNER JOIN Detalle_Ventas dv ON v.id_venta = dv.id_venta
    WHERE MONTH(v.fecha_venta) = p_mes
      AND YEAR(v.fecha_venta) = p_anio;

 
    SELECT
        p.nombre AS producto,
        SUM(dv.cantidad) AS unidades_vendidas,
        SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos_producto
    FROM Ventas v
    INNER JOIN Detalle_Ventas dv ON v.id_venta = dv.id_venta
    INNER JOIN Productos p ON dv.id_producto = p.id_producto
    WHERE MONTH(v.fecha_venta) = p_mes
      AND YEAR(v.fecha_venta) = p_anio
    GROUP BY p.nombre
    ORDER BY unidades_vendidas DESC;
END$$

DELIMITER ;

-- 10. sp_CambiarEstadoPedido
DELIMITER $$

CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN p_id_venta INT,
    IN p_nuevo_estado VARCHAR(30)
)
BEGIN
    DECLARE v_existe_venta INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_existe_venta FROM Ventas WHERE id_venta = p_id_venta;
    IF v_existe_venta = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta indicada no existe.';
    END IF;

    IF p_nuevo_estado NOT IN ('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estado indicado no es válido.';
    END IF;

    START TRANSACTION;

    UPDATE Ventas
    SET estado = p_nuevo_estado
    WHERE id_venta = p_id_venta;

  
    INSERT INTO Notificaciones (id_venta, mensaje)
    VALUES (p_id_venta, CONCAT('El pedido #', p_id_venta, ' cambió su estado a: ', p_nuevo_estado));

    COMMIT;

    SELECT 'Estado del pedido actualizado y notificación registrada' AS mensaje;
END$$

DELIMITER ;
-- 11. sp_RegistrarNuevoCliente
DELIMITER $$

CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_contrasena VARCHAR(255),
    IN p_direccion TEXT
)
BEGIN
    DECLARE v_existe_email INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_existe_email FROM Clientes WHERE email = p_email;
    IF v_existe_email > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un cliente registrado con ese email.';
    END IF;

    START TRANSACTION;

    INSERT INTO Clientes (nombre, apellido, email, contrasena, direccion_envio)
    VALUES (p_nombre, p_apellido, p_email, p_contrasena, p_direccion);

    COMMIT;

    SELECT LAST_INSERT_ID() AS id_cliente_creado, 'Cliente registrado correctamente' AS mensaje;
END$$

DELIMITER ;

