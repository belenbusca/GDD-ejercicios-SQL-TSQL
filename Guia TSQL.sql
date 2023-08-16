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

  ---------------- EJERCICIO N�1 ----------------------
1.Hacer una funci�n que dado un art�culo y un deposito devuelva un string que
indique el estado del dep�sito seg�n el art�culo. Si la cantidad almacenada es
menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo XX el
% de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar
�DEPOSITO COMPLETO�.
2.Realizar una funci�n que dado un art�culo y una fecha, retorne el stock que
exist�a a esa fecha
3.Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que deber�a existir un �nico gerente general
(deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado
sin jefe deber� elegir entre ellos el gerente general, el cual ser� seleccionado por
mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la
empresa. Al finalizar la ejecuci�n del objeto la tabla deber� cumplir con la regla
de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad
de empleados que hab�a sin jefe antes de la ejecuci�n.
4.Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del �ltimo a�o. Se deber� retornar el c�digo del vendedor
que m�s vendi� (en monto) a lo largo del �ltimo a�o.
AS
BEGIN

		update empleado set empl_comision = 
		(select sum(fact_total) from Factura 
		 where empl_codigo = fact_vendedor
		 and year(Fact_fecha) = (select top 1 year(fact_fecha)
		
		set @vendedor = (select top 1 fact_vendedor from factura 
		where year(Fact_fecha) = (select top 1 year(fact_fecha)
		order by fact_total )

		print @vendedor
END
5.Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definici�n:  */
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
LO HACEMOS CUANDO SOBRE TIEMPO
6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deber� reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda. */
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una l�nea por cada art�culo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vac�a. 
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composici�n y en los cuales el precio de
facturaci�n sea diferente al precio del c�lculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
tambi�n puede estar compuesto por otros y as� sucesivamente, la tabla se debe
crear y est� formada por las siguientes columnas:  
9. Crear el/los objetos de base de datos que ante alguna modificaci�n de un �tem de  -- aca es sin recursiva
factura de un art�culo con composici�n realice el movimiento de sus correspondientes componentes.*/
10. Crear el/los objetos de base de datos que ante el intento de borrar un art�culo
verifique que no exista stock y si es as� lo borre en caso contrario que emita un
mensaje de error.
11. Cree el/los objetos de base de datos necesarios para que dado un c�digo de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un c�digo mayor que su jefe directo. */
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por s� mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnolog�as. No se conoce la cantidad de niveles de composici�n existentes. */
13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
�Ning�n jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)�. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnolog�as. */ -- hecho con mati
14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qu� precio se realiz� la
compra. No se deber� permitir que dicho precio sea menor a la mitad de la suma
de los componentes. */ 
15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. 
El objeto principal debe poder ser utilizado como filtro en el where de una 
sentencia select. ---------------> el unico que se puede usar en un where es una funcion*/ 
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos) -----> para este ej no tener en cuenta composicion
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto. */
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
regla de negocio autom�ticamente �Ning�n jefe puede tener menos de 5 a�os de
antig�edad y tampoco puede tener m�s del 50% del personal a su cargo
(contando directos e indirectos) a excepci�n del gerente general�. Se sabe que en
la actualidad la regla se cumple y existe un �nico gerente general.                     */
vendedor.
El c�lculo de la comisi�n est� dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, m�s un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.                                  */
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.                                                     */
tenga m�s de 20 productos asignados, si un rubro tiene m�s de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpci�n �RUBRO REASIGNADO�, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada                          */
automaticamante se controle que en una misma factura no puedan venderse m�s
de dos productos con composici�n. Si esto ocurre debera rechazarse la factura.         */
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
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asign�rsele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.                     */
que la composici�n de los productos sea recursiva, o sea, que si el producto A
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.                                                   */
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.                            */
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los dep�sitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no est� asignado a ningun cliente, se
deber�n ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se ir�n aumentando la cantidad de dep�sitos
progresivamente para cada empleado.             
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le
corresponde es aquel que le vendi� m�s facturas a ese cliente, si en particular un
cliente no tiene facturas compradas se le deber� asignar el vendedor con m�s
venta de la empresa, o sea, el que en monto haya vendido m�s.                         */
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla                             */
pueda comprar m�s de 100 unidades en el mes de ning�n producto, si esto
ocurre no se deber� ingresar la operaci�n y se deber� emitir un mensaje �Se ha
superado el l�mite m�ximo de compra de un producto�. Se sabe que esta regla se
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
		print('Se ha superado el l�mite m�ximo de compra de un producto')
		
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

/* ---------------- EJERCICIO N�31 ----------------------
31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener m�s de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condici�n, si no existe un jefe para
asignarle se le deber� colocar como jefe al gerente general que es aquel que no
tiene jefe                                                                                */

/* ----------------- EJERCICIOS DE PARCIAL --------------------- */