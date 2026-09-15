-- script de funciones hecho por Daniel Florez Lopez


USE AS_TechShop;

ALTER TABLE Clientes ADD COLUMN fecha_nacimiento DATE NULL;
ALTER TABLE Productos ADD COLUMN peso_kg DECIMAL(6,2) NOT NULL DEFAULT 0.50;

DELIMITER //

-- 1. fn_CalcularTotalVenta

DROP FUNCTION IF EXISTS fn_CalcularTotalVenta //

CREATE FUNCTION fn_CalcularTotalVenta(p_id_venta INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_monto_total DECIMAL(10,2);
    DECLARE v_existe_venta INT;

    IF p_id_venta IS NULL OR p_id_venta <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_venta debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(*) INTO v_existe_venta FROM Ventas WHERE id_venta = p_id_venta;
    IF v_existe_venta = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta indicada no existe.';
    END IF;

    SELECT SUM(cantidad * precio_unitario_congelado)
    INTO v_monto_total
    FROM Detalle_Ventas
    WHERE id_venta = p_id_venta;


    RETURN IFNULL(v_monto_total, 0.00);
END //



-- 2. fn_VerificarDisponibilidadStock

DROP FUNCTION IF EXISTS fn_VerificarDisponibilidadStock //

CREATE FUNCTION fn_VerificarDisponibilidadStock(p_id_producto INT, p_cantidad_requerida INT)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock_actual INT;

    IF p_id_producto IS NULL OR p_id_producto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_producto debe ser un número mayor a cero.';
    END IF;

    IF p_cantidad_requerida IS NULL OR p_cantidad_requerida <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad requerida debe ser mayor a cero.';
    END IF;

    SELECT stock INTO v_stock_actual FROM Productos WHERE id_producto = p_id_producto;

    IF v_stock_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto indicado no existe.';
    END IF;

    IF v_stock_actual >= p_cantidad_requerida THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //



-- 3. fn_ObtenerPrecioProducto

DROP FUNCTION IF EXISTS fn_ObtenerPrecioProducto //

CREATE FUNCTION fn_ObtenerPrecioProducto(p_id_producto INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_precio DECIMAL(10,2);

    IF p_id_producto IS NULL OR p_id_producto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_producto debe ser un número mayor a cero.';
    END IF;

    SELECT precio INTO v_precio FROM Productos WHERE id_producto = p_id_producto;


    RETURN v_precio;
END //



-- 4. fn_CalcularEdadCliente

DROP FUNCTION IF EXISTS fn_CalcularEdadCliente //

CREATE FUNCTION fn_CalcularEdadCliente(p_id_cliente INT)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_nacimiento DATE;
    DECLARE v_existe_cliente INT;

    IF p_id_cliente IS NULL OR p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_cliente debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;

    SELECT fecha_nacimiento INTO v_fecha_nacimiento FROM Clientes WHERE id_cliente = p_id_cliente;


    IF v_fecha_nacimiento IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN TIMESTAMPDIFF(YEAR, v_fecha_nacimiento, CURDATE());
END //


-- 5. fn_FormatearNombreCompleto

DROP FUNCTION IF EXISTS fn_FormatearNombreCompleto //

CREATE FUNCTION fn_FormatearNombreCompleto(p_id_cliente INT)
RETURNS VARCHAR(200)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE v_existe_cliente INT;

    IF p_id_cliente IS NULL OR p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_cliente debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        RETURN NULL;
    END IF;

    SELECT TRIM(UPPER(nombre)), TRIM(UPPER(apellido))
    INTO v_nombre, v_apellido
    FROM Clientes
    WHERE id_cliente = p_id_cliente;

    RETURN CONCAT(IFNULL(v_nombre, 'SIN NOMBRE'), ' ', IFNULL(v_apellido, 'SIN APELLIDO'));
END //


-- 6. fn_EsClienteNuevo

DROP FUNCTION IF EXISTS fn_EsClienteNuevo //

CREATE FUNCTION fn_EsClienteNuevo(p_id_cliente INT)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_registro TIMESTAMP;
    DECLARE v_primera_compra TIMESTAMP;
    DECLARE v_existe_cliente INT;
    DECLARE v_dias_diferencia INT;

    IF p_id_cliente IS NULL OR p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_cliente debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;

    SELECT c.fecha_registro, v.fecha_venta
    INTO v_fecha_registro, v_primera_compra
    FROM Clientes c
    INNER JOIN Ventas v ON c.id_cliente = v.id_cliente
    WHERE c.id_cliente = p_id_cliente
    ORDER BY v.fecha_venta ASC
    LIMIT 1;

 
    IF v_primera_compra IS NULL THEN
        RETURN FALSE;
    END IF;

    SET v_dias_diferencia = TIMESTAMPDIFF(DAY, v_fecha_registro, v_primera_compra);

    IF v_dias_diferencia <= 30 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //



-- 7. fn_AplicarDescuento

DROP FUNCTION IF EXISTS fn_AplicarDescuento //

CREATE FUNCTION fn_AplicarDescuento(p_porcentaje INT, p_monto DECIMAL(10,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    IF p_porcentaje IS NULL OR p_porcentaje < 0 OR p_porcentaje > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El porcentaje debe estar entre 0 y 100.';
    END IF;

    IF p_monto IS NULL OR p_monto < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto no puede ser negativo.';
    END IF;

    RETURN ROUND(p_monto * (1 - (p_porcentaje / 100)), 2);
END //



-- 8. fn_ObtenerUltimaFechaCompra

DROP FUNCTION IF EXISTS fn_ObtenerUltimaFechaCompra //

CREATE FUNCTION fn_ObtenerUltimaFechaCompra(p_id_cliente INT)
RETURNS DATE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ultima_venta DATE;
    DECLARE v_existe_cliente INT;

    IF p_id_cliente IS NULL OR p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_cliente debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(*) INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_existe_cliente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente indicado no existe.';
    END IF;


    SELECT fecha_venta INTO v_ultima_venta
    FROM Ventas
    WHERE id_cliente = p_id_cliente
    ORDER BY fecha_venta DESC
    LIMIT 1;

    RETURN v_ultima_venta;
END //



-- 9. fn_ValidarFormatoEmail

DROP FUNCTION IF EXISTS fn_ValidarFormatoEmail //

CREATE FUNCTION fn_ValidarFormatoEmail(p_email VARCHAR(255))
RETURNS TINYINT(1)
DETERMINISTIC
NO SQL
BEGIN
    IF p_email IS NOT NULL
       AND TRIM(p_email) <> ''
       AND p_email NOT LIKE '% %'
       AND p_email LIKE '_%@_%.__%' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //



-- 10. fn_ObtenerNombreCategoria

DROP FUNCTION IF EXISTS fn_ObtenerNombreCategoria //

CREATE FUNCTION fn_ObtenerNombreCategoria(p_id_producto INT)
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre_categoria VARCHAR(255);

    IF p_id_producto IS NULL OR p_id_producto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_producto debe ser un número mayor a cero.';
    END IF;

    SELECT c.nombre INTO v_nombre_categoria
    FROM Productos p
    INNER JOIN Categorias c ON c.id_categoria = p.id_categoria
    WHERE p.id_producto = p_id_producto
    LIMIT 1;


    RETURN v_nombre_categoria;
END //

-- 11. fn_ContarVentasCliente

DROP FUNCTION IF EXISTS fn_ContarVentasCliente //

CREATE FUNCTION fn_ContarVentasCliente(p_id_cliente INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_ventas INT;

    IF p_id_cliente IS NULL OR p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_cliente debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(id_venta) INTO v_total_ventas
    FROM Ventas
    WHERE id_cliente = p_id_cliente;

    RETURN v_total_ventas;
END //
-- 12. fn_CalcularCostoEnvio
DROP FUNCTION IF EXISTS fn_CalcularCostoEnvio //

CREATE FUNCTION fn_CalcularCostoEnvio(p_id_venta INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_peso_total DECIMAL(10,2);
    DECLARE v_existe_venta INT;
    DECLARE v_costo_base DECIMAL(10,2) DEFAULT 5000.00;   -- costo fijo de manejo
    DECLARE v_tarifa_por_kg DECIMAL(10,2) DEFAULT 2000.00; -- costo por cada kg

    IF p_id_venta IS NULL OR p_id_venta <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El id_venta debe ser un número mayor a cero.';
    END IF;

    SELECT COUNT(*) INTO v_existe_venta FROM Ventas WHERE id_venta = p_id_venta;
    IF v_existe_venta = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta indicada no existe.';
    END IF;

    SELECT SUM(p.peso_kg * dv.cantidad)
    INTO v_peso_total
    FROM Detalle_Ventas dv
    INNER JOIN Productos p ON dv.id_producto = p.id_producto
    WHERE dv.id_venta = p_id_venta;

    -- Si la venta no tiene productos todavía, no hay costo de envío
    IF v_peso_total IS NULL THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(v_costo_base + (v_peso_total * v_tarifa_por_kg), 2);
END //

DELIMITER ;


