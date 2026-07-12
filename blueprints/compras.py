from flask import Blueprint, render_template, request, redirect, url_for, flash
from datetime import datetime
import psycopg2
from db import get_connection, mensaje_error_amigable

compras_bp = Blueprint("compras", __name__, url_prefix="/compras")

TASA_IVA = 0.19  # IVA General (19%), aplicado a todas las compras de insumos


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idCompra FROM CompraInsumo ORDER BY idCompra DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "COM001"
    numero = int(ultimo["idcompra"][3:]) + 1
    return f"COM{numero:03d}"


def generar_siguiente_numero_orden():
    conn = get_connection()
    cur = conn.cursor()
    anio_actual = datetime.now().year
    prefijo = f"OC-{anio_actual}-"
    cur.execute("""
        SELECT numeroOrden FROM CompraInsumo
        WHERE numeroOrden LIKE %s
        ORDER BY numeroOrden DESC LIMIT 1
    """, (prefijo + "%",))
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return f"{prefijo}0001"
    numero = int(ultimo["numeroorden"].split("-")[-1]) + 1
    return f"{prefijo}{numero:04d}"


def generar_siguiente_id_detalle():
    conn = get_connection()
    cur = conn.cursor()
    # Filtramos por el prefijo 'DCI' porque los datos sintéticos ya
    # cargados usan el prefijo 'DCO' para idDetalleCompra, y 'DCO' > 'DCI'
    # alfabéticamente: sin este filtro, ORDER BY ... DESC siempre
    # devolvía un 'DCOxxx' viejo y se repetía el mismo ID nuevo cada vez.
    cur.execute("""
        SELECT idDetalleCompra FROM DetalleCompraInsumo
        WHERE idDetalleCompra LIKE 'DCI%%'
        ORDER BY idDetalleCompra DESC LIMIT 1
    """)
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "DCI001"
    numero = int(ultimo["iddetallecompra"][3:]) + 1
    return f"DCI{numero:03d}"


def _recalcular_totales(cur, id_compra):
    """
    Recalcula subtotal e iva de la cabecera CompraInsumo a partir de la suma
    de subtotalLinea de todas sus líneas en DetalleCompraInsumo.
    Se llama después de cada INSERT o DELETE de una línea.
    Solo se debe invocar dentro de una transacción ya abierta (no hace commit).
    """
    cur.execute("""
        SELECT COALESCE(SUM(subtotalLinea), 0) AS suma
        FROM DetalleCompraInsumo
        WHERE idCompra = %s
    """, (id_compra,))
    subtotal = cur.fetchone()["suma"]
    iva = round(float(subtotal) * TASA_IVA, 2)
    cur.execute("""
        UPDATE CompraInsumo SET subtotal = %s, iva = %s
        WHERE idCompra = %s AND estado = 'Pendiente'
    """, (subtotal, iva, id_compra))


@compras_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT c.idCompra, c.numeroOrden, c.fechaCompra, c.subtotal, c.iva, c.total,
               c.estado, c.lugarEntrega,
               p.razonSocial AS proveedorNombre
        FROM CompraInsumo c
        JOIN Proveedor p ON c.idProveedor = p.idProveedor
        ORDER BY c.fechaCompra DESC, c.idCompra DESC
    """)
    compras = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("compras/listar.html", compras=compras)


@compras_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        numero_orden = generar_siguiente_numero_orden()
        try:
            cur.execute("""
                INSERT INTO CompraInsumo
                    (idCompra, numeroOrden, fechaCompra, idProveedor,
                     subtotal, iva, estado, lugarEntrega)
                VALUES (%s, %s, NOW(), %s, 0, 0, 'Pendiente', %s)
            """, (
                nuevo_id,
                numero_orden,
                request.form["idProveedor"],
                request.form["lugarEntrega"],
            ))
            conn.commit()
            flash(f"Orden de compra #{numero_orden} creada (Pendiente). Ahora agrega los insumos.")
            return redirect(url_for("compras.detalle", id_compra=nuevo_id))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("compras.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT idProveedor, razonSocial FROM Proveedor
        WHERE activo = TRUE ORDER BY razonSocial
    """)
    proveedores = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("compras/formulario.html", proveedores=proveedores)


