from flask import Blueprint, render_template, request, redirect, url_for, flash
import psycopg2
from db import get_connection, mensaje_error_amigable
from blueprints.inventario import calcular_estado

inventario_producto_bp = Blueprint(
    "inventario_producto", __name__, url_prefix="/inventario-producto"
)


def generar_siguiente_id():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT idInventarioProducto FROM inventarioProducto ORDER BY idInventarioProducto DESC LIMIT 1")
    ultimo = cur.fetchone()
    cur.close()
    conn.close()
    if ultimo is None:
        return "IPRO001"
    numero = int(ultimo["idinventarioproducto"][4:]) + 1
    return f"IPRO{numero:03d}"


@inventario_producto_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT inv.idInventarioProducto, inv.stockActual, inv.stockMinimo,
               inv.stockMaximo, inv.demandaDiaria, inv.ubicacionBodega, inv.fechaActualizacion,
               p.idProducto, p.nombre AS productoNombre, p.presentacion
        FROM inventarioProducto inv
        JOIN Producto p ON inv.idProducto = p.idProducto
        ORDER BY p.nombre
    """)
    filas = cur.fetchall()
    cur.close()
    conn.close()

    inventario = []
    for f in filas:
        estado, accion, dias_stock = calcular_estado(
            float(f["stockactual"]), float(f["demandadiaria"])
        )
        f = dict(f)
        f["estado"] = estado
        f["accion"] = accion
        f["diasStock"] = round(dias_stock, 1)
        inventario.append(f)

    return render_template("inventario_producto/listar.html", inventario=inventario)


@inventario_producto_bp.route("/nuevo", methods=["GET", "POST"])
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
            return redirect(url_for("inventario_producto.crear"))

        try:
            cur.execute("""
                INSERT INTO inventarioProducto
                    (idInventarioProducto, idProducto, stockActual, stockMinimo,
                     stockMaximo, demandaDiaria, ubicacionBodega)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                nuevo_id,
                request.form["idProducto"],
                request.form["stockActual"],
                stock_min,
                stock_max,
                request.form["demandaDiaria"],
                request.form["ubicacionBodega"],
            ))
            conn.commit()
            flash("Inventario de producto registrado correctamente.")
            return redirect(url_for("inventario_producto.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("inventario_producto.crear"))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT p.idProducto, p.nombre
        FROM Producto p
        LEFT JOIN inventarioProducto inv ON inv.idProducto = p.idProducto
        WHERE inv.idProducto IS NULL AND p.activo = TRUE
        ORDER BY p.nombre
    """)
    productos_disponibles = cur.fetchall()
    cur.close()
    conn.close()
    return render_template(
        "inventario_producto/formulario.html", productos=productos_disponibles, item=None
    )


@inventario_producto_bp.route("/editar/<id_inventario>", methods=["GET", "POST"])
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
            return redirect(url_for("inventario_producto.editar", id_inventario=id_inventario))

        try:
            cur.execute("""
                UPDATE inventarioProducto SET
                    stockActual = %s, stockMinimo = %s, stockMaximo = %s,
                    demandaDiaria = %s, ubicacionBodega = %s, fechaActualizacion = NOW()
                WHERE idInventarioProducto = %s
            """, (
                request.form["stockActual"],
                stock_min,
                stock_max,
                request.form["demandaDiaria"],
                request.form["ubicacionBodega"],
                id_inventario,
            ))
            conn.commit()
            flash("Inventario de producto actualizado correctamente.")
            return redirect(url_for("inventario_producto.listar"))
        except psycopg2.Error as e:
            conn.rollback()
            flash(mensaje_error_amigable(e))
            return redirect(url_for("inventario_producto.editar", id_inventario=id_inventario))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT inv.*, p.nombre AS productoNombre, p.presentacion
        FROM inventarioProducto inv
        JOIN Producto p ON inv.idProducto = p.idProducto
        WHERE inv.idInventarioProducto = %s
    """, (id_inventario,))
    item = cur.fetchone()
    cur.close()
    conn.close()
    return render_template("inventario_producto/formulario.html", productos=None, item=item)
