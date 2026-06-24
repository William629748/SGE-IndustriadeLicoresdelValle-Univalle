-- ============================================================
-- BLOQUE 2: COMPRAS DE INSUMOS - ILV
-- Ejecutar después del Bloque 1.
-- ============================================================

DELETE FROM DetalleCompraInsumo;
DELETE FROM CompraInsumo;

DO $$
DECLARE
    v_compra_id   VARCHAR(10);
    v_detalle_id  VARCHAR(10);
    v_fecha       TIMESTAMP;
    v_proveedor   VARCHAR(10);
    v_empleado    VARCHAR(10);
    v_estado      VARCHAR(20);
    v_subtotal    NUMERIC(14,2);
    v_iva         NUMERIC(14,2);
    v_insumo1     VARCHAR(10);
    v_insumo2     VARCHAR(10);
    v_cant1       NUMERIC(12,2);
    v_cant2       NUMERIC(12,2);
    v_precio1     NUMERIC(12,2);
    v_precio2     NUMERIC(12,2);
    v_recepcion   TIMESTAMP;

    -- Arrays de proveedores e insumos
    proveedores   VARCHAR(10)[] := ARRAY['PROV001','PROV002','PROV003','PROV004','PROV005','PROV006','PROV007','PROV008'];
    insumos_mp    VARCHAR(10)[] := ARRAY['INS001','INS002','INS003','INS004','INS005','INS006','INS007','INS015'];
    insumos_env   VARCHAR(10)[] := ARRAY['INS008','INS009','INS010','INS011'];
    insumos_etq   VARCHAR(10)[] := ARRAY['INS012','INS013','INS014'];
    empleados_rec VARCHAR(10)[] := ARRAY['EMP010','EMP011','EMP012','EMP013'];

    -- Peso de meses (más compras en oct=10, nov=11 previo a temporada alta)
    -- mes -> peso relativo
    mes_base      INTEGER;
    i             INTEGER;
    j             INTEGER;
    det_count     INTEGER := 0;

BEGIN
    FOR i IN 1..30 LOOP
        v_compra_id := 'COM' || LPAD(i::TEXT, 3, '0');

        -- Estacionalidad: más compras en oct y nov
        mes_base := CASE
            WHEN i <= 4  THEN 1 + (i % 3)          -- ene-mar
            WHEN i <= 6  THEN 4 + (i % 2)           -- abr-may
            WHEN i <= 8  THEN 6 + (i % 2)           -- jun-jul
            WHEN i <= 12 THEN 8 + (i % 2)           -- ago-sep
            WHEN i <= 18 THEN 10                     -- 6 compras en octubre
            WHEN i <= 24 THEN 11                     -- 6 compras en noviembre
            ELSE 12                                  -- dic
        END;

        v_fecha := (
            '2024-' || LPAD(mes_base::TEXT,2,'0') || '-' ||
            LPAD((1 + (i*7 % 25))::TEXT, 2, '0') || ' 08:00:00'
        )::TIMESTAMP;

        -- Proveedor rotativo
        v_proveedor := proveedores[1 + (i % array_length(proveedores,1))];

        -- Estado: 80% Recibido, 10% Pendiente, 10% Cancelado
        v_estado := CASE
            WHEN i % 10 = 0 THEN 'Cancelado'
            WHEN i % 10 = 9 THEN 'Pendiente'
            ELSE 'Recibido'
        END;

        v_empleado := CASE WHEN v_estado = 'Recibido'
            THEN empleados_rec[1 + (i % array_length(empleados_rec,1))]
            ELSE NULL
        END;

        v_recepcion := CASE WHEN v_estado = 'Recibido'
            THEN v_fecha + INTERVAL '3 days'
            ELSE NULL
        END;

        -- Subtotal e IVA coherentes (varía por mes: más caro en temporada)
        v_subtotal := (2000000 + (i * 150000) + CASE WHEN mes_base IN (10,11,12) THEN 1000000 ELSE 0 END)::NUMERIC(14,2);
        v_iva      := ROUND(v_subtotal * 0.19, 2);

        INSERT INTO CompraInsumo (
            idCompra, numeroOrden, fechaCompra, idProveedor,
            subtotal, iva, estado, fechaRecepcion, idEmpleadoRecibe
        ) VALUES (
            v_compra_id,
            'OC-2024-' || LPAD(i::TEXT, 4, '0'),
            v_fecha,
            v_proveedor,
            v_subtotal,
            v_iva,
            v_estado,
            v_recepcion,
            v_empleado
        );

        -- 2 detalles por compra
        FOR j IN 1..2 LOOP
            det_count := det_count + 1;
            v_detalle_id := 'DCO' || LPAD(det_count::TEXT, 3, '0');

            -- Alternar entre tipos de insumo según proveedor/iteración
            IF j = 1 THEN
                v_insumo1 := insumos_mp[1 + ((i + j) % array_length(insumos_mp,1))];
                v_cant1   := (100 + (i * 15) + CASE WHEN mes_base IN (10,11,12) THEN 200 ELSE 0 END)::NUMERIC(12,2);
                v_precio1 := (8000 + (i * 500))::NUMERIC(12,2);
                INSERT INTO DetalleCompraInsumo (
                    idDetalleCompra, idCompra, idInsumo, cantidad, precioUnitario
                ) VALUES (v_detalle_id, v_compra_id, v_insumo1, v_cant1, v_precio1);
            ELSE
                v_insumo2 := insumos_env[1 + ((i + j) % array_length(insumos_env,1))];
                v_cant2   := (500 + (i * 50))::NUMERIC(12,2);
                v_precio2 := (350 + (i * 20))::NUMERIC(12,2);
                INSERT INTO DetalleCompraInsumo (
                    idDetalleCompra, idCompra, idInsumo, cantidad, precioUnitario
                ) VALUES (v_detalle_id, v_compra_id, v_insumo2, v_cant2, v_precio2);
            END IF;
        END LOOP;

    END LOOP;
END;
$$;

SELECT 'CompraInsumo'        AS tabla, COUNT(*) AS registros FROM CompraInsumo
UNION ALL SELECT 'DetalleCompraInsumo', COUNT(*) FROM DetalleCompraInsumo;