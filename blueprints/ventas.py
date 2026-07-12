from flask import Blueprint, render_template, request, redirect, url_for, flash
from datetime import datetime
import psycopg2
from db import get_connection, mensaje_error_amigable

ventas_bp = Blueprint("ventas", __name__, url_prefix="/ventas")

TASA_IVA = 0.19  # IVA General (19%), aplicado a la mayoría de los productos ILV


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idVenta FROM Venta ORDER BY idVenta DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "VEN001"
    numero = int(ultimo["idventa"][3:]) + 1
    return f"VEN{numero:03d}"


@ventas_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT v.idVenta, v.fechaVenta, v.metodoPago, v.subTotal, v.iva, v.total,
               v.estadoVenta,
               cli.nombreRazonSocial AS clienteNombre,
               pdv.nombreRazonSocial AS puntoVentaNombre,
               dist.razonSocial AS distribuidorNombre,
               f.idFactura
        FROM Venta v
        JOIN ClienteEmpresa cli ON v.idCliente = cli.idCliente
        LEFT JOIN PuntoDeVenta pdv ON v.idPuntoVenta = pdv.idPuntoVenta
        LEFT JOIN Distribuidor dist ON v.idDistribuidor = dist.idDistribuidor
        LEFT JOIN Factura f ON v.idVenta = f.idVenta
        ORDER BY v.fechaVenta DESC, v.idVenta DESC
    """)
    ventas = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("ventas/listar.html", ventas=ventas)


@ventas_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()

        canal_valor = request.form["canal"]
        tipo_canal, id_canal = canal_valor.split(":")
        id_punto_venta = id_canal if tipo_canal == "PDV" else None
        id_distribuidor = id_canal if tipo_canal == "DIST" else None

        try:
            cur.execute("""
                INSERT INTO Venta
                    (idVenta, fechaVenta, metodoPago, subTotal, iva, total,
                     estadoVenta, idCliente, idPuntoVenta, idDistribuidor, idEmpleado)
                VALUES (%s, NOW(), %s, 0, 0, 0, 'PENDIENTE', %s, %s, %s, %s)
            """, (
                nuevo_id,
                request.form["metodoPago"],
                request.form["idCliente"],
                id_punto_venta,
                id_distribuidor,
                request.form["idEmpleado"],
            ))
            conn.commit()
            flash(f"Venta {nuevo_id} creada (Pendiente). Ahora agrega los productos.")
            return redirect(url_for("ventas.detalle", id_venta=nuevo_id))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("ventas.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT idCliente, nombreRazonSocial FROM ClienteEmpresa
        WHERE activo = TRUE ORDER BY nombreRazonSocial
    """)
    clientes = cur.fetchall()

    cur.execute("""
        SELECT idPuntoVenta, nombreRazonSocial FROM PuntoDeVenta
        WHERE estado = 'ACTIVO' ORDER BY nombreRazonSocial
    """)
    puntos_venta = cur.fetchall()

    cur.execute("""
        SELECT idDistribuidor, razonSocial FROM Distribuidor
        WHERE estado = 'ACTIVO' ORDER BY razonSocial
    """)
    distribuidores = cur.fetchall()

    cur.execute("""
        SELECT e.idEmpleado, e.nombres, e.apellidos
        FROM Empleado e
        JOIN Cargo c ON e.idCargo = c.idCargo
        WHERE c.area = 'Ventas' AND e.activo = TRUE
        ORDER BY e.apellidos
    """)
    empleados = cur.fetchall()

    cur.close()
    conn.close()
    return render_template(
        "ventas/formulario.html",
        clientes=clientes,
        puntos_venta=puntos_venta,
        distribuidores=distribuidores,
        empleados=empleados,
    )


def generar_siguiente_id_detalle():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idDetalleVenta FROM DetalleVenta ORDER BY idDetalleVenta DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "DVT001"
    numero = int(ultimo["iddetalleventa"][3:]) + 1
    return f"DVT{numero:03d}"


def _recalcular_totales(cur, id_venta):
    """
    Recalcula subTotal, iva y total de la cabecera Venta a partir de las
    líneas en DetalleVenta. El IVA se calcula por línea usando la
    tarifaIva REAL de cada producto (no un 19% fijo), porque el PDF exige
    aplicar la tarifa vigente y el esquema ya soporta tarifas distintas
    por producto (ej. productos exentos o con tarifa diferencial a futuro).
    Solo se debe invocar dentro de una transacción ya abierta (no hace commit).
    """
    cur.execute("""
        SELECT COALESCE(SUM(dv.subtotalProducto), 0) AS subtotal,
               COALESCE(SUM(dv.subtotalProducto * p.tarifaIva / 100), 0) AS iva
        FROM DetalleVenta dv
        JOIN Producto p ON dv.idProducto = p.idProducto
        WHERE dv.idVenta = %s
    """, (id_venta,))
    fila = cur.fetchone()
    subtotal = fila["subtotal"]
    iva = round(float(fila["iva"]), 2)
    total = round(float(subtotal) + iva, 2)
    cur.execute("""
        UPDATE Venta SET subTotal = %s, iva = %s, total = %s
        WHERE idVenta = %s AND estadoVenta = 'PENDIENTE'
    """, (subtotal, iva, total, id_venta))


