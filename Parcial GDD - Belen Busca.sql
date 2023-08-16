-- PARCIAL - BELEN BUSCA --

--SQL
SELECT zona_detalle, 

	   count(distinct depo_codigo) cant_depositosx_zona, 

	  (select count(distinct prod_codigo) 
	   from Producto join stock on stoc_producto = prod_codigo join DEPOSITO d2 on d2.depo_codigo = stoc_deposito
	   where prod_codigo in (select comp_producto from Composicion) and d2.depo_zona = zona_codigo) cant_prod_compuestos,

	   (select top 1 item_producto 
	    from Factura join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
					 join STOCK s2 on item_producto = s2.stoc_producto join DEPOSITO d2 on s2.stoc_deposito = d2.depo_codigo
	    where year(fact_fecha) = 2012 and d2.depo_zona = zona_codigo
		group by item_producto
		having sum(s2.stoc_cantidad) > 1
		order by sum(item_cantidad*item_precio) desc) prod_mas_vendido,

		(select top 1 empl_codigo 
		 from Empleado join Factura on fact_vendedor = empl_codigo join DEPOSITO on depo_encargado = empl_codigo
		 where depo_zona = zona_codigo
		 group by empl_codigo
		 order by sum(fact_total) desc) mejor_encargado

FROM Zona join DEPOSITO on depo_zona = zona_codigo
GROUP BY zona_detalle, zona_codigo
HAVING count(distinct depo_codigo) >= 3
order by (select top 1 sum(fact_total) 
		 from Empleado join Factura on fact_vendedor = empl_codigo join DEPOSITO on depo_encargado = empl_codigo
		 where depo_zona = zona_codigo
		 group by empl_codigo
		 order by sum(fact_total) desc)

-- Aca me olvide el order by :(

go
-- TSQL
-- factura -> vendedor - empleado 
-- fk si borro un empleado no puede quedar en la factura como fact vendedor 
-- si inserto una factura / modifico un fact vendedor tiene que existir ese empleado
create trigger vendedor_factura on Factura for insert, update as
BEGIN
	declare @cabecero_facturas char(14), @vendedor numeric(6,0) 
	declare cursorFacturas cursor for
	select fact_tipo+fact_sucursal+fact_numero, fact_vendedor from inserted
	OPEN cursorFacturas
	FETCH NEXT FROM cursorFacturas INTO @cabecero_facturas, @vendedor
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		if not exists(select empl_codigo from Empleado where empl_codigo = @vendedor)
		ROLLBACK
		FETCH NEXT FROM cursorFacturas INTO @cabecero_facturas, @vendedor
	END
	close cursorFacturas
	DEALLOCATE cursorFacturas
END

go

create trigger empleado_eliminado on Empleado for delete as
BEGIN
	declare @empleado numeric(6,0) 
	declare cursorEmpleado cursor for
	select empl_codigo from deleted
	OPEN cursorEmpleado
	FETCH NEXT FROM cursorEmpleado INTO @empleado
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		if exists(select * from Factura where fact_vendedor = @empleado)
			ROLLBACK
		FETCH NEXT FROM cursorEmpleado INTO @empleado
	END
	close cursorEmpleado
	DEALLOCATE cursorEmpleado
END

/*CORRECCION REINOSA: TSQL 8 
- NO TIENE SENTIDO EL CURSOR PORQUE HACER ROLLBACK CON QUE UNO ESTE MAL VUELVE TODO.  
- NO HACE FALTA QUE SEA PARA UPDATE. 
- FALTA EL TRIGGER EN CLIENTES INSERT, UPDATE.*/