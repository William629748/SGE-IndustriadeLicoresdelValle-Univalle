CREATE TABLE Proveedor (
	id_proveedor VARCHAR(10) PRIMARY KEY,
	nit VARCHAR(20),
	razon_social VARCHAR(150),
	telefono VARCHAR(15),
	celular VARCHAR(15),
	contacto_nombre VARCHAR(100),
	email VARCHAR(100),
	tipo_proveedor VARCHAR(50),
	condiciones_pago INTEGER,
	calificacion INTEGER,
	activo BOOLEAN,
	fecha_registro TIMESTAMP,
	direccion VARCHAR(200),
	ciudad VARCHAR(100)
);

CREATE TABLE Insumo (
	id_insumo VARCHAR(10) PRIMARY KEY,
	codigo_insumo VARCHAR(50),
	nombre VARCHAR(150),
	descripcion TEXT,
	unidad_medida VARCHAR(20),
	tipo_insumo VARCHAR(50),
	activo BOOLEAN,	
);

CREATE TABLE CompraInsumo (
	id_compra VARCHAR(10) PRIMARY KEY,
	numero_orden VARCHAR(50),
	fecha_compra TIMESTAMP,
	id_proveedor VARCHAR(10) REFERENCES Proveedor(id_proveedor),
	subtotal NUMERIC(14,2),
	iva NUMERIC(14,2),
	total NUMERIC(14,2) GENERATED ALWAYS AS (subtotal+iva) STORED,
	estado VARCHAR(20),
	fecha_recepcion TIMESTAMP,
	id_empleado_recibe VARCHAR(10) REFERENCES Empleado(id_empleado)
);

CREATE TABLE DetalleCompraInsumo(
	id_detalle_compra VARCHAR(10) PRIMARY KEY,
	id_compra VARCHAR(10) REFERENCES CompraInsumo(id_compra),
	id_insumo VARCHAR(10) REFERENCES Insumo(id_insumo),
	cantidad NUMERIC(12,2),
	precio_unitario NUMERIC(12,2),
	subtotal_linea(14,2) GENERATED ALWAYS AS (cantidad*precio_unitario) STORED
);

CREATE TABLE InventarioInsumo(
	id_inventario_insumo VARCHAR(10) PRIMARY KEY,
	id_insumo VARCHAR(10) REFERENCES Insumo(id_insumo),
	cantidad_disponible NUMERIC(12,2),
	stock_minimo NUMERIC(12,2),
	stock_maximo NUMERIC(12,2),
	ubicacion_bodega VARCHAR(100),
	fecha_actualizacion TIMESTAMP
);

CREATE TABLE ConsumoInsumo (
	id_consumo VARCHAR(10) PRIMARY KEY,
	id_lote VARCHAR(10) REFERENCES Lote(id_lote),
	id_insumo VARCHAR(10) REFERENCES Insumo (id_insumo),
	cantidad_consumida NUMERIC(12,2),
	fecha_consmo TIMESTAMP,
	id_empleado VARCHAR(10) REFERENCES Empleado(id_empleado)

);