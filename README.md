`> **Nota:** la aplicación web del proyecto **no se encuentra en la rama `main`**, sino en la rama **`app-web`**. Las instrucciones de instalación más abajo indican cómo cambiar a esa rama.

# Proyecto Final: Sistema de Gestión Empresarial (SGE) — Industria de Licores del Valle

**Asignatura:** 750006C Bases de Datos

**Institución:** Universidad del Valle - Escuela de Ingeniería de Sistemas y Computación

**Docente:** Susana Medina Gordillo

**Semestre:** 2026-1

**Repositorio:** [github.com/William629748/SGE-IndustriadeLicoresdelValle-Univalle](https://github.com/William629748/SGE-IndustriadeLicoresdelValle-Univalle)

## 🏢 Información de la Empresa Seleccionada

- **Nombre de la Empresa:** Industria de Licores del Valle (ILV)
- **Sector Económico:** Manufactura — producción y comercialización de licores
- **Descripción breve:** Empresa colombiana dedicada a la producción de licores. El sistema gestiona insumos y proveedores, producción por lotes, control de inventario de insumos y de producto terminado, ventas, facturación, distribuidores y puntos de venta.

## 👥 Integrantes del Grupo

1. William May - [Código]
2. Andrés Muñoz Moreno - [Código]
3. Juan Fernando Marmolejo - [Código]
4. Samuel Saldaña Giraldo - [Código]

## 🛠️ Stack Tecnológico

- **Lenguaje:** Python 3.11+
- **Framework Web:** Flask 3.1 (arquitectura basada en Blueprints)
- **Base de Datos:** PostgreSQL
- **ORM / Conector:** psycopg2-binary (conexión directa vía SQL, sin ORM)
- **Motor de plantillas:** Jinja2
- **Otras librerías:** python-dotenv (variables de entorno), Werkzeug

## 🌿 Arquitectura del Repositorio y Ramas

El repositorio distribuye el trabajo en varias ramas. La rama `main` solo contiene el diseño de base de datos (carpeta `db/`) y el diagrama ER (carpeta `docs/`). La aplicación web completa vive en la rama `app-web`.

- **main:** scripts SQL de diseño (DDL, vistas/triggers, datos de prueba) y el diagrama entidad-relación.
- **app-web:** aplicación Flask completa (backend, plantillas HTML, estáticos) + los mismos scripts de base de datos, lista para ejecutarse.
- **feature/EstructuraOrg, feature/Productos, feature/distribuidor, feature/proveedor:** ramas de desarrollo por módulo, ya integradas a `app-web` mediante pull requests.

Estructura principal de la rama `app-web`:

```
app-web/
├── app.py                     # Punto de entrada Flask, registro de blueprints
├── db.py                      # Conexión a PostgreSQL (psycopg2)
├── requirements.txt
├── .env.example
├── blueprints/                # Un módulo por entidad de negocio
│   ├── clientes.py
│   ├── proveedores.py
│   ├── insumos.py
│   ├── inventario.py
│   ├── categorias.py
│   ├── productos.py
│   ├── inventario_producto.py
│   ├── produccion.py
│   ├── compras.py
│   ├── ventas.py
│   └── facturas.py
├── templates/                 # Vistas Jinja2 (una carpeta por módulo)
├── static/css/
├── db/                        # Scripts SQL (DDL, retos, datos de prueba)
└── docs/                      # Diagrama entidad-relación
```

## 📐 Diseño de la Base de Datos

A continuación se describe la estructura relacional que soporta la aplicación.

### Diagrama Entidad-Relación (DER)

El diagrama se encuentra en `docs/Diagrama de BD.png` dentro del repositorio (disponible tanto en `main` como en `app-web`).

### Diccionario de Datos Resumido

- **Ubicación geográfica:** Pais, Departamento, Ciudad.
- **Estructura organizacional:** Cargo, Empleado.
- **Terceros:** Proveedor, ClienteEmpresa, Distribuidor.
- **Productos e insumos:** CategoriaProducto, Producto, Insumo, InventarioInsumo, inventarioProducto.
- **Compras:** CompraInsumo, DetalleCompraInsumo.
- **Producción:** LoteProduccion, ConsumoInsumo.
- **Ventas y facturación:** PuntoDeVenta, Venta, DetalleVenta, Factura.
- **Distribución:** Envio, Contrato.

## 🚀 Guía de Instalación y Ejecución

Estos pasos ejecutan la aplicación web, que está en la rama `app-web`, no en `main`.

### 1. Clonar el repositorio y cambiar a la rama app-web

```bash
git clone https://github.com/William629748/SGE-IndustriadeLicoresdelValle-Univalle.git
cd SGE-IndustriadeLicoresdelValle-Univalle
git checkout app-web
```

### 2. Configurar entorno virtual

```bash
python -m venv venv
source venv/bin/activate   # En Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configurar la Base de Datos

1. Crear una base de datos en PostgreSQL (por ejemplo `ilv_db`).
2. Ejecutar los scripts de la carpeta `db/` en este orden:

```bash
psql -U <usuario> -d ilv_db -f db/01_DDL_tablas.sql
psql -U <usuario> -d ilv_db -f db/02_ALTER_ajustes_pdf.sql
psql -U <usuario> -d ilv_db -f db/Bloque1_Datos_Maestros_ILV.sql
psql -U <usuario> -d ilv_db -f db/Bloque2_Compras_De_Insumos_ILV.sql
psql -U <usuario> -d ilv_db -f db/Bloque3_Produccion_Ventas_Documentos_ILV.sql
psql -U <usuario> -d ilv_db -f db/03_Reto_Trigger_InventarioCompras.sql
psql -U <usuario> -d ilv_db -f db/04_Reto_Indices.sql
psql -U <usuario> -d ilv_db -f db/05_Reto_Vistas.sql
```

### 4. Configurar variables de entorno

Copiar `.env.example` a `.env` y completar con los datos de tu base local:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ilv_db
DB_USER=tu_usuario
DB_PASSWORD=tu_password
SECRET_KEY=una-clave-secreta-cualquiera
```

### 5. Ejecutar la aplicación

```bash
python app.py
```

La aplicación quedará disponible en `http://127.0.0.1:5000`.

> Nota: para usuarios de Windows, la rama `app-web` incluye además la guía `EJECUTAR_EN_WINDOWS.md` con el mismo procedimiento paso a paso.

## 📄 Notas de Entrega y Funcionalidades

- **Módulos de negocio:** clientes, proveedores, insumos, inventario de insumos, categorías, productos, inventario de producto, producción, compras, ventas y facturas, cada uno como un Blueprint independiente de Flask.
- **Retos de base de datos:** la carpeta `db/` incluye un trigger sobre inventario/compras (03), índices (04) y vistas (05), aplicados sobre el modelo base.
- **Consultas:** el archivo `db/Consultas_ILV.sql` agrupa las consultas de análisis solicitadas para la entrega (clientes, ventas, distribución, etc.).
- **Conexión a datos:** la app usa psycopg2 directamente (sin ORM), con la cadena de conexión configurada por variables de entorno en `db.py`.
- Juan Fernando Marmolejo (2437661)
