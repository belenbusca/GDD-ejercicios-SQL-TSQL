--PRACTIA TSQL
/* < UN POCO DE TEORIA DE REPASO >
3 tipos de ejerciicos: funcion, proc o trigger

 - GRAN DIFERENCIA FUNC VS PROC -
Funcion -> no puede modificar datos
Procuders -> puede modificar datos

 - PROC VS TRIGGER -
Ambos modifican datos
Procuders -> se ejecuta manualmente o programada (ej cada cierto tiempo, mensualmente, etc), 
             es un objeto aislado, no asociado a una tabla
			 si tengo que "arreglar cosas", modificar cosas hacia atras, corregir, rectificar datos

Trigger -> se ejecuta a partir de un evento (INSERT, DELETE, UPDATE q se haga de una tabla), 
           se dispara, automaticamente, esta asociado a una tabla. No se puede controlar cuando se ejecuta.
		   a futuro, si se sabe que la regla se cumple, potencialmente se puede hacer un trigger.
		   Una restriccion de FK son trigger, si yo quiero borrar un producto ya vendido en item factura, por fk
		   el producto ya existe en otra tabla. Esto se implementa con un trigger instead of delete.
		   Se usa mucho para validar, controlar, muy usado en reglas automaticas y reglas de negocio. 
		   Beneficioso porque el trigger se encarga de la base de datos mientras las reglas esten claras, 
		   no hay errores externos del programador.

 ------------- TEORIA TRIGGERS -------------
TRIGGER SOBRE X_TABLA PARA INSERTED, DELETED, UPDATE
 
Por ej.: UPDATE PRODUCTO SET PROD_PRECIO = PRECIO_NUEVO
 INSERTED -> FILAS QUE SE VAN A INSERTAR / INSERTARON / DESPUES DE LA MODIFICACION -> Con el ej.: PROD_PRECIO = PRECIO_NEUVO
 DELETED  -> FILAS QUE SE VAN A BORRAR   / BORRARON   / ANTES DE LA MODIFICACION   -> Con el ej.: PROD_PRECIO = PRECIO_VIEJO

TRIGGER SE EJECUTA POR INSERT:
 INSERTED - N FILAS
 DELETED  - 0 FILAS

TRIGGER SE EJECUTA POR DELETED:
 INSERTED - 0 FILAS
 DELETED  - N FILAS

TRIGGER SE EJECUTA POR UPDATE:  
 INSERTED - N FILAS
					---> CANT FILAS INSERTED = CANT FILAS DELETED
 DELETED  - N FILAS
 
INSERT MASIVO EN SQL SERVER
 En SQL Server el insert es masivo, es decir, yo puedo volver para atras lo que inserte, pero tiene que ser todo, no puedo
 volver una fila para atras, por eso es masivo. (En MYSQL y Oracle es diferente, los triggers se pueden ejecutar por CADA fila o masivos)
 LAS OPERACIONES CON TRIGGER DE SQLSERVER SIEMPRE ES MASIVO, hay que considerar que entra + de 1 transaccion a la vez, 
 el trigger es disparado por 1 o N filas que quieren entrar A LA VEZ.
 Si hacemos un insert de un select, si quiere insertar 4 filas, en el inserted habra 4 filas. 
 Nunca hagamos los triggers como si fuesen operaciones unitarias de a 1 fila, siempre N FILAS. 
 Atomico, una transaccion, si falla algo, se vuelve TODO para atras, no se hace nada. 

 -------- FOR --------
 CUANDO SIRVE FOR (AFTER):
 Son utiles cuando las cosas no quedan a medio cargar.
 Por ejemplo, son utiles cuando quiero hacer un control de una factura, porque una factura no puede quedar a medio cargar, 
 y hay que vovler TODO para atras.
 Intentar usar siempre after a menos que se especifique lo contrario porque al ser masivo y volver todo para atras, 
 es mas SEGURO
 VA POR LO QUE ESTA MAL (Para entender ver ej18)

 -------- INSTEAD OF --------
 CUANDO SIRVE INSTEAD OF:
 Se usa para palicar logicas mas especificas por cada fila.
 Aca no tendria sentido usarlo con facturas porque no pueden quedar incompletas.
 Cuando necesito hacer un control dentro del codigo donde tenga que hacer un tratamiento especifico por cada fila
 y ver si entra o no. Por ejemplo:
	Necesito un trigger solamente para aquellos alumnos que hayan cursado paradigmas. Tengo que dejar entrar a unos si y otros no.
SOLO USARLO CUNADO SE ESPECIFIQUE EN EL ENUNCIADO "Enrtan SOLO los productos que cumplen x cosa", sino usar for q es mas seguro.
VA POR LO QUE ESTA BIEN (Para entender ver ej18) -> vas a tener que insertar/deletear o lo que sea poniendo en el select 
lo que esta bien, lo que cumple 

COMO FUNCIONA: Reemplaza la operacion que llamo al trigger por lo que programamos.
	Si tiramos un insert dice, en vez de hacer el insert hace esto. Si para algunas filas habia que hacer el insert, hay que
	ponerlo dentro del codigo del trigger.


SE PUEDEN COMBINAR INSERT, DELETE Y UPDATE DENTRO DE UN MISMO TRIGGER, SIEMPRE Y CUANDO EL MOMENTO DE DISPARARLO O EL 
TRATAMIENTO COINCIDA. Se usa if dentro del mismo trigger para separarlos y hacerlo en uno solo.
Si no tienen el mismo tratamiento o no se disparan al mismo tiempo, se hacen 2 trigger por separado.

-----> PREGUNTA DE HENRY: LA FK, EL TRIGGER, ES INSTEAD OF O ES AFTER / FOR?
Es after porque vuelve toda la tansaccion para atras ante el error. Por ej:.
si yo hago delete from Cliente, es decir, que borre todos los clientes, va a dar error de FK, 
porque las facturas dependen del cliente, tienen la fk fact_cliente. Vuelve toda la transaccion para atras, 
no va a borrar los clientes que no estan en facturas y los que si estan no. Si alguno da error hace ROLLBACK

  ---------------- EJERCICIO N°1 ----------------------
1.Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/

create function ej_1 (@articulo char(8), @deposito char(2))
returns varchar(50)
AS
begin
	declare @cant_actual decimal(12, 2), @cant_max decimal(12, 2), @retorno varchar(50)

	SELECT @cant_actual = stoc_cantidad, @cant_max = stoc_stock_maximo 
	FROM STOCK
	WHERE stoc_producto = @articulo and stoc_deposito = @deposito

	if @cant_actual >= @cant_max
		set @retorno = 'DEPOSITO COMPLETO'
	else
		if @cant_max != 0
			set @retorno = 'OCUPACION DEL DEPOSITO ' + str((@cant_actual/ @cant_max)*100.00) + '%'
		else 
			set @retorno = 'CANTIDAD MAXIMA 0'--POR SI NO DIVIDE POR 0
	return @retorno
end
go

create function ej1 (@articulo char(8), @deposito char(2))
returns varchar(50)
AS
begin
	return(select case when(stoc_cantidad > stoc_stock_maximo) then 'DEPOSITO COMPLETO'
				  else 'OCUPACION DEL DEPOSITO ' + str(stoc_cantidad/ stoc_stock_maximo*100) + '%'
		   from STOCK where stoc_producto = @articulo and stoc_deposito = @deposito)
end
go
--- para ver si funca
select stoc_producto, stoc_deposito, dbo.ej_1(stoc_producto, stoc_deposito)
from STOCK
go
/* ---------------- EJERCICIO N°2 ----------------------
2.Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/

create function ej_2 (@articulo char(8), @fecha smalldatetime) 
returns decimal(12, 2)
begin
	declare @stock_actual decimal(12, 2)
	declare @cant_vendida decimal(12, 2)

	select @stock_actual = sum(stoc_cantidad)
	from STOCK
	where stoc_producto = @articulo

	select @cant_vendida = sum(item_cantidad)
	from Item_Factura JOIN Factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
	where item_producto = @articulo and fact_fecha > @fecha 

	return @stock_actual + @cant_vendida
end
go
-- OTRA FORMA DE HACERLO BY HENRRY
-- Es lo mismo pero sin variables.

create function ej2 (@producto char(8), @fecha smalldatetime)
returns decimal(12, 2)
as
begin
	return (select sum(stoc_cantidad) from STOCK where stoc_producto = @producto) + 
	(select sum(item_cantidad)
	from Item_Factura JOIN Factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
	where item_producto = @producto and fact_fecha >= @fecha)
end
go
/* ---------------- EJERCICIO N°3 ----------------------
3.Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.
*/
--hay que modificar datos (no es funciton), como pide que se ejecute en un momento determinado, ahora, es un proc. 
--no pide ejecutar automaticamente 

