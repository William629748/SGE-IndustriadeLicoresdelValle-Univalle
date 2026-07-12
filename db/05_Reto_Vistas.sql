-- ============================================================
-- RETO (punto 2): 3 vistas de consultas recurrentes del negocio.
-- ============================================================

-- VISTA 1 (obligatoria por el PDF): estado de stock de insumos con
-- días de stock CALCULADOS al vuelo, nunca almacenados en una tabla.
CREATE OR REPLACE VIEW vista_estado_stock_insumos AS
SELECT
    i.idInsumo,
    i.nombre AS insumo,
    p.razonSocial AS proveedor,
    ii.cantidadDisponible,
    ii.stockMinimo,
    ii.stockMaximo,
    ROUND(COALESCE(demanda.promedioDiario, 0), 2) AS demandaDiariaPromedio,
    CASE
        WHEN COALESCE(demanda.promedioDiario, 0) = 0 THEN NULL
        ELSE ROUND(ii.cantidadDisponible / demanda.promedioDiario, 1)
    END AS diasStock,
    CASE
        WHEN COALESCE(demanda.promedioDiario, 0) = 0 THEN 'SIN CONSUMO REGISTRADO'
        WHEN ii.cantidadDisponible / demanda.promedioDiario = 0 THEN 'AGOTADO'
        WHEN ii.cantidadDisponible / demanda.promedioDiario < 5 THEN 'CRÍTICO'
        WHEN ii.cantidadDisponible / demanda.promedioDiario <= 15 THEN 'ALERTA'
        ELSE 'SEGURO'
    END AS categoriaEstado,
    CASE
        WHEN COALESCE(demanda.promedioDiario, 0) = 0 THEN 'Sin datos suficientes'
        WHEN ii.cantidadDisponible / demanda.promedioDiario = 0 THEN 'Pedido inmediato'
        WHEN ii.cantidadDisponible / demanda.promedioDiario < 5 THEN 'Pedido de emergencia'
        WHEN ii.cantidadDisponible / demanda.promedioDiario <= 15 THEN 'Realizar pedido normal'
        ELSE 'Mantener monitoreo'
    END AS accionRecomendada
FROM Insumo i
JOIN InventarioInsumo ii ON i.idInsumo = ii.idInsumo
JOIN Proveedor p ON i.idProveedor = p.idProveedor
LEFT JOIN (
    SELECT
        idInsumo,
        SUM(cantidadConsumida) / GREATEST(
            DATE_PART('day', MAX(fechaConsumo) - MIN(fechaConsumo))::numeric, 1
        ) AS promedioDiario
    FROM ConsumoInsumo
    GROUP BY idInsumo
) demanda ON demanda.idInsumo = i.idInsumo
WHERE i.activo = TRUE;

-- VISTA 2: productos más vendidos (unidades e ingresos totales).
CREATE OR REPLACE VIEW vista_productos_mas_vendidos AS
SELECT
    p.idProducto,
    p.nombre AS producto,
    p.presentacion,
    cp.nombreCategoria AS categoria,
    SUM(dv.cantidad) AS unidadesVendidas,
    SUM(dv.subtotalProducto) AS ingresosTotales,
    COUNT(DISTINCT dv.idVenta) AS numeroVentas
FROM DetalleVenta dv
JOIN Producto p ON dv.idProducto = p.idProducto
JOIN CategoriaProducto cp ON p.idCategoria = cp.idCategoria
JOIN Venta v ON dv.idVenta = v.idVenta
WHERE v.estadoVenta = 'COMPLETADA'
GROUP BY p.idProducto, p.nombre, p.presentacion, cp.nombreCategoria
ORDER BY unidadesVendidas DESC;

-- VISTA 3: compras pendientes por proveedor, con días transcurridos.
CREATE OR REPLACE VIEW vista_compras_pendientes AS
SELECT
    c.idCompra,
    c.numeroOrden,
    p.razonSocial AS proveedor,
    p.tiempoEntregaPromedio,
    c.fechaCompra,
    DATE_PART('day', NOW() - c.fechaCompra) AS diasTranscurridos,
    c.total,
    c.lugarEntrega,
    CASE
        WHEN DATE_PART('day', NOW() - c.fechaCompra) > p.tiempoEntregaPromedio
        THEN 'RETRASADA'
        ELSE 'EN TIEMPO'
    END AS estadoEntrega
FROM CompraInsumo c
JOIN Proveedor p ON c.idProveedor = p.idProveedor
WHERE c.estado = 'Pendiente'
ORDER BY diasTranscurridos DESC;
