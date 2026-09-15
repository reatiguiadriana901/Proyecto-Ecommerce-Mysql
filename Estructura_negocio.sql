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
    direccion_envio TEXT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE Productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    descripcion TEXT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    costo DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    sku VARCHAR(50) NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    id_categoria INT NOT NULL,
    id_provider INT NOT NULL, 
    
    
    CONSTRAINT chk_precio_positivo CHECK (precio > 0),
    CONSTRAINT chk_costo_positivo CHECK (costo >= 0),
    CONSTRAINT chk_stock_no_negativo CHECK (stock >= 0),
    

    CONSTRAINT fk_productos_categorias FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria),
    CONSTRAINT fk_productos_proveedores FOREIGN KEY (id_provider) REFERENCES Proveedores(id_proveedor)
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

-- ------------------------
-- INSERCION DE DATOS
-- ------------------------

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Detalle_Ventas;
TRUNCATE TABLE Ventas;
TRUNCATE TABLE Productos;
TRUNCATE TABLE Clientes;
TRUNCATE TABLE Proveedores;
TRUNCATE TABLE Categorias;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos, celulares, computadores y accesorios tecnológicos.'),
('Ropa', 'Prendas de vestir para todas las edades.'),
('Hogar', 'Muebles, decoración y utensilios de cocina.');

INSERT INTO Proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechSupplier Inc', 'contacto@techsupplier.com', '+1 555-0199'),
('Moda Global Ltda', 'ventas@modaglobal.com', '+57 300-1234567'),
('Home Comfort', 'info@homecomfort.com', '+57 315-8887766');

INSERT INTO Clientes (nombre, apellido, email, contrasena, direccion_envio, fecha_registro) VALUES
('Adriana', 'Gomez', 'adriana@mail.com', '$2b$12$SecureHashForAdriana', 'Bucaramanga, Santander', '2026-01-10 14:30:00'),
('Sergio', 'Perez', 'sergio@mail.com', '$2b$12$SecureHashForSergio', 'Bogotá, Cundinamarca', '2026-01-12 09:15:00'),
('Juan', 'Rodriguez', 'juan@mail.com', '$2b$12$HashJuan', 'Medellín, Antioquia', '2026-01-25 18:20:00'),
('Maria', 'Lopez', 'maria@mail.com', '$2b$12$HashMaria', 'Cali, Valle', '2026-01-20 11:00:00'),
('Carlos', 'Mendoza', 'carlos@mail.com', '$2b$12$HashCarlos', 'Barranquilla, Atlántico', '2026-01-25 16:45:00'),
('Andres', 'Castro', 'andres@mail.com', '$2b$12$HashAndres', 'Bucaramanga, Santander', '2026-01-15 10:00:00'),
('Camila', 'Díaz', 'camila@mail.com', '$2b$12$HashCamila', 'Bogotá, Cundinamarca', '2026-02-20 11:30:00'),
('Mateo', 'Silva', 'mateo@mail.com', '$2b$12$HashMateo', 'Medellín, Antioquia', '2026-04-05 14:15:00'),
('Valeria', 'Rojas', 'valeria@mail.com', '$2b$12$HashValeria', 'Cali, Valle', '2026-05-12 09:00:00'),
('Lucas', 'Torres', 'lucas@mail.com', '$2b$12$HashLucas', 'Bucaramanga, Santander', '2026-07-22 16:40:00');

INSERT INTO Productos (nombre, descripcion, precio, costo, stock, sku, id_categoria, id_provider) VALUES
('Smartphone X', 'Pantalla OLED, 128GB', 800.00, 500.00, 50, 'TECH-SPH-X', 1, 1),
('Audífonos Bluetooth', 'Cancelación de ruido activa', 150.00, 75.00, 100, 'TECH-AUD-BT', 1, 1),
('Camiseta de Algodón', 'Color negro, 100% algodón', 25.00, 10.00, 200, 'CLTH-CAM-N', 2, 2),
('Jeans Slim Fit', 'Pantalón de mezclilla azul', 45.00, 20.00, 150, 'CLTH-JNS-S', 2, 2),
('Lámpara de Escritorio', 'Luz LED regulable', 35.00, 15.00, 30, 'HOME-LAM-LED', 3, 3),
('Cafetera Express', 'Presión de 15 bares', 120.00, 60.00, 15, 'HOME-CAF-EXP', 3, 3),
('Televisor 4K 55"', 'Smart TV con IA', 600.00, 400.00, 20, 'TECH-TV-55', 1, 1),
('Teclado Mecánico', 'Luces RGB, switches red', 80.00, 35.00, 45, 'TECH-TEC-MEC', 1, 1),
('Chaqueta de Cuero', 'Estilo motociclista, negra', 120.00, 55.00, 60, 'CLTH-CHQ-C', 2, 2),
('Zapatos Deportivos', 'Suela de alta resistencia', 75.00, 30.00, 80, 'CLTH-ZAP-DEP', 2, 2),
('Espejo de Sala', 'Marco de madera rústica', 45.00, 18.00, 15, 'HOME-ESP-MAD', 3, 3),
('Sartén Antiadherente', 'Teflón de alta calidad', 30.00, 12.00, 120, 'HOME-SAR-ANT', 3, 3);

INSERT INTO Ventas (id_cliente, fecha_venta, estado, total) VALUES
(1, '2026-08-10 14:30:00', 'Entregado', 950.00),
(2, '2026-08-15 09:15:00', 'Entregado', 70.00),
(3, '2026-09-01 18:20:00', 'Procesando', 800.00),
(1, '2026-09-05 11:00:00', 'Entregado', 155.00),
(4, '2026-09-12 16:45:00', 'Enviado', 150.00),
(6, '2026-02-15 14:00:00', 'Entregado', 680.00),
(7, '2026-03-10 11:20:00', 'Entregado', 120.00),
(8, '2026-04-20 16:45:00', 'Entregado', 150.00),
(9, '2026-05-05 10:10:00', 'Entregado', 45.00),
(10, '2026-07-25 19:30:00', 'Entregado', 60.00),
(1, '2026-08-20 15:00:00', 'Entregado', 80.00),
(6, '2026-08-22 13:10:00', 'Entregado', 120.00),
(2, '2026-09-02 09:40:00', 'Procesando', 600.00);

INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) VALUES
(1, 1, 1, 800.00),
(1, 2, 1, 150.00),
(2, 3, 1, 25.00),
(2, 4, 1, 45.00),
(3, 1, 1, 800.00),
(4, 6, 1, 120.00),
(4, 5, 1, 35.00),
(5, 2, 1, 150.00),
(6, 7, 1, 600.00),
(6, 8, 1, 80.00),
(7, 9, 1, 120.00),
(8, 10, 2, 75.00),
(9, 11, 1, 45.00),
(10, 12, 2, 30.00),
(11, 8, 1, 80.00),
(12, 9, 1, 120.00),
(13, 7, 1, 600.00);