from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

produccion_bp = Blueprint("produccion", __name__, url_prefix="/produccion")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idLote FROM LoteProduccion ORDER BY idLote DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "LOT001"
    numero = int(ultimo["idlote"][3:]) + 1
    return f"LOT{numero:03d}"


@produccion_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT l.idLote, l.fechaProduccion, l.fechaVencimiento, l.cantidadProducida,
               l.estado, l.observaciones,
               p.nombre AS productoNombre,
               e.nombres AS empleadoNombres, e.apellidos AS empleadoApellidos
        FROM LoteProduccion l
        JOIN Producto p ON l.idProducto = p.idProducto
        JOIN Empleado e ON l.idEmpleado = e.idEmpleado
        ORDER BY l.fechaProduccion DESC, l.idLote DESC
    """)
    lotes = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("produccion/listar.html", lotes=lotes)


@produccion_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        try:
            cur.execute("""
                INSERT INTO LoteProduccion
                    (idLote, fechaProduccion, fechaVencimiento, cantidadProducida,
                     idProducto, idEmpleado, estado, observaciones)
                VALUES (%s, %s, %s, %s, %s, %s, 'EN_PROCESO', %s)
            """, (
                nuevo_id,
                request.form["fechaProduccion"],
                request.form["fechaVencimiento"],
                request.form["cantidadProducida"],
                request.form["idProducto"],
                request.form["idEmpleado"],
                request.form.get("observaciones") or None,
            ))
            conn.commit()
            flash("Lote de producción registrado correctamente (estado: EN_PROCESO).")
            return redirect(url_for("produccion.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("produccion.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT idProducto, nombre FROM Producto WHERE activo = TRUE ORDER BY nombre")
    productos = cur.fetchall()
    cur.execute("""
        SELECT idEmpleado, nombres, apellidos FROM Empleado
        WHERE activo = TRUE ORDER BY nombres
    """)
    empleados = cur.fetchall()
    cur.close()
    conn.close()
    return render_template(
        "produccion/formulario.html", productos=productos, empleados=empleados, lote=None
    )


@produccion_bp.route("/editar/<id_lote>", methods=["GET", "POST"])
def editar(id_lote):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT * FROM LoteProduccion WHERE idLote = %s", (id_lote,))
    lote = cur.fetchone()

    if lote is None:
        cur.close()
        conn.close()
        flash("El lote no existe.")
        return redirect(url_for("produccion.listar"))

    if lote["estado"] != "EN_PROCESO":
        cur.close()
        conn.close()
        flash(f"Este lote está {lote['estado']} y ya no puede editarse (afectó inventarios o fue rechazado).")
        return redirect(url_for("produccion.listar"))

    if request.method == "POST":
        try:
            cur.execute("""
                UPDATE LoteProduccion SET
                    fechaProduccion = %s, fechaVencimiento = %s, cantidadProducida = %s,
                    idProducto = %s, idEmpleado = %s, observaciones = %s
                WHERE idLote = %s AND estado = 'EN_PROCESO'
            """, (
                request.form["fechaProduccion"],
                request.form["fechaVencimiento"],
                request.form["cantidadProducida"],
                request.form["idProducto"],
                request.form["idEmpleado"],
                request.form.get("observaciones") or None,
                id_lote,
            ))
            conn.commit()
            flash("Lote actualizado correctamente.")
            return redirect(url_for("produccion.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("produccion.editar", id_lote=id_lote))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT idProducto, nombre FROM Producto WHERE activo = TRUE ORDER BY nombre")
    productos = cur.fetchall()
    cur.execute("""
        SELECT idEmpleado, nombres, apellidos FROM Empleado
        WHERE activo = TRUE ORDER BY nombres
    """)
    empleados = cur.fetchall()
    cur.close()
    conn.close()
    return render_template(
        "produccion/formulario.html", productos=productos, empleados=empleados, lote=lote
    )


def generar_siguiente_id_consumo():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idConsumo FROM ConsumoInsumo ORDER BY idConsumo DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "CNS001"
    numero = int(ultimo["idconsumo"][3:]) + 1
    return f"CNS{numero:03d}"


@produccion_bp.route("/<id_lote>/consumo", methods=["GET", "POST"])
def consumo(id_lote):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT * FROM LoteProduccion WHERE idLote = %s", (id_lote,))
    lote = cur.fetchone()

    if lote is None:
        cur.close()
        conn.close()
        flash("El lote no existe.")
        return redirect(url_for("produccion.listar"))

    if lote["estado"] != "EN_PROCESO":
        cur.close()
        conn.close()
        flash(f"Este lote está {lote['estado']} y ya no admite registrar consumo de insumos.")
        return redirect(url_for("produccion.listar"))

    if request.method == "POST":
        nuevo_id = generar_siguiente_id_consumo()
        try:
            cur.execute("""
                INSERT INTO ConsumoInsumo
                    (idConsumo, idLote, idInsumo, cantidadConsumida, fechaConsumo, idEmpleado)
                VALUES (%s, %s, %s, %s, NOW(), %s)
            """, (
                nuevo_id,
                id_lote,
                request.form["idInsumo"],
                request.form["cantidadConsumida"],
                lote["idempleado"],
            ))
            conn.commit()
            flash("Consumo de insumo registrado correctamente.")
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
        finally:
            cur.close()
            conn.close()
        return redirect(url_for("produccion.consumo", id_lote=id_lote))

    cur.execute("""
        SELECT c.idConsumo, c.cantidadConsumida, c.fechaConsumo,
               i.nombre AS insumoNombre, i.unidadMedida
        FROM ConsumoInsumo c
        JOIN Insumo i ON c.idInsumo = i.idInsumo
        WHERE c.idLote = %s
        ORDER BY c.fechaConsumo DESC
    """, (id_lote,))
    consumos = cur.fetchall()

    cur.execute("SELECT idInsumo, nombre, unidadMedida FROM Insumo WHERE activo = TRUE ORDER BY nombre")
    insumos = cur.fetchall()

    cur.close()
    conn.close()
    return render_template(
        "produccion/consumo.html", lote=lote, consumos=consumos, insumos=insumos
    )


@produccion_bp.route("/consumo/eliminar/<id_consumo>", methods=["POST"])
def eliminar_consumo(id_consumo):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT c.idLote, l.estado
        FROM ConsumoInsumo c
        JOIN LoteProduccion l ON c.idLote = l.idLote
        WHERE c.idConsumo = %s
    """, (id_consumo,))
    fila = cur.fetchone()

    if fila is None:
        cur.close()
        conn.close()
        flash("El registro de consumo no existe.")
        return redirect(url_for("produccion.listar"))

    if fila["estado"] != "EN_PROCESO":
        cur.close()
        conn.close()
        flash("No se puede eliminar: el lote ya no está EN_PROCESO.")
        return redirect(url_for("produccion.listar"))

    try:
        cur.execute("DELETE FROM ConsumoInsumo WHERE idConsumo = %s", (id_consumo,))
        conn.commit()
        flash("Línea de consumo eliminada.")
    except psycopg2.Error as e:
        conn.rollback()
        flash(mensaje_error_amigable(e))
    finally:
        cur.close()
        conn.close()

    return redirect(url_for("produccion.consumo", id_lote=fila["idlote"]))