@ventas_bp.route("/<id_venta>/detalle", methods=["GET", "POST"])
def detalle(id_venta):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT v.*, cli.nombreRazonSocial AS clienteNombre
        FROM Venta v
        JOIN ClienteEmpresa cli ON v.idCliente = cli.idCliente
        WHERE v.idVenta = %s
    """, (id_venta,))
    venta = cur.fetchone()

    if venta is None:
        cur.close()
        conn.close()
        flash("La venta no existe.")
        return redirect(url_for("ventas.listar"))

    if venta["estadoventa"] != "PENDIENTE":
        cur.close()
        conn.close()
        flash("Esta venta ya fue cerrada y no admite cambios en sus líneas.")
        return redirect(url_for("ventas.listar"))

    if request.method == "POST":
        id_producto = request.form["idProducto"]
        cantidad = request.form["cantidad"]

        cur.execute("SELECT precioBase FROM Producto WHERE idProducto = %s", (id_producto,))
        producto = cur.fetchone()

        if producto is None:
            cur.close()
            conn.close()
            flash("El producto seleccionado no existe.")
            return redirect(url_for("ventas.detalle", id_venta=id_venta))

        precio_unitario = producto["preciobase"]
        nuevo_id = generar_siguiente_id_detalle()
        try:
            cur.execute("""
                INSERT INTO DetalleVenta
                    (idDetalleVenta, cantidad, precioUnitario, subtotalProducto, idVenta, idProducto)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                nuevo_id,
                cantidad,
                precio_unitario,
                float(cantidad) * float(precio_unitario),
                id_venta,
                id_producto,
            ))
            _recalcular_totales(cur, id_venta)
            conn.commit()
            flash("Producto agregado a la venta.")
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
        finally:
            cur.close()
            conn.close()
        return redirect(url_for("ventas.detalle", id_venta=id_venta))

    cur.execute("""
        SELECT dv.idDetalleVenta, dv.cantidad, dv.precioUnitario, dv.subtotalProducto,
               p.nombre AS productoNombre, p.presentacion
        FROM DetalleVenta dv
        JOIN Producto p ON dv.idProducto = p.idProducto
        WHERE dv.idVenta = %s
        ORDER BY dv.idDetalleVenta
    """, (id_venta,))
    lineas = cur.fetchall()

    cur.execute("""
        SELECT p.idProducto, p.nombre, p.presentacion, p.precioBase,
               COALESCE(ip.stockActual, 0) AS stockActual
        FROM Producto p
        LEFT JOIN inventarioProducto ip ON p.idProducto = ip.idProducto
        ORDER BY p.nombre
    """)
    productos = cur.fetchall()

    cur.close()
    conn.close()
    return render_template(
        "ventas/detalle.html", venta=venta, lineas=lineas, productos=productos
    )


