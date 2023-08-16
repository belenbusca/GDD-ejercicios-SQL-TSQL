
-- 34??


/* ---------------- EJERCICIO N°1 ----------------------
1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.
*/
SELECT *
FROM Cliente

/*VEO MI UNIVERSO: Primero miro FROM, trabajo con clientes. Miro las columnas de cliente,
ya se q tengo 6 columnas maximo, ahora veo cuales me pide. Filtro y por ultimo ordeno.
me pide razon social y cod cliente para ordenarlo. ORDER BY por defecto es de mayor a menor (seria ASC), 
si me pedia mayor a menor debia poner
ORDER BY clie_codigo DEC */

SELECT clie_codigo, clie_razon_social
FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo

/* ---------------- EJERCICIO N°2 ----------------------
2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/

SELECT prod_codigo, prod_detalle
FROM Item_Factura JOIN Producto ON (item_producto = prod_codigo)
				  JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad) DESC

/* ---------------- EJERCICIO N°3 ----------------------
3.Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.*/

SELECT prod_codigo, prod_detalle, SUM(stoc_cantidad)
FROM Producto JOIN STOCK ON stoc_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle

/* ---------------- EJERCICIO N°4 ----------------------
4. Realizar una consulta que muestre para TODOS los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.*/

/*ATOMICIDAD EN SELECT
OJO el universo, si yo agregos joins el universo aumenta, usamos stock en una subconsulta para no agregarla en join. 
No necesitamos agrandar el universo, no hay que usar join en este caso
Si la PK es doble y yo solo joineo con una parte de la pk, ya se que va a haber filas repetidas. 
Stock tiene como PKs stoc_producto y stoc_deposito, nosotros entre producto y stock tenemos el prod codigo en comun, el deposito no,
por lo que sabemos que se van a repetir filas -> hacemos un subselect en el where :)
La subquery no participa en la atomicidad, se usa cuando no queremos q nuestro universo se vea alterado
*/ 

SELECT prod_codigo, prod_detalle, count(comp_producto) as cant_componentes
FROM Producto LEFT JOIN Composicion ON comp_producto = prod_codigo
WHERE prod_codigo in (SELECT stoc_producto
					  FROM STOCK
					  GROUP BY stoc_producto
					  HAVING avg(stoc_cantidad) > 100) -- en clase pusimos > 1 para que no de todo 0 en cant
GROUP BY prod_codigo, prod_detalle

/*  ---------------- EJERCICIO N°5 ----------------------
5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.*/

SELECT prod_codigo, prod_detalle, SUM(item_cantidad)
FROM Producto JOIN Item_Factura ON (item_producto = prod_codigo)
			  JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
HAVING SUM(item_cantidad) > (SELECT SUM(item_cantidad)
				FROM Item_Factura JOIN Factura ON 
				(fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero) and item_producto = prod_codigo
				WHERE YEAR(fact_fecha) = 2011) -- aca puede ir el "and item_producto = prod_codigo" en vez de ir en el join

-- NO AFECTA ATOMICIDAD JOIN CON FACTURA, porque cada una de sus pks se matchea con las de item factura que ya estaban.
-- hay 19484 filas joineando item factura y tambien hay 19484 filas joineando depsues factura
	SELECT * FROM Producto JOIN Item_Factura ON (item_producto = prod_codigo)
						   JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)					 

/*- TOMA SIN EL GROUP BY EN LA SUBCONSULTA porque no muestra un campo que no es calculado, 
directamente muestra el CAMPO CALCULADO con el SUM

- and item_producto = prod_codigo (TAMBIEN PODRIA IR EN UN WHERE en vez de ir en el JOIN, ver + abajo como quedaria)
Necesito saber cuanto se vendio ESE producto, si yo no pongo esto me devuelve la totalidad
de lo que se vendio en el 2011, para todos los productos. Conoce el prod_codigo porque es una subconsulta

- Es un subselect DINAMICO, porque depende del select de afuera, lo va a ejecutar por cada producto del que hablamos en el select
de afuera, lo llama 629 veces que es la cantidad de filas que habia en la consulta sin la subconsulta
Si yo quiero ejecutar un SUBSELECT DINAMICO solito, sin su contexto, tira error, no ejecuta. En cambio el ESTATICO si 
compila, porque arroja siempre lo mismo*/

SELECT prod_codigo, prod_detalle, SUM(item_cantidad)
FROM Producto JOIN Item_Factura ON (item_producto = prod_codigo)
			  JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
HAVING SUM(item_cantidad) > (SELECT SUM(item_cantidad)
			FROM Item_Factura JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
			WHERE YEAR(fact_fecha) = 2011 and item_producto = prod_codigo)

/* ---------------- EJERCICIO N°6 ----------------------
6. Mostrar PARA TODOS los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/

select rubr_id, rubr_detalle, count(distinct prod_codigo), sum(isnull(stoc_cantidad, 0))
from Rubro left join Producto on rubr_id = prod_rubro
		   join STOCK on stoc_producto = prod_codigo
where prod_codigo in (select stoc_producto from stock
					  group by stoc_producto
					  having sum(stoc_cantidad) > (select sum(stoc_cantidad) from stock
												   where stoc_producto = '00000000' and stoc_deposito = '00'))
group by rubr_id, rubr_detalle

-- count cuenta filas, si una fila tiene null, no la cuenta

/* En este caso necesitamos hacer un JOIN STOCK porque necesitamso el stock para hacer la suma, no puedo usarlo con
subconsultas como en el ej 4.

puede haber problemas de atomicidad al joinear con stock, el count(prod_codigo) contaria + de 1 vez si el codigo esta repetido
por ej. habia 121 caramelos, pero al joinear con stock hay 284. SOLUCION: Ponerle un DISTINCT
Solo sivrve como segunda forma de hacer group by, funciona en el count

Otro poblema es el sum de stoc cantidad. Al haber hecho un left join con RUBRO, si no hay un producto igual aparece el rubro, pero 
esta en NULL. SOLUCION> Agregar un isnull y que le ponga 0.*/

