-- -----------------------------------------
-- Consultas Avanzadas (Análisis y Reporteo)
-- -----------------------------------------

-- 1. Top 10 Productos Más Vendidos

SELECT p.nombre AS producto, SUM(dv.cantidad) AS totales_vendidos
FROM Detalle_Ventas dv
JOIN Productos p ON dv.id_producto = p.id_producto
GROUP BY p.id_producto
ORDER BY totales_vendidos DESC
LIMIT 10;


-- 2. Productos con Bajas Ventas

WITH TablaDePorcentajes AS (
    SELECT 
        p.nombre AS producto, 
        SUM(dv.cantidad * dv.precio_unitario_congelado) AS total_vendido,
        PERCENT_RANK() OVER (ORDER BY SUM(dv.cantidad * dv.precio_unitario_congelado) ASC) AS porc_rango
    FROM Detalle_Ventas dv
    JOIN Productos p ON dv.id_producto = p.id_producto
    GROUP BY p.id_producto, p.nombre
)

SELECT producto, total_vendido
FROM TablaDePorcentajes
WHERE porc_rango <= 0.10;



-- 3. Clientes VIP

SELECT cl.nombre AS cliente, SUM(v.total) AS total_ventas
FROM Clientes cl
JOIN Ventas v ON cl.id_cliente = v.id_cliente 
GROUP BY cl.nombre, cl.id_cliente
ORDER BY total_ventas DESC
LIMIT 5;



-- 4. Análisis de Ventas Mensuales

SELECT 
	YEAR(v.fecha_venta) AS anio,
	MONTH(v.fecha_venta) AS mes,
	SUM(v.total) AS total_ventas
FROM Ventas v 
GROUP BY YEAR(v.fecha_venta), MONTH(v.fecha_venta)
ORDER BY anio DESC, mes DESC;



-- 5.Crecimiento de Clientes

SELECT 
	YEAR(cl.fecha_registro) AS anio,
	QUARTER(cl.fecha_registro) AS trimestre,
	COUNT(*) AS numero_clientes 
FROM Clientes cl
GROUP BY YEAR(cl.fecha_registro),QUARTER(cl.fecha_registro)
ORDER BY anio DESC, trimestre DESC;



-- 6. Tasa de Compra Repetida

WITH ComprasPorCliente AS (
    SELECT id_cliente, COUNT(id_venta) AS cantidad_compras
    FROM Ventas
    GROUP BY id_cliente
)

SELECT 
	COUNT(CASE WHEN cantidad_compras > 1 THEN 1 END) AS clientes_fieles,
	COUNT(*) AS total_clientes_compradores,
	(COUNT(CASE WHEN cantidad_compras > 1 THEN 1 END) / COUNT(*)) * 100 AS porcentaje_repeticion
	FROM ComprasPorCliente;



-- 7. Productos Comprados Juntos Frecuentemente 

SELECT 
	dv1.id_producto AS producto_1, 
	dv2.id_producto AS producto_2, 
	count(*) AS total_pares_comprados
FROM Detalle_Ventas dv1
JOIN Detalle_Ventas dv2 ON dv1.id_venta = dv2.id_venta
WHERE dv1.id_producto < dv2.id_producto 
GROUP BY dv1.id_producto, dv2.id_producto
ORDER BY total_pares_comprados DESC;



-- 8. Rotación de Inventario

CREATE VIEW v_stock_por_categoria AS
SELECT id_categoria, SUM(stock) AS total_stock
FROM Productos
GROUP BY id_categoria;

CREATE VIEW v_ventas_por_categoria AS
SELECT p.id_categoria, SUM(dv.cantidad) AS total_vendido
FROM Detalle_Ventas dv
JOIN Productos p ON dv.id_producto = p.id_producto
GROUP BY p.id_categoria;

SELECT c.nombre AS categoria, vc.total_vendido / sc.total_stock AS tasa_rotacion
FROM Categorias c
JOIN v_ventas_por_categoria vc ON vc.id_categoria = c.id_categoria
JOIN v_stock_por_categoria sc ON sc.id_categoria = c.id_categoria
ORDER BY tasa_rotacion DESC; 