create proc ej3
as
begin
	update empleado set empl_jefe = (select top 1 empl_codigo from Empleado
									 where empl_jefe is null
									 order by empl_salario desc, empl_ingreso)
	where empl_jefe is null and empl_codigo <> (select top 1 empl_codigo from Empleado
												where empl_jefe is null
												order by empl_salario desc, empl_ingreso)
	return
end
go

-- GERENTE GENERAL -- 
select top 1 empl_codigo
from Empleado
where empl_jefe is null
order by empl_salario desc, empl_ingreso
go
-- OTRA FROMA PARA NO COMPARAR
create proc ej3
as
begin
	update empleado set empl_jefe = (select top 1 empl_codigo from Empleado
									 where empl_jefe is null
									 order by empl_salario desc, empl_ingreso)
	where empl_jefe is null 

	update empleado set empl_jefe = null
	where empl_codigo = empl_jefe -- el q tenga como jefe a el mismo le ponemos null
	return
end
go

/* ---------------- EJERCICIO N°4 ----------------------
4.Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.
*/

drop proc ej4

create proc ej4 (@vendedor numeric(6) output)
AS
BEGIN

		update empleado set empl_comision = 
		(select sum(fact_total) from Factura 
		 where empl_codigo = fact_vendedor
		 and year(Fact_fecha) = (select top 1 year(fact_fecha)
							     from factura 
						    	 order by fact_fecha desc))
		
		set @vendedor = (select top 1 fact_vendedor from factura 
		where year(Fact_fecha) = (select top 1 year(fact_fecha)
								  from factura 
								  order by fact_fecha desc)
		order by fact_total )

		print @vendedor
END

-- para ver si esta bien
declare @empleado numeric(6)
exec dbo.ej4 @empleado

/* ---------------- EJERCICIO N°5 ----------------------
5.Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:  */
Create table Fact_table
( 
	anio char(4) not null,
	mes char(2) not null,
	familia char(3) not null,
	rubro char(4) not null,
	zona char(3) not null,
	cliente char(6) not null,
	producto char(8) not null,
	cantidad decimal(12,2) not null,
	monto decimal(12,2)
)
Alter table Fact_table
Add constraint pk_Fact_table_ID primary key(anio,mes,familia,rubro,zona,cliente,producto)
go

create proc migrar_hechos_fact_table as
begin
	insert Fact_table(anio, mes, familia, rubro, zona, cliente, producto, cantidad, monto)
	select
		year(fact_fecha),
		month(fact_fecha),
		fami_id,
		rubr_id,
		zona_codigo,
		fact_cliente,
		prod_codigo,
		sum(item_cantidad),
		sum(item_cantidad*item_precio)
	from Factura join Item_Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
				 join Producto on item_producto = prod_codigo
				 join Familia on fami_id = prod_familia
				 join Rubro on rubr_id = prod_rubro
				 join Empleado on fact_vendedor = empl_codigo
				 join Departamento on empl_departamento = depa_codigo
				 join Zona on zona_codigo = depa_zona
	group by year(fact_fecha),
			 month(fact_fecha),
			 fami_id,
			 rubr_id,
			 zona_codigo,
			 fact_cliente,
			 prod_codigo
end

exec migrar_hechos_fact_table
select * from fact_table

drop table Fact_table
drop proc migrar_hechos_fact_table

/* ---------------- EJERCICIO N°6 ---------------------- ES TEDIOSO Y COMPLEJO, DEJARLO PARA HACERLO MAS AL FINAL DE LA PRACTICA,
LO HACEMOS CUANDO SOBRE TIEMPO
6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda. */
go
create proc ej6 as
BEGIN
	DECLARE @NUMERO char(8), @TIPO char(1), @SUCURSAL char(4)
	DECLARE cursorFacturas cursor for 
		select fact_numero, fact_tipo, fact_sucursal from Factura
	OPEN cursorFacturas
	FETCH NEXT FROM cursorFacturas INTO @NUMERO, @TIPO, @SUCURSAL
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		FETCH NEXT FROM cursorFacturas INTO @NUMERO, @TIPO, @SUCURSAL
	END
	CLOSE cursorFacturas
	DEALLOCATE cursorFacturas
END

