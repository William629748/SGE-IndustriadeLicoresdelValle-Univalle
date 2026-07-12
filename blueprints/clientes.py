from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

clientes_bp = Blueprint("clientes", __name__, url_prefix="/clientes")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idCliente FROM ClienteEmpresa ORDER BY idCliente DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "CLI001"
    numero = int(ultimo["idcliente"][3:]) + 1
    return f"CLI{numero:03d}"


@clientes_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT c.idCliente, c.nombreRazonSocial, c.nit, c.telefono,
               c.correo, c.tipoCliente, c.activo, ci.nombre AS ciudad
        FROM ClienteEmpresa c
        JOIN Ciudad ci ON c.idCiudad = ci.idCiudad
        ORDER BY c.idCliente
    """)
    clientes = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("clientes/listar.html", clientes=clientes)


@clientes_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        try:
            cur.execute("""
                INSERT INTO ClienteEmpresa
                    (idCliente, tipoDocumento, numeroDocumento, nombreRazonSocial,
                     nit, direccion, idCiudad, telefono, celular, correo,
                     tipoCliente, habeasData, representanteLegal, tipoRegimen, activo)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE)
            """, (
                nuevo_id,
                request.form["tipoDocumento"],
                request.form["numeroDocumento"],
                request.form["nombreRazonSocial"],
                request.form["nit"],
                request.form["direccion"],
                request.form["idCiudad"],
                request.form.get("telefono") or None,
                request.form["celular"],
                request.form["correo"],
                request.form["tipoCliente"],
                "habeasData" in request.form,
                request.form["representanteLegal"],
                request.form["tipoRegimen"],
            ))
            conn.commit()
            flash("Cliente creado correctamente.")
            return redirect(url_for("clientes.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("clientes.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT idCiudad, nombre FROM Ciudad ORDER BY nombre")
    ciudades = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("clientes/formulario.html", ciudades=ciudades, cliente=None)


@clientes_bp.route("/editar/<id_cliente>", methods=["GET", "POST"])
def editar(id_cliente):
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        try:
            cur.execute("""
                UPDATE ClienteEmpresa SET
                    direccion = %s, idCiudad = %s, telefono = %s, celular = %s,
                    correo = %s, tipoCliente = %s, habeasData = %s,
                    representanteLegal = %s, tipoRegimen = %s
                WHERE idCliente = %s
            """, (
                request.form["direccion"],
                request.form["idCiudad"],
                request.form.get("telefono") or None,
                request.form["celular"],
                request.form["correo"],
                request.form["tipoCliente"],
                "habeasData" in request.form,
                request.form["representanteLegal"],
                request.form["tipoRegimen"],
                id_cliente,
            ))
            conn.commit()
            flash("Cliente actualizado correctamente.")
            return redirect(url_for("clientes.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("clientes.editar", id_cliente=id_cliente))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT * FROM ClienteEmpresa WHERE idCliente = %s", (id_cliente,))
    cliente = cur.fetchone()
    cur.execute("SELECT idCiudad, nombre FROM Ciudad ORDER BY nombre")
    ciudades = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("clientes/formulario.html", ciudades=ciudades, cliente=cliente)


@clientes_bp.route("/eliminar/<id_cliente>", methods=["POST"])
def eliminar(id_cliente):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE ClienteEmpresa SET activo = FALSE WHERE idCliente = %s", (id_cliente,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Cliente desactivado correctamente.")
    return redirect(url_for("clientes.listar"))


@clientes_bp.route("/activar/<id_cliente>", methods=["POST"])
def activar(id_cliente):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE ClienteEmpresa SET activo = TRUE WHERE idCliente = %s", (id_cliente,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Cliente activado correctamente.")
    return redirect(url_for("clientes.listar"))