SELECT rubr_id, rubr_detalle, count(distinct prod_codigo) as cant_articulos, sum(isnull(stoc_cantidad,0))
FROM Rubro LEFT JOIN Producto ON (prod_rubro = rubr_id) 
        /*LEFT*/JOIN STOCK ON (stoc_producto = prod_codigo)
WHERE prod_codigo in (SELECT stoc_producto
						FROM Stock 
						GROUP BY stoc_producto
						HAVING sum(stoc_cantidad) > (SELECT sum(stoc_cantidad)
													 FROM STOCK
													 WHERE stoc_producto = '00000000' and stoc_deposito = '00'))
GROUP BY rubr_id, rubr_detalle

/*HACEMOS EL SUBCONJUNTO DE LOS ART CON STOCK MAYOR AL ESPECIFICADO y luego lo agregamos en nuestro select
original
AHORA EL LEFT NO TIENE SENTIDO, porque yo estoy pidiendo los articulos que tengan un stock mayor a un determinado articulo
Por lo que estoy tomando los que tienen stock, los que no tengan stock no van a estar en ese subconjunto, por eso 
*/
SELECT stoc_producto
FROM Stock 
GROUP BY stoc_producto
HAVING sum(stoc_cantidad) > (SELECT sum(stoc_cantidad)
							 FROM STOCK
							 WHERE stoc_producto = '00000000' and stoc_deposito = '00')
	
/* ---------------- EJERCICIO N°7 ----------------------
7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio = 10, 
mayor precio = 12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.*/

SELECT 
	prod_codigo, 
	prod_detalle, 
	max(item_precio) 'Mayor precio', 
	min(item_precio) 'Menor precio',
	((max(item_precio) - min(item_precio)) / min(item_precio)) * 100 'Diferencia precio'
FROM Producto JOIN Item_Factura ON item_producto = prod_codigo
WHERE prod_codigo IN (
	SELECT stoc_producto
	FROM STOCK
	GROUP BY stoc_producto
	HAVING SUM(stoc_cantidad) > 0
	)
GROUP BY prod_codigo, prod_detalle 

/*Funciona tambien usando having en vez de Where, pero es mejor con where porque de esta froma primero filtra y 
despues hace las cuentas, en cambio con having, hace todas las cuentas y despues filtra
SIEMPRE SE FILTRA CON HAVING SI NO SE PUEDE CON EL WHERE, solo se usa para filtrar depsues del group by*/

/*  ---------------- EJERCICIO N°8 ----------------------

8.Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del artículo, 
stock del depósito que más stock tiene.*/

SELECT prod_detalle, max(stoc_cantidad)
FROM Stock JOIN Producto ON (prod_codigo = stoc_producto)
WHERE stoc_cantidad > 0 -- puede haber stock negativo en la vida real y lo podria contar
GROUP BY prod_detalle
HAVING count(*) = (select count(*) FROM DEPOSITO)

-- CUANTOS DEPOSITOS TENGO?:
select count(*) FROM DEPOSITO

/*  ---------------- EJERCICIO N°9 ----------------------

9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del mismo (del jefe) y 
la cantidad de depósitos que ambos tienen asignados.*/

SELECT e.empl_jefe, e.empl_codigo, rtrim(j.empl_nombre)+' '+rtrim(j.empl_apellido), count(depo_encargado)
FROM Empleado e	JOIN DEPOSITO ON (depo_encargado = empl_codigo or depo_encargado = empl_jefe)
			    JOIN Empleado j ON j.empl_codigo = e.empl_jefe
GROUP BY e.empl_jefe, e.empl_codigo, rtrim(j.empl_nombre)+' '+rtrim(j.empl_apellido)

/*  ---------------- EJERCICIO N°10 ----------------------

10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos vendidos 
en la historia. Además mostrar de esos productos, quien fue el cliente que mayor compra realizo.*/

-- 10 MAS VENDIDOS --
SELECT top 10 item_producto
FROM Item_Factura
GROUP BY item_producto
ORDER BY Sum(item_cantidad) DESC

-- 10 MENOS VENDIDOS --
SELECT top 10 item_producto
FROM Item_Factura
GROUP BY item_producto
ORDER BY Sum(item_cantidad)