-- 9. Productos que Necesitan Reabastecimiento

SELECT p.nombre AS productos, p.stock AS stock
FROM Productos p
WHERE p.stock <= 10;



-- 10. Análisis de Carrito Abandonado (Simulado)

SELECT 
    v.id_venta,
    cl.nombre AS cliente,
    v.fecha_venta,
    v.total
FROM Ventas v
JOIN Clientes cl ON cl.id_cliente = v.id_cliente
WHERE v.estado = 'Pendiente de Pago'
AND v.fecha_venta < NOW() - INTERVAL 72 HOUR;



-- 11. Rendimiento de Proveedores

SELECT prov.nombre AS proveedores, SUM(dv.cantidad) AS volumen_ventas
FROM Proveedores prov
JOIN Productos prod ON prov.id_proveedor = prod.id_proveedor
JOIN Detalle_Ventas dv ON prod.id_producto = dv.id_producto
GROUP BY prov.nombre, prov.id_proveedor
ORDER BY volumen_ventas DESC;



-- 12. Análisis Geográfico de Ventas

SELECT cl.ciudad AS ciudad, COUNT(*) AS numero_ventas, SUM(v.total) AS ingresos_totales
FROM Clientes cl
JOIN Ventas v ON cl.id_cliente = v.id_cliente
GROUP BY cl.ciudad
ORDER BY numero_ventas DESC; 



-- 13. Ventas por Hora del Día (Horas Pico de Compras)

SELECT 
    HOUR(v.fecha_venta) AS hora_dia,
    COUNT(*) AS cantidad_ventas,
    SUM(v.total) AS ingresos_totales
FROM Ventas v
GROUP BY HOUR(v.fecha_venta)
ORDER BY cantidad_ventas DESC;



-- 14. Impacto de Promociones

SELECT
    CASE
        WHEN v.fecha_venta < '2026-08-10' THEN 'Antes de la Promoción'
        WHEN v.fecha_venta BETWEEN '2026-08-10' AND '2026-08-25' THEN 'Durante la Promoción'
        ELSE 'Después de la Promoción'
    END AS periodo_campania,
    SUM(dv.cantidad) AS unidades_vendidas,
    SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos_totales
FROM Detalle_Ventas dv
JOIN Ventas v ON dv.id_venta = v.id_venta
JOIN Productos p ON dv.id_producto = p.id_producto
WHERE p.nombre = 'Smartphone X 128GB'
GROUP BY periodo_campania
ORDER BY CASE periodo_campania
    WHEN 'Antes de la Promoción' THEN 1
    WHEN 'Durante la Promoción' THEN 2
    WHEN 'Después de la Promoción' THEN 3
END;




-- 15. Análisis de Cohort

WITH primera_compra AS (
   
    SELECT id_cliente, MIN(fecha_venta) AS fecha_primera_compra
    FROM Ventas
    GROUP BY id_cliente
),
ventas_con_meses AS (
   
    SELECT
        v.id_cliente,
        DATE_FORMAT(pc.fecha_primera_compra, '%Y-%m') AS mes_cohorte,
        TIMESTAMPDIFF(MONTH, pc.fecha_primera_compra, v.fecha_venta) AS meses_despues
    FROM Ventas v
    JOIN primera_compra pc ON v.id_cliente = pc.id_cliente
)

SELECT
    mes_cohorte,
    meses_despues,
    COUNT(DISTINCT id_cliente) AS clientes_activos
FROM ventas_con_meses
GROUP BY mes_cohorte, meses_despues
ORDER BY mes_cohorte, meses_despues;



 -- 16. Margen de Beneficio por Producto

SELECT nombre AS producto,
	   (precio - costo) AS margen, 
	   ((precio - costo) * 100.0) / precio AS margen_porcentaje  
FROM Productos
ORDER BY margen_porcentaje DESC;




-- 17.Tiempo Promedio Entre Compras	

