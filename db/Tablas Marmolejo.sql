CREATE TABLE Proveedor (
	id_proveedor VARCHAR(10) PRIMARY KEY,
	nit VARCHAR(20) NOT NULL UNIQUE,
	razon_social VARCHAR(150) NOT NULL,
	telefono VARCHAR(15),
	celular VARCHAR(15),
	contacto_nombre VARCHAR(100),
	email VARCHAR(100) UNIQUE,
	tipo_proveedor VARCHAR(50),
	condiciones_pago INTEGER,
	calificacion INTEGER CHECK (calificacion BETWEEN 1 AND 5),
	activo BOOLEAN NOT NULL DEFAULT TRUE,
	fecha_registro TIMESTAMP NOT NULL DEFAULT NOW(),
	direccion VARCHAR(200),
	ciudad VARCHAR(100)
);

CREATE TABLE Insumo (
	id_insumo VARCHAR(10) PRIMARY KEY,
	codigo_insumo VARCHAR(50) NOT NULL UNIQUE,
	nombre VARCHAR(150) NOT NULL,
	descripcion TEXT,
	unidad_medida VARCHAR(20) NOT NULL,
	tipo_insumo VARCHAR(50),
	activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE CompraInsumo (
	id_compra VARCHAR(10) PRIMARY KEY,
	numero_orden VARCHAR(50) NOT NULL UNIQUE,
	fecha_compra TIMESTAMP NOT NULL,
	id_proveedor VARCHAR(10) NOT NULL REFERENCES Proveedor(id_proveedor),
	subtotal NUMERIC(14,2) NOT NULL CHECK (subtotal>=0),
	iva NUMERIC(14,2) NOT NULL CHECK (iva>=0),
	total NUMERIC(14,2) GENERATED ALWAYS AS (subtotal+iva) STORED,
	estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
	fecha_recepcion TIMESTAMP,
	id_empleado_recibe VARCHAR(10) REFERENCES Empleado(id_empleado)
);

CREATE TABLE DetalleCompraInsumo(
	id_detalle_compra VARCHAR(10) PRIMARY KEY,
	id_compra VARCHAR(10) NOT NULL REFERENCES CompraInsumo(id_compra),
	id_insumo VARCHAR(10) NOT NULL REFERENCES Insumo(id_insumo),
	cantidad NUMERIC(12,2) NOT NULL CHECK (cantidad>0),
	precio_unitario NUMERIC(12,2) NOT NULL CHECK(precio_unitario >0),
	subtotal_linea NUMERIC(14,2) GENERATED ALWAYS AS (cantidad*precio_unitario) STORED
);

CREATE TABLE InventarioInsumo(
	id_inventario_insumo VARCHAR(10) PRIMARY KEY,
	id_insumo VARCHAR(10) NOT NULL UNIQUE REFERENCES Insumo(id_insumo),
	cantidad_disponible NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (cantidad_disponible>=0),
	stock_minimo NUMERIC(12,2) NOT NULL CHECK (stock_minimo>=0),
	stock_maximo NUMERIC(12,2) NOT NULL,
	ubicacion_bodega VARCHAR(100),
	fecha_actualizacion TIMESTAMP NOT NULL DEFAULT NOW(),
	CONSTRAINT chk_stock CHECK (stock_maximo > stock_minimo)
);

CREATE TABLE ConsumoInsumo (
	id_consumo VARCHAR(10) PRIMARY KEY,
	id_lote VARCHAR(10) NOT NULL REFERENCES Lote(id_lote),
	id_insumo VARCHAR(10) NOT NULL REFERENCES Insumo (id_insumo),
	cantidad_consumida NUMERIC(12,2) NOT NULL CHECK(cantidad_consumida >0),
	fecha_consumo TIMESTAMP NOT NULL,
	id_empleado VARCHAR(10) NOT NULL REFERENCES Empleado(id_empleado)

);