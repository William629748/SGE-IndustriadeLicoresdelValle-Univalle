CREATE TABLE Pais (
	idPais VARCHAR(10) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
	codigoIso VARCHAR(3) UNIQUE --Ej: COL
);
CREATE TABLE Departamento (
	idDepartamento VARCHAR(10) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	codigoDANE VARCHAR(5) NOT NULL,
	idPais VARCHAR(10) NOT NULL,
	CONSTRAINT fk_departamento_pais FOREIGN KEY (idPais) REFERENCES PAIS(idPais)
 );
 CREATE TABLE Ciudad (
	idCiudad VARCHAR(10) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	codigoDANE VARCHAR(5) NOT NULL,
	idDepartamento VARCHAR(10) NOT NULL,
	CONSTRAINT fk_ciudad_departamento FOREIGN KEY (idDepartamento) REFERENCES DEPARTAMENTO(idDepartamento)
 );
 CREATE TABLE Distribuidor (
	idDistribuidor VARCHAR(10) PRIMARY KEY,
	nitDistribuidor VARCHAR(20) NOT NULL UNIQUE,
	razonSocial VARCHAR(150) NOT NULL,
	telefono VARCHAR(15) NOT NULL UNIQUE,
	correo VARCHAR(100) NOT NULL UNIQUE,
	direccion VARCHAR(200) NOT NULL,
	idCiudad VARCHAR(10) NOT NULL, --FK
	tipoDistribuidor VARCHAR(30) NOT NULL,
	estado VARCHAR(100) NOT NULL DEFAULT 'ACTIVO',
	fechaRegistro TIMESTAMP NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_distribuidor_ciudad FOREIGN KEY (idCiudad) REFERENCES Ciudad(idCiudad)
 );
 CREATE TABLE PuntoDeVenta (
	idPuntoVenta VARCHAR(10) PRIMARY KEY,
	nombreRazonSocial VARCHAR(50) NOT NULL UNIQUE,
	nit VARCHAR(30) NOT NULL UNIQUE,
	direccion VARCHAR(200) NOT NULL,
	idCiudad VARCHAR(10) NOT NULL, --FK
	telefono VARCHAR(15) NOT NULL,
	correo VARCHAR(100) NOT NULL UNIQUE,
	tipoPunto VARCHAR(20) NOT NULL,
	capacidadAlmacenamiento INTEGER NOT NULL,
	estado VARCHAR(20) NOT NULL,
	fechaRegistro TIMESTAMP NOT NULL DEFAULT NOW(),
	idDistribuidor VARCHAR(10),
	CONSTRAINT fk_punto_ciudad FOREIGN KEY (idCiudad) REFERENCES Ciudad(idCiudad),
	CONSTRAINT fk_punto_distribuidor FOREIGN KEY (idDistribuidor) REFERENCES Distribuidor(idDistribuidor)
 );
 CREATE TABLE Venta (
	idVenta VARCHAR(10) PRIMARY KEY,
	fechaVenta TIMESTAMP NOT NULL DEFAULT NOW(),
	horaVenta TIME NOT NULL DEFAULT CURRENT_TIME,
	metodoPago VARCHAR(30) NOT NULL,
	subTotal NUMERIC(12,2) NOT NULL,
	iva NUMERIC(12,2) NOT NULL,
	total NUMERIC(12,2) NOT NULL,
	estadoVenta VARCHAR(30) NOT NULL,
	idCliente VARCHAR(10) NOT NULL, --Referencia a ClienteEmpresa
	idPuntoVenta VARCHAR(10),
	idDistribuidor VARCHAR(10),
	idEmpleado VARCHAR(10) NOT NULL, --Vendedor responsable
	CONSTRAINT fk_venta_punto FOREIGN KEY (idPuntoVenta) REFERENCES PuntoDeVenta(idPuntoVenta),
	CONSTRAINT fk_venta_distribuidor FOREIGN KEY (idDistribuidor) REFERENCES Distribuidor(idDistribuidor)
 );
 CREATE TABLE DetalleVenta (
    idDetalleVenta VARCHAR(10) PRIMARY KEY,
    cantidad INTEGER NOT NULL CHECK (cantidad >= 1),
    precioUnitario NUMERIC(12,2) NOT NULL,
    subtotalProducto NUMERIC(12,2) NOT NULL,
    idVenta VARCHAR(10) NOT NULL,
    idProducto VARCHAR(10) NOT NULL, -- Referencia a Producto
    CONSTRAINT fk_detalle_venta FOREIGN KEY (idVenta) REFERENCES Venta(idVenta)
);
CREATE TABLE Factura (
    idFactura VARCHAR(10) PRIMARY KEY,
    numeroFactura VARCHAR(20) NOT NULL UNIQUE,
    fechaFactura TIMESTAMP NOT NULL DEFAULT NOW(),
    subtotal NUMERIC(12,2) NOT NULL,
    iva NUMERIC(12,2) NOT NULL,
    total NUMERIC(12,2) NOT NULL,
    metodoPago VARCHAR(30) NOT NULL,
    estadoFactura VARCHAR(20) NOT NULL DEFAULT 'EMITIDA',
    idVenta VARCHAR(10) NOT NULL UNIQUE, -- Relación 1:1 según esquema
    cufe VARCHAR(100) UNIQUE,
    CONSTRAINT fk_factura_venta FOREIGN KEY (idVenta) REFERENCES Venta(idVenta)
);
CREATE TABLE Envio (
    idEnvio VARCHAR(10) PRIMARY KEY,
    idVenta VARCHAR(10) NOT NULL,
    fechaEnvio TIMESTAMP NOT NULL DEFAULT NOW(),
    direccionEntrega VARCHAR(200) NOT NULL,
    idCiudad VARCHAR(10) NOT NULL, -- FK ciudad de entrega
    fechaEntrega DATE NOT NULL,
    empresaTransportadora VARCHAR(50) NOT NULL,
    guiaTransporte VARCHAR(100) NOT NULL UNIQUE,
    estadoEnvio VARCHAR(20) NOT NULL DEFAULT 'PREPARANDO',
    pagoEfectuado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_envio_venta FOREIGN KEY (idVenta) REFERENCES Venta(idVenta),
    CONSTRAINT fk_envio_ciudad FOREIGN KEY (idCiudad) REFERENCES Ciudad(idCiudad),
    CONSTRAINT fk_fecha_entrega CHECK (fechaEntrega >= CAST(fechaEnvio AS DATE))
);
CREATE TABLE Cargo (
	idCargo VARCHAR(10) PRIMARY KEY,
	nombreCargo VARCHAR(100) NOT NULL UNIQUE,
	descripcion TEXT NULL,
	nivel INTEGER NOT NULL,
	salarioBase NUMERIC(12,2) NOT NULL,
	area VARCHAR(100) NOT NULL,
	activo BOOLEAN NOT NULL DEFAULT TRUE,
	CHECK (nivel >= 1),
	CHECK (SalarioBase > 0)
);
CREATE TABLE Empleado(
	idEmpleado VARCHAR(10) PRIMARY KEY,
	tipoDocumento VARCHAR(3) NOT NULL,
	numeroDocumento VARCHAR(20) NOT NULL UNIQUE,
	nombres VARCHAR(100) NOT NULL,
	apellidos VARCHAR(100) NOT NULL,
	fechaNacimiento DATE NOT NULL,
	direccion VARCHAR(200) NOT NULL,
	telefono VARCHAR(15) NULL,
	celular VARCHAR(15) NOT NULL,
	correo VARCHAR(100) NOT NULL UNIQUE,
	fechaIngreso DATE NOT NULL,
	fechaRetiro DATE NULL,
	idCargo VARCHAR(10) NOT NULL,
	activo BOOLEAN NOT NULL DEFAULT TRUE,
	CONSTRAINT fk_empleado_cargo FOREIGN KEY (idCargo) REFERENCES Cargo(idCargo),
	CHECK(tipoDocumento IN('CC','CE','TI')),
	CHECK (fechaRetiro IS NULL OR fechaRetiro >= fechaIngreso)
);

