
--Consulta 1

SELECT
    nombreRazonSocial,
    telefono,
    correo
FROM ClienteEmpresa

INNER JOIN Ciudad
ON ClienteEmpresa.idCiudad=Ciudad.idCiudad

WHERE Ciudad.idCiudad='CIU001';

--Consulta 2

SELECT
    Ciudad.nombre,
    COUNT(*) clientes
FROM ClienteEmpresa
INNER JOIN Ciudad
ON ClienteEmpresa.idCiudad=Ciudad.idCiudad
GROUP BY Ciudad.nombre
HAVING COUNT(*) > 2;

--Consulta 3

SELECT
	Proveedor.razonSocial,
	Proveedor.nit,
	COUNT(CompraInsumo.idCompra) AS totalOrdenes,
	SUM(CompraInsumo.total) AS totalComprado
FROM Proveedor
INNER JOIN CompraInsumo ON Proveedor.idProveedor = CompraInsumo.idProveedor
GROUP BY Proveedor.razonSocial, Proveedor.nit
ORDER BY totalComprado DESC;

--Consulta 4

SELECT
	Insumo.nombre,
	Insumo.unidadMedida,
	SUM(DetalleCompraInsumo.cantidad) AS cantidadTotalComprada,
	SUM(DetalleCompraInsumo.subtotalLinea) AS valorTotalComprado
FROM Insumo
INNER JOIN DetalleCompraInsumo ON Insumo.idInsumo = DetalleCompraInsumo.idInsumo
Group by Insumo.nombre, Insumo.unidadMedida
ORDER BY cantidadTotalComprada DESC;

--Consulta 5

SELECT
	Insumo.nombre,
	Insumo.tipoInsumo,
	InventarioInsumo.cantidadDisponible,
	InventarioInsumo.stockMinimo,
	InventarioInsumo.stockMaximo,
	InventarioInsumo.ubicacionBodega
FROM Insumo
INNER JOIN InventarioInsumo ON Insumo.idInsumo=InventarioInsumo.idInsumo
Where InventarioInsumo.cantidadDisponible < InventarioInsumo.stockMinimo
ORDER BY InventarioInsumo.cantidadDisponible ASC;