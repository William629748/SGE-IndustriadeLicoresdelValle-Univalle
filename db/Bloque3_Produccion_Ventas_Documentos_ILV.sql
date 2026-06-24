-- ============================================================
-- BLOQUE 3: PRODUCCIÓN, VENTAS Y DOCUMENTOS - ILV
-- Ejecutar después del Bloque 1 y 2.
-- Genera: 80 Lotes, 200+ ConsumoInsumo,
--         300 Ventas, 600 DetalleVenta,
--         ~255 Facturas, ~90 Envíos, 40 Contratos
-- ============================================================

DELETE FROM Envio;
DELETE FROM Factura;
DELETE FROM DetalleVenta;
DELETE FROM Venta;
DELETE FROM ConsumoInsumo;
DELETE FROM LoteProduccion;
DELETE FROM Contrato;

DO $$
DECLARE
    -- Contadores
    i               INTEGER;
    j               INTEGER;
    k               INTEGER;
    det_count       INTEGER := 0;
    cons_count      INTEGER := 0;
    venta_count     INTEGER := 0;
    dventa_count    INTEGER := 0;
    fact_count      INTEGER := 0;
    envio_count     INTEGER := 0;
    cont_count      INTEGER := 0;

    -- Variables lote
    v_lote_id       VARCHAR(10);
    v_fecha_prod    DATE;
    v_mes           INTEGER;
    v_cantidad_prod NUMERIC(12,2);
    v_producto      VARCHAR(10);
    v_empleado_prod VARCHAR(10);
    v_estado_lote   VARCHAR(100);
    num_consumos    INTEGER;

    -- Variables consumo
    v_cons_id       VARCHAR(10);
    v_insumo        VARCHAR(10);
    v_cant_cons     NUMERIC(12,2);

    -- Variables venta
    v_venta_id      VARCHAR(10);
    v_fecha_venta   TIMESTAMP;
    v_mes_venta     INTEGER;
    v_canal         INTEGER; -- 1=PuntoVenta, 2=Distribuidor
    v_pdv           VARCHAR(10);
    v_dist          VARCHAR(10);
    v_cliente       VARCHAR(10);
    v_vendedor      VARCHAR(10);
    v_metodo        VARCHAR(30);
    v_estado_venta  VARCHAR(30);
    v_subtotal_v    NUMERIC(12,2);
    v_iva_v         NUMERIC(12,2);
    v_total_v       NUMERIC(12,2);
    dias_mes        INTEGER;

    -- Variables detalle venta
    v_dv_id         VARCHAR(10);
    v_prod_dv       VARCHAR(10);
    v_cant_dv       INTEGER;
    v_precio_dv     NUMERIC(12,2);
    v_sub_dv        NUMERIC(12,2);
    num_detalles    INTEGER;

    -- Variables factura / envío
    v_fact_id       VARCHAR(10);
    v_envio_id      VARCHAR(10);

    -- Variables contrato
    v_cont_id       VARCHAR(10);
    v_tipo_cont     VARCHAR(30);

    -- Arrays de referencia
    productos_pop   VARCHAR(10)[] := ARRAY['PRO001','PRO002','PRO004'];
    productos_todos VARCHAR(10)[] := ARRAY['PRO001','PRO002','PRO003','PRO004','PRO005',
                                           'PRO006','PRO007','PRO008','PRO009','PRO010',
                                           'PRO011','PRO012'];
    precios         NUMERIC[]     := ARRAY[17500,18200,9500,32000,45000,
                                           28000,35000,38000,95000,62000,
                                           28000,30000];
    insumos_prod    VARCHAR(10)[] := ARRAY['INS001','INS002','INS003','INS004',
                                           'INS005','INS006','INS007','INS015'];
    empleados_prod  VARCHAR(10)[] := ARRAY['EMP003','EMP004','EMP005','EMP017'];
    empleados_vend  VARCHAR(10)[] := ARRAY['EMP007','EMP008','EMP009','EMP016'];
    clientes        VARCHAR(10)[] := ARRAY['CLI001','CLI002','CLI003','CLI004','CLI005',
                                           'CLI006','CLI007','CLI008','CLI009','CLI010',
                                           'CLI011','CLI012','CLI013','CLI014','CLI015'];
    pdvs            VARCHAR(10)[] := ARRAY['PDV001','PDV002','PDV003','PDV004',
                                           'PDV005','PDV006','PDV007','PDV008','PDV010'];
    dists           VARCHAR(10)[] := ARRAY['DIS001','DIS002','DIS003','DIS004','DIS005','DIS006'];
    empleados_cont  VARCHAR(10)[] := ARRAY['EMP001','EMP002','EMP006','EMP010','EMP014',
                                           'EMP015','EMP007','EMP008'];
    proveedores     VARCHAR(10)[] := ARRAY['PROV001','PROV002','PROV003','PROV004',
                                           'PROV005','PROV006','PROV007','PROV008'];
    clientes_emp    VARCHAR(10)[] := ARRAY['CLI001','CLI002','CLI003','CLI004',
                                           'CLI005','CLI006','CLI013','CLI014'];

    -- Peso estacional por mes (índice 1=ene ... 12=dic)
    -- dic=3x feb, temporada alta: jun, dic
    peso_mes        INTEGER[] := ARRAY[8,4,6,7,8,12,9,7,8,10,11,20];

    -- Número de ventas por mes (total 300 distribuidas proporcionalmente)
    ventas_mes      INTEGER[] := ARRAY[20,10,14,16,20,28,22,17,19,24,26,84];
    -- Verificar suma: 20+10+14+16+20+28+22+17+19+24+26+84 = 300 ✓

