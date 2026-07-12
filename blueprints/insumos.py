from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

insumos_bp = Blueprint("insumos", __name__, url_prefix="/insumos")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idInsumo FROM Insumo ORDER BY idInsumo DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "INS001"
    numero = int(ultimo["idinsumo"][3:]) + 1
    return f"INS{numero:03d}"


@insumos_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT i.idInsumo, i.codigoInsumo, i.nombre, i.unidadMedida,
               i.tipoInsumo, i.activo, p.razonSocial AS proveedor
        FROM Insumo i
        JOIN Proveedor p ON i.idProveedor = p.idProveedor
        ORDER BY i.idInsumo
    """)
    insumos = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("insumos/listar.html", insumos=insumos)


@insumos_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        try:
            cur.execute("""
                INSERT INTO Insumo
                    (idInsumo, codigoInsumo, nombre, descripcion, unidadMedida,
                     tipoInsumo, idProveedor, activo)
                VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE)
            """, (
                nuevo_id,
                request.form["codigoInsumo"],
                request.form["nombre"],
                request.form.get("descripcion") or None,
                request.form["unidadMedida"],
                request.form["tipoInsumo"],
                request.form["idProveedor"],
            ))
            conn.commit()
            flash("Insumo creado correctamente.")
            return redirect(url_for("insumos.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("insumos.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT idProveedor, razonSocial FROM Proveedor WHERE activo = TRUE ORDER BY razonSocial")
    proveedores = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("insumos/formulario.html", proveedores=proveedores, insumo=None)


@insumos_bp.route("/editar/<id_insumo>", methods=["GET", "POST"])
def editar(id_insumo):
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        try:
            cur.execute("""
                UPDATE Insumo SET
                    nombre = %s, descripcion = %s, unidadMedida = %s,
                    tipoInsumo = %s, idProveedor = %s
                WHERE idInsumo = %s
            """, (
                request.form["nombre"],
                request.form.get("descripcion") or None,
                request.form["unidadMedida"],
                request.form["tipoInsumo"],
                request.form["idProveedor"],
                id_insumo,
            ))
            conn.commit()
            flash("Insumo actualizado correctamente.")
            return redirect(url_for("insumos.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("insumos.editar", id_insumo=id_insumo))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT * FROM Insumo WHERE idInsumo = %s", (id_insumo,))
    insumo = cur.fetchone()
    cur.execute("SELECT idProveedor, razonSocial FROM Proveedor WHERE activo = TRUE ORDER BY razonSocial")
    proveedores = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("insumos/formulario.html", proveedores=proveedores, insumo=insumo)


@insumos_bp.route("/eliminar/<id_insumo>", methods=["POST"])
def eliminar(id_insumo):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE Insumo SET activo = FALSE WHERE idInsumo = %s", (id_insumo,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Insumo desactivado correctamente.")
    return redirect(url_for("insumos.listar"))


@insumos_bp.route("/activar/<id_insumo>", methods=["POST"])
def activar(id_insumo):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE Insumo SET activo = TRUE WHERE idInsumo = %s", (id_insumo,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Insumo activado correctamente.")
    return redirect(url_for("insumos.listar"))