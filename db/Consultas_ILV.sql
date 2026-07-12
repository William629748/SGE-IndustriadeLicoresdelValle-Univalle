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
-- ============================================================
-- CONSULTAS BÁSICAS (11 a 20) — aspectos simples del negocio,
-- sin JOIN complejo ni GROUP BY, según lo exige el PDF para la
-- Entrega Final (10 básicas + 10 complejas = 20 en total).
-- ============================================================

--Consulta 11
-- Listado de todos los clientes activos, ordenados alfabéticamente.
SELECT idCliente, nombreRazonSocial, nit, tipoCliente
FROM ClienteEmpresa
WHERE activo = TRUE
ORDER BY nombreRazonSocial;

--Consulta 12
-- Catálogo completo de productos con su precio base y tarifa de IVA.
SELECT idProducto, nombre, presentacion, precioBase, tarifaIva
FROM Producto
ORDER BY nombre;

--Consulta 13
-- Proveedores activos con calificación de 4 o más (buen desempeño histórico).
SELECT idProveedor, razonSocial, tipoProveedor, calificacion
FROM Proveedor
WHERE activo = TRUE AND calificacion >= 4
ORDER BY calificacion DESC;

--Consulta 14
-- Órdenes de compra que siguen en estado Pendiente (aún no recibidas).
SELECT idCompra, numeroOrden, fechaCompra, total, lugarEntrega
FROM CompraInsumo
WHERE estado = 'Pendiente'
ORDER BY fechaCompra;

--Consulta 15
-- Insumos cuya cantidad disponible está por debajo del stock mínimo (alerta de reorden).
SELECT idInsumo, cantidadDisponible, stockMinimo, ubicacionBodega
FROM InventarioInsumo
WHERE cantidadDisponible < stockMinimo;

--Consulta 16
-- Empleados activos contratados en lo que va del año actual.
SELECT idEmpleado, nombres, apellidos, fechaIngreso
FROM Empleado
WHERE activo = TRUE AND fechaIngreso >= DATE_TRUNC('year', CURRENT_DATE)
ORDER BY fechaIngreso DESC;

--Consulta 17
-- Facturas emitidas con un total superior a $500.000.
SELECT numeroFactura, fechaFactura, total, estadoFactura
FROM Factura
WHERE total > 500000
ORDER BY total DESC;

--Consulta 18
-- Lotes de producción próximos a vencer (en los siguientes 30 días).
SELECT idLote, fechaProduccion, fechaVencimiento, cantidadProducida, estado
FROM LoteProduccion
WHERE fechaVencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY fechaVencimiento;

--Consulta 19
-- Envíos que todavía no han sido pagados por el cliente/distribuidor.
SELECT idEnvio, guiaTransporte, empresaTransportadora, estadoEnvio, fechaEntrega
FROM Envio
WHERE pagoEfectuado = FALSE
ORDER BY fechaEntrega;

--Consulta 20
-- Productos con grado alcohólico superior a 35° (línea de licores fuertes).
SELECT idProducto, nombre, presentacion, gradoAlcoholico
FROM Producto
WHERE gradoAlcoholico > 35
ORDER BY gradoAlcoholico DESC;
