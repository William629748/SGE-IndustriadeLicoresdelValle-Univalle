-- ============================================================
-- RETO (punto 3): Gestión automática de inventario con PL/pgSQL
-- Cuando una Orden de Compra pasa de 'Pendiente' a 'Recibida',
-- este trigger suma automáticamente la cantidad de cada línea
-- de DetalleCompraInsumo al cantidadDisponible de InventarioInsumo.
-- No requiere cambios en el código Python: la app solo hace
-- UPDATE CompraInsumo SET estado = 'Recibida' y la BD hace el resto.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_actualizar_inventario_compra()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE InventarioInsumo ii
    SET cantidadDisponible = ii.cantidadDisponible + dci.cantidad,
        fechaActualizacion = NOW()
    FROM DetalleCompraInsumo dci
    WHERE dci.idCompra = NEW.idCompra
      AND ii.idInsumo = dci.idInsumo;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_inventario_compra ON CompraInsumo;

CREATE TRIGGER trg_actualizar_inventario_compra
AFTER UPDATE OF estado ON CompraInsumo
FOR EACH ROW
WHEN (NEW.estado = 'Recibida' AND OLD.estado = 'Pendiente')
EXECUTE FUNCTION fn_actualizar_inventario_compra();