/* ---------------- EJERCICIO N°7 ----------------------
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía. 

-- codigo, Detalle, Cant. Mov. , Precio de Venta, Renglon, Ganancia  */
-- toto tiene el q hizo mati 
drop table ventas
create table ventas(
	renglon int,						   -- Nro. de línea de la tabla
	codigo char(8) NULL,
	detalle char(50) NULL,
	cant_mov int NULL,                     -- Cantidad de movimientos de ventas (Item factura)
	precio_venta decimal(12, 2) NULL,      -- Precio promedio de venta                           
	ganancia char(6) NOT NULL              -- Precio de Venta – Cantidad * Costo Actual
)

alter table ventas add constraint pk_ventas_id primary key(renglon)
go

create proc ej7 (@fecha_comienzo smalldatetime, @fecha_fin smalldatetime) as
begin
	DECLARE @renglon int, @codigo char(8), @detalle char(50), @cant_mov int, @precio_venta decimal(12, 2), @ganancia char(6)
	DECLARE cArticulos CURSOR FOR 
	select prod_codigo, 
		   prod_detalle,
		   sum(item_cantidad),
		   avg(item_precio),
		   sum(item_precio*item_cantidad)
	from Producto join Item_Factura on prod_codigo = item_producto
				  join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
	where fact_fecha between @fecha_comienzo and @fecha_fin
	group by prod_codigo, prod_detalle

	OPEN cArticulos
	set @renglon = 0
	FETCH NEXT FROM cArticulos INTO @codigo, @detalle, @cant_mov, @precio_venta, @ganancia
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @renglon = @renglon + 1
		insert into ventas values (@renglon, @codigo, @detalle, @cant_mov, @precio_venta, @ganancia)
		FETCH NEXT FROM cArticulos INTO @codigo, @detalle, @cant_mov, @precio_venta, @ganancia
	END
	CLOSE cArticulos
	DEALLOCATE cArticulos
end

go
/* ---------------- EJERCICIO N°8 ----------------------
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:  
--codigo, detalle, cantidad, precio_generado, precio_Facturado */

/* --- EXPLICACION MATI ---
La tabla composicion es recursiva, no sabemos la profundidad de su composiicon, asi como tenemos combos de hamburguesa, 
la misma hamburguesa puede ser una composicion de pan, carne, lechuga, etc. No lo sabemos. Hay que crear una funcion recursiva.

---------------------------- EJEMPLO BIG MAC ---------------------------------
ITEM FACTURA
COMBO BIG MAC -- 2000
      |
COMPOSICION 
COMP_PRODUCTO |  COMP_COMPONENTE      |  COMP_CANTIDAD
COMBO BIG MAC -- HAMBURGUESA BIG MAC  -- 1
COMBO BIG MAC -- GASEOSA              -- 1
COMBO BIG MAC -- PAPAS FRITAS         -- 1

PRODUCTO
PROD_DETALLLE        -- PROD_PRECIO -- es un sum(prod_precio*)
HAMBURGUESA BIG MAC  -- 1500
GASEOSA              -- 400
PAPAS FRITAS         -- 700
---------------------------------------
                     -- 2600 Si lo compro separado me sale mas caro q en combo
COMBO BIG MAC        -- 2000
----------------------------------------
2600 - 2000 = 600 DIFERENCIA LO QUE SALE COMPRAR POR SEPARADO LOS PROD Y COMPRAR EL COMBO COMPUESTO

-------------------------------- OTRO EJEMPLO, COMBO AMIGO -------------------------------------
ITEM FACTURA
COMBO AMIGO -- 4500
      |
COMPOSICION 
COMP_PRODUCTO -- COMP_COMPONENTE    -- COMP_CANTIDAD
COMBO AMIGO -- HAMBURGUESA BIG MAC  -- 2
COMBO AMIGO -- GASEOSA              -- 2
COMBO AMIGO -- PAPAS FRITAS         -- 2

PRODUCTO
PROD_DETALLLE        -- PROD_PRECIO
HAMBURGUESA BIG MAC  -- 1500 * 2
GASEOSA              -- 400  * 2
PAPAS FRITAS         -- 700  * 2
---------------------------------------
                     -- 5200 Si lo compro separado me sale mas caro q en combo
COMBO AMIGO          -- 4600
----------------------------------------
5200 - 4600 = 600 DIFERENCIA LO QUE SALE COMPRAR POR SEPARADO LOS PROD Y COMPRAR EL COMBO COMPUESTO
*/ 

---------- CREACION TABLA ----------

create table diferencias(
	codigo char(8),                   --cod del articulo (el combo)
	detalle char(50),                 --detalle del articulo
	cantidad decimal(12, 2),          --cant de productos que conforman el combo 
	precio_generado decimal(12, 2),   --precio q se compone a traves de sus comp
	precio_facturado decimal(12, 2),  --precio del prod (item_precio)
)

---------- CREACION FUNCION ----------
create function calcular_precio_generado(@combo char(8)) returns decimal(12, 2) as
begin
	declare @precio decimal(12, 2)

	----- CON LAS FUNCIONES RECURSIVAS, EMPEZAMOS DANDO LA CONDICION DE CORTE !! -----
	if NOT EXISTS (select * from Composicion where comp_producto = @combo) -- si ya llegamos al producto que ya no es compuesto
	begin
		set @precio = (select isnull(prod_precio, 0) from Producto where prod_codigo = @combo)
		return @precio
	end

	set @precio = 0 -- como el precio es acumulativo, lo tengo que inicializar en las funciones recursivas

	declare @componente char(8), @cantidad decimal(12, 2)
	declare cComp cursor for 
		select comp_componente, comp_cantidad from Composicion where comp_producto = @combo
	open cComp
	fetch next from cComp into @componente, @cantidad
	while @@FETCH_STATUS = 0
		begin
			set @precio = @precio + @cantidad * dbo.calcular_precio_generado(@componente) -- el costo acumulado
			fetch next from cComp into @componente, @cantidad
		end
	close cComp
	deallocate cComp

	return @precio
end

---------- CREACION PROCEDURE ----------
create proc ej8 as
begin
	insert diferencias (codigo, detalle, cantidad, precio_generado, precio_facturado)
		select prod_codigo,
			   prod_detalle,
			   count(distinct comp_componente), -- la atomicidad se nos va por item factura, hay muchos precios que varian por mismo prod a lo largo del tiempo
			   dbo.calcular_precio_generado(prod_codigo),
			   item_precio
		from Item_Factura join Producto on prod_codigo = item_producto join Composicion on comp_producto = prod_codigo
		where item_producto in (select comp_producto from Composicion) and dbo.calcular_precio_generado(prod_codigo) <> item_precio
		group by item_producto, prod_detalle, item_precio -- suena raro agrupar por precio, pero como queremos justamente los precios 