def _cerrar_lote(id_lote, nuevo_estado):
    """
    Cambia el estado de un lote EN_PROCESO a FINALIZADO o RECHAZADO,
    e impacta los inventarios en una sola transacción:
      - Siempre resta del InventarioInsumo cada cantidadConsumida
        registrada para este lote (el insumo ya se gastó físicamente,
        sin importar si el lote se finaliza o se rechaza).
      - Solo si nuevo_estado == 'FINALIZADO', suma cantidadProducida
        al stockActual de inventarioProducto.
    Si algo falla (ej. CHECK cantidadDisponible >= 0), se hace rollback
    completo y el lote NO cambia de estado.
    """
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM LoteProduccion WHERE idLote = %s", (id_lote,))
        lote = cur.fetchone()

        if lote is None:
            flash("El lote no existe.")
            return

        if lote["estado"] != "EN_PROCESO":
            flash(f"Este lote ya está {lote['estado']}, no se puede cambiar de nuevo.")
            return

        cur.execute("""
            UPDATE LoteProduccion SET estado = %s
            WHERE idLote = %s AND estado = 'EN_PROCESO'
        """, (nuevo_estado, id_lote))

        cur.execute("""
            SELECT idInsumo, cantidadConsumida
            FROM ConsumoInsumo
            WHERE idLote = %s
        """, (id_lote,))
        consumos = cur.fetchall()

        for c in consumos:
            cur.execute("""
                UPDATE InventarioInsumo
                SET cantidadDisponible = cantidadDisponible - %s,
                    fechaActualizacion = NOW()
                WHERE idInsumo = %s
            """, (c["cantidadconsumida"], c["idinsumo"]))

        if nuevo_estado == "FINALIZADO":
            cur.execute("""
                UPDATE inventarioProducto
                SET stockActual = stockActual + %s,
                    fechaActualizacion = NOW()
                WHERE idProducto = %s
            """, (lote["cantidadproducida"], lote["idproducto"]))

        conn.commit()
        flash(f"Lote {id_lote} marcado como {nuevo_estado} e inventarios actualizados.")
    except psycopg2.Error as e:
        conn.rollback()
        flash(mensaje_error_amigable(e))
    finally:
        cur.close()
        conn.close()


@produccion_bp.route("/finalizar/<id_lote>", methods=["POST"])
def finalizar(id_lote):
    _cerrar_lote(id_lote, "FINALIZADO")
    return redirect(url_for("produccion.listar"))


@produccion_bp.route("/rechazar/<id_lote>", methods=["POST"])
def rechazar(id_lote):
    _cerrar_lote(id_lote, "RECHAZADO")
    return redirect(url_for("produccion.listar"))