WITH compras_con_anterior AS (
    
    SELECT
        id_cliente,
        fecha_venta,
        LAG(fecha_venta) OVER (PARTITION BY id_cliente ORDER BY fecha_venta) AS fecha_compra_anterior
    FROM Ventas
),
diferencias_dias AS (
    
    SELECT
        id_cliente,
        DATEDIFF(fecha_venta, fecha_compra_anterior) AS dias_entre_compras
    FROM compras_con_anterior
    WHERE fecha_compra_anterior IS NOT NULL  
)

SELECT
    cl.nombre AS cliente,
    ROUND(AVG(d.dias_entre_compras), 1) AS promedio_dias_entre_compras
FROM diferencias_dias d
JOIN Clientes cl ON cl.id_cliente = d.id_cliente
GROUP BY cl.id_cliente, cl.nombre
ORDER BY promedio_dias_entre_compras ASC;


 
 -- 18. Productos Más Vistos vs. Comprados

CREATE TABLE producto_vistas (
    id_producto INT PRIMARY KEY,
    cantidad_vistas INT NOT NULL,

    CONSTRAINT fk_vistas_producto FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);

INSERT INTO producto_vistas (id_producto, cantidad_vistas) VALUES
(1, 120), (2, 340), (3, 90), (4, 200), (5, 500), (6, 410), (7, 150), (8, 95), (9, 60), (10, 80),
(11, 45), (12, 70), (13, 220), (14, 130), (15, 60), (16, 40), (17, 180), (18, 90), (19, 75), (20, 260),
(21, 140), (22, 55), (23, 65), (24, 100), (25, 85);


SELECT
    p.nombre AS producto,
    pv.cantidad_vistas,
    COALESCE(SUM(dv.cantidad), 0) AS unidades_compradas,
    ROUND(COALESCE(SUM(dv.cantidad), 0) / pv.cantidad_vistas * 100, 2) AS tasa_conversion_pct
FROM Productos p
JOIN producto_vistas pv ON p.id_producto = pv.id_producto
LEFT JOIN Detalle_Ventas dv ON p.id_producto = dv.id_producto
GROUP BY p.id_producto, p.nombre, pv.cantidad_vistas
ORDER BY tasa_conversion_pct DESC;



-- 19. Segmentación de Clientes (RFM)

WITH rfm_base AS (
    SELECT
        cl.id_cliente,
        cl.nombre,
        DATEDIFF(CURDATE(), MAX(v.fecha_venta)) AS recencia_dias,
        COUNT(v.id_venta) AS frecuencia,
        SUM(v.total) AS monetario
    FROM Clientes cl
    JOIN Ventas v ON cl.id_cliente = v.id_cliente
    GROUP BY cl.id_cliente, cl.nombre
)
SELECT
    nombre,
    recencia_dias,
    frecuencia,
    monetario,
    CASE
        WHEN recencia_dias <= 60 AND frecuencia >= 3 AND monetario >= 500 THEN 'Cliente VIP'
        WHEN recencia_dias <= 90 AND frecuencia >= 2 THEN 'Cliente Frecuente'
        WHEN recencia_dias > 180 THEN 'Cliente en Riesgo'
        ELSE 'Cliente Ocasional'
    END AS segmento_rfm
FROM rfm_base
ORDER BY monetario DESC;




-- 20. Predicción de Demanda Simple (categoría: Gaming)

CREATE VIEW v_ventas_mensuales_por_categoria AS
SELECT
    c.nombre AS categoria,
    YEAR(v.fecha_venta) AS anio,
    MONTH(v.fecha_venta) AS mes,
    SUM(dv.cantidad * dv.precio_unitario_congelado) AS total_mes
FROM Categorias c
JOIN Productos p ON c.id_categoria = p.id_categoria
JOIN Detalle_Ventas dv ON p.id_producto = dv.id_producto
JOIN Ventas v ON dv.id_venta = v.id_venta
GROUP BY c.nombre, YEAR(v.fecha_venta), MONTH(v.fecha_venta);


SELECT ROUND(AVG(total_mes), 2) AS prediccion_proximo_mes
FROM v_ventas_mensuales_por_categoria
WHERE categoria = 'Gaming';