end														  -- diferentes, que varian, si es el mismo precio lo inserto solo una vez.


/* ---------------- EJERCICIO N°9 ----------------------
9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de  -- aca es sin recursiva
factura de un artículo con composición realice el movimiento de sus correspondientes componentes.*/

-- una modificaicon en un producto de item factura puede ser un delete o un update de cantidad
-- tiene que ser ante una operacion, por lo que debe ser un trigger de un update
-- relizar los movimientos correspondiente es subir o bajar el stock
-- si en item factura tenemos coca con cantidad 4 y se modifica a 3, el stock aumenta 1
-- si se modifica a 5, hay que descontar 1 en stock.

create trigger ej9 on item_factura for update as -- ???????? no se si ta bien :(
BEGIN
	if(select count(*) from inserted where item_producto in (select comp_producto from Composicion)) > 0
	BEGIN
		declare @codigo char(8), @cantidad_inicial decimal(12, 2), @cantidad_final decimal(12, 2), @deposito char (2)
		declare cItem cursor for
			select stoc_producto, d.item_cantidad, i.item_cantidad, stoc_deposito 
			from inserted i join deleted d on i.item_numero+i.item_tipo+i.item_sucursal = d.item_numero+d.item_tipo+d.item_sucursal 
							and i.item_producto = d.item_producto
							join Composicion on comp_producto = i.item_producto
						    join STOCK on stoc_producto = i.item_producto

		open cItem
		fetch next from cItem into @codigo, @cantidad_inicial, @cantidad_final, @deposito
		while @@FETCH_STATUS = 0
		BEGIN
			update stock 
			set stoc_cantidad = stoc_cantidad + (@cantidad_inicial - @cantidad_final)
			where stoc_producto = @codigo and stoc_deposito = @deposito
			fetch next from cItem into @codigo, @cantidad_inicial, @cantidad_final, @deposito
		END
		close cItem
		deallocate cItem
	END
END

/* ---------------- EJERCICIO N°10 ----------------------
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
*/
-- "ANTE EL INTENTO DE BORRAR" -> TRIGGER, ESS UN EVENTO
-- tengo que ver si los que estan en la tabla deleted tiene stock o no 

-- CON INSTEAD OF
create trigger tr1 on Producto instead of delete as
begin
	if(select count(*) from deleted join STOCK on prod_codigo = stoc_producto
	                   group by prod_codigo
					   having sum(stoc_cantidad) > 0) > 0
		print('no se pueden borrar porque aun tienen stock')

	else 
		delete from Producto where prod_codigo in (select prod_codigo from deleted)
end


-- CON FOR

create trigger tr1for on producto for delete as
begin
	if(select count(*) from deleted join STOCK on prod_codigo = stoc_producto
	                   group by prod_codigo
					   having sum(stoc_cantidad) > 0) > 0
	begin
		print('no se pueden borrar porque aun tienen stock')
		ROLLBACK
	end
end
go
/* ---------------- EJERCICIO N°11 ----------------------
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo. */

create function ej11 (@empleado numeric(6 ,0)) returns int as
BEGIN
	declare @cantidadEmpleados int
	set @cantidadEmpleados = (select isnull(count(distinct empl_codigo), 0) from Empleado where empl_jefe = @empleado 
																							and empl_codigo != @empleado)

	return @cantidadEmpleados + (select isnull(sum(dbo.ej11(empl_codigo)), 0) from Empleado where empl_jefe = @empleado 
																						and empl_codigo != @empleado)
END
go
-- para probar funcionamiento 
select * from Empleado
select dbo.ej11('2') -- bien, el empl 2 tiene solo 1 subordinado
select dbo.ej11('3') -- bien, quiroga tiene 5 sub
drop function ej11
go
/* ---------------- EJERCICIO N°12 ----------------------
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes. */

create function ver_componentes(@producto char(8), @componente char(8)) returns int as
BEGIN
	if(@producto = @componente)
		return 1
	else
	BEGIN
		declare @componente_de_ex_componente char(8)
		declare cComponente cursor for select comp_componente from composicion where comp_producto = @componente
		open cComponente
		FETCH NEXT from cComponente into @componente_de_ex_componente
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if(dbo.ver_componentes(@producto, @componente_de_ex_componente) = 1)
			BEGIN	
				CLOSE cComponente
				DEALLOCATE cComponente
				return 1
			END
			FETCH NEXT from cComponente into @componente_de_ex_componente
		END
		CLOSE cComponente
		DEALLOCATE cComponente
	END
	return 0
END
go

create trigger ej12 on composicion for insert, update as
BEGIN
	if(select count(*) from inserted where dbo.ver_componentes(comp_producto, comp_componente) = 1) > 0
	ROLLBACK
	PRINT('HAY UN PRODUCTO COMPUESTO POR SI MISMO')
END
go

/* ---------------- EJERCICIO N°13 ----------------------
13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías. */ -- hecho con mati

--Se sabe que en la actualidad dicha regla se cumple -> control a futuro -> trigger
-- habla del salario -> insert update, delete no porque si se elimina el salario "va a ser menos"
-- ante un insert y un update que se fije si se cumple, si no se cumple rollback
-- tambien necesitamos una funcion recursiva que vaya acumulando los salarios de sus empleados dir o indir

create function salarioEmpleados(@jefe numeric(6,0)) returns decimal(12,2) as
BEGIN
	DECLARE @salarioEmpleados decimal(12,2)

	set @salarioEmpleados = (select isnull(sum(empl_salario), 0) from Empleado where empl_jefe = @jefe)

	RETURN @salarioEmpleados + (select isnull(sum(dbo.salarioEmpleados(empl_codigo)), 0) from Empleado where empl_jefe = @jefe)
END
go

create trigger ej13 on Empleado for insert, update as 
BEGIN
	if exists(select count(*) from inserted where (dbo.salarioEmpleados(empl_codigo)*0.2) <= empl_salario)
		ROLLBACK
END
go

/* ---------------- EJERCICIO N°14 ----------------------
14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes. */ 
/*
comp precio + comp precio + comp recio > precio -> insertar y print 
precio < comp precio + comp precio + comp recio / 2 -> delete
Vamos a insertar siempre, a menos que precio < comp precio + comp precio + comp recio / 2 
porque estamos haciendo x cosa en vez de insert en item factura, es decir, si el prod no es compuesto hay que insertar por ej*/

/*En este ej se podria hacer primero un cursor de facturas para que inserte las que estan bien y las que estan mal nop,
  el ejercicio no pide eso y aparte en la vida real es rari, asi que no hace falta segun henry*/
create function calcularPrecioComponentes(@prod char(8)) returns decimal(12,2) as
BEGIN
	RETURN (select isnull(sum(prod_precio), 0) from Producto join Composicion on comp_componente = prod_codigo and comp_producto = @prod)
END
go

create trigger ej14 on item_factura instead of insert as
BEGIN
		DECLARE @num char(8), @tipo char(1), @sucursal char(4), @prod char(8), @precio decimal(12, 2), @cantidad decimal(12, 2)
		DECLARE @cliente char(6), @fecha smalldatetime
		DECLARE cursorItem cursor for 
			select item_numero, item_tipo, item_sucursal, item_producto, item_precio, item_cantidad, fact_cliente, fact_fecha
			from inserted join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		OPEN cursorItem
		FETCH NEXT from cursorItem INTO @num, @tipo, @sucursal, @prod, @precio, @cantidad
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if(@precio > dbo.calcularPrecioComponentes(@prod) / 2)
			BEGIN
				INSERT Item_Factura values (@tipo, @sucursal, @num, @prod, @cantidad, @precio)
				if(@precio < dbo.calcularPrecioComponentes(@prod))
				BEGIN
					--DECLARE @cliente char(6), @fecha smalldatetime
					PRINT(' FECHA: ' + @fecha + ' CLIENTE: ' + @cliente + ' PRODUCTO: ' + @prod + ' PRECIO: ' + @precio)
				END
			END
			ELSE
			BEGIN -- yo habia pensado que no hacia falta borrar items pq es un istead of, entonces pense no hace falta pq no se inserto
			-- NO ES ASI, porque capaz primero vinieron 3 items que cumplian la regla y se insertaron, y yo no puedo dejar la fact a medias
			-- tengo que borrar los items que se pueden haber insertado antes y borrar la factura
				delete from Item_Factura where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@num
				delete from Factura where fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@num -- el de la factura si porque no puede quedar a medias
				print('El precio del producto no puede ser menor a la mitad de sus componentes')			
			END
			FETCH NEXT from cursorItem INTO @num, @tipo, @sucursal, @prod, @precio, @cantidad
		END
		CLOSE cursorItem
		DEALLOCATE cursorItem
END 
go

select * from Composicion join Producto on comp_producto = prod_codigo
select prod_detalle, prod_precio from Producto where prod_codigo = '00001123' -- 1,70 comp 1
select prod_detalle, prod_precio from Producto where prod_codigo = '00001109' -- 3.51 comp 2
                                                                                ------------ suma 5,21
select prod_detalle, prod_precio from Producto where prod_codigo = '00001104' -- prod 3,51
select dbo.calcularPrecioComponentes('00001104') -- da 5,21
go
/* ---------------- EJERCICIO N°15 ----------------------
15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. 
El objeto principal debe poder ser utilizado como filtro en el where de una 
sentencia select. ---------------> el unico que se puede usar en un where es una funcion*/ 

create function f15 (@producto char(8)) returns decimal(12,2) as
BEGIN
	DECLARE @precio decimal(12,2)
	if not exists (select * from Composicion where comp_producto = @producto)
		set @precio = (select prod_precio from Producto where prod_codigo = @producto)
	ELSE 
		BEGIN
			set @precio = @precio + (select isnull(sum(dbo.f15(comp_componente)*comp_cantidad), 0) 
									 from Composicion where comp_producto = @producto)
		END
	return @precio
END
go
-- tambien podria hacerse con un cursor

/* ---------------- EJERCICIO N°16 ----------------------
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos) -----> para este ej no tener en cuenta composicion
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto. */

create trigger EJ16 on Item_factura for insert as
BEGIN
	declare @prod char(8), @cantidad_comprada decimal(12,2)
	declare @stoc_cant decimal(12,2), @deposito char(2)
	declare @ultimo_depo char(2)

	declare cursorItem cursor for -- para ir tratando cada item en particular
	select i.item_producto, i.item_cantidad from inserted i
	open cursorItem
	fetch next cursorItem into @prod, @cantidad_comprada
	while @@FETCH_STATUS = 0
	BEGIN -- otro cursor para ir recorriendo los stoc deposito y ver en cual o cuales hay que ir restadno
		declare cursorStock cursor for -- no es top 1 porque seria si con ese depo ya te alcanza. Si se hace top 1, despues hay que ver si no alcanzo y habria que hacer otro, no esta mal, pero mejor lo otro
		select stoc_cantidad, stoc_deposito from stock where stoc_producto = @prod order by stoc_cantidad desc
		open cursorStock
		fetch next cursorStock into @stoc_cant, @deposito
		while @@FETCH_STATUS = 0
			BEGIN
				if(@stoc_cant >= @cantidad_comprada)
					BEGIN
						update STOCK set @stoc_cant = @stoc_cant - @cantidad_comprada 
						where stoc_deposito = @deposito and stoc_producto = @prod
						set @cantidad_comprada = 0
						break -- corto y salgo del while pq ya alcanzo, ya paso al siguiente prod
					END
				ELSE 
					BEGIN
						update STOCK set @stoc_cant = 0 
						where stoc_deposito = @deposito and stoc_producto = @prod
						set @cantidad_comprada = @cantidad_comprada - @stoc_cant
					END
				set @ultimo_depo = @deposito
				fetch next cursorStock into @stoc_cant, @deposito
			END
		---- aca que es post ultima isntancia hay que dejarlo en negativo al ultimo deposito si no habia mas cant
		if @cantidad_comprada > 0
			update stock set stoc_cantidad = stoc_cantidad - @cantidad_comprada where stoc_deposito = @ultimo_depo and stoc_producto = @prod
		close cursorStock
		deallocate cursorStock
		fetch next cursorItem into @prod, @cantidad_comprada
	END
	close cursorStock
	deallocate cursorStock
END
go
/* ---------------- EJERCICIO N°17 ----------------------
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
-- hecho con henry una version diferente en la clase 13/6 con instead of
-- NO COMPLICARLA, si la consigna NO ESPECIFICA que los que estan bien tienen que entrar,
   hacerlo asi con for.
   Si especifica se hace con instead of
*/

create trigger tr17 on stock for insert, update as
begin
	
	if exists (select * from inserted where stoc_cantidad > stoc_stock_maximo or stoc_cantidad < stoc_punto_reposicion)
		BEGIN
			PRINT('El producto no cumple el minimo y el maximo')
			ROLLBACK
		END
end
go

/*SI PIDIERA QUE LOS QUE CUMPLEN SE MODIFIQUEN/ SE INSERTEN: */

-- PARA DIFERENCIAS SI FUE UN UPDATE O UN INSERT, PORQUE HAY QUE "REPLICAR" LA OPERACION, SE HACE UN 
-- IF EXIST (SELECT COUNT(*) FROM DELETED), SI ES = 0 ES QUE FUE UN INSERT
create trigger ej_17 on stock instead of insert, update as
BEGIN
	IF (SELECT COUNT(*) FROM DELETED) = 0-- ES POR INSERT
		BEGIN
			INSERT stock select * from inserted where stoc_cantidad < stoc_stock_maximo and stoc_cantidad > stoc_punto_reposicion
		END
	ELSE --ES POR UPDATE. TENGO QUE HACER UN SET POR CADA COLUMNA, TENGO QUE USAR CURSORES, DECLARANDO C/U DE LAS VARIABLES DE STOCK
		BEGIN
			DECLARE @prod char(8), @deposito char(2), @prox_repo smalldatetime, @detalle char(100), @stoc_max decimal(12,2), 
					@stoc_punto_repo decimal(12,2), @cantidad decimal(12,2)
			DECLARE cursorStock cursor for  -- el select si o si con * porque necesitamso TODAS las columnas para el update
			select * from inserted where stoc_cantidad < stoc_stock_maximo and stoc_cantidad > stoc_punto_reposicion
			OPEN cursorStock
			FETCH NEXT from cursorStock into @prod, @deposito, @prox_repo, @detalle, @stoc_max, @stoc_punto_repo, @cantidad
			WHILE @@FETCH_STATUS = 0
				BEGIN  -- SIEMPRE UPDATE SET "CLUMNAS MENOS LAS DE PK" WHERE "PKS"
					UPDATE stock set stoc_proxima_reposicion = @prox_repo, stoc_detalle = @detalle, stoc_stock_maximo = @stoc_max,
									 stoc_punto_reposicion = @stoc_punto_repo, stoc_cantidad = @cantidad
					where stoc_producto = @prod and stoc_deposito = @deposito
					FETCH NEXT from cursorStock into @prod, @deposito, @prox_repo, @detalle, @stoc_max, @stoc_punto_repo, @cantidad
				END
			CLOSE cursorStock
			DEALLOCATE cursorStock
		END
END
go
/* ---------------- EJERCICIO N°18 ----------------------
18 con henry 
18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
*/
-- LAS FACTURAS SALVO QUE EN ALGUN EJERCICIO LO ESPECIFIQUE NO SE MODIFICAN, POR ESO
-- SOLO INSERT

create trigger ej18 on factura for insert as
BEGIN
	if exists(select i.fact_cliente, YEAR(i.fact_fecha), month(i.fact_fecha), sum(i.fact_total) 
			  from inserted i join Cliente on clie_codigo = i.fact_cliente
			  group by i.fact_cliente, YEAR(i.fact_fecha), month(i.fact_fecha)
			  having (sum(i.fact_total) + (select sum(fact_total) from factura
										  where year(fact_fecha) = year(i.fact_fecha)
										  and month(fact_fecha) = month(i.fact_fecha)
										  and fact_cliente = i.fact_cliente)) > clie_limite_credito)
		ROLLBACK				   
END
go

/*DE ESTA FROMA CON EL FOR, SE "CANCELAN" TODOS LOS INSERT, POR MAS QUE HABIA OTRAS FACTURAS DE OTROS CLIENTES QUE CAPAZ
  SI CUMPLIAN LA REGLA, CAPAZ NO SUPERABAN EL LIMITE DE CREDITO
  
  LO HACEMOS CON INSTEAD OF PARA VER COMO SERIA SI QUEREMOS QUE SE INSERTEN LAS FILAS PARA LAS FACTURAS DE LOS CLIENTES
  QUE SI CUMPLEN LA REGLA:                                                                                                */

alter trigger ej18 on factura instead of insert as
BEGIN
	insert factura select * from inserted where fact_cliente in 
	(select i.fact_cliente, YEAR(i.fact_fecha), month(i.fact_fecha), sum(i.fact_total) 
	 from inserted i join Cliente on clie_codigo = i.fact_cliente
	 group by i.fact_cliente, YEAR(i.fact_fecha), month(i.fact_fecha)
	 having (sum(i.fact_total) + (select sum(fact_total) from factura
								  where year(fact_fecha) = year(i.fact_fecha)
								  and month(fact_fecha) = month(i.fact_fecha)
								  and fact_cliente = i.fact_cliente)) <= clie_limite_credito)
END
go
 -- tambien estaba bien si haciamos un cursor e insertabamos uno por uno los que cumplen la regla

 /*ES MUY COMPLICADO EL UPDATE CON EL INSTEAD OF PORQUE COMO NO SABMEOS LO QUE CAMBIO SE TIENE QUE HACER UN SET
   DE CADA COLUMNA, UNA POR UNA IR UPDATEANDO */
-- en realidad no es complicado, es engorroso, porque en realidad es bastante metodico

/* ---------------- EJERCICIO N°19 ----------------------
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.                     */

create function aniosAntiguedad(@empleado numeric(6,0)) returns smalldatetime as
BEGIN
	return (select datediff(year, empl_ingreso, getdate()) from empleado where empl_codigo = @empleado)
END
go

create function cantidadEmpleados(@empleado numeric(6,0)) returns int as
BEGIN
	DECLARE @cantidadEmpleados int 
	set @cantidadEmpleados = (select count(distinct empl_codigo) from Empleado where empl_jefe = @empleado)

	return @cantidadEmpleados + (select isnull(sum(dbo.cantidadEmpleados(empl_codigo)), 0) from Empleado where empl_jefe = @empleado)
END

go
create trigger ej19 on Empleado for update, insert, delete as -- el delete es por lo del 50%
BEGIN
	 IF(select count(*) from inserted) > 0 -- es por inserted o update
		 BEGIN 
			declare @empleado numeric(6,0), @jefe numeric(6,0) 
			declare cursorEmpleado cursor for
			select empl_codigo, empl_jefe  from inserted where empl_codigo in (select e.empl_jefe from empleado e)
			open cursorEmpleado
			FETCH NEXT FROM cursorEmpleado INTO @empleado, @jefe
			WHILE @@FETCH_STATUS = 0
				BEGIN
					if(dbo.aniosAntiguedad(@empleado) < 5)
					ROLLBACK
					if(dbo.cantidadEmpleados(@empleado) > (select count(*) from empleado)/2) and @jefe is not null -- si no es el gerente g.
					ROLLBACK
					FETCH NEXT FROM cursorEmpleado INTO @empleado, @jefe
				END
			close cursorEmpleado
			DEALLOCATE cursorEmpleado 
		 END
	 ELSE -- entra por deleted -- no hace falta un cursor para deleted, como ahora por deleted hay que chequear q ningun jefe supere el 
	                           -- 50%, hago un select q si alguno no cumple haga rollback
		/*BEGIN   ESTA BIEN PERO MAS FACIL E EFICIENTE HACER LA CONSULTA DIRECTA
			declare @jefeDelDeleted numeric(6,0) 
			declare cursorJefe cursor for
			select empl_jefe from deleted where empl_jefe is not null group by empl_jefe
			open cursorJefe
			FETCH NEXT FROM cursorJefe INTO @jefeDelDeleted
			WHILE @@FETCH_STATUS = 0
				BEGIN
					if(dbo.cantidadEmpleados(@jefeDelDeleted) > (select count(*) from empleado)/2)
					ROLLBACK
					FETCH NEXT FROM cursorJefe INTO @jefeDelDeleted
				END
			close cursorJefe
			DEALLOCATE cursorJefe
		END*/ 
		BEGIN -- no importa a quien borraron, por eso no es deleted, en general, si no se sigue cumpliendo la regla para algun jefe chau
		-- si mati tiene 10 empleados y henry 5 y a henry le borran 1, henry va a seguir cumpliendo la regla pero tal vz mati no,
		-- porque ahora en cuanto a proporcion de empleados comparando al total, va a tener mas que antes.
			if exists (select empl_jefe from Empleado
					   group by empl_jefe
					   having dbo.cantidadEmpleados(empl_codigo) > (select count(*) from empleado)/2)
				ROLLBACK
		END
END 
go

/* ---------------- EJERCICIO N°20 ----------------------
20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.                                  */

create function cantidadProdDiferentesVendidos(@vendedor numeric(6,0), @mes smalldatetime) returns int as
BEGIN
	return (select count(distinct item_producto) 
			from Factura join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
where fact_vendedor = @vendedor and month(fact_fecha) = @mes)
END
go

create function calcularComision(@vendedor numeric(6,0), @mes smalldatetime) returns decimal(12,2) as
BEGIN
	DECLARE @comision decimal(12,2)
	IF(dbo.cantidadProdDiferentesVendidos(@vendedor, @mes) < 50)
		set @comision = 0.05 * (select isnull(sum(fact_total), 0) from Factura where fact_vendedor = @vendedor and month(fact_fecha) = @mes)
	ELSE 
		set @comision = 0.08 * (select isnull(sum(fact_total), 0) from Factura where fact_vendedor = @vendedor and month(fact_fecha) = @mes)
	return @comision
END
go

create trigger ej20 on factura for insert as
BEGIN
	declare @vendedor numeric(6,0), @mes smalldatetime
	declare cursorVenta cursor for 
	select fact_vendedor, fact_fecha from inserted
	open cursorVenta
	FETCH NEXT FROM cursorVenta INTO @vendedor, @mes
	WHILE @@FETCH_STATUS = 0
	BEGIN
		update Empleado set empl_comision = dbo.calcularComision(@vendedor, @mes)
		where empl_codigo = @vendedor
		FETCH NEXT FROM cursorVenta INTO @vendedor, @mes
	END
	CLOSE cursorVenta
	DEALLOCATE cursorVenta
END
GO
/* ---------------- EJERCICIO N°21 ----------------------
21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.                                                     */

create function cantFamiliasDistintas(@cabezalFacturas char(14)) returns int as
BEGIN
	return (select count(distinct prod_familia) from Producto join Item_Factura on prod_codigo = item_producto
			where item_tipo+item_sucursal+item_numero = @cabezalFacturas)
END
go

create trigger ej21 on factura for insert as
BEGIN
	if exists(select fact_tipo+fact_sucursal+fact_numero from inserted where dbo.cantFamiliasDistintas(fact_tipo+fact_sucursal+fact_numero) > 1)
	BEGIN	
		declare @cabezalFactura char(14)
		declare cursorFactura cursor for
		select fact_tipo+fact_sucursal+fact_numero from inserted
		open cursorFactura
		FETCH NEXT FROM cursorFactura INTO @cabezalFactura
		WHILE @@FETCH_STATUS = 0
		BEGIN
			delete from Item_Factura where item_tipo+item_sucursal+item_numero = @cabezalFactura
			delete from Factura where fact_tipo+fact_sucursal+fact_numero = @cabezalFactura
			print('ERROR, no se pueden ingresar productos de diferentes familias en una misma factura, no se grabo la factura: ' + @cabezalFactura)
			FETCH NEXT FROM cursorFactura INTO @cabezalFactura	
		END
		CLOSE cursorFactura
		DEALLOCATE cursorFactura
	END
END
go
/* ---------------- EJERCICIO N°22 ----------------------
22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada                          */

create function cantidadProductos(@rubro char(4)) returns int as
BEGIN
	return (select count(distinct prod_codigo) from Producto where prod_rubro = @rubro)
END

GO

create proc distribuirProductos(@rubro char(4), @cantidadADistribuir int) as
BEGIN
	DECLARE @RubroDondeInsertar char(4), @cantidadRubroDondeInsertar int
	DECLARE cursorRubro cursor for
	select rubr_id, (20 - dbo.cantidadProductos(rubr_id)) from Rubro where rubr_id <> @rubro and dbo.cantidadProductos(rubr_id) < 20
	OPEN cursorRubro
	FETCH NEXT FROM cursorRubro INTO @RubroDondeInsertar, @cantidadRubroDondeInsertar
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@cantidadRubroDondeInsertar >= @cantidadADistribuir)
			BEGIN
				DECLARE @vecesUpdate int
				SET @vecesUpdate = 0
				WHILE(@vecesUpdate <= @cantidadADistribuir)
				BEGIN 
					update Producto set prod_rubro = @RubroDondeInsertar where prod_rubro = @rubro
					set @vecesUpdate = @vecesUpdate + 1
				END
				set @cantidadADistribuir = 0
				break
			END
		ELSE 
			BEGIN
				DECLARE @vecesUpdate2 int
				SET @vecesUpdate2 = 0
				WHILE(@vecesUpdate2 <= @cantidadRubroDondeInsertar)
				BEGIN 
					update Producto set prod_rubro = @RubroDondeInsertar where prod_rubro = @rubro
					set @vecesUpdate2 = @vecesUpdate2 + 1
				END
				set @cantidadADistribuir = @cantidadADistribuir - @cantidadRubroDondeInsertar
			END

		FETCH NEXT FROM cursorRubro INTO @RubroDondeInsertar, @cantidadRubroDondeInsertar
	END
	IF @cantidadADistribuir > 0
		BEGIN
			insert into rubro values ('xx', 'RUBRO REASIGNADO')
			SET @vecesUpdate2 = 0
			WHILE(@vecesUpdate2 <= @cantidadADistribuir)
			BEGIN 
				update Producto set prod_rubro = 'xx' where prod_rubro = @rubro
				set @vecesUpdate2 = @vecesUpdate2 + 1
			END
		END
	CLOSE cursorRubro
	DEALLOCATE cursorRubro
