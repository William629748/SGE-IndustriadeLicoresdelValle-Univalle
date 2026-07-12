-- ============================================================
-- RETO (punto 1): Índices en las tablas más consultadas por ILV.
-- Postgres NO indexa automáticamente las columnas FK (solo PK/UNIQUE),
-- así que las relaciones que más se recorren en JOIN sí lo necesitan.
-- ============================================================

-- Ventas: se filtra y ordena constantemente por cliente y por fecha
-- (listado de ventas, reportes de ventas del mes).
CREATE INDEX IF NOT EXISTS idx_venta_cliente ON Venta(idCliente);
CREATE INDEX IF NOT EXISTS idx_venta_fecha ON Venta(fechaVenta);

-- DetalleVenta: se une con Producto en casi cada consulta de facturación
-- y reportes de productos más vendidos.
CREATE INDEX IF NOT EXISTS idx_detalleventa_producto ON DetalleVenta(idProducto);
CREATE INDEX IF NOT EXISTS idx_detalleventa_venta ON DetalleVenta(idVenta);

-- Compras: se filtra por proveedor y por estado ('Pendiente' vs 'Recibida')
-- en cada carga del listado de compras.
CREATE INDEX IF NOT EXISTS idx_compra_proveedor ON CompraInsumo(idProveedor);
CREATE INDEX IF NOT EXISTS idx_compra_estado ON CompraInsumo(estado);

-- DetalleCompraInsumo: se une con Insumo constantemente al recibir compras
-- y al calcular totales.
CREATE INDEX IF NOT EXISTS idx_detallecompra_insumo ON DetalleCompraInsumo(idInsumo);
CREATE INDEX IF NOT EXISTS idx_detallecompra_compra ON DetalleCompraInsumo(idCompra);

-- Producto: se filtra por categoría en el catálogo y en reportes.
CREATE INDEX IF NOT EXISTS idx_producto_categoria ON Producto(idCategoria);

-- ConsumoInsumo: base del cálculo de demanda diaria para las vistas de stock.
CREATE INDEX IF NOT EXISTS idx_consumo_insumo ON ConsumoInsumo(idInsumo);
CREATE INDEX IF NOT EXISTS idx_consumo_lote ON ConsumoInsumo(idLote);

-- Cliente y Proveedor: se unen con Ciudad en casi todos los listados.
CREATE INDEX IF NOT EXISTS idx_cliente_ciudad ON ClienteEmpresa(idCiudad);
CREATE INDEX IF NOT EXISTS idx_proveedor_ciudad ON Proveedor(idCiudad);
