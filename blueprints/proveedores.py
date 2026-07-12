from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

proveedores_bp = Blueprint("proveedores", __name__, url_prefix="/proveedores")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idProveedor FROM Proveedor ORDER BY idProveedor DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "PROV001"
    numero = int(ultimo["idproveedor"][4:]) + 1
    return f"PROV{numero:03d}"


@proveedores_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT p.idProveedor, p.razonSocial, p.nit, p.telefono,
               p.email, p.tipoProveedor, p.calificacion, p.activo,
               p.tiempoEntregaPromedio, ci.nombre AS ciudad
        FROM Proveedor p
        JOIN Ciudad ci ON p.idCiudad = ci.idCiudad
        ORDER BY p.idProveedor
    """)
    proveedores = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("proveedores/listar.html", proveedores=proveedores)


@proveedores_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        try:
            cur.execute("""
                INSERT INTO Proveedor
                    (idProveedor, nit, razonSocial, direccion, idCiudad, telefono,
                     celular, contactoNombre, email, tipoProveedor, condicionesPago,
                     calificacion, habeasData, representanteLegal, tipoRegimen,
                     tiempoEntregaPromedio, bancoNombre, tipoCuenta, numeroCuenta,
                     contactoCartera, contactoLogistico, activo)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE)
            """, (
                nuevo_id,
                request.form["nit"],
                request.form["razonSocial"],
                request.form["direccion"],
                request.form["idCiudad"],
                request.form.get("telefono") or None,
                request.form["celular"],
                request.form["contactoNombre"],
                request.form["email"],
                request.form["tipoProveedor"],
                request.form["condicionesPago"],
                request.form["calificacion"],
                "habeasData" in request.form,
                request.form["representanteLegal"],
                request.form["tipoRegimen"],
                request.form["tiempoEntregaPromedio"],
                request.form.get("bancoNombre") or None,
                request.form.get("tipoCuenta") or None,
                request.form.get("numeroCuenta") or None,
                request.form.get("contactoCartera") or None,
                request.form.get("contactoLogistico") or None,
            ))
            conn.commit()
            flash("Proveedor creado correctamente.")
            return redirect(url_for("proveedores.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("proveedores.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT idCiudad, nombre FROM Ciudad ORDER BY nombre")
    ciudades = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("proveedores/formulario.html", ciudades=ciudades, proveedor=None)


@proveedores_bp.route("/editar/<id_proveedor>", methods=["GET", "POST"])
def editar(id_proveedor):
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        try:
            cur.execute("""
                UPDATE Proveedor SET
                    direccion = %s, idCiudad = %s, telefono = %s, celular = %s,
                    contactoNombre = %s, email = %s, tipoProveedor = %s,
                    condicionesPago = %s, calificacion = %s, habeasData = %s,
                    representanteLegal = %s, tipoRegimen = %s, tiempoEntregaPromedio = %s,
                    bancoNombre = %s, tipoCuenta = %s, numeroCuenta = %s,
                    contactoCartera = %s, contactoLogistico = %s
                WHERE idProveedor = %s
            """, (
                request.form["direccion"],
                request.form["idCiudad"],
                request.form.get("telefono") or None,
                request.form["celular"],
                request.form["contactoNombre"],
                request.form["email"],
                request.form["tipoProveedor"],
                request.form["condicionesPago"],
                request.form["calificacion"],
                "habeasData" in request.form,
                request.form["representanteLegal"],
                request.form["tipoRegimen"],
                request.form["tiempoEntregaPromedio"],
                request.form.get("bancoNombre") or None,
                request.form.get("tipoCuenta") or None,
                request.form.get("numeroCuenta") or None,
                request.form.get("contactoCartera") or None,
                request.form.get("contactoLogistico") or None,
                id_proveedor,
            ))
            conn.commit()
            flash("Proveedor actualizado correctamente.")
            return redirect(url_for("proveedores.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("proveedores.editar", id_proveedor=id_proveedor))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT * FROM Proveedor WHERE idProveedor = %s", (id_proveedor,))
    proveedor = cur.fetchone()
    cur.execute("SELECT idCiudad, nombre FROM Ciudad ORDER BY nombre")
    ciudades = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("proveedores/formulario.html", ciudades=ciudades, proveedor=proveedor)


@proveedores_bp.route("/eliminar/<id_proveedor>", methods=["POST"])
def eliminar(id_proveedor):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) AS total FROM CompraInsumo WHERE idProveedor = %s", (id_proveedor,))
    tiene_compras = cur.fetchone()["total"] > 0
    cur.execute("SELECT COUNT(*) AS total FROM Insumo WHERE idProveedor = %s", (id_proveedor,))
    tiene_insumos = cur.fetchone()["total"] > 0

    cur.execute("UPDATE Proveedor SET activo = FALSE WHERE idProveedor = %s", (id_proveedor,))
    conn.commit()
    cur.close()
    conn.close()

    if tiene_compras or tiene_insumos:
        flash("Proveedor desactivado. Nota: tiene compras/insumos asociados, se conserva su historial.")
    else:
        flash("Proveedor desactivado correctamente.")
    return redirect(url_for("proveedores.listar"))


@proveedores_bp.route("/activar/<id_proveedor>", methods=["POST"])
def activar(id_proveedor):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE Proveedor SET activo = TRUE WHERE idProveedor = %s", (id_proveedor,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Proveedor activado correctamente.")
    return redirect(url_for("proveedores.listar"))