END
GO

create proc recategorizarPorductos as
BEGIN 
	DECLARE @rubro char(4)
	DECLARE cursorRubro cursor for
	select rubr_id from Rubro
	OPEN cursorRubro
	FETCH NEXT FROM cursorRubro INTO @rubro
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if dbo.cantidadProductos(@rubro) > 20
			BEGIN
				DECLARE @cantProductosACambiar int
				SET @cantProductosACambiar = dbo.cantidadProductos(@rubro) - 20
				exec dbo.distribuirProductos @rubro, @cantProductosACambiar 
			END
		FETCH NEXT FROM cursorRubro INTO @rubro
	END
	CLOSE cursorRubro
	DEALLOCATE cursorRubro
END
GO
/* ---------------- EJERCICIO N°23 ----------------------
23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.         */

create function contarComposicionFactura(@factura char(13))
returns int
as
begin
    declare @cantidad int
    select @cantidad = count(distinct item_producto) 
        from Item_Factura 
        where @factura = item_tipo+item_sucursal+item_numero
        and
        item_producto in (select comp_producto from Composicion)

        return @cantidad
end
GO 
create trigger ej23 on factura for insert
as
begin
    DECLARE @tipo CHAR, @sucursal CHAR(4), @numero CHAR(8)

    declare c1 cursor for select fact_tipo, fact_sucursal, fact_numero from inserted

    fetch next from c1 into @tipo, @sucursal, @numero

    while @@FETCH_STATUS = 0
    begin

        if(dbo.contarComposicionFactura(@tipo+@sucursal+@numero) > 2)
        begin
            delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@SUCURSAL+@tipo
            delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@SUCURSAL+@tipo
        end

        fetch next from c1 into @tipo, @sucursal, @numero
    end
    close c1
    deallocate c1

