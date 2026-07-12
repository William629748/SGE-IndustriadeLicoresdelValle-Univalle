-- Ajustes a ClienteEmpresa: Habeas Data, Representante Legal, Régimen Tributario
ALTER TABLE ClienteEmpresa
    ADD COLUMN habeasData BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN representanteLegal VARCHAR(150) NOT NULL DEFAULT 'Por definir',
    ADD COLUMN tipoRegimen VARCHAR(20) NOT NULL DEFAULT 'NO_RESPONSABLE'
        CHECK (tipoRegimen IN ('RESPONSABLE_IVA', 'NO_RESPONSABLE'));

-- Ajustes a Proveedor: mismos campos heredados de Cliente + campos propios del PDF
ALTER TABLE Proveedor
    ADD COLUMN habeasData BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN representanteLegal VARCHAR(150) NOT NULL DEFAULT 'Por definir',
    ADD COLUMN tipoRegimen VARCHAR(20) NOT NULL DEFAULT 'NO_RESPONSABLE'
        CHECK (tipoRegimen IN ('RESPONSABLE_IVA', 'NO_RESPONSABLE')),
    ADD COLUMN tiempoEntregaPromedio INTEGER NOT NULL DEFAULT 7 CHECK (tiempoEntregaPromedio > 0),
    ADD COLUMN bancoNombre VARCHAR(100),
    ADD COLUMN tipoCuenta VARCHAR(20) CHECK (tipoCuenta IN ('AHORROS','CORRIENTE')),
    ADD COLUMN numeroCuenta VARCHAR(30),
    ADD COLUMN contactoCartera VARCHAR(100),
    ADD COLUMN contactoLogistico VARCHAR(100);

-- Ajuste a Insumo: proveedor asociado obligatorio
ALTER TABLE Insumo
    ADD COLUMN idProveedor VARCHAR(10) REFERENCES Proveedor(idProveedor);

-- Rellenamos idProveedor en los insumos que ya existen, usando su primera compra registrada
UPDATE Insumo i
SET idProveedor = sub.idProveedor
FROM (
    SELECT DISTINCT ON (dci.idInsumo) dci.idInsumo, ci.idProveedor
    FROM DetalleCompraInsumo dci
    JOIN CompraInsumo ci ON dci.idCompra = ci.idCompra
    ORDER BY dci.idInsumo, ci.fechaCompra ASC
) sub
WHERE i.idInsumo = sub.idInsumo;

-- Respaldo: los insumos que NO aparecen en ninguna compra quedan sin proveedor.
-- Les asignamos un proveedor válido para poder aplicar la restricción NOT NULL.
UPDATE Insumo
SET idProveedor = (SELECT idProveedor FROM Proveedor ORDER BY idProveedor LIMIT 1)
WHERE idProveedor IS NULL;

-- Ahora sí lo dejamos obligatorio para todo insumo nuevo
ALTER TABLE Insumo
    ALTER COLUMN idProveedor SET NOT NULL;

-- Ajuste a CompraInsumo: lugar de entrega (exigido por el PDF para Órdenes de Pedido)
ALTER TABLE CompraInsumo
    ADD COLUMN lugarEntrega VARCHAR(150) NOT NULL DEFAULT 'Bodega Principal - Sede ILV';
-- Ajuste a Producto: eliminación lógica (el PDF exige no perder histórico
-- de movimientos de inventario, en vez de borrar el registro físico)
ALTER TABLE Producto ADD COLUMN activo BOOLEAN NOT NULL DEFAULT TRUE;

-- Ajuste a InventarioInsumo: se agrega demanda diaria, requerida por el PDF
-- para calcular Días de Stock = cantidadDisponible / demandaDiaria.
-- IMPORTANTE: los "días de stock" NUNCA se almacenan (lo prohíbe el PDF),
-- se calculan siempre en el momento de la consulta.
ALTER TABLE InventarioInsumo
    ADD COLUMN demandaDiaria NUMERIC(12,2) NOT NULL DEFAULT 1
        CHECK (demandaDiaria > 0);
ALTER TABLE InventarioInsumo
    ALTER COLUMN demandaDiaria DROP DEFAULT;

-- Ajustes a inventarioProducto: se agregan stockMinimo (referencia de negocio)
-- y demandaDiaria (obligatoria para calcular Días de Stock = stockActual / demandaDiaria).
-- Igual que en InventarioInsumo, los días de stock NUNCA se almacenan.
ALTER TABLE inventarioProducto
    ADD COLUMN stockMinimo NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (stockMinimo >= 0),
    ADD COLUMN demandaDiaria NUMERIC(12,2) NOT NULL DEFAULT 1
        CHECK (demandaDiaria > 0);
ALTER TABLE inventarioProducto
    ALTER COLUMN stockMinimo DROP DEFAULT,
    ALTER COLUMN demandaDiaria DROP DEFAULT;

-- Ajuste a LoteProduccion: normalizar 'EN PROCESO' (con espacio) a 'EN_PROCESO'
-- (mismo estilo que el resto del esquema, ej. NO_RESPONSABLE) y restringir
-- estado a los 3 valores válidos del negocio.
UPDATE LoteProduccion SET estado = 'EN_PROCESO' WHERE estado = 'EN PROCESO';

ALTER TABLE LoteProduccion
    ALTER COLUMN estado SET DEFAULT 'EN_PROCESO';

ALTER TABLE LoteProduccion
    ADD CONSTRAINT chk_estado_lote
        CHECK (estado IN ('EN_PROCESO', 'FINALIZADO', 'RECHAZADO'));
