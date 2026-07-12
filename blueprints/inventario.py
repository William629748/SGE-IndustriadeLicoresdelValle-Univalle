from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

inventario_bp = Blueprint("inventario", __name__, url_prefix="/inventario")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idInventarioInsumo FROM InventarioInsumo ORDER BY idInventarioInsumo DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "INV001"
    numero = int(ultimo["idinventarioinsumo"][3:]) + 1
    return f"INV{numero:03d}"


def calcular_estado(cantidad, demanda_diaria):
    """
    Calcula el estado del inventario según Días de Stock = cantidad / demandaDiaria.
    Los días de stock NUNCA se guardan en la BD (lo exige el PDF): se calculan
    aquí, en el momento de la consulta, y se devuelven solo para mostrarlos.
    Umbrales según el PDF:
        0 días          -> AGOTADO  -> Pedido inmediato
        menos de 5 días -> CRÍTICO  -> Pedido de emergencia
        entre 5 y 15    -> ALERTA   -> Realizar pedido normal
        más de 15 días  -> SEGURO   -> Mantener monitoreo
    """
    dias_stock = cantidad / demanda_diaria

    if dias_stock <= 0:
        return "AGOTADO", "Pedido inmediato", dias_stock
    if dias_stock < 5:
        return "CRÍTICO", "Pedido de emergencia", dias_stock
    if dias_stock <= 15:
        return "ALERTA", "Realizar pedido normal", dias_stock
    return "SEGURO", "Mantener monitoreo", dias_stock


@inventario_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT inv.idInventarioInsumo, inv.cantidadDisponible, inv.stockMinimo,
               inv.stockMaximo, inv.demandaDiaria, inv.ubicacionBodega, inv.fechaActualizacion,
               i.idInsumo, i.nombre AS insumoNombre, i.unidadMedida
        FROM InventarioInsumo inv
        JOIN Insumo i ON inv.idInsumo = i.idInsumo
        ORDER BY i.nombre
    """)
    filas = cur.fetchall()
    cur.close()
    conn.close()

    inventario = []
    for f in filas:
        estado, accion, dias_stock = calcular_estado(
            float(f["cantidaddisponible"]), float(f["demandadiaria"])
        )
        f = dict(f)
        f["estado"] = estado
        f["accion"] = accion
        f["diasStock"] = round(dias_stock, 1)
        inventario.append(f)

    return render_template("inventario/listar.html", inventario=inventario)


@inventario_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        stock_min = float(request.form["stockMinimo"])
        stock_max = float(request.form["stockMaximo"])
        if stock_max <= stock_min:
            cur.close()
            conn.close()
            flash("El stock máximo debe ser mayor que el stock mínimo.")
            return redirect(url_for("inventario.crear"))

        try:
            cur.execute("""
                INSERT INTO InventarioInsumo
                    (idInventarioInsumo, idInsumo, cantidadDisponible, stockMinimo,
                     stockMaximo, demandaDiaria, ubicacionBodega)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                nuevo_id,
                request.form["idInsumo"],
                request.form["cantidadDisponible"],
                stock_min,
                stock_max,
                request.form["demandaDiaria"],
                request.form["ubicacionBodega"],
            ))
            conn.commit()
            flash("Inventario registrado correctamente.")
            return redirect(url_for("inventario.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("inventario.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT i.idInsumo, i.nombre
        FROM Insumo i
        LEFT JOIN InventarioInsumo inv ON inv.idInsumo = i.idInsumo
        WHERE inv.idInsumo IS NULL AND i.activo = TRUE
        ORDER BY i.nombre
    """)
    insumos_disponibles = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("inventario/formulario.html", insumos=insumos_disponibles, item=None)


@inventario_bp.route("/editar/<id_inventario>", methods=["GET", "POST"])
def editar(id_inventario):
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        stock_min = float(request.form["stockMinimo"])
        stock_max = float(request.form["stockMaximo"])
        if stock_max <= stock_min:
            cur.close()
            conn.close()
            flash("El stock máximo debe ser mayor que el stock mínimo.")
            return redirect(url_for("inventario.editar", id_inventario=id_inventario))

        try:
            cur.execute("""
                UPDATE InventarioInsumo SET
                    cantidadDisponible = %s, stockMinimo = %s, stockMaximo = %s,
                    demandaDiaria = %s, ubicacionBodega = %s, fechaActualizacion = NOW()
                WHERE idInventarioInsumo = %s
            """, (
                request.form["cantidadDisponible"],
                stock_min,
                stock_max,
                request.form["demandaDiaria"],
                request.form["ubicacionBodega"],
                id_inventario,
            ))
            conn.commit()
            flash("Inventario actualizado correctamente.")
            return redirect(url_for("inventario.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("inventario.editar", id_inventario=id_inventario))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT inv.*, i.nombre AS insumoNombre, i.unidadMedida
        FROM InventarioInsumo inv
        JOIN Insumo i ON inv.idInsumo = i.idInsumo
        WHERE inv.idInventarioInsumo = %s
    """, (id_inventario,))
    item = cur.fetchone()
    cur.close()
    conn.close()
    return render_template("inventario/formulario.html", insumos=None, item=item)
