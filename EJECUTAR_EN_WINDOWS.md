# Guia para ejecutar el proyecto en Windows

Sistema de Gestion Empresarial - Industria de Licores del Valle (Flask + PostgreSQL).
Sigue estos pasos en orden. Copia y pega cada comando en **PowerShell** o **CMD**.

---

## 1. Requisitos previos (instalar una sola vez)

1. **Python 3.11 o superior** -> https://www.python.org/downloads/
   - IMPORTANTE: en el instalador marca la casilla **"Add Python to PATH"**.
2. **PostgreSQL 15 o superior** -> https://www.postgresql.org/download/windows/
   - Durante la instalacion anota la contrasena del usuario `postgres`.
   - Deja el puerto por defecto: **5432**.
3. **Git** -> https://git-scm.com/download/win

Verifica que quedaron instalados (cierra y abre la terminal despues de instalar):

    python --version
    psql --version
    git --version

---

## 2. Descargar el proyecto

    git clone <URL-DEL-REPOSITORIO>
    cd SGE-IndustriadeLicoresdelValle-Univalle

Si te pasan el proyecto en un .zip, descomprimelo y entra a la carpeta con `cd`.

---

## 3. Crear el entorno virtual e instalar dependencias

    python -m venv venv
    venv\Scripts\activate
    pip install -r requirements.txt

Cuando el entorno esta activo veras `(venv)` al inicio de la linea.
Para desactivarlo mas tarde escribe: `deactivate`

---

## 4. Crear la base de datos

Abre la consola de Postgres (te pedira la contrasena del usuario postgres):

    psql -U postgres

Dentro de psql ejecuta (crea el usuario y la base que usa la app):

    CREATE USER andres_ilv WITH PASSWORD 'ilv2026';
    CREATE DATABASE ilv_db OWNER andres_ilv;
    \q

---

## 5. Cargar las tablas, los datos y los retos

Ejecuta los scripts SQL EN ESTE ORDEN (te pedira la contrasena `ilv2026`):

    psql -U andres_ilv -d ilv_db -f db/01_DDL_tablas.sql
    psql -U andres_ilv -d ilv_db -f db/02_ALTER_ajustes_pdf.sql
    psql -U andres_ilv -d ilv_db -f db/Bloque1_Datos_Maestros_ILV.sql
    psql -U andres_ilv -d ilv_db -f db/Bloque2_Compras_De_Insumos_ILV.sql
    psql -U andres_ilv -d ilv_db -f db/Bloque3_Produccion_Ventas_Documentos_ILV.sql
    psql -U andres_ilv -d ilv_db -f db/03_Reto_Trigger_InventarioCompras.sql
    psql -U andres_ilv -d ilv_db -f db/04_Reto_Indices.sql
    psql -U andres_ilv -d ilv_db -f db/05_Reto_Vistas.sql

---

## 6. Configurar las variables de entorno

Copia el archivo de ejemplo y renombralo a `.env`:

    copy .env.example .env

Abre el `.env` con el Bloc de notas y deja los datos de tu base:

    DB_HOST=localhost
    DB_PORT=5432
    DB_NAME=ilv_db
    DB_USER=andres_ilv
    DB_PASSWORD=ilv2026
    SECRET_KEY=cualquier-texto-aleatorio

(Si usaste otro usuario o contrasena en el paso 4, ponlos aqui.)

---

## 7. Ejecutar la aplicacion

Con el entorno virtual activo `(venv)`:

    python app.py

Veras un mensaje como: `Running on http://127.0.0.1:5000`
Abre esa direccion en el navegador: **http://127.0.0.1:5000**

Para detener el servidor: presiona **Ctrl + C** en la terminal.

---

## Problemas comunes

- **"python no se reconoce como comando"**: no marcaste "Add Python to PATH".
  Reinstala Python marcando esa casilla, o usa `py` en vez de `python`.
- **"psql no se reconoce"**: agrega la carpeta bin de PostgreSQL al PATH,
  por ejemplo: `C:\Program Files\PostgreSQL\16\bin`.
- **Error de conexion a la base de datos**: revisa que el servicio de PostgreSQL
  este corriendo y que el usuario/contrasena del `.env` coincidan con el paso 4.
- **"No module named flask"**: activa el entorno con `venv\Scripts\activate`
  y vuelve a correr `pip install -r requirements.txt`.
