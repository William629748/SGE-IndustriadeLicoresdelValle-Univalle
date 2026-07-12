import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        cursor_factory=RealDictCursor
    )


def mensaje_error_amigable(error):
    """Traduce errores de PostgreSQL a mensajes legibles para el usuario final,
    en vez de mostrar el traceback técnico de psycopg2."""
    if isinstance(error, psycopg2.errors.UniqueViolation):
        return "Ya existe un registro con ese mismo valor único (código, NIT, nombre, etc.)."
    if isinstance(error, psycopg2.errors.NumericValueOutOfRange):
        return "Uno de los valores numéricos ingresados es demasiado grande para ese campo."
    if isinstance(error, psycopg2.errors.CheckViolation):
        return "Uno de los valores no cumple una regla de negocio (ej. rango o formato permitido)."
    if isinstance(error, psycopg2.errors.ForeignKeyViolation):
        return "El registro relacionado (proveedor, categoría, ciudad, etc.) no existe o no es válido."
    if isinstance(error, psycopg2.errors.NotNullViolation):
        return "Falta un campo obligatorio."
    return "Ocurrió un error al guardar los datos. Verifica la información e intenta de nuevo."