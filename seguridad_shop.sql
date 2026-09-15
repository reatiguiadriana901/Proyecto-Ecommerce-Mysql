

USE AS_TechShop;

ALTER TABLE Productos ADD COLUMN ubicacion VARCHAR(100) NULL;

-- Tabla de auditoría general (acciones importantes sobre la base de datos)
CREATE TABLE Auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(100) NOT NULL,
    accion VARCHAR(255) NOT NULL,
    tabla_afectada VARCHAR(100) NULL,
    fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla que guarda el historial de cambios de precio (para el Auditor_Financiero)
CREATE TABLE Logs_Precios (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_logprecio_producto FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);



-- 1. ROL: Administrador_Sistema

CREATE ROLE IF NOT EXISTS 'Administrador_Sistema';

GRANT ALL PRIVILEGES ON AS_TechShop.* TO 'Administrador_Sistema';


-- 2. ROL: Gerente_Marketing

CREATE ROLE IF NOT EXISTS 'Gerente_Marketing';

GRANT SELECT ON AS_TechShop.Ventas TO 'Gerente_Marketing';
GRANT SELECT ON AS_TechShop.Detalle_Ventas TO 'Gerente_Marketing';
GRANT SELECT ON AS_TechShop.Clientes TO 'Gerente_Marketing';


-- 3. ROL: Analista_Datos

CREATE ROLE IF NOT EXISTS 'Analista_Datos';

GRANT SELECT ON AS_TechShop.Categorias TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Proveedores TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Clientes TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Productos TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Ventas TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Detalle_Ventas TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Devoluciones TO 'Analista_Datos';
GRANT SELECT ON AS_TechShop.Creditos_Cliente TO 'Analista_Datos';

-- 4. ROL: Empleado_Inventario

CREATE ROLE IF NOT EXISTS 'Empleado_Inventario';

GRANT SELECT ON AS_TechShop.Productos TO 'Empleado_Inventario';

GRANT UPDATE (stock, ubicacion) ON AS_TechShop.Productos TO 'Empleado_Inventario';


GRANT EXECUTE ON PROCEDURE AS_TechShop.sp_AjustarNivelStock TO 'Empleado_Inventario';



-- 5. ROL: Atencion_Cliente

CREATE ROLE IF NOT EXISTS 'Atencion_Cliente';

GRANT SELECT ON AS_TechShop.Clientes TO 'Atencion_Cliente';
GRANT SELECT ON AS_TechShop.Ventas TO 'Atencion_Cliente';
GRANT SELECT ON AS_TechShop.Detalle_Ventas TO 'Atencion_Cliente';
GRANT UPDATE (direccion_envio) ON AS_TechShop.Clientes TO 'Atencion_Cliente';
GRANT UPDATE (estado) ON AS_TechShop.Ventas TO 'Atencion_Cliente';

-- Procedimientos útiles para esta labor
GRANT EXECUTE ON PROCEDURE AS_TechShop.sp_ActualizarDireccionCliente TO 'Atencion_Cliente';
GRANT EXECUTE ON PROCEDURE AS_TechShop.sp_CambiarEstadoPedido TO 'Atencion_Cliente';
GRANT EXECUTE ON PROCEDURE AS_TechShop.sp_ObtenerHistorialComprasCliente TO 'Atencion_Cliente';
GRANT EXECUTE ON PROCEDURE AS_TechShop.sp_RegistrarNuevoCliente TO 'Atencion_Cliente';



-- 6. ROL: Auditor_Financiero
CREATE ROLE IF NOT EXISTS 'Auditor_Financiero';

GRANT SELECT ON AS_TechShop.Ventas TO 'Auditor_Financiero';
GRANT SELECT ON AS_TechShop.Detalle_Ventas TO 'Auditor_Financiero';
GRANT SELECT ON AS_TechShop.Productos TO 'Auditor_Financiero';
GRANT SELECT ON AS_TechShop.Logs_Precios TO 'Auditor_Financiero';



-- 7. Usuario administrador
CREATE USER IF NOT EXISTS 'admin_user'@'%' IDENTIFIED BY 'lavidaesunbanano';
GRANT 'Administrador_Sistema' TO 'admin_user'@'%';
SET DEFAULT ROLE 'Administrador_Sistema' TO 'admin_user'@'%';

-- 8. Usuario de marketing
CREATE USER IF NOT EXISTS 'marketing_user'@'%' IDENTIFIED BY 'lavidaesunbanano';
GRANT 'Gerente_Marketing' TO 'marketing_user'@'%';
SET DEFAULT ROLE 'Gerente_Marketing' TO 'marketing_user'@'%';

-- 9. Usuario de inventario
CREATE USER IF NOT EXISTS 'inventory_user'@'%' IDENTIFIED BY 'lavidaesunbanano';
GRANT 'Empleado_Inventario' TO 'inventory_user'@'%';
SET DEFAULT ROLE 'Empleado_Inventario' TO 'inventory_user'@'%';

-- 10. Usuario de atención al cliente
CREATE USER IF NOT EXISTS 'support_user'@'%' IDENTIFIED BY 'lavidaesunbanano';
GRANT 'Atencion_Cliente' TO 'support_user'@'%';
SET DEFAULT ROLE 'Atencion_Cliente' TO 'support_user'@'%';




-- 11. IMPEDIR QUE Analista_Datos EJECUTE DELETE O TRUNCATE
GRANT SELECT, DELETE, DROP, INSERT, UPDATE ON AS_TechShop.* TO 'Analista_Datos';

REVOKE DELETE, DROP, INSERT, UPDATE ON AS_TechShop.* FROM 'Analista_Datos';

FLUSH PRIVILEGES;

