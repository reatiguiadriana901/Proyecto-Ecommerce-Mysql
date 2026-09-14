-- script de funciones hecho por Daniel Florez Lopez
USE AS_TechShop;
DELIMITER //

CREATE FUNCTION IF NOT EXISTS fn_CalcularTotalVenta(var_id_venta INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE MONTO_TOTAL_VAR DECIMAL(10,2);
	
	SELECT SUM(cantidad * precio_unitario_congelado) 
	INTO MONTO_TOTAL_VAR 
	FROM Detalle_Ventas 
	WHERE id_venta = var_id_venta;
	
	IF MONTO_TOTAL_VAR IS NULL THEN
		RETURN 0.00;
	ELSE
		RETURN MONTO_TOTAL_VAR;
	END IF;
END //




CREATE FUNCTION IF NOT EXISTS fn_VerificarDisponibilidadStock(var_id_producto INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE var_stock int ;
	select stock into var_stock from Productos WHERE id_producto  =  var_id_producto;

	IF var_stock IS NULL THEN
		RETURN 0;
	ELSE
		RETURN var_stock;
	END IF;

	
END // 



CREATE FUNCTION IF NOT EXISTS fn_ObtenerPrecioProducto(var_id_producto INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE var_precio DECIMAL(10,2);
	select precio into var_precio from Productos WHERE id_producto  =  var_id_producto;

	IF var_precio IS NULL THEN
		RETURN 0;
	ELSE
		RETURN var_precio;
	END IF;
		
END // 




CREATE FUNCTION IF NOT EXISTS fn_CalcularEdadCliente (var_id_cliente INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE var_fecha DATE ;
    DECLARE var_edad INT;

    select fecha_registro into var_fecha from Clientes WHERE id_cliente  = var_id_cliente;

   SET var_edad = TIMESTAMPDIFF(YEAR, var_fecha, CURDATE());
   
   RETURN var_edad;
    
END //


CREATE FUNCTION IF NOT EXISTS fn_FormatearNombreCompleto (var_id_cliente INT)
RETURNS VARCHAR(200)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE var_nombre VARCHAR(100);
    DECLARE var_apellido VARCHAR(100);
    DECLARE var_estandar VARCHAR(200);

    SELECT TRIM(UPPER(nombre)), 
		TRIM(UPPER(apellido)) 
    into var_nombre,var_apellido from Clientes WHERE id_cliente = var_id_cliente;
    SET var_estandar = CONCAT(IFNULL(var_nombre, 'SIN NOMBRE'), ' ', IFNULL(var_apellido, 'SIN APELLIDO'));  
    RETURN var_estandar; 
END //



CREATE FUNCTION IF NOT EXISTS fn_EsClienteNuevo(var_id_cliente INT)
RETURNS BOOL
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE var_fecha_registro_cliente TIMESTAMP;
    DECLARE var_primera_compra TIMESTAMP;
    DECLARE var_isnew INT;

	select c.fecha_registro ,v.fecha_venta  into var_fecha_registro_cliente,var_primera_compra from Clientes c
	inner join Ventas v on c.id_cliente  = v.id_cliente 
	where  c.id_cliente = var_id_cliente
	ORDER BY v.fecha_venta  ASC LIMIT 1;
	
	SET var_isnew = TIMESTAMPDIFF(DAY,var_fecha_registro_cliente,var_primera_compra);
	IF var_isnew <= 30 THEN
		return TRUE;
	ELSE 
		RETURN FALSE;
	END IF;
END //


CREATE FUNCTION IF NOT EXISTS fn_AplicarDescuento (porcentaje INT,monto DECIMAL(10,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
   DECLARE total decimal(10,2);
   set total =  monto * (1-(porcentaje/100));
   RETURN total;	
END // 


CREATE FUNCTION IF NOT EXISTS fn_ObtenerUltimaFechaCompra(var_id_cliente INT)
RETURNS DATE
DETERMINISTIC
READS SQL DATA
BEGIN
	declare ultima_venta DATE ;	
	select fecha_venta into ultima_venta from Ventas WHERE id_cliente = var_id_cliente  order by fecha_venta desc limit 1;
    return  ultima_venta;
END //

CREATE FUNCTION IF NOT EXISTS fn_ValidarFormatoEmail(var_email VARCHAR(255))
RETURNS TINYINT(1)
DETERMINISTIC
NO SQL
BEGIN

    IF var_email IS NOT NULL 
       AND var_email NOT LIKE '% %' 
       AND var_email LIKE '_%@_%.__%' THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END //


CREATE FUNCTION IF NOT EXISTS fn_ObtenerNombreCategoria (var_id_producto INT)
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA 
BEGIN
	DECLARE var_nombre_categoria varchar(255);
	SELECT c.nombre into  var_nombre_categoria from  Productos  p
	INNER JOIN Categorias c on c.id_categoria = p.id_categoria
	Where p.id_producto = var_id_producto LIMIT 1;
	
	
	  IF var_nombre_categoria IS NULL then
	  	return null;
	  else
	  	return  var_nombre_categoria;
	  END IF;
END //


CREATE FUNCTION IF NOT EXISTS fn_ContarVentasCliente (var_id_cliente INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE venta_total int ;
	SELECT COUNT(v.id_venta) INTO venta_total from Ventas v where v.id_cliente = var_id_cliente;
    
    IF venta_total IS NULL THEN
    	RETURN 0;
    ELSE
    	RETURN venta_total;
    END IF;
END //

DELIMITER ;