@ventas_bp.route("/detalle/eliminar/<id_detalle>", methods=["POST"])
def eliminar_detalle(id_detalle):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT dv.idVenta, v.estadoVenta
        FROM DetalleVenta dv
        JOIN Venta v ON dv.idVenta = v.idVenta
        WHERE dv.idDetalleVenta = %s
    """, (id_detalle,))
    fila = cur.fetchone()

    if fila is None:
        cur.close()
        conn.close()
        flash("La línea no existe.")
        return redirect(url_for("ventas.listar"))

    if fila["estadoventa"] != "PENDIENTE":
        cur.close()
        conn.close()
        flash("No se puede eliminar: la venta ya fue cerrada.")
        return redirect(url_for("ventas.listar"))

    try:
        cur.execute("DELETE FROM DetalleVenta WHERE idDetalleVenta = %s", (id_detalle,))
        _recalcular_totales(cur, fila["idventa"])
        conn.commit()
        flash("Línea eliminada de la venta.")
    except psycopg2.Error as e:
        conn.rollback()
        flash(mensaje_error_amigable(e))
    finally:
        cur.close()
        conn.close()

    return redirect(url_for("ventas.detalle", id_venta=fila["idventa"]))


def generar_siguiente_id_factura(cur):
    cur.execute("SELECT idFactura FROM Factura ORDER BY idFactura DESC LIMIT 1")
    ultimo = cur.fetchone()
    if ultimo is None:
        return "FAC001"
    numero = int(ultimo["idfactura"][3:]) + 1
    return f"FAC{numero:03d}"


def generar_siguiente_numero_factura(cur):
    anio_actual = datetime.now().year
    prefijo = f"FE-{anio_actual}-"
    cur.execute("""
        SELECT numeroFactura FROM Factura
        WHERE numeroFactura LIKE %s
        ORDER BY numeroFactura DESC LIMIT 1
    """, (prefijo + "%",))
    ultimo = cur.fetchone()
    if ultimo is None:
        return f"{prefijo}0001"
    numero = int(ultimo["numerofactura"].split("-")[-1]) + 1
    return f"{prefijo}{numero:04d}"


def generar_siguiente_id_envio(cur):
    cur.execute("SELECT idEnvio FROM Envio ORDER BY idEnvio DESC LIMIT 1")
    ultimo = cur.fetchone()
    if ultimo is None:
        return "ENV001"
    numero = int(ultimo["idenvio"][3:]) + 1
    return f"ENV{numero:03d}"


def generar_siguiente_guia(cur):
    anio_actual = datetime.now().year
    cur.execute("SELECT COUNT(*) AS total FROM Envio")
    total = cur.fetchone()["total"] + 1
    return f"GU{total:04d}-ILV{anio_actual}"


@ventas_bp.route("/<id_venta>/completar", methods=["POST"])
def completar(id_venta):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT * FROM Venta WHERE idVenta = %s", (id_venta,))
    venta = cur.fetchone()

    if venta is None:
        cur.close()
        conn.close()
        flash("La venta no existe.")
        return redirect(url_for("ventas.listar"))

    if venta["estadoventa"] != "PENDIENTE":
        cur.close()
        conn.close()
        flash("Esta venta ya fue cerrada anteriormente.")
        return redirect(url_for("ventas.listar"))

    cur.execute("SELECT idProducto, cantidad FROM DetalleVenta WHERE idVenta = %s", (id_venta,))
    lineas = cur.fetchall()

    if not lineas:
        cur.close()
        conn.close()
        flash("No se puede completar una venta sin productos. Agrega al menos una línea.")
        return redirect(url_for("ventas.detalle", id_venta=id_venta))

    try:
        cur.execute("""
            UPDATE Venta SET estadoVenta = 'COMPLETADA'
            WHERE idVenta = %s AND estadoVenta = 'PENDIENTE'
        """, (id_venta,))

        for l in lineas:
            cur.execute("""
                UPDATE inventarioProducto
                SET stockActual = stockActual - %s, fechaActualizacion = NOW()
                WHERE idProducto = %s
            """, (l["cantidad"], l["idproducto"]))

        id_factura = generar_siguiente_id_factura(cur)
        numero_factura = generar_siguiente_numero_factura(cur)
        cur.execute("""
            INSERT INTO Factura
                (idFactura, numeroFactura, subtotal, iva, total,
                 metodoPago, estadoFactura, idVenta)
            VALUES (%s, %s, %s, %s, %s, %s, 'EMITIDA', %s)
        """, (
            id_factura, numero_factura,
            venta["subtotal"], venta["iva"], venta["total"],
            venta["metodopago"], id_venta,
        ))

        mensaje = f"Venta completada. Factura {numero_factura} generada. Inventario de productos actualizado."

        if venta["iddistribuidor"] is not None:
            empresa_transportadora = request.form.get("empresaTransportadora")
            if not empresa_transportadora:
                raise ValueError("Debes seleccionar una empresa transportadora para completar una venta por distribuidor.")

            cur.execute("""
                SELECT direccion, idCiudad FROM ClienteEmpresa WHERE idCliente = %s
            """, (venta["idcliente"],))
            cliente = cur.fetchone()

            id_envio = generar_siguiente_id_envio(cur)
            guia = generar_siguiente_guia(cur)
            cur.execute("""
                INSERT INTO Envio
                    (idEnvio, idVenta, fechaEnvio, direccionEntrega, idCiudad,
                     fechaEntrega, empresaTransportadora, guiaTransporte,
                     estadoEnvio, pagoEfectuado)
                VALUES (%s, %s, NOW(), %s, %s,
                        (CURRENT_DATE + INTERVAL '5 days'), %s, %s,
                        'PREPARANDO', FALSE)
            """, (
                id_envio, id_venta, cliente["direccion"], cliente["idciudad"],
                empresa_transportadora, guia,
            ))
            mensaje += f" Envío {id_envio} (guía {guia}) creado con {empresa_transportadora}."

        conn.commit()
        flash(mensaje)
    except (psycopg2.Error, ValueError) as e:
        conn.rollback()
        if isinstance(e, ValueError):
            flash(str(e))
        else:
            flash(mensaje_error_amigable(e))
    finally:
        cur.close()
        conn.close()

    return redirect(url_for("ventas.listar"))
