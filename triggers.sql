-- -----------------------------------------
-- Triggers (Disparadores)
-- -----------------------------------------

-- 1. Guarda un log de cambios de precios.

DELIMITER //

CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN
    IF NEW.precio <> OLD.precio THEN
        INSERT INTO Logs_Precios (id_producto, precio_anterior, precio_nuevo)
        VALUES (OLD.id_producto, OLD.precio, NEW.precio);
    END IF;
END //

DELIMITER ;

-- 2. Verifica el stock antes de registrar una venta
DELIMITER //

CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON Detalle_Ventas
FOR EACH ROW
BEGIN
	
    DECLARE stock_actual INT;

    SELECT stock INTO stock_actual
    FROM Productos
    WHERE id_producto = NEW.id_producto;

    IF stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente para completar la venta';
    END IF;
END //

DELIMITER ;

-- 3. Decrementa el stock después de una venta 

DELIMITER //

CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON Detalle_Ventas
FOR EACH ROW
BEGIN
    UPDATE Productos
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END //

DELIMITER ;

-- 4.Impide eliminar una categoría si tiene productos asociados.

DELIMITER //

CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON Categorias
FOR EACH ROW
BEGIN
	
	DECLARE v_hay_productos INT;
	
	SELECT COUNT(*) 
	INTO v_hay_productos
	FROM Productos
	WHERE id_categoria = OLD.id_categoria;
	
	IF v_hay_productos > 0 THEN
	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar la categoria seleccionada aun cuenta con productos asociados';
    END IF;
	
END //

DELIMITER ;

-- 5. Registra en una tabla de auditoría cada vez que se crea un nuevo cliente


DELIMITER //

CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON Clientes
FOR EACH ROW
BEGIN
	INSERT INTO auditoria_nuevo_cliente(id_cliente, nombre) 
	VALUES (NEW.id_cliente, NEW.nombre);
	
END //

DELIMITER ;


-- 6.Actualiza un campo total_gastado en la tabla clientes después de cada compra


DELIMITER //

CREATE TRIGGER trg_update_total_gastado_cliente
AFTER INSERT ON Ventas
FOR EACH ROW
BEGIN
	UPDATE Clientes
    SET  total_gastado = NEW.total + total_gastado
    WHERE id_cliente = NEW.id_cliente;

END //

DELIMITER ;

-- 7. Actualiza automáticamente la fecha de última modificación de un producto

CREATE TABLE auditoria_productos (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    fecha_modificacion DATETIME NOT NULL,
	
    CONSTRAINT fk_auditoria_producto FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);
	

DELIMITER //

CREATE TRIGGER trg_set_fecha_modificacion_producto
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN

	 auditoria_productos
	SET fecha_modificacion = Now()
	WHERE id_producto = NEW.id_producto;
	
END//

DELIMITER ;

-- 8. Impide que el stock de un producto se actualice a un valor negativo.

DELIMITER //

CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN
	
	IF NEW.stock < 0 THEN
	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede actualizar el stock debe ser un valor positivo';
    END IF;
		
END //

DELIMITER ;

-- 9. Convierte a mayúscula la primera letra del nombre y apellido de un cliente al insertarlo.

DELIMITER //

CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON Clientes
FOR EACH ROW
BEGIN
	SET NEW.nombre = CONCAT(UPPER(LEFT(NEW.nombre,1)), LOWER(SUBSTRING(NEW.nombre,2)));
    SET NEW.apellido = CONCAT(UPPER(LEFT(NEW.apellido,1)), LOWER(SUBSTRING(NEW.apellido,2)));
END //
DELIMITER ;


-- 10. Recalcula el total en la tabla ventas si se modifica un detalle_venta.

DELIMITER //

CREATE TRIGGER trg_recalculate_total_venta_on_detalle_change
AFTER UPDATE ON Detalle_Ventas
FOR EACH ROW
BEGIN
	
	DECLARE v_total DECIMAL(10,2);
	
	SELECT SUM(cantidad * precio_unitario_congelado) 
	INTO v_total 
	FROM Detalle_Ventas 
	WHERE id_venta = NEW.id_venta;
	
	UPDATE Ventas
    SET  total = v_total
    WHERE id_venta = NEW.id_venta;
	
END //

DELIMITER ;
