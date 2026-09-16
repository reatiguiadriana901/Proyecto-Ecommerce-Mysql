-- -----------------------------------------
--           Eventos Programados
-- -----------------------------------------

-- 1.  Genera un reporte de ventas semanal

DELIMITER //

CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO reporte_ventas_semanales (cantidad, total, fecha_reporte)
    SELECT COUNT(*), SUM(total), NOW()
    FROM Ventas
    WHERE fecha_venta >= NOW() - INTERVAL 1 WEEK;
END //

DELIMITER ;


-- 2. Borra tablas temporales diariamente

-- CREATE TABLE temp_busquedas (
 --   id_busqueda INT AUTO_INCREMENT PRIMARY KEY,
 --   id_cliente INT NULL,
 --   termino_buscado VARCHAR(150),
 --   fecha_busqueda TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

DELIMITER //

CREATE EVENT evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    TRUNCATE TABLE temp_busquedas;
END //

DELIMITER ;


-- 3. Archiva logs de más de 6 meses en tablas históricas


DELIMITER //

CREATE EVENT evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO log_cambios_precio_historico
    SELECT * FROM Logs_Precios
    WHERE fecha_cambio < NOW() - INTERVAL 6 MONTH;

    DELETE FROM log_cambios_precio
    WHERE fecha_cambio < NOW() - INTERVAL 6 MONTH;
END //

DELIMITER ;


-- 4. Desactiva códigos de descuento que han expirado.

DELIMITER //

CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE Promociones
    SET activo = FALSE
    WHERE fecha_fin < CURDATE()
    AND activo = TRUE;
END //

DELIMITER ;

-- 5. Recalcula el nivel de lealtad de los clientes cada noche.

ALTER TABLE Clientes ADD COLUMN nivel_lealtad VARCHAR(20) DEFAULT 'Bronce';

DELIMITER //

CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE Clientes
    SET nivel_lealtad = 
        CASE
            WHEN total_gastado >= 1000 THEN 'Oro'
            WHEN total_gastado >= 300 THEN 'Plata'
            ELSE 'Bronce'
        END;
END //

DELIMITER ;

-- 6.Crea una lista de productos que necesitan ser reabastecidos

DELIMITER //

CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO lista_reabastecimiento (nombre_producto, stock_actual)
    SELECT nombre, stock
    FROM Productos
    WHERE stock <= 10;
END //

DELIMITER ;

-- 7. Reconstruye los índices de las tablas más usadas para optimizar el rendimiento.

DELIMITER //

CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    OPTIMIZE TABLE Productos;
    OPTIMIZE TABLE Ventas;
    OPTIMIZE TABLE Detalle_Ventas;
    OPTIMIZE TABLE Clientes;
END //

DELIMITER ;

-- 8. Desactiva cuentas de clientes sin actividad en más de un año.

ALTER TABLE Clientes ADD COLUMN cuenta_activa BOOLEAN DEFAULT TRUE;

DELIMITER //

CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE Clientes c
    SET cuenta_activa = FALSE
    WHERE cuenta_activa = TRUE
    AND NOT EXISTS (
        SELECT 1 FROM Ventas v
        WHERE v.id_cliente = c.id_cliente
        AND v.fecha_venta > NOW() - INTERVAL 1 YEAR
    );
END //

DELIMITER ;

-- 9. Agrega los datos de ventas del día en una tabla de resumen para acelerar reportes.

DELIMITER //

CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO resumen_ventas_diarias (fecha, cantidad_ventas, total_vendido)
    SELECT CURDATE(), COUNT(*), SUM(total)
    FROM Ventas
    WHERE DATE(fecha_venta) = CURDATE();
END //

DELIMITER ;

-- 10. Busca inconsistencias en los datos (ej. ventas sin detalles).

DELIMITER //

CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO alertas_inconsistencia (descripcion, id_referencia)
    SELECT 'Venta sin ningun detalle asociado', v.id_venta
    FROM Ventas v
    WHERE NOT EXISTS (
        SELECT 1 FROM Detalle_Ventas dv
        WHERE dv.id_venta = v.id_venta
    );
END //

DELIMITER ;

-- activacion de los eventos

SET GLOBAL event_scheduler = ON;