@compras_bp.route("/<id_compra>/detalle", methods=["GET", "POST"])
def detalle(id_compra):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT c.*, p.razonSocial AS proveedorNombre
        FROM CompraInsumo c
        JOIN Proveedor p ON c.idProveedor = p.idProveedor
        WHERE c.idCompra = %s
    """, (id_compra,))
    compra = cur.fetchone()

    if compra is None:
        cur.close()
        conn.close()
        flash("La orden de compra no existe.")
        return redirect(url_for("compras.listar"))

    if compra["estado"] != "Pendiente":
        cur.close()
        conn.close()
        flash("Esta orden ya fue recibida y no admite cambios en sus líneas.")
        return redirect(url_for("compras.listar"))

    if request.method == "POST":
        nuevo_id = generar_siguiente_id_detalle()
        try:
            cur.execute("""
                INSERT INTO DetalleCompraInsumo
                    (idDetalleCompra, idCompra, idInsumo, cantidad, precioUnitario)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                nuevo_id,
                id_compra,
                request.form["idInsumo"],
                request.form["cantidad"],
                request.form["precioUnitario"],
            ))
            _recalcular_totales(cur, id_compra)
            conn.commit()
            flash("Insumo agregado a la orden de compra.")
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
        finally:
            cur.close()
            conn.close()
        return redirect(url_for("compras.detalle", id_compra=id_compra))

    cur.execute("""
        SELECT d.idDetalleCompra, d.cantidad, d.precioUnitario, d.subtotalLinea,
               i.nombre AS insumoNombre, i.unidadMedida
        FROM DetalleCompraInsumo d
        JOIN Insumo i ON d.idInsumo = i.idInsumo
        WHERE d.idCompra = %s
        ORDER BY d.idDetalleCompra
    """, (id_compra,))
    lineas = cur.fetchall()

    cur.execute("SELECT idInsumo, nombre, unidadMedida FROM Insumo WHERE activo = TRUE ORDER BY nombre")
    insumos = cur.fetchall()

    cur.close()
    conn.close()
    return render_template(
        "compras/detalle.html", compra=compra, lineas=lineas, insumos=insumos
    )


@compras_bp.route("/<id_compra>/recibir", methods=["POST"])
def recibir(id_compra):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT estado FROM CompraInsumo WHERE idCompra = %s", (id_compra,))
    compra = cur.fetchone()

    if compra is None:
        cur.close()
        conn.close()
        flash("La orden de compra no existe.")
        return redirect(url_for("compras.listar"))

    if compra["estado"] != "Pendiente":
        cur.close()
        conn.close()
        flash("Esta orden ya fue recibida anteriormente.")
        return redirect(url_for("compras.listar"))

    cur.execute("SELECT COUNT(*) AS total FROM DetalleCompraInsumo WHERE idCompra = %s", (id_compra,))
    if cur.fetchone()["total"] == 0:
        cur.close()
        conn.close()
        flash("No se puede recibir una orden sin insumos. Agrega al menos una línea.")
        return redirect(url_for("compras.detalle", id_compra=id_compra))

    try:
        # El trigger trg_actualizar_inventario_compra (db/03_Reto_Trigger_InventarioCompras.sql)
        # se dispara con este UPDATE y suma automáticamente las cantidades
        # de cada línea al InventarioInsumo. No hace falta tocar el inventario aquí.
        cur.execute("""
            UPDATE CompraInsumo SET estado = 'Recibida'
            WHERE idCompra = %s AND estado = 'Pendiente'
        """, (id_compra,))
        conn.commit()
        flash("Orden de compra recibida. El inventario de insumos se actualizó automáticamente.")
    except psycopg2.Error as e:
        conn.rollback()
        flash(mensaje_error_amigable(e))
    finally:
        cur.close()
        conn.close()

    return redirect(url_for("compras.listar"))


@compras_bp.route("/detalle/eliminar/<id_detalle>", methods=["POST"])
def eliminar_detalle(id_detalle):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT d.idCompra, c.estado
        FROM DetalleCompraInsumo d
        JOIN CompraInsumo c ON d.idCompra = c.idCompra
        WHERE d.idDetalleCompra = %s
    """, (id_detalle,))
    fila = cur.fetchone()

    if fila is None:
        cur.close()
        conn.close()
        flash("La línea no existe.")
        return redirect(url_for("compras.listar"))

    if fila["estado"] != "Pendiente":
        cur.close()
        conn.close()
        flash("No se puede eliminar: la orden ya fue recibida.")
        return redirect(url_for("compras.listar"))

    try:
        cur.execute("DELETE FROM DetalleCompraInsumo WHERE idDetalleCompra = %s", (id_detalle,))
        _recalcular_totales(cur, fila["idcompra"])
        conn.commit()
        flash("Línea eliminada de la orden de compra.")
    except psycopg2.Error as e:
        conn.rollback()
        flash(mensaje_error_amigable(e))
    finally:
        cur.close()
        conn.close()

    return redirect(url_for("compras.detalle", id_compra=fila["idcompra"]))