CREATE TABLE ClienteEmpresa (
	idCliente VARCHAR(10) PRIMARY KEY,
	tipoDocumento VARCHAR(3) NOT NULL,
	numeroDocumento VARCHAR(20) NOT NULL UNIQUE,
	nombreRazonSocial VARCHAR(150) NOT NULL,
	nit VARCHAR(20) NOT NULL UNIQUE,
	direccion VARCHAR(200) NOT NULL,
	idCiudad VARCHAR(10) NOT NULL,
	telefono VARCHAR(15) NULL,
	celular VARCHAR(15) NOT NULL,
	correo VARCHAR(100) NOT NULL UNIQUE,
	tipoCliente VARCHAR(20) NOT NULL,
	fechaRegistro TIMESTAMP NOT NULL DEFAULT NOW(),
	activo BOOLEAN NOT NULL DEFAULT TRUE,
	CONSTRAINT fk_clienteEmpresa_ciudad FOREIGN KEY (idCiudad) REFERENCES ciudad(idCiudad),
	CHECK(tipoDocumento IN('CC','CE','TI')),
	CHECK(tipoCliente IN('MAYORISTA','MINORISTA','DISTRIBUIDOR'))
);
CREATE TABLE Contrato (
	idContrato VARCHAR(10) PRIMARY KEY,
	numeroContrato VARCHAR(50) NOT NULL UNIQUE,
	tipoContrato VARCHAR(30) NOT NULL,
	fechaInicio DATE NOT NULL,
	fechaFin DATE NULL,
	valorContrato NUMERIC(14,2) NULL,
	descripcionObjeto TEXT NULL,
	modalidad TEXT NOT NULL,
	estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
	idEmpleado VARCHAR(10) NULL,
	idDistribuidor VARCHAR(10) NULL,
	idProveedor VARCHAR(10) NULL, --necesita de proveedor
	idPuntoVenta VARCHAR(10) NULL,
	idClienteEmpresa VARCHAR(10) NULL,
	CONSTRAINT fk_contrato_empleado FOREIGN KEY (idEmpleado) REFERENCES Empleado(idEmpleado),
	CONSTRAINT fk_contrato_distribuidor FOREIGN KEY (idDistribuidor) REFERENCES Distribuidor(idDistribuidor),
	CONSTRAINT fk_contrato_puntoventa FOREIGN KEY (idPuntoVenta) REFERENCES PuntoDeVenta(idPuntoVenta),
	CONSTRAINT fk_contrato_clienteempresa FOREIGN KEY (idClienteEmpresa) REFERENCES ClienteEmpresa(idCliente),
	CHECK(tipoContrato IN('EMPLEADO','DISTRIB','PROVEEDOR','PTO_VENTA','CLIENTE_EMPRESA')),
	CHECK (fechaFin IS NULL OR fechaFin > fechaInicio),
	CHECK (estado IN('ACTIVO','TERMINADO','SUSPENDIDO'))
);
