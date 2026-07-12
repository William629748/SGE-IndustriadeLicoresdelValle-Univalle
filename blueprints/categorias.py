from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable

categorias_bp = Blueprint("categorias", __name__, url_prefix="/categorias")


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idCategoria FROM CategoriaProducto ORDER BY idCategoria DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "CAT001"
    numero = int(ultimo["idcategoria"][3:]) + 1
    return f"CAT{numero:03d}"


@categorias_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM CategoriaProducto ORDER BY nombreCategoria")
    categorias = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("categorias/listar.html", categorias=categorias)


@categorias_bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    if request.method == "POST":
        nuevo_id = generar_siguiente_id()
        conn = get_connection()
        cur = conn.cursor()
        try:
            cur.execute("""
                INSERT INTO CategoriaProducto (idCategoria, nombreCategoria, descripcion)
                VALUES (%s, %s, %s)
            """, (
                nuevo_id,
                request.form["nombreCategoria"],
                request.form.get("descripcion") or None,
            ))
            conn.commit()
            flash("Categoría creada correctamente.")
            return redirect(url_for("categorias.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("categorias.crear"))
        finally:
            cur.close()
            conn.close()

    return render_template("categorias/formulario.html", categoria=None)


@categorias_bp.route("/editar/<id_categoria>", methods=["GET", "POST"])
def editar(id_categoria):
    conn = get_connection()
    cur = conn.cursor()

    if request.method == "POST":
        try:
            cur.execute("""
                UPDATE CategoriaProducto SET nombreCategoria = %s, descripcion = %s
                WHERE idCategoria = %s
            """, (
                request.form["nombreCategoria"],
                request.form.get("descripcion") or None,
                id_categoria,
            ))
            conn.commit()
            flash("Categoría actualizada correctamente.")
            return redirect(url_for("categorias.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("categorias.editar", id_categoria=id_categoria))
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT * FROM CategoriaProducto WHERE idCategoria = %s", (id_categoria,))
    categoria = cur.fetchone()
    cur.close()
    conn.close()
    return render_template("categorias/formulario.html", categoria=categoria)