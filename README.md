# SGE - Industria de Licores del Valle (Univalle)

Sistema de Gestión Empresarial (SGE) para una industria de licores, desarrollado como proyecto académico de la Universidad del Valle. El proyecto tiene dos partes:

- **Modelo de base de datos** (rama `main`): esquema relacional en PostgreSQL con datos de prueba y consultas de negocio.
- **Aplicación web** (rama `app-web`): app en Flask + PostgreSQL que consume ese modelo con CRUD completo por módulo.

> Este repositorio usa varias ramas en paralelo (ver [Ramas del repositorio](#ramas-del-repositorio)). La rama `main` solo contiene el modelo de datos; para ejecutar la aplicación web hay que cambiar a la rama `app-web`.

## Ramas del repositorio

| Rama | Contenido |
|---|---|
| `main` | Modelo de datos (DDL, datos de prueba, consultas SQL) y diagrama ER |
| `app-web` | Aplicación web completa (Flask) que usa el modelo de datos |
| `feature/EstructuraOrg` | Desarrollo en curso de estructura organizacional (cargos/empleados) |
| `feature/Productos` | Desarrollo en curso del módulo de productos |
| `feature/distribuidor` | Desarrollo en curso del módulo de distribuidores |
| `feature/proveedor` | Desarrollo en curso del módulo de proveedores |

## Modelo de datos (rama `main`)

Esquema PostgreSQL con **23 tablas** que cubren datos maestros, compras, producción, inventarios, ventas, facturación, envíos y contratos.

```
db/
├── 01_DDL_tablas.sql                        # Definición de las 23 tablas
├── Bloque1_Datos_Maestros_ILV.sql           # Carga de datos maestros
├── Bloque2_Compras_De_Insumos_ILV.sql       # Compras de insumos (datos generados)
├── Bloque3_Produccion_Ventas_Documentos_ILV.sql  # Producción, ventas, facturas, envíos, contratos
└── Consultas_ILV.sql                        # 10 consultas de negocio de ejemplo
docs/
└── Diagrama de BD.png                       # Diagrama entidad-relación
```

Dominios del modelo: `Pais/Departamento/Ciudad`, `Cargo/Empleado`, `CategoriaProducto/Producto/Insumo`, `Proveedor/ClienteEmpresa/Distribuidor/PuntoDeVenta`, `CompraInsumo/DetalleCompraInsumo/InventarioInsumo/InventarioProducto`, `LoteProduccion/ConsumoInsumo`, `Venta/DetalleVenta/Factura/Envio` y `Contrato`.

## Aplicación web (rama `app-web`)

App en **Flask** organizada por *blueprints*, uno por módulo de negocio, con vistas Jinja2 y conexión directa a PostgreSQL vía `psycopg2`.

```
app-web/
├── app.py                    # Punto de entrada; registra todos los blueprints
├── db.py                     # Conexión a PostgreSQL y traducción de errores a mensajes amigables
├── requirements.txt          # Flask, psycopg2-binary, python-dotenv, etc.
├── .env.example              # Variables de entorno de ejemplo
├── blueprints/                # Un módulo por entidad de negocio
│   ├── categorias.py          # /categorias
│   ├── clientes.py            # /clientes
│   ├── compras.py             # /compras (incluye recepción y recálculo de totales)
│   ├── facturas.py            # /facturas
│   ├── insumos.py             # /insumos
│   ├── inventario.py          # /inventario (insumos, con cálculo de estado de stock)
│   ├── inventario_producto.py # /inventario-producto
│   ├── produccion.py          # /produccion (lotes, consumo de insumos, cierre de lote)
│   ├── productos.py           # /productos
│   ├── proveedores.py         # /proveedores
│   └── ventas.py              # /ventas (incluye generación de factura y envío)
├── templates/                 # Vistas Jinja2 (listar/formulario/detalle por módulo)
└── static/css/                # Estilos base
```

Cada módulo expone operaciones CRUD (listar, crear, editar, activar/eliminar según el caso) sobre su entidad correspondiente, con generación automática de IDs consecutivos y recálculo de totales en compras y ventas.

Además del esquema base, la rama `app-web` agrega scripts adicionales en `db/`:

| Script | Propósito |
|---|---|
| `02_ALTER_ajustes_pdf.sql` | Agrega campos de habeas data, representante legal y régimen tributario a `ClienteEmpresa` y `Proveedor`, y datos bancarios/logísticos a `Proveedor` |
| `03_Reto_Trigger_InventarioCompras.sql` | Trigger PL/pgSQL: al pasar una compra a estado `Recibida`, actualiza automáticamente el inventario de insumos |
| `04_Reto_Indices.sql` | Índices sobre las columnas FK más consultadas (ventas, detalle de venta, compras, etc.) |
| `05_Reto_Vistas.sql` | Vistas de negocio, incluyendo estado de stock de insumos con días de cobertura calculados |

### Cómo ejecutar la aplicación web

Requiere Python 3.11+, PostgreSQL 15+ y Git. (Ver también `EJECUTAR_EN_WINDOWS.md` en la rama `app-web` para el paso a paso detallado en Windows.)

```bash
# 1. Clonar y cambiar a la rama de la app
git clone https://github.com/William629748/SGE-IndustriadeLicoresdelValle-Univalle.git
cd SGE-IndustriadeLicoresdelValle-Univalle
git checkout app-web

# 2. Entorno virtual y dependencias
python -m venv venv
source venv/bin/activate        # En Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. Crear base de datos en PostgreSQL
psql -U postgres -c "CREATE USER andres_ilv WITH PASSWORD 'ilv2026';"
psql -U postgres -c "CREATE DATABASE ilv_db OWNER andres_ilv;"

# 4. Cargar esquema, datos y extensiones, en este orden
psql -U andres_ilv -d ilv_db -f db/01_DDL_tablas.sql
psql -U andres_ilv -d ilv_db -f db/02_ALTER_ajustes_pdf.sql
psql -U andres_ilv -d ilv_db -f db/Bloque1_Datos_Maestros_ILV.sql
psql -U andres_ilv -d ilv_db -f db/Bloque2_Compras_De_Insumos_ILV.sql
psql -U andres_ilv -d ilv_db -f db/Bloque3_Produccion_Ventas_Documentos_ILV.sql
psql -U andres_ilv -d ilv_db -f db/03_Reto_Trigger_InventarioCompras.sql
psql -U andres_ilv -d ilv_db -f db/04_Reto_Indices.sql
psql -U andres_ilv -d ilv_db -f db/05_Reto_Vistas.sql

# 5. Configurar variables de entorno
cp .env.example .env
# Edita .env con host/usuario/contraseña de tu base

# 6. Ejecutar
python app.py
# Abre http://127.0.0.1:5000
```

## Tecnologías

- **Backend**: Python 3.11+, Flask 3.1, psycopg2-binary
- **Base de datos**: PostgreSQL (triggers, vistas, índices, columnas generadas)
- **Frontend**: Jinja2 + CSS

## Autores

Proyecto académico — Universidad del Valle (Univalle).

- Andrés Muñoz Moreno (2438908)
- William Rooselbelt May Barreto (2435731)
- Samuel Saldaña Girando (2437631)
- Juan Fernando Marmolejo (2437661)