----- se resuelve asi:
SELECT prod_codigo, prod_detalle, (SELECT top 1 fact_cliente
								   FROM Factura JOIN Item_Factura ON 
								   (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
								   WHERE item_producto = prod_codigo
								   GROUP BY fact_cliente
								   ORDER BY sum(item_cantidad) DESC
								   ) 'Cliente mas comprador'
FROM Producto
WHERE prod_codigo IN (
			SELECT top 10 item_producto
			FROM Item_Factura
			GROUP BY item_producto
			ORDER BY Sum(item_cantidad) DESC)
   or prod_codigo IN (
			SELECT top 10 item_producto
			FROM Item_Factura
			GROUP BY item_producto
			ORDER BY Sum(item_cantidad))

/*  ---------------- EJERCICIO N°11 ----------------------

11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de 
productos vendidos y el monto de dichas ventas sin impuestos. 
Los datos se deberán ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga, 
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para el año 2012.*/

/* se joinea con producto para poder llegar a item prducto que es quien tiene las cantidades, pero esta no tiene 
familia, lo tiene producto
*/

SELECT fami_detalle, count(distinct item_producto) 'Cant dif prod vendidos', sum(item_cantidad*item_precio) 'Monto'
FROM Familia JOIN Producto ON prod_familia = fami_id JOIN Item_Factura ON item_producto = prod_codigo 
WHERE fami_id IN (SELECT fami_id
				  FROM Familia JOIN Producto ON prod_familia = fami_id
							   JOIN Item_Factura ON item_producto = prod_codigo
							   JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
				  WHERE year(fact_fecha) = 2012
				  GROUP BY fami_id
				  HAVING sum(item_cantidad*item_precio) > 20000)									  
GROUP BY fami_detalle
ORDER BY 'Cant dif prod vendidos' DESC

/*  ---------------- EJERCICIO N°12 ----------------------

12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe promedio pagado 
por el producto, cantidad de depósitos en los cuales hay stock del producto y stock actual del producto 
en todos los depósitos. Se deberán mostrar aquellos productos que hayan tenido operaciones en el año 2012 y 
los datos deberán ordenarse de mayor a menor por monto vendido del producto.*/ 

/*ME SEGMENTASTE con prod codigo, por eso lo necesita en el group by gramaticalmente. Cuando hace el segundo for para filtrar
con prod cod, independientemente si lo mostras o no. Ocurre cuando filtres por un campo interior, si adentro de un subselect
filtras por un campo, aunque no lo muestres. Siempre es asi.
*/

SELECT prod_detalle, 
	   count(distinct fact_cliente) 'cant clientes', 
	   cast(avg(item_precio) as decimal(10,2)) 'promedio pagado',

	   (SELECT count(distinct stoc_deposito)
		FROM STOCK
		WHERE stoc_producto = item_producto -- Cuando hago un join siemore especifico, bueno en el subselect tmb
		/*FILTRAMOS EN EL SUBSELECT, item producto lo busca afuera, por lo que va en el group by de afuera*/
		GROUP BY stoc_producto
		HAVING sum(stoc_cantidad) > 0) 'cant depositos stock', --puede haber stock negativo en la vida real

		(SELECT sum(stoc_cantidad)
		FROM STOCK
		WHERE stoc_producto = item_producto
		GROUP BY stoc_producto
		HAVING sum(stoc_cantidad) > 0) 'stock total depositos' --puede haber stock negativo en la vida real

FROM Producto JOIN Item_Factura ON item_producto = prod_codigo
			  JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE item_producto in (SELECT item_producto
						FROM Item_Factura JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
						WHERE year(fact_fecha) = 2012)
-- WHERE year(fact_fecha) = 2012 MAL esto muestra las facturas del 2012, agarra unicamente las ventas del 2012
-- nosotros buscamos TODAS las ventas (no solo las ventas del 2012) que hubo PARA los prod que tuvieron ventas en el 2012
GROUP BY prod_detalle, item_producto -- por haber filtrado en un subselect tiene q estar aca
ORDER BY sum(item_cantidad*item_precio) DESC


/*   ---------------- EJERCICIO N°13 ----------------------

13. Realizar una consulta que retorne para cada producto que posea composición nombre del producto, precio del producto,
	precio de la sumatoria de los precios por la cantidad de los productos que lo componen. 
	Solo se deberán mostrar los productos que estén compuestos por más de 2 productos 
	y deben ser ordenados de mayor a menor por cantidad de productos que lo componen. */

 SELECT pp.prod_detalle 'combo', 
		pp.prod_precio 'precio prod composicion',
		sum(comp_cantidad*pc.prod_precio) 'precio combo'
 FROM Composicion JOIN Producto pp ON comp_producto   = pp.prod_codigo -- el comp prod es el codigo del producto promo, el que adenro tiene prod indiv
				  JOIN Producto pc ON comp_componente = pc.prod_codigo -- el componente es el individual
-- estos join amplia mi universo en COLUMNAS, trae + info, pero no afecta la atomicidad, no + universo en filas. Porque se unen por la primary key en composicion
 --where comp_cantidad >= 2 MAL porque esto es la cant que tiene cada componente en el combo, ej.: 4 pilas. Hay que ver la cant de componentes en 1 combo ej.: linterna con pilas 2 (las pilas y la linterna)
 GROUP BY pp.prod_detalle, pp.prod_precio
 HAVING count(comp_producto) >= 2
 ORDER BY count(comp_producto) desc


 -- SELECT PARA VER COMO ESTA COMPUESTO EL UNIVERSO
 SELECT *
 FROM Composicion JOIN Producto pp ON comp_producto   = pp.prod_codigo -- el comp prod es el codigo del producto promo, el que adenro tiene prod indiv
				  JOIN Producto pc ON comp_componente = pc.prod_codigo

/*    ---------------- EJERCICIO N°14 ----------------------
14. Escriba una consulta que retorne una estadística de ventas por cliente. 
Los campos que debe retornar son:
- Código del cliente
- Cantidad de veces que compro en el último año
- Promedio por compra en el último año
- Cantidad de productos diferentes que compro en el último año
- Monto de la mayor compra que realizo en el último año --- aca use top 1 y es max, me confunde un poquito ------------!!!!--------------
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna */

select 
	clie_codigo, 
	count(distinct fact_numero+fact_tipo+fact_sucursal) veces_compradas,
	avg(fact_total) promedio,
	count(distinct item_producto) cant_productos,
	max(fact_total) max_compra
from cliente join Factura on clie_codigo = fact_cliente
			 join Item_Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
where year(fact_fecha) in (select top 1 year(fact_fecha)
								from Factura
								order by year(fact_fecha) desc)
group by clie_codigo 
order by veces_compradas

/*   ---------------- EJERCICIO N°15 ----------------------
Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. 
El resultado debe mostrar el código y descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:

PROD1 DETALLE1          PROD2 DETALLE2           VECES
1731  MARLBORO KS       1718  PHILIPS MORRIS KS  507
1718  PHILIPS MORRIS KS 1705  PHILIPS MORRIS BOX 10562
*/
-- la pk compuesta de factura la igual con 2 copias de item factura y esos items los igualo con su respectivo producto
select p1.prod_codigo producto1, p1.prod_detalle, p2.prod_codigo producto2, p2.prod_detalle, count(fact_numero+fact_tipo+fact_sucursal) veces_vendidas
from Producto p1 join Item_Factura i1 on p1.prod_codigo = i1.item_producto
				 join Factura on fact_numero+fact_tipo+fact_sucursal = i1.item_numero+i1.item_tipo+i1.item_sucursal
				 join Item_Factura i2 on i2.item_numero+i2.item_tipo+i2.item_sucursal = fact_numero+fact_tipo+fact_sucursal
				 join Producto p2 on p2.prod_codigo = i2.item_producto
where p1.prod_codigo > p2.prod_codigo -- no se usa != porque eso hace que se repita siendo linternas prod1, malboro prod2 y despues malboro prod1 y linternas prod2
--uso > 
group by p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
having count(fact_numero+fact_tipo+fact_sucursal) > 500
order by count(fact_numero+fact_tipo+fact_sucursal)

-- POR QUE USAR > Y NO !=  ??
/*
ITEM FACTURA 1 ---- 1, 2, 3 (prod q aparecen)         Si uso != esto me va a dar: (1,2), (1,3), (2,1), (2,3), (3,1), (3,2)
   |												  Se repiten los pares invertidos, yo deberia agarrar este conj: (2,1), (3,1), (3,2)
FACTURA												  o este conj.: (1,2), (1,3), (2,3). Para eso, uso el > o el <.
   |												  Si uso p1.prod_codigo > p2.prod_codigo me queda:
ITEM FACTURA 2 ---- 1, 2, 3						   	  (2,1), (3,1), (3,2)
*/


/*    ---------------- EJERCICIO N°16 ----------------------
16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos 
clientes cuyas ventas son inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012
*/

 select clie_razon_social, sum(item_cantidad),
 			(select top 1 item_producto
			from item_factura join Factura on (item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero)
			where year(fact_fecha) = 2012 and clie_codigo = fact_cliente
			group by item_producto
			order by SUM(ITEM_CANTIDAD) desc)
 from cliente join Factura on (fact_cliente = clie_codigo) 
 join Item_Factura on (item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero)
 where year(fact_fecha) = 2012
 group by clie_razon_social,clie_codigo
 having sum(item_cantidad * item_precio) < 1/3 * (select avg(item_cantidad * item_precio)
											from item_factura
											where item_producto =
												(select top 1 item_producto
												from item_factura join Factura on (item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero)
												where year(fact_fecha) = 2012
												group by item_producto
												order by SUM(ITEM_CANTIDAD) desc))


/*    ---------------- EJERCICIO N°17 ----------------------
17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto. */

select 
	(CONCAT(YEAR(fe.fact_fecha), RIGHT(CONCAT('0', MONTH(fe.fact_fecha)), 2))) PERIODO, 
	-- right(cadena,longitud):select right('buenos dias',8); retorna "nos dias".
	-- otra froma es YEAR(fe.fact_fecha)*100+month(fe.fact_fecha)
	prod_codigo PROD,
	prod_detalle DETALLE,
	sum(item_cantidad) CANTIDAD_VENDIDA,
	isnull((select sum(item_cantidad)
			from Item_Factura join Factura fi on fi.fact_numero+fi.fact_tipo+fi.fact_sucursal = item_numero+item_tipo+item_sucursal
			where month(fe.fact_fecha) = month(fi.fact_fecha) and year(fi.fact_fecha) = year(fe.fact_fecha) - 1)
	, 0) VENTAS_ANIO_ANT,
	count(*) CANT_FACTURAS
from Producto join Item_Factura on prod_codigo = item_producto
			  join Factura fe on fe.fact_numero+fe.fact_tipo+fe.fact_sucursal = item_numero+item_tipo+item_sucursal
group by prod_codigo, prod_detalle, YEAR(fe.fact_fecha), MONTH(fe.fact_fecha)
order by PERIODO, PROD

/*    ---------------- EJERCICIO N°18 ----------------------
18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro. */

select 
	rubr_detalle DETALLE_RUBRO,
	isnull(sum(item_cantidad*item_precio), 0) VENTAS,
	isnull((select top 1 prod_codigo
			from Producto join Item_Factura on prod_codigo = item_producto
			where prod_rubro = rubr_id
			group by prod_codigo
			order by sum(item_cantidad) desc), '-') PROD1,
	isnull((select top 1 prod_codigo
		    from Producto join Item_Factura on prod_codigo = item_producto
		    where prod_rubro = rubr_id and prod_codigo not in (select top 1 prod_codigo
															  from Producto join Item_Factura on prod_codigo = item_producto
															  where prod_rubro = rubr_id
															  group by prod_codigo
														      order by sum(item_cantidad) desc)
			group by prod_codigo
			order by sum(item_cantidad) desc), '-') PROD2,
	isnull((select top 1 fact_cliente
			from Item_Factura join Producto on prod_codigo = item_producto
							  join Factura on fact_numero+fact_tipo+fact_sucursal=item_numero+item_tipo+item_sucursal
			where prod_rubro = rubr_id and fact_fecha > (select dateadd(day, -30, max(fact_fecha))
														 from Factura)
			group by  fact_cliente
			order by sum(item_cantidad) desc ), '-') CLIENTE
from Rubro join Producto on rubr_id = prod_rubro
		   join Item_Factura on item_producto = prod_codigo
group by rubr_detalle, rubr_id
order by count(distinct item_producto) desc

/*    ---------------- EJERCICIO N°19 ----------------------
19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
- Codigo de producto
- Detalle del producto
- Codigo de la familia del producto
- Detalle de la familia actual del producto
- Codigo de la familia sugerido para el producto
- Detalla de la familia sugerido para el producto

La familia sugerida para un producto es 
	la que poseen la mayoria de los productos cuyo detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. 
Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente */

select 
	p1.prod_codigo, p1.prod_detalle, 
	fami_id, fami_detalle,
	(select top 1 prod_familia
	 from Producto p2
	 where LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
	 group by p2.prod_familia
	 order by count(*) desc, prod_familia) cod_fami_sugerida,
	(select top 1 fami_detalle
	 from Producto p2 join Familia on fami_id = p2.prod_familia
	 where LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
	 group by fami_id, fami_detalle
	 order by count(*) desc, fami_id) detalle_fami_sugerida
from Producto p1 join Familia on fami_id = p1.prod_familia
where prod_familia not in (select top 1 p2.prod_familia
						   from Producto p2 
						   where LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
						   group by p2.prod_familia
						   order by count(*) desc, prod_familia)
order by prod_detalle

/*    ---------------- EJERCICIO N°20 ----------------------
20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje 2012. 
El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como 
	la cantidad de facturas que superen los 100 pesos que haya vendido en el año, 
para los que tengan menos de 50 facturas en el año el calculo del 
	puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año. */

select top 3
	empl_codigo, 
	empl_nombre, 
	empl_apellido, 
	year(empl_ingreso) anio_ingreso, 
	case
		when((select count(fact_vendedor)
			 from Factura
			 where fact_vendedor = empl_codigo 
				and year(fact_fecha) = 2011) >= 50)
	    then(select count(*)
			  from Factura
			  where fact_vendedor = empl_codigo 
				and year(fact_fecha) = 2011
				and fact_total > 100 )
		else (select (0.5*count(fact_vendedor))
			  from Factura
			  where year(fact_fecha) = 2011 and fact_vendedor in (select es.empl_codigo
																  from Empleado es
																  where es.empl_jefe = empl_codigo))
	end puntaje_2011,
	case
		when((select count(fact_vendedor)
			 from Factura
			 where fact_vendedor = empl_codigo 
				and year(fact_fecha) = 2012) >= 50)
	    then(select count(*)
			  from Factura
			  where fact_vendedor = empl_codigo 
				and year(fact_fecha) = 2012
				and fact_total > 100 )
		else (select (0.5*count(fact_vendedor))
			  from Factura
			  where year(fact_fecha) = 2012 and fact_vendedor in (select es.empl_codigo
																  from Empleado es
																  where es.empl_jefe = empl_codigo))
	end puntaje_2012
from Empleado
order by 6 desc

/*    ---------------- EJERCICIO N°21 ----------------------
21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta 
	cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar son:
	- Año
	- Clientes a los que se les facturo mal en ese año
	- Facturas mal realizadas en ese año */

select year(fact_fecha) anio, count(distinct fact_cliente) cant_clie_mal_fact, count(*) cant_malas_fact
from Factura
where (fact_total - fact_total_impuestos - (select sum(item_cantidad*item_precio)
											from Item_Factura
											where item_numero+item_tipo+item_sucursal = fact_numero+fact_tipo+fact_sucursal)) > 1
group by year(fact_fecha) 

/*    ---------------- EJERCICIO N°22 ----------------------
22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
	 Detalle del rubro
	 Numero de trimestre del año (1 a 4)
	 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
	menos un producto del rubro
	 Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica. */

select 
	rubr_detalle,
	case -- existe una funcion que lo hace: DATEPART(QUARTER, fact_fecha) Trimestre 
		when(month(fact_fecha) <= 3)
		then 1
		when(month(fact_fecha) <= 6)
		then 2
		when(month(fact_fecha) <= 9)
		then 3
		else 4
	end trimestre,
	count(distinct fact_numero+fact_tipo+fact_sucursal) cant_fact_emitidas,
	count(distinct item_producto) cant_prod
from Rubro join Producto on rubr_id = prod_rubro
		   join Item_Factura on item_producto = prod_codigo
		   join Factura on item_numero+item_tipo+item_sucursal = fact_numero+fact_tipo+fact_sucursal
where prod_codigo not in (select comp_producto from Composicion)
group by rubr_detalle, 
		 case
			when(month(fact_fecha) <= 3)
			then 1
			when(month(fact_fecha) <= 6)
			then 2
			when(month(fact_fecha) <= 9)
			then 3
			else 4
		  end
having count(distinct fact_numero+fact_tipo+fact_sucursal) > 100
order by 1, 3 desc

/*    ---------------- EJERCICIO N°23 ----------------------
23. Realizar una consulta SQL que para cada año muestre :
	 Año
	 El producto con composición más vendido para ese año.
	 Cantidad de productos que componen directamente al producto más vendido
	 La cantidad de facturas en las cuales aparece ese producto.
	 El código de cliente que más compro ese producto.
	 El porcentaje que representa la venta de ese producto respecto al total de venta
	  del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente */

select 
	year(fact_fecha) anio,
	item_producto,
	(select count(comp_componente)
	 from Composicion
	 where comp_producto = item_producto) cant_componentes,
	 count(distinct fact_numero+fact_tipo+fact_sucursal) cant_facturas,
	 (select top 1 f2.fact_cliente
	  from Factura f2 join Item_Factura ifi on ifi.item_numero+ifi.item_tipo+ifi.item_sucursal=f2.fact_numero+f2.fact_tipo+f2.fact_sucursal
	  where ifi.item_producto = item_producto and year(f2.fact_fecha) = year(fact_fecha)
	  group by f2.fact_cliente
	  order by sum(ifi.item_cantidad) desc) clie_codigo,
	 (sum(item_cantidad*item_precio)*100/ (select sum(ifi.item_cantidad*ifi.item_precio)
										   from Factura f2 join Item_Factura ifi on ifi.item_numero+ifi.item_tipo+ifi.item_sucursal=f2.fact_numero+f2.fact_tipo+f2.fact_sucursal
										   where year(f2.fact_fecha) = year(fact_fecha))) porcentaje
from Factura join Item_Factura on item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
where item_producto in (select top 1 comp_producto
						from Composicion join Item_Factura ifi on comp_producto = ifi.item_producto
										 join Factura fi on ifi.item_numero+ifi.item_tipo+ifi.item_sucursal=fi.fact_numero+fi.fact_tipo+fi.fact_sucursal
					    where year(fact_fecha) = year(fi.fact_fecha)
						group by comp_producto
						order by sum(item_cantidad) desc)
group by year(fact_fecha), item_producto
order by sum(item_cantidad*item_precio) desc

/*    ---------------- EJERCICIO N°24 ----------------------
24. Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
	 Código de Producto
	 Nombre del Producto
	 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente. */

select prod_codigo, prod_detalle, sum(item_cantidad) unidades_facturadas
from Producto join Item_Factura on item_producto = prod_codigo
			  join Factura on item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
where prod_codigo in (select comp_producto
					  from Composicion)
	  and fact_vendedor in (select top 2 empl_codigo
							from Empleado
							order by empl_comision desc)
group by prod_codigo, prod_detalle
having count(item_producto) >= 5
order by 3 desc

/*    ---------------- EJERCICIO N°25 ----------------------
25. Realizar una consulta SQL que para cada año y familia muestre :
	a. Año
	b. El código de la familia más vendida en ese año.
	c. Cantidad de Rubros que componen esa familia.
	d. Cantidad de productos que componen directamente al producto más vendido de
	esa familia.
	e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
	familia.
	f. El código de cliente que más compro productos de esa familia.
	g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente. */

select
	year(fact_fecha) anio,
	fami_id,
	count(distinct prod_rubro) cant_rubros,
	isnull((select top 1 count(comp_componente)
			from Producto join Composicion on comp_producto = prod_codigo
						  join Item_Factura on prod_codigo = item_producto
						  join Factura fi on item_numero+item_tipo+item_sucursal=fi.fact_numero+fi.fact_tipo+fi.fact_sucursal
			where prod_familia = fami_id and year(fi.fact_fecha) = year(fact_fecha)
			group by prod_codigo
			order by sum(item_cantidad) desc), 1) cant_componentes,
	count(distinct fact_numero+fact_tipo+fact_sucursal) cant_facturas,
	(select top 1 fact_cliente 
	 from Producto join Item_Factura on prod_codigo = item_producto
				   join Factura fi on item_numero+item_tipo+item_sucursal=fi.fact_numero+fi.fact_tipo+fi.fact_sucursal
	 where prod_familia = fami_id and year(fi.fact_fecha) = year(fact_fecha)
	 group by fact_cliente
	 order by sum(item_cantidad) desc) cliente,
	 (sum(item_cantidad*item_precio)*100)/(select sum(item_cantidad*item_precio) 
										   from Item_Factura join Factura fi on item_numero+item_tipo+item_sucursal=fi.fact_numero+fi.fact_tipo+fi.fact_sucursal 
										   where year(fi.fact_fecha) = year(fact_fecha)) porcentaje
from Familia join Producto on fami_id = prod_familia
			 join Item_Factura on item_producto = prod_codigo
			 join Factura on item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
where fami_id in (select top 1 fami_id
				  from Familia join Producto on fami_id = prod_familia
							   join Item_Factura on item_producto = prod_codigo
							   join Factura fi on item_numero+item_tipo+item_sucursal=fi.fact_numero+fi.fact_tipo+fi.fact_sucursal
				  where year(fi.fact_fecha) = year(fact_fecha)
				  group by fami_id
				  order by sum(item_cantidad) desc)
group by year(fact_fecha), fami_id
order by sum(item_cantidad*item_precio) desc

/*    ---------------- EJERCICIO N°26 ----------------------
26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
	 Empleado
	 Depósitos que tiene a cargo
	 Monto total facturado en el año corriente
	 Codigo de Cliente al que mas le vendió
	 Producto más vendido
	 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor. */

select 
	empl_codigo, 
	count(distinct depo_codigo) cantDepositos,
	(select sum(fi.fact_total)
	 from Factura fi
	 where year(fi.fact_fecha) = year(fact_fecha) and fact_vendedor = empl_codigo) montoFactruado,
	(select top 1 fact_cliente
	 from Factura
	 where fact_vendedor = empl_codigo
	 group by fact_cliente
	 order by sum(fact_total) desc) clienteMasComprador,
	(select top 1 item_producto
	 from Item_Factura join Factura on fact_numero+fact_tipo+fact_sucursal=item_numero+item_tipo+item_sucursal
	 where fact_vendedor = empl_codigo
	 group by item_producto
	 order by sum(item_cantidad) desc) prodMasVendido,
	((select sum(fi.fact_total)
	  from Factura fi
	  where year(fi.fact_fecha) = year(fact_fecha)
	   and fact_vendedor = empl_codigo)*100/(select sum(fe.fact_total)
										      from Factura fe
											  where year(fe.fact_fecha) = year(fact_fecha))) Porcentaje
from DEPOSITO right join Empleado on depo_encargado = empl_codigo
			  left join Factura on fact_vendedor = empl_codigo
where year(fact_fecha) = (select max(year(fact_fecha)) from factura) -- year(GETDATE())
group by empl_codigo
order by 3 desc

/*    ---------------- EJERCICIO N°27 ----------------------
27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
	 Año
	 Codigo de envase
	 Detalle del envase
	 Cantidad de productos que tienen ese envase
	 Cantidad de productos facturados de ese envase
	 Producto mas vendido de ese envase
	 Monto total de venta de ese envase en ese año
	 Porcentaje de la venta de ese envase respecto al total vendido de ese año
Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor */

select 
	year(fact_fecha) anio,
	enva_codigo,
	enva_detalle,
	(select count(distinct prod_codigo) 
	 from Producto
	 where prod_envase = enva_codigo) cantProductos,
	count(distinct item_producto) cantProductosFact,
	(select top 1 item_producto
	 from Item_Factura join Producto on prod_codigo = item_producto
	 where prod_envase = enva_codigo
	 group by item_producto
	 order by sum(item_cantidad)) prodMasVendido,
	sum(item_cantidad*item_precio) montoTotal,
	(sum(item_cantidad*item_precio)*100)/(select sum(item_cantidad*item_precio) 
										  from Item_Factura join Factura fi on item_numero+item_tipo+item_sucursal=fi.fact_numero+fi.fact_tipo+fi.fact_sucursal 
										  where year(fi.fact_fecha) = year(fact_fecha)) porcentaje
from envases join Producto on enva_codigo = prod_envase 
			 join Item_Factura on prod_codigo = item_producto
			 join Factura on fact_numero+fact_tipo+fact_sucursal=item_numero+item_tipo+item_sucursal
group by year(fact_fecha), enva_codigo, enva_detalle 
order by 1, 5 desc

/*    ---------------- EJERCICIO N°28 ----------------------
28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
	 Año.
	 Codigo de Vendedor
	 Detalle del Vendedor
	 Cantidad de facturas que realizó en ese año
	 Cantidad de clientes a los cuales les vendió en ese año.
	 Cantidad de productos facturados con composición en ese año
	 Cantidad de productos facturados sin composicion en ese año.
	 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor*/

select
	year(fact_fecha) anio,
	fact_vendedor,
	empl_apellido,
	count(distinct fact_numero+fact_tipo+fact_sucursal) cantFacturas,
	count(distinct fact_cliente) cantClientes,
	isnull((select count(distinct item_producto)
			from Item_Factura join Factura fi on fi.fact_numero+fi.fact_tipo+fi.fact_sucursal = item_numero+item_tipo+item_sucursal
			where item_producto in (select comp_producto from Composicion)
			 and year(fi.fact_fecha) = year(fact_fecha)
			 and fi.fact_vendedor = fact_vendedor), 0) cantProdConComposicion,
	(select count(distinct item_producto)
	 from Item_Factura join Factura fi on fi.fact_numero+fi.fact_tipo+fi.fact_sucursal = item_numero+item_tipo+item_sucursal
	 where item_producto not in (select comp_producto from Composicion)
	  and year(fi.fact_fecha) = year(fact_fecha)
	  and fi.fact_vendedor = fact_vendedor) cantProdSinComposicion,
	sum(fact_total) montoTotal
from Factura join Empleado on fact_vendedor = empl_codigo
group by year(fact_fecha), fact_vendedor, empl_apellido
order by 1 desc, (select count(distinct item_producto)
			 from Item_Factura join Factura fi on fi.fact_numero+fi.fact_tipo+fi.fact_sucursal = item_numero+item_tipo+item_sucursal
			 where year(fi.fact_fecha) = year(fact_fecha)
			  and fact_vendedor = fi.fact_vendedor) desc

/*    ---------------- EJERCICIO N°29 ----------------------
29. Se solicita que realice una estadística de venta por producto para el año 2011, solo para
los productos que pertenezcan a las familias que tengan más de 20 productos asignados
a ellas, la cual deberá devolver las siguientes columnas:
	a. Código de producto
	b. Descripción del producto
	c. Cantidad vendida
	d. Cantidad de facturas en la que esta ese producto
	e. Monto total facturado de ese producto
Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor. */

select prod_codigo, prod_detalle,
	   sum(item_cantidad) cantVendida,
	   count(distinct fact_numero + fact_tipo + fact_sucursal) cantFacturas,
	   sum(item_cantidad*item_precio) montoToal
from Producto join Item_Factura on prod_codigo = item_producto
			  join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
where prod_familia in (select prod_familia
					   from Familia join Producto on prod_familia = fami_id
					   group by prod_familia
					   having count(distinct prod_codigo) > 20)
 and year(fact_fecha) = 2011
 group by prod_codigo, prod_detalle
 order by 3 desc


/*    ---------------- EJERCICIO N°30 ----------------------
30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:
	 Nombre del Jefe
	 Cantidad de empleados a cargo
	 Monto total vendido de los empleados a cargo
	 Cantidad de facturas realizadas por los empleados a cargo
	 Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario. 
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.*/

select j.empl_nombre, 
	   count(distinct e.empl_codigo) cantEmpleados,
	   sum(fact_total) montoTotal,
	   count(distinct fact_tipo+fact_sucursal+fact_numero) cantFacturas,
	   (select top 1 empl_nombre
	    from Empleado join Factura on fact_vendedor = empl_codigo
		where empl_jefe = j.empl_codigo and (year(fact_fecha)=2012)
		group by empl_nombre
		order by sum(fact_total) desc)
from Empleado j join Empleado e on e.empl_jefe = j.empl_codigo
				join factura on fact_vendedor = e.empl_codigo
where year(fact_fecha) = 2012
group by j.empl_nombre, j.empl_codigo
having count(distinct fact_tipo+fact_sucursal+fact_numero) > 10
order by 3 desc

/*    ---------------- EJERCICIO N°31 ----------------------
31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
	 Año.
	 Codigo de Vendedor
	 Detalle del Vendedor
	 Cantidad de facturas que realizó en ese año
	 Cantidad de clientes a los cuales les vendió en ese año.
	 Cantidad de productos facturados con composición en ese año
	 Cantidad de productos facturados sin composicion en ese año.
	 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor. */

---- REPETIDO, = 28 !!! ----

/*    ---------------- EJERCICIO N°32 ----------------------
32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
siguientes columnas:
	 Código de familia
	 Detalle de familia
	 Código de familia
	 Detalle de familia
	 Cantidad de facturas
	 Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas más de 10 veces. */

select f1.fami_id codFamilia1, f1.fami_detalle detalleFamilia1,
	   f2.fami_id codFamilia2, f2.fami_detalle detalleFamilia2,
	   count(distinct fact_numero+fact_tipo+fact_sucursal) cantFacturas,
	   sum(i1.item_cantidad*i1.item_precio)+sum(i2.item_cantidad*i2.item_precio) totalVendido
from Familia f1 join Producto p1 on f1.fami_id = p1.prod_familia join Item_Factura i1 on i1.item_producto = p1.prod_codigo
				join Factura on fact_numero+fact_tipo+fact_sucursal = i1.item_numero+i1.item_tipo+i1.item_sucursal
				join Item_Factura i2 on i2.item_numero+i2.item_tipo+i2.item_sucursal = fact_numero+fact_tipo+fact_sucursal
				join Producto p2 on p2.prod_codigo = i2.item_producto join Familia f2 on f2.fami_id = p2.prod_familia
where f1.fami_id > f2.fami_id
group by f1.fami_id, f1.fami_detalle, f2.fami_id, f2.fami_detalle
having count(distinct fact_numero+fact_tipo+fact_sucursal) > 10
order by 6

/*    ---------------- EJERCICIO N°33 ----------------------
33. Se requiere obtener una estadística de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto más vendido del año 2012. Se deberá mostrar:
	a. Código de producto
	b. Nombre del producto
	c. Cantidad de unidades vendidas
	d. Cantidad de facturas en la cual se facturo
	e. Precio promedio facturado de ese producto.
	f. Total facturado para ese producto
El resultado deberá ser ordenado por el total vendido por producto para el año 2012. */

select prod_codigo, prod_detalle, 
	   isnull(sum(item_cantidad), 0) cantUnidadesVendidas, 
	   count(distinct fact_numero+fact_tipo+fact_sucursal) cantFacturas,
	   isnull(avg(item_precio), 0) promedio,
	   isnull(sum(item_cantidad*item_precio), 0) total
from Producto join Item_Factura on item_producto = prod_codigo
			  join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
where prod_codigo in (select comp_componente from Composicion)
      and year(fact_fecha) = 2012 
	  and prod_codigo in (select top 1 item_producto
	                      from Item_Factura join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
						  where year(fact_fecha) = 2012 and item_producto in (select comp_producto from Composicion)
						  group by item_producto
						  order by sum(item_cantidad) desc)
group by prod_codigo, prod_detalle
order by 6

-------- consulta aparte mia porque quise ver cuales eran productos combo y cuales eran sus componentes --------
select p2.prod_codigo, p2.prod_detalle, p1.prod_codigo, p1.prod_detalle
from Composicion join Producto p2 on p2.prod_codigo = comp_componente join producto p1 on p1.prod_codigo = comp_producto
where p1.prod_codigo in (select comp_producto from Composicion)

/*    ---------------- EJERCICIO N°34 ----------------------
34. Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal
facturadas por cada mes del año 2011.
Se considera que una factura es incorrecta cuando en la misma factura se factutan productos de dos rubros diferentes. 
Si no hay facturas mal hechas se debe retornar 0. Las columnas que se deben mostrar son:
1- Codigo de Rubro
2- Mes
3- Cantidad de facturas mal realizadas. */
-- el sleect de afuera tiene que devolver todas las facturas, esten bien hechas o mal hechas, porque sino en que momento me deuvelve 0?
-- y en el subselect de la 3er columna, ahi si necesito la cant de facturas mal hechas, se hace con case porque si es subselect
-- si da 1 tiene que estar bien. 
select prod_rubro, 
	   month(fact_fecha) mes,
	   case when (select count(distinct prod_rubro) from Producto join Item_Factura i1 on i1.item_producto = prod_codigo
				  where i1.item_tipo + i1.item_sucursal + i1.item_numero = item_tipo + item_sucursal+item_numero 
				  group by i1.item_tipo + i1.item_sucursal + i1.item_numero)>1
			then (select count(distinct prod_rubro) from Producto join Item_Factura i1 on i1.item_producto = prod_codigo
				  where i1.item_tipo + i1.item_sucursal + i1.item_numero = item_tipo + item_sucursal+item_numero 
				  group by i1.item_tipo + i1.item_sucursal + i1.item_numero)
			else 0
			end as cantMalFacturadas
from Producto join Item_Factura on item_producto = prod_codigo
			  join Factura on fact_tipo + fact_sucursal + fact_numero   = item_tipo + item_sucursal+ item_numero 
where year(fact_fecha) = 2011 
group by prod_rubro, month(fact_fecha), item_tipo + item_sucursal+ item_numero 
order by 3

select prod_rubro,
       month(fact_Fecha) Mes,
	   CASE WHEN (select count(distinct prod_rubro)
				 from Producto
				 join Item_Factura on item_producto = prod_codigo
				 where i1.item_tipo + i1.item_sucursal +i1.item_numero  = item_tipo + item_sucursal+item_numero 
				 group by item_tipo+item_sucursal+item_numero )>1
			then (select count(distinct prod_rubro)
				 from Producto
				 join Item_Factura on item_producto = prod_codigo
				 where i1.item_tipo + i1.item_sucursal +i1.item_numero  = item_tipo + item_sucursal+item_numero 
				 group by item_tipo+item_sucursal+item_numero )
			else 0
			end as CantDeFacturas				
from Producto 
join Item_Factura i1 on i1.item_producto = prod_codigo
join Factura on i1.item_tipo + i1.item_sucursal + i1.item_numero  = fact_tipo + fact_sucursal + fact_numero  
--join factura on fact_tipo = i1.item_tipo and fact_sucursal = I1.item_sucursal and fact_numero = I1.item_numero --con esta da igual pero mas rapido
where year(fact_fecha) = 2011
group by prod_rubro,month(fact_Fecha),  i1.item_tipo + i1.item_sucursal + i1.item_numero
order by 3
/*    ---------------- EJERCICIO N°35 ----------------------
35. Se requiere realizar una estadística de ventas por año y producto, para ello se solicita
que escriba una consulta sql que retorne las siguientes columnas:
	 Año
	 Codigo de producto
	 Detalle del producto
	 Cantidad de facturas emitidas a ese producto ese año
	 Cantidad de vendedores diferentes que compraron ese producto ese año.
	 Cantidad de productos a los cuales compone ese producto, si no compone a ninguno
	se debera retornar 0.
	 Porcentaje de la venta de ese producto respecto a la venta total de ese año.
Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida.*/

select year(fact_fecha) anio, prod_codigo, prod_detalle, 
	   count(distinct fact_numero+fact_tipo+fact_sucursal) cantFacturas,
	   count(distinct fact_vendedor) cantVendedores,
	   isnull((select count(distinct comp_producto)
			   from Composicion
			   where comp_componente = prod_codigo), 0) cantProductos,
	   (sum(item_cantidad*item_precio)*100)/(select sum(fi.fact_total)
											 from Factura fi
											 where year(fi.fact_fecha) = year(fact_fecha)) porcentaje
from Producto join Item_Factura on prod_codigo = item_producto
			  join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
group by year(fact_fecha), prod_codigo, prod_detalle
order by 1, sum(item_cantidad) desc