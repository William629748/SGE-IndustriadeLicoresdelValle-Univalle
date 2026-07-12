from flask import Flask, render_template
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY")

from blueprints.clientes import clientes_bp
app.register_blueprint(clientes_bp)

from blueprints.proveedores import proveedores_bp
app.register_blueprint(proveedores_bp)

from blueprints.insumos import insumos_bp
app.register_blueprint(insumos_bp)

from blueprints.inventario import inventario_bp
app.register_blueprint(inventario_bp)

from blueprints.categorias import categorias_bp
app.register_blueprint(categorias_bp)

from blueprints.productos import productos_bp
app.register_blueprint(productos_bp)

from blueprints.inventario_producto import inventario_producto_bp
app.register_blueprint(inventario_producto_bp)

from blueprints.produccion import produccion_bp
app.register_blueprint(produccion_bp)

from blueprints.compras import compras_bp
app.register_blueprint(compras_bp)

from blueprints.ventas import ventas_bp
app.register_blueprint(ventas_bp)

from blueprints.facturas import facturas_bp
app.register_blueprint(facturas_bp)

@app.route("/")
def inicio():
    return render_template("inicio.html")

if __name__ == "__main__":
    app.run(debug=True)
