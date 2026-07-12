from flask import Blueprint, render_template, redirect, url_for, flash
from db import get_connection

facturas_bp = Blueprint("facturas", __name__, url_prefix="/facturas")


@facturas_bp.route("/")
def listar():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT f.idFactura, f.numeroFactura, f.fechaFactura, f.subtotal,
               f.iva, f.total, f.metodoPago, f.estadoFactura,
               cli.nombreRazonSocial AS clienteNombre
        FROM Factura f
        JOIN Venta v ON f.idVenta = v.idVenta
        JOIN ClienteEmpresa cli ON v.idCliente = cli.idCliente
        ORDER BY f.fechaFactura DESC, f.idFactura DESC
    """)
    facturas = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("facturas/listar.html", facturas=facturas)


@facturas_bp.route("/<id_factura>")
def ver(id_factura):
    conn = get_connection()
    cur = conn.cursor()

    # Cabecera: Factura + Venta + Cliente. Los "Datos del Vendedor" (NIT,
    # Razón Social, dirección de ILV) los dejamos fijos en el template,
    # porque son constantes de la empresa, no cambian por venta.
    cur.execute("""
        SELECT f.*, v.fechaVenta,
               cli.nombreRazonSocial AS clienteNombre,
               cli.nit AS clienteNit,
               cli.tipoDocumento AS clienteTipoDocumento,
               cli.numeroDocumento AS clienteNumeroDocumento
        FROM Factura f
        JOIN Venta v ON f.idVenta = v.idVenta
        JOIN ClienteEmpresa cli ON v.idCliente = cli.idCliente
        WHERE f.idFactura = %s
    """, (id_factura,))
    factura = cur.fetchone()

    if factura is None:
        cur.close()
        conn.close()
        flash("La factura no existe.")
        return redirect(url_for("facturas.listar"))

    # Detalle de bienes, con IVA discriminado por ítem (lo exige el PDF)
    cur.execute("""
        SELECT dv.cantidad, dv.precioUnitario, dv.subtotalProducto,
               p.nombre AS productoNombre, p.presentacion, p.tarifaIva,
               ROUND(dv.subtotalProducto * p.tarifaIva / 100, 2) AS ivaLinea
        FROM DetalleVenta dv
        JOIN Producto p ON dv.idProducto = p.idProducto
        WHERE dv.idVenta = %s
        ORDER BY dv.idDetalleVenta
    """, (factura["idventa"],))
    lineas = cur.fetchall()

    cur.close()
    conn.close()
    return render_template("facturas/ver.html", factura=factura, lineas=lineas)
