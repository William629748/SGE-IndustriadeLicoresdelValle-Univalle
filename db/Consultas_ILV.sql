
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
<<<<<<< Updated upstream
ORDER BY InventarioInsumo.cantidadDisponible ASC;
=======
ORDER BY InventarioInsumo.cantidadDisponible ASC;
--Consulta 6
SELECT
    ClienteEmpresa.nombreRazonSocial,
    COUNT(Venta.idVenta) AS totalVentas,
    SUM(Venta.total) AS valorTotalComprado
FROM ClienteEmpresa
INNER JOIN Venta
    ON ClienteEmpresa.idCliente = Venta.idCliente
GROUP BY ClienteEmpresa.nombreRazonSocial
ORDER BY valorTotalComprado DESC;
--Consulta 7
SELECT
    Producto.nombre,
    COUNT(LoteProduccion.idLote) AS totalLotes,
    SUM(LoteProduccion.cantidadProducida) AS cantidadTotalProducida
FROM Producto
INNER JOIN LoteProduccion
    ON Producto.idProducto = LoteProduccion.idProducto
GROUP BY Producto.nombre
ORDER BY cantidadTotalProducida DESC;
--Consulta 8
SELECT
    Producto.nombre,
    InventarioProducto.stockActual,
    InventarioProducto.stockMaximo,
    InventarioProducto.ubicacionBodega
FROM Producto
INNER JOIN InventarioProducto
    ON Producto.idProducto = InventarioProducto.idProducto
WHERE InventarioProducto.stockActual > 0
ORDER BY InventarioProducto.stockActual DESC;