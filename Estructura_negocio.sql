
DROP DATABASE IF EXISTS AS_TechShop;
CREATE DATABASE AS_TechShop;
USE AS_TechShop;
 
-- ------------------------
-- CREACIÓN DE TABLAS
-- ------------------------
 
CREATE TABLE Categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT NULL
);
 
CREATE TABLE Proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    email_contacto VARCHAR(150) NOT NULL UNIQUE,
    telefono_contacto VARCHAR(50) NULL
);
 
CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    ciudad VARCHAR(100) NULL,
    direccion_completa TEXT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
CREATE TABLE Productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    descripcion TEXT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    costo DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    ubicacion VARCHAR(100) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    id_categoria INT NOT NULL,
    id_proveedor INT NOT NULL,
 
    CONSTRAINT chk_precio_positivo CHECK (precio > 0),
    CONSTRAINT chk_costo_positivo CHECK (costo >= 0),
    CONSTRAINT chk_stock_no_negativo CHECK (stock >= 0),
 
    CONSTRAINT fk_productos_categorias FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria),
    CONSTRAINT fk_productos_proveedores FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);
 
CREATE TABLE Ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL DEFAULT 'Pendiente de Pago',
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
 
    CONSTRAINT fk_ventas_clientes FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);
 
CREATE TABLE Detalle_Ventas (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario_congelado DECIMAL(10, 2) NOT NULL,
 
    CONSTRAINT chk_cantidad_positiva CHECK (cantidad > 0),
 
    CONSTRAINT fk_detalle_ventas FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_productos FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
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

-- Tabla correspondiente al punto 5 de los triggers

CREATE TABLE auditoria_nuevo_cliente(
id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
id_cliente INT NOT NULL,
nombre VARCHAR(100),
fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_id_cliente FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

-- Tabla correspondiente al punto 1 de los Eventos


CREATE TABLE reporte_ventas_semanales(
    id_reporte_semanal INT AUTO_INCREMENT PRIMARY KEY,
    cantidad INT,
    total DECIMAL(10,2),
    fecha_reporte TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------
-- INSERCIÓN DE DATOS
-- ------------------------
 

INSERT INTO Categorias (nombre, descripcion) VALUES
('Computadores', 'Laptops, PCs de escritorio y monitores.'),
('Celulares', 'Smartphones y smartwatches.'),
('Accesorios', 'Cargadores, cables, fundas y power banks.'),
('Audio', 'Audífonos, parlantes y barras de sonido.'),
('Televisores y Monitores', 'Smart TVs y monitores especializados.'),
('Gaming', 'Consolas, periféricos y accesorios para gamers.');
 

INSERT INTO Proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechSupplier Inc', 'contacto@techsupplier.com', '+1 555-0199'),
('Global Compu Parts', 'ventas@globalcompuparts.com', '+57 300-1234567'),
('SoundWave Distribuciones', 'info@soundwave.com', '+57 315-8887766'),
('GameZone Supplies', 'ventas@gamezonesupplies.com', '+57 320-4445566');
 

INSERT INTO Clientes (nombre, apellido, email, contrasena, ciudad, direccion_completa, fecha_registro) VALUES
('Adriana', 'Gomez', 'adriana@mail.com', '$2b$12$SecureHashForAdriana', 'Bucaramanga', 'Bucaramanga, Santander', '2026-01-10 14:30:00'),
('Sergio', 'Perez', 'sergio@mail.com', '$2b$12$SecureHashForSergio', 'Bogotá', 'Bogotá, Cundinamarca', '2026-01-12 09:15:00'),
('Juan', 'Rodriguez', 'juan@mail.com', '$2b$12$HashJuan', 'Medellín', 'Medellín, Antioquia', '2026-01-25 18:20:00'),
('Maria', 'Lopez', 'maria@mail.com', '$2b$12$HashMaria', 'Cali', 'Cali, Valle', '2026-01-20 11:00:00'),
('Carlos', 'Mendoza', 'carlos@mail.com', '$2b$12$HashCarlos', 'Barranquilla', 'Barranquilla, Atlántico', '2026-01-25 16:45:00'),
('Andres', 'Castro', 'andres@mail.com', '$2b$12$HashAndres', 'Bucaramanga', 'Bucaramanga, Santander', '2026-01-15 10:00:00'),
('Camila', 'Díaz', 'camila@mail.com', '$2b$12$HashCamila', 'Bogotá', 'Bogotá, Cundinamarca', '2026-02-20 11:30:00'),
('Mateo', 'Silva', 'mateo@mail.com', '$2b$12$HashMateo', 'Medellín', 'Medellín, Antioquia', '2026-04-05 14:15:00'),
('Valeria', 'Rojas', 'valeria@mail.com', '$2b$12$HashValeria', 'Cali', 'Cali, Valle', '2026-05-12 09:00:00'),
('Lucas', 'Torres', 'lucas@mail.com', '$2b$12$HashLucas', 'Bucaramanga', 'Bucaramanga, Santander', '2026-07-22 16:40:00');
 

INSERT INTO Productos (nombre, descripcion, precio, costo, stock, sku, id_categoria, id_proveedor) VALUES
('Laptop UltraSlim 14"', 'Ligera, ideal para trabajo diario', 950.00, 650.00, 25, 'COMP-ULT-14', 1, 2),
('Laptop Gamer RTX', 'Tarjeta gráfica dedicada, alto rendimiento', 1800.00, 1300.00, 15, 'COMP-GAM-RTX', 1, 2),
('PC de Escritorio Ryzen 5', 'Equipo completo para oficina y estudio', 900.00, 600.00, 10, 'COMP-PC-R5', 1, 2),
('Monitor 27" 4K', 'Panel IPS, alta resolución', 350.00, 220.00, 30, 'COMP-MON-27', 1, 2),
('Smartphone X 128GB', 'Pantalla OLED, 128GB de almacenamiento', 800.00, 500.00, 50, 'CEL-SPX-128', 2, 1),
('Smartphone Pro Max 256GB', 'Cámara triple, batería de larga duración', 1200.00, 800.00, 20, 'CEL-SPPM-256', 2, 1),
('Smartphone Económico 64GB', 'Ideal para uso básico diario', 250.00, 150.00, 60, 'CEL-SPE-64', 2, 1),
('Smartwatch Deportivo', 'Monitor de ritmo cardíaco y GPS', 180.00, 90.00, 40, 'CEL-SW-DEP', 2, 1),
('Cargador Rápido 65W', 'Compatible con USB-C', 35.00, 15.00, 100, 'ACC-CAR-65W', 3, 1),
('Power Bank 20000mAh', 'Carga rápida, doble salida USB', 45.00, 22.00, 80, 'ACC-PB-20K', 3, 1),
('Hub USB-C 7 en 1', 'HDMI, USB 3.0, lector SD', 55.00, 28.00, 45, 'ACC-HUB-7', 3, 2),
('Funda Protectora Smartphone', 'Resistente a caídas', 20.00, 8.00, 150, 'ACC-FUN-SP', 3, 1),
('Audífonos Bluetooth ANC', 'Cancelación de ruido activa', 150.00, 75.00, 60, 'AUD-BT-ANC', 4, 3),
('Parlante Portátil Bluetooth', 'Resistente al agua, 12h de batería', 80.00, 40.00, 50, 'AUD-PAR-BT', 4, 3),
('Audífonos Gamer con Micrófono', 'Sonido envolvente 7.1', 65.00, 30.00, 55, 'AUD-GAM-MIC', 4, 3),
('Barra de Sonido 2.1', 'Subwoofer incluido', 120.00, 60.00, 25, 'AUD-BAR-21', 4, 3),
('Televisor 4K 55" Smart TV', 'Smart TV con sistema operativo integrado', 600.00, 400.00, 20, 'TV-4K-55', 5, 2),
('Televisor 4K 65" Smart TV', 'Pantalla grande, HDR10', 900.00, 620.00, 12, 'TV-4K-65', 5, 2),
('Monitor Gamer 144Hz 24"', 'Baja latencia, ideal para esports', 280.00, 170.00, 35, 'TV-MON-144', 5, 2),
('Consola de Videojuegos', 'Última generación, 1TB de almacenamiento', 500.00, 350.00, 18, 'GAM-CONS-X', 6, 4),
('Control Inalámbrico', 'Compatible con múltiples plataformas', 60.00, 30.00, 70, 'GAM-CTRL-IN', 6, 4),
('Silla Gamer Ergonómica', 'Soporte lumbar ajustable', 250.00, 140.00, 15, 'GAM-SILLA', 6, 4),
('Mousepad Gaming XL', 'Superficie extendida, base antideslizante', 25.00, 10.00, 90, 'GAM-MP-XL', 6, 4),
('Teclado Mecánico RGB', 'Switches red, iluminación personalizable', 80.00, 35.00, 45, 'GAM-TEC-RGB', 6, 4),
('Mouse Gamer Óptico', 'Sensor de alta precisión, 6 botones', 45.00, 20.00, 65, 'GAM-MOU-OPT', 6, 4);
 

INSERT INTO Ventas (id_cliente, fecha_venta, estado, total) VALUES
(1, '2026-01-15 10:00:00', 'Entregado', 950.00),
(2, '2026-01-18 11:30:00', 'Entregado', 90.00),
(3, '2026-02-05 09:15:00', 'Procesando', 1800.00),
(1, '2026-02-10 15:40:00', 'Entregado', 140.00),
(4, '2026-02-15 14:00:00', 'Entregado', 600.00),
(6, '2026-02-20 16:20:00', 'Entregado', 500.00),
(7, '2026-03-01 11:20:00', 'Entregado', 1005.00),
(8, '2026-03-10 16:45:00', 'Entregado', 150.00),
(9, '2026-03-15 10:10:00', 'Entregado', 80.00),
(10, '2026-03-20 19:30:00', 'Entregado', 500.00),
(1, '2026-04-02 12:00:00', 'Entregado', 125.00),
(2, '2026-04-10 09:40:00', 'Enviado', 1200.00),
(3, '2026-04-18 13:10:00', 'Entregado', 350.00),
(5, '2026-04-25 17:00:00', 'Entregado', 900.00),
(6, '2026-05-05 10:30:00', 'Entregado', 250.00),
(7, '2026-05-12 15:00:00', 'Entregado', 200.00),
(1, '2026-05-20 11:45:00', 'Entregado', 900.00),
(8, '2026-06-01 14:15:00', 'Procesando', 280.00),
(9, '2026-06-10 16:50:00', 'Entregado', 115.00),
(10, '2026-06-18 18:20:00', 'Entregado', 120.00),
(2, '2026-07-01 09:00:00', 'Entregado', 105.00),
(1, '2026-07-15 12:30:00', 'Cancelado', 1800.00),
(4, '2026-08-05 11:00:00', 'Entregado', 835.00),
(6, '2026-08-20 13:40:00', 'Entregado', 120.00),
(1, '2026-09-05 10:00:00', 'Pendiente de Pago', 80.00);
 

INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) VALUES
(1, 5, 1, 800.00), (1, 13, 1, 150.00),
(2, 9, 2, 35.00), (2, 12, 1, 20.00),
(3, 2, 1, 1800.00),
(4, 14, 1, 80.00), (4, 21, 1, 60.00),
(5, 17, 1, 600.00),
(6, 7, 2, 250.00),
(7, 1, 1, 950.00), (7, 11, 1, 55.00),
(8, 13, 1, 150.00),
(9, 10, 1, 45.00), (9, 9, 1, 35.00),
(10, 20, 1, 500.00),
(11, 24, 1, 80.00), (11, 25, 1, 45.00),
(12, 6, 1, 1200.00),
(13, 4, 1, 350.00),
(14, 18, 1, 900.00),
(15, 22, 1, 250.00),
(16, 8, 1, 180.00), (16, 12, 1, 20.00),
(17, 3, 1, 900.00),
(18, 19, 1, 280.00),
(19, 15, 1, 65.00), (19, 23, 2, 25.00),
(20, 16, 1, 120.00),
(21, 9, 3, 35.00),
(22, 2, 1, 1800.00),
(23, 5, 1, 800.00), (23, 9, 1, 35.00),
(24, 21, 2, 60.00),
(25, 14, 1, 80.00);
