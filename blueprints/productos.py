from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

productos_bp = Blueprint("productos", __name__, url_prefix="/productos")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idProducto FROM Producto ORDER BY idProducto DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "PRO001"
    numero = int(ultimo["idproducto"][3:]) + 1
    return f"PRO{numero:03d}"


@productos_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT p.idProducto, p.codigoBarras, p.nombre, p.presentacion,
               p.gradoAlcoholico, p.precioBase, p.tarifaIva, p.activo,
               c.nombreCategoria
        FROM Producto p
        JOIN CategoriaProducto c ON p.idCategoria = c.idCategoria
        ORDER BY p.idProducto
    """)
    productos = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("productos/listar.html", productos=productos)


@productos_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        try:
            cur.execute("""
                INSERT INTO Producto
                    (idProducto, codigoBarras, nombre, descripcion, presentacion,
                     gradoAlcoholico, precioBase, tarifaIva, sysTrace, idCategoria, activo)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE)
            """, (
                nuevo_id,
                request.form["codigoBarras"],
                request.form["nombre"],
                request.form.get("descripcion") or None,
                request.form["presentacion"],
                request.form["gradoAlcoholico"],
                request.form["precioBase"],
                request.form["tarifaIva"],
                request.form["sysTrace"],
                request.form["idCategoria"],
            ))
            conn.commit()
            flash("Producto creado correctamente.")
            return redirect(url_for("productos.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("productos.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT idCategoria, nombreCategoria FROM CategoriaProducto ORDER BY nombreCategoria")
    categorias = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("productos/formulario.html", categorias=categorias, producto=None)


@productos_bp.route("/editar/<id_producto>", methods=["GET", "POST"])
def editar(id_producto):
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        try:
            cur.execute("""
                UPDATE Producto SET
                    nombre = %s, descripcion = %s, presentacion = %s,
                    gradoAlcoholico = %s, precioBase = %s, tarifaIva = %s,
                    idCategoria = %s
                WHERE idProducto = %s
            """, (
                request.form["nombre"],
                request.form.get("descripcion") or None,
                request.form["presentacion"],
                request.form["gradoAlcoholico"],
                request.form["precioBase"],
                request.form["tarifaIva"],
                request.form["idCategoria"],
                id_producto,
            ))
            conn.commit()
            flash("Producto actualizado correctamente.")
            return redirect(url_for("productos.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("productos.editar", id_producto=id_producto))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT * FROM Producto WHERE idProducto = %s", (id_producto,))
    producto = cur.fetchone()
    cur.execute("SELECT idCategoria, nombreCategoria FROM CategoriaProducto ORDER BY nombreCategoria")
    categorias = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("productos/formulario.html", categorias=categorias, producto=producto)


@productos_bp.route("/eliminar/<id_producto>", methods=["POST"])
def eliminar(id_producto):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE Producto SET activo = FALSE WHERE idProducto = %s", (id_producto,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Producto desactivado correctamente.")
    return redirect(url_for("productos.listar"))


@productos_bp.route("/activar/<id_producto>", methods=["POST"])
def activar(id_producto):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE Producto SET activo = TRUE WHERE idProducto = %s", (id_producto,))
    conn.commit()
    cur.close()
    conn.close()
    flash("Producto activado correctamente.")
    return redirect(url_for("productos.listar"))