end

/* ---------------- EJERCICIO N°29 ----------------------
29. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla                             */

-- en caso de q una factura no cumpla, ademas de rollback, borrar los items anteriores que estaban en la factura antes de 
-- que se dispare el trigger y despues borrar el cabecero de la factura. Ahi ya podes hacer rollback

-- es sobre inserted porque las fact no se pueden modificar, y si se elimina no afecta en el problema

create trigger ej29 on Item_factura for inserted as
BEGIN
	
END
go

-- 30 explica henry algo en particular 
/* ---------------- EJERCICIO N°30 ----------------------
30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar más de 100 unidades en el mes de ningún producto, si esto
ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha
superado el límite máximo de compra de un producto”. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.                                  */
-- que las facturas no pueden ser modificadas  ------> NO VA A HABER UN UPDATE, ES SOLO INSERT 
create trigger ej30 on item_factura for insert as -- ES ON ITEM FACTURA PORQUE SI O SI TENGO QUE SABER EL PROD Y SU CANT
BEGIN 
	if exists (select fact_numero+fact_tipo+fact_sucursal
			   from inserted i join factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
			   group by item_producto, fact_cliente, year(fact_fecha), month(fact_fecha)
			   having sum(item_cantidad) + (select sum(i1.item_cantidad)
											from Item_Factura i1 join factura f1 on f1.fact_numero+f1.fact_tipo+f1.fact_sucursal = i1.item_numero+i1.item_tipo+i1.item_sucursal
											where item_producto = i1.item_producto and fact_cliente = f1.fact_cliente
											and year(fact_fecha) = year(f1.fact_fecha) and month(fact_fecha) = month(f1.fact_fecha)) > 100)
	
	BEGIN --OJO QUE NO ALCANZA CON SOLO HACER ROLLBACK, SON FACTURAS!!!, se eliminan los items que ya estaban en la factura, 
	      -- se elimina la facutra y ahi si se hace el rollback por el item que se disparo el trigger
		print('Se ha superado el límite máximo de compra de un producto')
		
		-- DELETE ITEMS ANTERIORES
		delete Item_Factura where item_numero+item_tipo+item_sucursal in (select fact_numero+fact_tipo+fact_sucursal
			   from inserted i join factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
			   group by item_producto, fact_cliente, year(fact_fecha), month(fact_fecha)
			   having sum(item_cantidad) + (select sum(i1.item_cantidad)
											from Item_Factura i1 join factura f1 on f1.fact_numero+f1.fact_tipo+f1.fact_sucursal = i1.item_numero+i1.item_tipo+i1.item_sucursal
											where item_producto = i1.item_producto and fact_cliente = f1.fact_cliente
											and year(fact_fecha) = year(f1.fact_fecha) and month(fact_fecha) = month(f1.fact_fecha)) > 100)
		
		-- DELETE FACTURA 
		delete from Factura where fact_numero+fact_tipo+fact_sucursal in (select fact_numero+fact_tipo+fact_sucursal
			   from inserted i join factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
			   group by item_producto, fact_cliente, year(fact_fecha), month(fact_fecha)
			   having sum(item_cantidad) + (select sum(i1.item_cantidad)
											from Item_Factura i1 join factura f1 on f1.fact_numero+f1.fact_tipo+f1.fact_sucursal = i1.item_numero+i1.item_tipo+i1.item_sucursal
											where item_producto = i1.item_producto and fact_cliente = f1.fact_cliente
											and year(fact_fecha) = year(f1.fact_fecha) and month(fact_fecha) = month(f1.fact_fecha)) > 100)
		
		-- ROLLBACK DEL ITEM QUE SE ESTABA INSERTANDO
		ROLLBACK
	END	
END
go

--------- !!!!!!!!!!! Como vemos ante un trigger tal vez haya que eliminar cosas anteriores, 
--------- esto puede pasar con FACTURAS y COMPOSICION, con todo lo que para lo mismo tenga muchas filas. Entran TODAS O NINGUNA
--------- no pueden ir por partes :) HAY QUE CONTROLAR LA CONSISTENCIA :)