BEGIN

    -- ===========================================================
    -- LOTES DE PRODUCCIÓN (80 lotes)
    -- ===========================================================
    FOR i IN 1..80 LOOP
        v_lote_id := 'LOT' || LPAD(i::TEXT, 3, '0');

        -- Distribuir lotes por mes con más en oct/nov/dic/jun
        v_mes := CASE
            WHEN i <= 5  THEN 1
            WHEN i <= 9  THEN 2
            WHEN i <= 14 THEN 3
            WHEN i <= 19 THEN 4
            WHEN i <= 25 THEN 5
            WHEN i <= 33 THEN 6   -- 8 lotes en junio
            WHEN i <= 38 THEN 7
            WHEN i <= 43 THEN 8
            WHEN i <= 48 THEN 9
            WHEN i <= 56 THEN 10  -- 8 lotes en octubre
            WHEN i <= 65 THEN 11  -- 9 lotes en noviembre
            ELSE 12               -- 15 lotes en diciembre
        END;

        dias_mes := CASE v_mes
            WHEN 2 THEN 28 ELSE
            CASE WHEN v_mes IN (4,6,9,11) THEN 30 ELSE 31 END
        END;

        v_fecha_prod := ('2024-' || LPAD(v_mes::TEXT,2,'0') || '-' ||
                         LPAD((1 + (i*3 % (dias_mes-1)))::TEXT,2,'0'))::DATE;

        -- Productos: 60% populares, 40% resto
        v_producto := CASE
            WHEN i % 10 <= 5 THEN productos_pop[1 + (i % 3)]
            ELSE productos_todos[4 + (i % 9)]
        END;

        -- Cantidad producida mayor en temporada alta
        v_cantidad_prod := CASE
            WHEN v_mes IN (11,12) THEN 3000 + (i * 25) % 2000
            WHEN v_mes IN (6,10)  THEN 2000 + (i * 20) % 1500
            ELSE                       800  + (i * 15) % 700
        END;

        v_empleado_prod := empleados_prod[1 + (i % array_length(empleados_prod,1))];

        v_estado_lote := CASE
            WHEN i % 20 = 0 THEN 'RECHAZADO'
            WHEN i % 10 = 0 THEN 'EN PROCESO'
            ELSE 'FINALIZADO'
        END;

        INSERT INTO LoteProduccion (
            idLote, fechaProduccion, fechaVencimiento,
            cantidadProducida, idProducto, idEmpleado, estado, observaciones
        ) VALUES (
            v_lote_id,
            v_fecha_prod,
            v_fecha_prod + INTERVAL '730 days',
            v_cantidad_prod,
            v_producto,
            v_empleado_prod,
            v_estado_lote,
            CASE WHEN v_estado_lote = 'RECHAZADO' THEN 'Lote rechazado por control de calidad' ELSE NULL END
        );

        -- ===========================================================
        -- CONSUMO INSUMO: 2-4 consumos por lote (total ~200)
        -- ===========================================================
        num_consumos := 2 + (i % 3); -- 2, 3 o 4 consumos
        FOR j IN 1..num_consumos LOOP
            cons_count := cons_count + 1;
            v_cons_id := 'CNS' || LPAD(cons_count::TEXT, 3, '0');
            v_insumo  := insumos_prod[1 + ((i + j) % array_length(insumos_prod,1))];
            v_cant_cons := ROUND((v_cantidad_prod * 0.05 * j)::NUMERIC, 2);

            INSERT INTO ConsumoInsumo (
                idConsumo, idLote, idInsumo,
                cantidadConsumida, fechaConsumo, idEmpleado
            ) VALUES (
                v_cons_id,
                v_lote_id,
                v_insumo,
                v_cant_cons,
                (v_fecha_prod::TIMESTAMP + (j || ' hours')::INTERVAL),
                v_empleado_prod
            );
        END LOOP;

    END LOOP;

    -- ===========================================================
    -- VENTAS (300 ventas con estacionalidad)
    -- ===========================================================
    FOR v_mes IN 1..12 LOOP
        FOR i IN 1..ventas_mes[v_mes] LOOP
            venta_count := venta_count + 1;
            v_venta_id  := 'VEN' || LPAD(venta_count::TEXT, 3, '0');

            dias_mes := CASE v_mes
                WHEN 2 THEN 28 ELSE
                CASE WHEN v_mes IN (4,6,9,11) THEN 30 ELSE 31 END
            END;

            v_fecha_venta := ('2024-' || LPAD(v_mes::TEXT,2,'0') || '-' ||
                              LPAD((1 + (i*3 % (dias_mes-1)))::TEXT,2,'0') ||
                              ' ' || LPAD((8 + (i % 12))::TEXT,2,'0') || ':00:00')::TIMESTAMP;

            -- Canal: 70% punto de venta, 30% distribuidor
            v_canal := CASE WHEN (venta_count % 10) <= 6 THEN 1 ELSE 2 END;
            v_pdv   := CASE WHEN v_canal = 1 THEN pdvs[1 + (venta_count % array_length(pdvs,1))] ELSE NULL END;
            v_dist  := CASE WHEN v_canal = 2 THEN dists[1 + (venta_count % array_length(dists,1))] ELSE NULL END;

            v_cliente  := clientes[1 + (venta_count % array_length(clientes,1))];
            v_vendedor := empleados_vend[1 + (venta_count % array_length(empleados_vend,1))];

            -- Método de pago 40/40/20
            v_metodo := CASE
                WHEN venta_count % 5 = 0 THEN 'CREDITO'
                WHEN venta_count % 2 = 0 THEN 'TRANSFERENCIA'
                ELSE 'EFECTIVO'
            END;

            -- Estado 85/10/5
            v_estado_venta := CASE
                WHEN venta_count % 20 = 0 THEN 'CANCELADA'
                WHEN venta_count % 10 = 0 THEN 'PENDIENTE'
                ELSE 'COMPLETADA'
            END;

            -- Calcular subtotal e IVA (se completan con los detalles)
            -- Usamos valores base según mes (más alto en diciembre)
            v_subtotal_v := ROUND((
                150000 +
                (venta_count * 5000 % 300000) +
                CASE WHEN v_mes = 12 THEN 200000
                     WHEN v_mes IN (6,11) THEN 100000
                     ELSE 0 END
            )::NUMERIC, 2);
            v_iva_v   := ROUND(v_subtotal_v * 0.19, 2);
            v_total_v := v_subtotal_v + v_iva_v;

            INSERT INTO Venta (
                idVenta, fechaVenta, horaVenta, metodoPago,
                subTotal, iva, total, estadoVenta,
                idCliente, idPuntoVenta, idDistribuidor, idEmpleado
            ) VALUES (
                v_venta_id,
                v_fecha_venta,
                v_fecha_venta::TIME,
                v_metodo,
                v_subtotal_v,
                v_iva_v,
                v_total_v,
                v_estado_venta,
                v_cliente,
                v_pdv,
                v_dist,
                v_vendedor
            );

            -- ===========================================================
            -- DETALLE VENTA: 2 detalles por venta (total 600)
            -- ===========================================================
            num_detalles := 2;
            FOR k IN 1..num_detalles LOOP
                dventa_count := dventa_count + 1;
                v_dv_id := 'DVT' || LPAD(dventa_count::TEXT, 3, '0');

                -- 70% productos populares, 30% otros
                IF (dventa_count % 10) <= 6 THEN
                    v_prod_dv := productos_pop[1 + (dventa_count % 3)];
                ELSE
                    v_prod_dv := productos_todos[4 + (dventa_count % 9)];
                END IF;

                -- Precio del producto
                v_precio_dv := precios[
                    array_position(productos_todos, v_prod_dv)
                ]::NUMERIC(12,2);

                -- Cantidad mayor en temporada alta
                v_cant_dv := CASE
                    WHEN v_mes = 12 THEN 10 + (dventa_count % 40)
                    WHEN v_mes IN (6,11) THEN 5 + (dventa_count % 25)
                    ELSE 1 + (dventa_count % 15)
                END;

                v_sub_dv := ROUND((v_cant_dv * v_precio_dv)::NUMERIC, 2);

                INSERT INTO DetalleVenta (
                    idDetalleVenta, cantidad, precioUnitario,
                    subtotalProducto, idVenta, idProducto
                ) VALUES (
                    v_dv_id,
                    v_cant_dv,
                    v_precio_dv,
                    v_sub_dv,
                    v_venta_id,
                    v_prod_dv
                );
            END LOOP;

            -- ===========================================================
            -- FACTURA: solo para ventas COMPLETADAS
            -- ===========================================================
            IF v_estado_venta = 'COMPLETADA' THEN
                fact_count := fact_count + 1;
                v_fact_id  := 'FAC' || LPAD(fact_count::TEXT, 3, '0');
                INSERT INTO Factura (
                    idFactura, numeroFactura, subtotal, iva, total,
                    metodoPago, estadoFactura, idVenta, cufe
                ) VALUES (
                    v_fact_id,
                    'FE-2024-' || LPAD(fact_count::TEXT, 4, '0'),
                    v_subtotal_v,
                    v_iva_v,
                    v_total_v,
                    v_metodo,
                    CASE WHEN fact_count % 15 = 0 THEN 'ANULADA'
                         WHEN fact_count % 5  = 0 THEN 'PAGADA'
                         ELSE 'EMITIDA' END,
                    v_venta_id,
                    md5(v_venta_id || fact_count::TEXT || random()::TEXT)
                );

                -- ===========================================================
                -- ENVÍO: solo ventas por distribuidor y completadas
                -- ===========================================================
                IF v_dist IS NOT NULL THEN
                    envio_count := envio_count + 1;
                    v_envio_id  := 'ENV' || LPAD(envio_count::TEXT, 3, '0');
                    INSERT INTO Envio (
                        idEnvio, idVenta, fechaEnvio, direccionEntrega,
                        idCiudad, fechaEntrega, empresaTransportadora,
                        guiaTransporte, estadoEnvio, pagoEfectuado
                    ) VALUES (
                        v_envio_id,
                        v_venta_id,
                        v_fecha_venta + INTERVAL '1 day',
                        'Dirección de entrega cliente ' || v_cliente,
                        'CIU00' || (1 + (envio_count % 9))::TEXT,
                        (v_fecha_venta + INTERVAL '5 days')::DATE,
                        CASE envio_count % 4
                            WHEN 0 THEN 'SERVIENTREGA'
                            WHEN 1 THEN 'COORDINADORA'
                            WHEN 2 THEN 'DEPRISA'
                            ELSE        'TCC'
                        END,
                        'GU' || LPAD(envio_count::TEXT,4,'0') || '-ILV2024',
                        CASE
                            WHEN envio_count % 20 = 0 THEN 'DEVUELTO'
                            WHEN envio_count % 5  = 0 THEN 'PREPARANDO'
                            WHEN envio_count % 2  = 0 THEN 'EN_CAMINO'
                            ELSE 'ENTREGADO'
                        END,
                        envio_count % 3 != 0
                    );
                END IF;
            END IF;

        END LOOP; -- fin ventas por mes
    END LOOP; -- fin meses

    -- ===========================================================
    -- CONTRATOS (40 contratos, 8 por tipo)
    -- ===========================================================
    FOR i IN 1..40 LOOP
        cont_count  := cont_count + 1;
        v_cont_id   := 'CON' || LPAD(cont_count::TEXT, 3, '0');

        -- 8 de cada tipo: EMPLEADO, DISTRIB, PROVEEDOR, PTO_VENTA, CLIENTE_EMPRESA
        v_tipo_cont := CASE
            WHEN i <= 8  THEN 'EMPLEADO'
            WHEN i <= 16 THEN 'DISTRIB'
            WHEN i <= 24 THEN 'PROVEEDOR'
            WHEN i <= 32 THEN 'PTO_VENTA'
            ELSE              'CLIENTE_EMPRESA'
        END;

        INSERT INTO Contrato (
            idContrato, numeroContrato, tipoContrato, fechaInicio, fechaFin,
            valorContrato, descripcionObjeto, modalidad, estado,
            idEmpleado, idDistribuidor, idProveedor, idPuntoVenta, idClienteEmpresa
        ) VALUES (
            v_cont_id,
            'CONT-2024-' || LPAD(i::TEXT, 3, '0'),
            v_tipo_cont,
            ('2024-' || LPAD((1 + (i % 11))::TEXT,2,'0') || '-01')::DATE,
            CASE WHEN i % 5 = 0 THEN NULL
                 ELSE ('2025-' || LPAD((1 + (i % 11))::TEXT,2,'0') || '-01')::DATE
            END,
            CASE v_tipo_cont
                WHEN 'EMPLEADO'        THEN (3000000 + i * 200000)::NUMERIC(14,2)
                WHEN 'DISTRIB'         THEN (50000000 + i * 1000000)::NUMERIC(14,2)
                WHEN 'PROVEEDOR'       THEN (20000000 + i * 500000)::NUMERIC(14,2)
                WHEN 'PTO_VENTA'       THEN (10000000 + i * 300000)::NUMERIC(14,2)
                ELSE                        (30000000 + i * 800000)::NUMERIC(14,2)
            END,
            'Contrato de ' || v_tipo_cont || ' número ' || i,
            CASE WHEN i % 2 = 0 THEN 'ORDEN DE SERVICIO' ELSE 'CONTRATO FIJO' END,
            CASE WHEN i % 8 = 0 THEN 'SUSPENDIDO' WHEN i % 5 = 0 THEN 'TERMINADO' ELSE 'ACTIVO' END,
            -- Exactamente una FK NOT NULL según tipo
            CASE WHEN v_tipo_cont = 'EMPLEADO'        THEN empleados_cont[1+(i%array_length(empleados_cont,1))] ELSE NULL END,
            CASE WHEN v_tipo_cont = 'DISTRIB'          THEN dists[1+((i-8)%array_length(dists,1))]              ELSE NULL END,
            CASE WHEN v_tipo_cont = 'PROVEEDOR'        THEN proveedores[1+((i-16)%array_length(proveedores,1))] ELSE NULL END,
            CASE WHEN v_tipo_cont = 'PTO_VENTA'        THEN pdvs[1+((i-24)%array_length(pdvs,1))]               ELSE NULL END,
            CASE WHEN v_tipo_cont = 'CLIENTE_EMPRESA'  THEN clientes_emp[1+((i-32)%array_length(clientes_emp,1))] ELSE NULL END
        );
    END LOOP;

END;
$$;

-- Verificación de volumen final
SELECT 'LoteProduccion'      AS tabla, COUNT(*) AS registros FROM LoteProduccion
UNION ALL SELECT 'ConsumoInsumo',      COUNT(*) FROM ConsumoInsumo
UNION ALL SELECT 'Venta',              COUNT(*) FROM Venta
UNION ALL SELECT 'DetalleVenta',       COUNT(*) FROM DetalleVenta
UNION ALL SELECT 'Factura',            COUNT(*) FROM Factura
UNION ALL SELECT 'Envio',              COUNT(*) FROM Envio
UNION ALL SELECT 'Contrato',           COUNT(*) FROM Contrato;