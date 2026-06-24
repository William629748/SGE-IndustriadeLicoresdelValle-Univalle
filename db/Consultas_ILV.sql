
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

-- Consulta 9

SELECT
    'DISTRIBUIDOR' AS tipoCanal,
    d.razonSocial AS nombreCanal,
    d.tipoDistribuidor AS clasificacion,
    COUNT(v.idVenta) AS totalVentas,
    SUM(v.subTotal) AS subtotalAcumulado,
    SUM(v.iva) AS ivaAcumulado,
    SUM(v.total) AS totalFacturado,
    ROUND(AVG(v.total), 2) AS ticketPromedio
FROM Distribuidor d
INNER JOIN Venta v ON d.idDistribuidor = v.idDistribuidor
GROUP BY d.razonSocial, d.tipoDistribuidor

UNION ALL

SELECT
    'PUNTO DE VENTA' AS tipoCanal,
    p.nombreRazonSocial AS nombreCanal,
    p.tipoPunto AS clasificacion,
    COUNT(v.idVenta) AS totalVentas,
    SUM(v.subTotal) AS subtotalAcumulado,
    SUM(v.iva) AS ivaAcumulado,
    SUM(v.total) AS totalFacturado,
    ROUND(AVG(v.total), 2) AS ticketPromedio
FROM PuntoDeVenta p
INNER JOIN Venta v ON p.idPuntoVenta = v.idPuntoVenta
GROUP BY p.nombreRazonSocial, p.tipoPunto

ORDER BY totalFacturado DESC;


-- Consulta 10

SELECT
    f.numeroFactura,
    f.estadoFactura,
    f.total AS totalFacturado,
    v.metodoPago,
    v.estadoVenta,
    ce.nombreRazonSocial AS cliente,
    e.guiaTransporte,
    e.empresaTransportadora,
    e.estadoEnvio,
    e.fechaEnvio::DATE AS fechaDespacho,
    e.fechaEntrega,
    e.pagoEfectuado,
    c.nombre AS ciudadDestino
FROM Factura f
INNER JOIN Venta v ON f.idVenta = v.idVenta
INNER JOIN ClienteEmpresa ce ON v.idCliente = ce.idCliente
INNER JOIN Envio e ON v.idVenta = e.idVenta
INNER JOIN Ciudad c ON e.idCiudad = c.idCiudad
ORDER BY e.fechaEnvio DESC;