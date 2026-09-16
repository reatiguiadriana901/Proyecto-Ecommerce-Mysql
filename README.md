# Proyecto de Base de Datos para un E-commerce — AS_TechShop

## 📋 Descripción

Este proyecto diseña e implementa el núcleo de una base de datos relacional para una tienda en línea especializada en tecnología (**AS_TechShop**). El sistema gestiona de forma eficiente y segura el catálogo de productos, el inventario, los clientes y todo el ciclo de vida de las ventas, incluyendo consultas analíticas de negocio, automatización mediante triggers y eventos programados, funciones reutilizables, procedimientos almacenados transaccionales y un esquema de seguridad basado en roles.

## 👥 Integrantes

- Adriana Marcela Reátigui Mateus
- Sergio Daniel Flórez López

## 🗂️ Estructura del repositorio

Todos los scripts se encuentran en la raíz del repositorio y deben ejecutarse **en el orden numérico indicado**, ya que cada archivo depende de los objetos creados en los anteriores.

| Archivo | Contenido |
|---|---|
| `01_Esquema_y_Datos.sql` | Creación de la base de datos, todas las tablas (`CREATE TABLE`) y la carga de datos de ejemplo (`INSERT INTO`). |
| `02_Consultas_Avanzadas.sql` | Las 20 consultas de análisis y reporteo, cada una precedida por un comentario con la pregunta de negocio que responde. |
| `03_Funciones.sql` | Las 20 funciones definidas por el usuario (`CREATE FUNCTION`). |
| `04_Seguridad.sql` | Creación de roles, usuarios y asignación de permisos (`CREATE ROLE`, `CREATE USER`, `GRANT`). |
| `05_Triggers.sql` | Tabla de auditoría de precios y los 20 triggers (`CREATE TRIGGER`). |
| `06_Eventos.sql` | Tablas de apoyo para reportes/alertas y los 20 eventos programados (`CREATE EVENT`), junto con la activación del `event_scheduler`. |
| `07_Procedimientos_Almacenados.sql` | Los 20 procedimientos almacenados (`CREATE PROCEDURE`). |

## ▶️ Instrucciones de ejecución

1. Ejecutar `01_Esquema_y_Datos.sql` para crear la base de datos `AS_TechShop`, su estructura completa y cargar los datos iniciales.
2. Ejecutar en orden los archivos `02`, `03`, `05`, `06` y `07` (consultas, funciones, triggers, eventos y procedimientos).
3. Ejecutar `04_Seguridad.sql` **al final**, después de `07`: los permisos `GRANT EXECUTE ON PROCEDURE` requieren que los procedimientos ya existan en la base de datos.
4. Verificar que el `event_scheduler` esté activo (`SHOW VARIABLES LIKE 'event_scheduler';`) para que los eventos programados se ejecuten correctamente.

## 🧩 Decisiones de diseño adicionales

Algunos ejercicios del enunciado requerían datos o estructuras que no estaban contempladas en el modelo original de 6 entidades. Estas son las adiciones y por qué existen:

- **`ciudad` y `direccion_completa` en `Clientes`**: se separó la ciudad como columna propia (en vez de texto libre combinado) para permitir el Análisis Geográfico de Ventas de forma confiable.
- **`total_gastado`, `fecha_modificacion`, `nivel_lealtad`, `cuenta_activa`** (vía `ALTER TABLE`): columnas requeridas por triggers/eventos específicos que no formaban parte del esquema inicial.
- **`log_cambios_precio`**: tabla de auditoría para el trigger de cambios de precio.
- **`Promociones`**: tabla nueva para soportar el evento de desactivación automática de promociones vencidas.
- **`producto_vistas`**: tabla simulada (con datos de ejemplo) para poder comparar productos más vistos vs. más comprados, ya que el sistema no registra vistas reales.
- **`v_stock_por_categoria`, `v_ventas_por_categoria`, `v_ventas_mensuales_por_categoria`**: vistas creadas para reutilizar cálculos agregados en varias consultas (rotación de inventario y predicción de demanda por categoría).
- **Carrito Abandonado (Simulado)**: se reutilizó el estado `'Pendiente de Pago'` ya existente en `Ventas` en vez de crear una tabla de carritos real, siguiendo la indicación explícita de "(Simulado)" en el enunciado.
- **`fecha_nacimiento` en `Clientes` y `peso_kg` en `Productos`** (vía `ALTER TABLE`): requeridas por `fn_CalcularEdadCliente` y `fn_CalcularCostoEnvio` respectivamente.
- **`ubicacion` en `Productos`** (vía `ALTER TABLE`): requerida para el permiso de `Empleado_Inventario`, que solo puede modificar `stock` y `ubicacion`.
- **`Devoluciones`, `Creditos_Cliente`, `Historial_Stock`, `Notificaciones`**: tablas de soporte para los procedimientos `sp_ProcesarDevolucion`, `sp_AjustarNivelStock` y `sp_CambiarEstadoPedido`.

## 🛠️ Motor de base de datos

MySQL 8.0 o superior (se utilizan funciones de ventana como `PERCENT_RANK()` y `LAG()`, disponibles desde esta versión).
