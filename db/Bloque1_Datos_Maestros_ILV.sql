-- ============================================================
-- BLOQUE 1: DATOS MAESTROS - ILV
-- Ejecutar primero. Incluye DELETE para ser idempotente.
-- ============================================================

-- Limpiar en orden inverso de FK
DELETE FROM Envio;
DELETE FROM Factura;
DELETE FROM DetalleVenta;
DELETE FROM Venta;
DELETE FROM ConsumoInsumo;
DELETE FROM LoteProduccion;
DELETE FROM DetalleCompraInsumo;
DELETE FROM CompraInsumo;
DELETE FROM InventarioInsumo;
DELETE FROM inventarioProducto;
DELETE FROM Contrato;
DELETE FROM PuntoDeVenta;
DELETE FROM Distribuidor;
DELETE FROM ClienteEmpresa;
DELETE FROM Proveedor;
DELETE FROM Empleado;
DELETE FROM Producto;
DELETE FROM Insumo;
DELETE FROM CategoriaProducto;
DELETE FROM Cargo;
DELETE FROM Ciudad;
DELETE FROM Departamento;
DELETE FROM Pais;

-- ============================================================
-- PAIS
-- ============================================================
INSERT INTO Pais (idPais, nombre, codigoIso) VALUES
('PAIS001', 'Colombia', 'COL');

-- ============================================================
-- DEPARTAMENTO
-- ============================================================
INSERT INTO Departamento (idDepartamento, nombre, codigoDANE, idPais) VALUES
('DEP001', 'Valle del Cauca',  '76', 'PAIS001'),
('DEP002', 'Antioquia',        '05', 'PAIS001'),
('DEP003', 'Cundinamarca',     '25', 'PAIS001'),
('DEP004', 'Atlántico',        '08', 'PAIS001'),
('DEP005', 'Santander',        '68', 'PAIS001');

-- ============================================================
-- CIUDAD
-- ============================================================
INSERT INTO Ciudad (idCiudad, nombre, codigoDANE, idDepartamento) VALUES
('CIU001', 'Cali',           '76001', 'DEP001'),
('CIU002', 'Buenaventura',   '76109', 'DEP001'),
('CIU003', 'Medellín',       '05001', 'DEP002'),
('CIU004', 'Bello',          '05088', 'DEP002'),
('CIU005', 'Bogotá',         '11001', 'DEP003'),
('CIU006', 'Soacha',         '25754', 'DEP003'),
('CIU007', 'Barranquilla',   '08001', 'DEP004'),
('CIU008', 'Soledad',        '08634', 'DEP004'),
('CIU009', 'Bucaramanga',    '68001', 'DEP005'),
('CIU010', 'Floridablanca',  '68276', 'DEP005');

-- ============================================================
-- CARGO
-- ============================================================
INSERT INTO Cargo (idCargo, nombreCargo, descripcion, nivel, salarioBase, area, activo) VALUES
('CAR001', 'Director de Producción',    'Dirige el proceso productivo de la destilería',            5, 8500000.00,  'Producción',     TRUE),
('CAR002', 'Jefe de Calidad',           'Supervisa los estándares de calidad del producto',         4, 6200000.00,  'Producción',     TRUE),
('CAR003', 'Operario de Destilación',   'Opera los equipos de destilación y mezcla',                2, 2100000.00,  'Producción',     TRUE),
('CAR004', 'Gerente Comercial',         'Lidera la estrategia de ventas y distribución',            5, 9000000.00,  'Ventas',         TRUE),
('CAR005', 'Asesor Comercial',          'Gestiona clientes y pedidos comerciales',                  2, 2500000.00,  'Ventas',         TRUE),
('CAR006', 'Coordinador Logístico',     'Coordina despachos, envíos y transporte',                  3, 3800000.00,  'Logística',      TRUE),
('CAR007', 'Auxiliar de Bodega',        'Maneja inventario físico y despachos',                     1, 1800000.00,  'Logística',      TRUE),
('CAR008', 'Analista Administrativo',   'Gestiona procesos contables y administrativos',            3, 3200000.00,  'Administración', TRUE);

-- ============================================================
-- CATEGORIA PRODUCTO
-- ============================================================
INSERT INTO CategoriaProducto (idCategoria, nombreCategoria, descripcion) VALUES
('CAT001', 'Aguardiente', 'Licores anisados tradicionales colombianos'),
('CAT002', 'Ron',         'Rones elaborados con caña de azúcar'),
('CAT003', 'Vodka',       'Vodkas destilados de alta pureza'),
('CAT004', 'Whisky',      'Whiskys importados y nacionales'),
('CAT005', 'Cremas',      'Licores cremosos y de frutas');

-- ============================================================
-- INSUMO
-- ============================================================
INSERT INTO Insumo (idInsumo, codigoInsumo, nombre, descripcion, unidadMedida, tipoInsumo, activo) VALUES
('INS001', 'INS-AE-001',  'Alcohol Etílico Rectificado',  'Alcohol de alta pureza para destilación',           'Litros',    'Materia Prima',  TRUE),
('INS002', 'INS-AT-002',  'Agua Tratada Desmineralizada', 'Agua purificada para mezcla de licores',            'Litros',    'Materia Prima',  TRUE),
('INS003', 'INS-AZ-003',  'Azúcar Refinada',              'Azúcar blanca para endulzado de licores',           'Kg',        'Materia Prima',  TRUE),
('INS004', 'INS-AN-004',  'Esencia de Anís',              'Extracto natural de anís para aguardiente',         'Litros',    'Materia Prima',  TRUE),
('INS005', 'INS-CA-005',  'Caramelo Natural',             'Colorante caramelo para ron y cremas',              'Kg',        'Materia Prima',  TRUE),
('INS006', 'INS-ME-006',  'Melaza de Caña',               'Subproducto de caña para fermentación de ron',      'Kg',        'Materia Prima',  TRUE),
('INS007', 'INS-LE-007',  'Levadura Industrial',          'Levadura para proceso de fermentación',             'Kg',        'Materia Prima',  TRUE),
('INS008', 'INS-BT-008',  'Botella Vidrio 750ml',         'Envase de vidrio estándar 750ml',                   'Unidades',  'Envases',        TRUE),
('INS009', 'INS-BT-009',  'Botella Vidrio 375ml',         'Envase de vidrio media botella 375ml',              'Unidades',  'Envases',        TRUE),
('INS010', 'INS-TP-010',  'Tapa Rosca Metálica',          'Tapa de cierre para botellas estándar',             'Unidades',  'Envases',        TRUE),
('INS011', 'INS-TP-011',  'Corcho Sintético',             'Tapón sintético para productos premium',            'Unidades',  'Envases',        TRUE),
('INS012', 'INS-ET-012',  'Etiqueta Frontal Aguardiente', 'Etiqueta impresa para línea aguardiente',           'Unidades',  'Etiquetas',      TRUE),
('INS013', 'INS-ET-013',  'Etiqueta Frontal Ron',         'Etiqueta impresa para línea ron',                   'Unidades',  'Etiquetas',      TRUE),
('INS014', 'INS-CJ-014',  'Caja Cartón x12 Unidades',     'Empaque secundario para 12 botellas',               'Unidades',  'Empaque',        TRUE),
('INS015', 'INS-FL-015',  'Filtro de Carbón Activado',    'Filtro para purificación final del licor',          'Unidades',  'Materia Prima',  TRUE);

-- ============================================================
-- EMPLEADO
-- ============================================================
INSERT INTO Empleado (idEmpleado, tipoDocumento, numeroDocumento, nombres, apellidos, fechaNacimiento, direccion, telefono, celular, correo, fechaIngreso, fechaRetiro, idCargo, activo) VALUES
('EMP001', 'CC', '10123456', 'Carlos Alberto',  'Mosquera Reyes',     '1978-03-15', 'Cra 5 # 12-30 Cali',          '6023456789', '3101234567', 'carlos.mosquera@ilv.com.co',   '2018-02-01', NULL,         'CAR001', TRUE),
('EMP002', 'CC', '20234567', 'Luisa Fernanda',  'Torres Castaño',     '1985-07-22', 'Cl 18 # 4-10 Cali',           '6023456780', '3112345678', 'luisa.torres@ilv.com.co',      '2019-05-15', NULL,         'CAR002', TRUE),
('EMP003', 'CC', '30345678', 'Jhon Fredy',      'Patiño Giraldo',     '1990-11-08', 'Cra 8 # 20-15 Cali',          NULL,         '3123456789', 'jhon.patino@ilv.com.co',       '2020-01-10', NULL,         'CAR003', TRUE),
('EMP004', 'CC', '40456789', 'María Elena',     'Salcedo Muñoz',      '1982-04-30', 'Cl 25 # 8-40 Cali',           '6023456781', '3134567890', 'maria.salcedo@ilv.com.co',     '2018-08-20', NULL,         'CAR003', TRUE),
('EMP005', 'CC', '50567890', 'Andrés Felipe',   'Guerrero López',     '1988-09-14', 'Cra 12 # 35-22 Cali',         NULL,         '3145678901', 'andres.guerrero@ilv.com.co',   '2021-03-01', NULL,         'CAR003', TRUE),
('EMP006', 'CC', '60678901', 'Sandra Milena',   'Herrera Ospina',     '1980-12-05', 'Cl 10 # 2-55 Cali',           '6023456782', '3156789012', 'sandra.herrera@ilv.com.co',    '2017-11-15', NULL,         'CAR004', TRUE),
('EMP007', 'CC', '70789012', 'Ricardo',         'Vargas Quintero',    '1987-06-18', 'Cra 15 # 45-10 Cali',         NULL,         '3167890123', 'ricardo.vargas@ilv.com.co',    '2020-07-01', NULL,         'CAR005', TRUE),
('EMP008', 'CC', '80890123', 'Diana Carolina',  'Ríos Bermúdez',      '1993-02-27', 'Cl 32 # 14-08 Cali',          '6023456783', '3178901234', 'diana.rios@ilv.com.co',        '2021-09-01', NULL,         'CAR005', TRUE),
('EMP009', 'CE', '90901234', 'Valentina',       'Moreno Castro',      '1991-08-11', 'Cra 20 # 6-30 Cali',          NULL,         '3189012345', 'valentina.moreno@ilv.com.co',  '2022-01-15', NULL,         'CAR005', TRUE),
('EMP010', 'CC', '11012345', 'Jorge Iván',      'Sánchez Melo',       '1986-05-23', 'Cl 50 # 22-18 Cali',          '6023456784', '3190123456', 'jorge.sanchez@ilv.com.co',     '2019-10-01', NULL,         'CAR006', TRUE),
('EMP011', 'CC', '12123456', 'Mauricio',        'Pérez Hurtado',      '1984-10-09', 'Cra 3 # 18-44 Cali',          NULL,         '3201234567', 'mauricio.perez@ilv.com.co',    '2018-06-01', NULL,         'CAR006', TRUE),
('EMP012', 'CC', '13234567', 'Paola Andrea',    'Gómez Cardona',      '1992-01-17', 'Cl 7 # 9-25 Cali',            '6023456785', '3212345678', 'paola.gomez@ilv.com.co',       '2022-04-01', NULL,         'CAR007', TRUE),
('EMP013', 'CC', '14345678', 'Luis Miguel',     'Holguín Arango',     '1989-07-04', 'Cra 28 # 11-60 Cali',         NULL,         '3223456789', 'luis.holguin@ilv.com.co',      '2020-11-01', NULL,         'CAR007', TRUE),
('EMP014', 'CC', '15456789', 'Gloria Inés',     'Ospina Valencia',    '1979-03-28', 'Cl 15 # 5-12 Cali',           '6023456786', '3234567890', 'gloria.ospina@ilv.com.co',     '2017-09-01', NULL,         'CAR008', TRUE),
('EMP015', 'CC', '16567890', 'Felipe',          'Castillo Ríos',      '1995-11-30', 'Cra 9 # 42-33 Cali',          NULL,         '3245678901', 'felipe.castillo@ilv.com.co',   '2023-02-01', NULL,         'CAR008', TRUE),
('EMP016', 'CC', '17678901', 'Natalia',         'Arboleda Flórez',    '1994-04-12', 'Cl 38 # 16-20 Cali',          '6023456787', '3256789012', 'natalia.arboleda@ilv.com.co',  '2022-08-15', NULL,         'CAR005', TRUE),
('EMP017', 'CC', '18789012', 'Camilo',          'Rodríguez Leal',     '1990-09-25', 'Cra 6 # 28-07 Cali',          NULL,         '3267890123', 'camilo.rodriguez@ilv.com.co',  '2021-06-01', NULL,         'CAR003', TRUE),
('EMP018', 'CC', '19890123', 'Alejandra',       'Nieto Soto',         '1988-12-14', 'Cl 22 # 10-55 Cali',          '6023456788', '3278901234', 'alejandra.nieto@ilv.com.co',   '2019-03-01', '2022-12-31', 'CAR005', FALSE),
('EMP019', 'CC', '21901234', 'Hernán Darío',    'Betancourt Cruz',    '1983-06-07', 'Cra 18 # 33-44 Cali',         NULL,         '3289012345', 'hernan.betancourt@ilv.com.co', '2018-01-15', '2023-06-30', 'CAR007', FALSE),
('EMP020', 'TI', '22012345', 'Sebastián',       'Montoya Agudelo',    '1999-02-19', 'Cl 44 # 7-18 Cali',           '6023456790', '3290123456', 'sebastian.montoya@ilv.com.co', '2020-09-01', '2021-08-31', 'CAR003', FALSE);

-- ============================================================
-- PRODUCTO
-- ============================================================
INSERT INTO Producto (idProducto, codigoBarras, nombre, descripcion, presentacion, gradoAlcoholico, precioBase, tarifaIva, sysTrace, idCategoria) VALUES
('PRO001', '7702132000010', 'Aguardiente Blanco del Valle 750ml',  'Aguardiente sin azúcar clásico del Valle',       '750ml', 29.00, 17500.00, 19.00, 'ILV2024001AC', 'CAT001'),
('PRO002', '7702132000027', 'Aguardiente Sin Azúcar 750ml',        'Aguardiente light sin azúcar añadida',           '750ml', 29.00, 18200.00, 19.00, 'ILV2024002AC', 'CAT001'),
('PRO003', '7702132000034', 'Aguardiente Blanco del Valle 375ml',  'Presentación media botella aguardiente clásico', '375ml', 29.00,  9500.00, 19.00, 'ILV2024003AC', 'CAT001'),
('PRO004', '7702132000041', 'Ron Dorado 3 Años 750ml',             'Ron añejado 3 años en barrica de roble',         '750ml', 37.50, 32000.00, 19.00, 'ILV2024004RN', 'CAT002'),
('PRO005', '7702132000058', 'Ron Negro Reserva 750ml',             'Ron oscuro con notas de vainilla y caramelo',    '750ml', 40.00, 45000.00, 19.00, 'ILV2024005RN', 'CAT002'),
('PRO006', '7702132000065', 'Ron Blanco Extra 750ml',              'Ron blanco suave para cócteles',                 '750ml', 35.00, 28000.00, 19.00, 'ILV2024006RN', 'CAT002'),
('PRO007', '7702132000072', 'Vodka Puro 750ml',                    'Vodka triple destilado de alta pureza',          '750ml', 37.50, 35000.00, 19.00, 'ILV2024007VK', 'CAT003'),
('PRO008', '7702132000089', 'Vodka Citrus 750ml',                  'Vodka con infusión natural de cítricos',         '750ml', 37.50, 38000.00, 19.00, 'ILV2024008VK', 'CAT003'),
('PRO009', '7702132000096', 'Whisky Single Malt 750ml',            'Whisky de malta premium envejecido 8 años',      '750ml', 43.00, 95000.00, 19.00, 'ILV2024009WK', 'CAT004'),
('PRO010', '7702132000102', 'Whisky Blend Suave 750ml',            'Whisky blend accesible y suave',                 '750ml', 40.00, 62000.00, 19.00, 'ILV2024010WK', 'CAT004'),
('PRO011', '7702132000119', 'Crema de Chocolate 750ml',            'Licor cremoso de chocolate artesanal',           '750ml', 17.00, 28000.00, 19.00, 'ILV2024011CR', 'CAT005'),
('PRO012', '7702132000126', 'Crema de Café 750ml',                 'Licor cremoso con extracto de café colombiano',  '750ml', 17.00, 30000.00, 19.00, 'ILV2024012CR', 'CAT005');

-- ============================================================
-- PROVEEDOR
-- ============================================================
INSERT INTO Proveedor (idProveedor, nit, razonSocial, telefono, celular, contactoNombre, email, tipoProveedor, condicionesPago, calificacion, activo, direccion, idCiudad) VALUES
('PROV001', '800123456-1', 'Alcoholes del Valle S.A.',        '6023001122', '3101000001', 'Pedro Ramírez',    'ventas@alcoholesvalle.com',   'MATERIA_PRIMA', 30, 5, TRUE, 'Zona Industrial # 1-10 Cali',      'CIU001'),
('PROV002', '800234567-2', 'Envases y Vidrios S.A.S.',        '6023002233', '3112000002', 'Ana Gómez',        'pedidos@envasesvidrios.com',  'ENVASES',       45, 4, TRUE, 'Cra 30 # 15-20 Cali',              'CIU001'),
('PROV003', '800345678-3', 'Etiquetas Gráficas Ltda.',        '6044003344', '3123000003', 'Mario Suárez',     'info@etiquetasgraficas.com',  'ETIQUETAS',     30, 4, TRUE, 'Cl 50 # 42-10 Medellín',           'CIU003'),
('PROV004', '800456789-4', 'Azúcares del Cauca S.A.',         '6023004455', '3134000004', 'Claudia Herrera',  'ventas@azucarescauca.com',    'MATERIA_PRIMA', 60, 5, TRUE, 'Autopista Sur Km 5 Cali',          'CIU001'),
('PROV005', '800567890-5', 'Esencias Naturales Colombia',     '6014005566', '3145000005', 'Roberto Díaz',     'info@esenciasnaturales.com',  'MATERIA_PRIMA', 30, 3, TRUE, 'Cl 72 # 10-15 Bogotá',             'CIU005'),
('PROV006', '800678901-6', 'Empaques Industriales S.A.S.',    '6023006677', '3156000006', 'Sofía Martínez',   'ventas@empaquesind.com',      'ENVASES',       45, 4, TRUE, 'Zona Franca Local 22 Cali',        'CIU001'),
('PROV007', '800789012-7', 'Levaduras y Fermentos Ltda.',     '6044007788', '3167000007', 'Héctor Vargas',    'pedidos@levadurasferm.com',   'MATERIA_PRIMA', 30, 4, TRUE, 'Cra 80 # 33-40 Medellín',          'CIU003'),
('PROV008', '800890123-8', 'Servicios de Filtración S.A.',    '6023008899', '3178000008', 'Laura Mendoza',    'info@servifiltracion.com',    'SERVICIOS',     15, 5, TRUE, 'Cra 1 # 70-30 Cali',               'CIU001');

-- ============================================================
-- CLIENTE EMPRESA
-- ============================================================
INSERT INTO ClienteEmpresa (idCliente, tipoDocumento, numeroDocumento, nombreRazonSocial, nit, direccion, idCiudad, telefono, celular, correo, tipoCliente, activo) VALUES
('CLI001', 'NIT', '900111001-1', 'Licores y Distribuciones del Norte S.A.S.', '900111001-1', 'Cl 30 # 15-20 Barranquilla',   'CIU007', '6053001001', '3001001001', 'contacto@licorespnorte.com',   'MAYORISTA',    TRUE),
('CLI002', 'NIT', '900222002-2', 'Grupo Comercial Antioqueño Ltda.',          '900222002-2', 'Cra 70 # 45-10 Medellín',      'CIU003', '6044002002', '3002002002', 'ventas@gcantioqueño.com',      'MAYORISTA',    TRUE),
('CLI003', 'NIT', '900333003-3', 'Supermercados La Economía S.A.',            '900333003-3', 'Cl 10 # 5-30 Cali',            'CIU001', '6023003003', '3003003003', 'pedidos@laeconomia.com',       'MAYORISTA',    TRUE),
('CLI004', 'NIT', '900444004-4', 'Distribuidora Central Bogotá S.A.S.',       '900444004-4', 'Av Eldorado # 68-50 Bogotá',   'CIU005', '6014004004', '3004004004', 'info@distcentralbog.com',      'MAYORISTA',    TRUE),
('CLI005', 'NIT', '900555005-5', 'Licores Finos del Caribe S.A.',             '900555005-5', 'Cra 44 # 72-15 Barranquilla',  'CIU007', '6053005005', '3005005005', 'ventas@licoresfinos.com',      'MAYORISTA',    TRUE),
('CLI006', 'NIT', '900666006-6', 'Comercializadora Santandereana Ltda.',      '900666006-6', 'Cl 35 # 22-10 Bucaramanga',    'CIU009', '6077006006', '3006006006', 'info@comsantand.com',          'MAYORISTA',    TRUE),
('CLI007', 'NIT', '900777007-7', 'Minimarket Express S.A.S.',                 '900777007-7', 'Cra 15 # 80-20 Bogotá',        'CIU005', '6014007007', '3007007007', 'pedidos@minimarketexp.com',    'MINORISTA',    TRUE),
('CLI008', 'NIT', '900888008-8', 'Tienda La Esquina del Valle',               '900888008-8', 'Cl 4 # 8-55 Cali',             'CIU001', '6023008008', '3008008008', 'ventas@laesquinavalle.com',    'MINORISTA',    TRUE),
('CLI009', 'NIT', '900999009-9', 'Bar & Restaurante El Sabor S.A.S.',         '900999009-9', 'Cl 85 # 14-30 Medellín',       'CIU003', '6044009009', '3009009009', 'reservas@elsabormed.com',      'MINORISTA',    TRUE),
('CLI010', 'NIT', '901010010-0', 'Depósito de Licores San Pedro',             '901010010-0', 'Cra 8 # 22-40 Cali',           'CIU001', '6023010010', '3010010010', 'info@depositoranpedro.com',    'MINORISTA',    TRUE),
('CLI011', 'NIT', '901111011-1', 'Club Social y Deportivo Los Andes',         '901111011-1', 'Av 6N # 25-10 Cali',           'CIU001', '6023011011', '3011011011', 'eventos@clublosandes.com',     'MINORISTA',    TRUE),
('CLI012', 'NIT', '901212012-2', 'Hotel Boutique El Colonial S.A.S.',         '901212012-2', 'Cl 9 # 3-40 Cali',             'CIU001', '6023012012', '3012012012', 'compras@hotelcolonial.com',    'MINORISTA',    TRUE),
('CLI013', 'NIT', '901313013-3', 'Licores Premium del Pacífico S.A.S.',       '901313013-3', 'Cl 1 # 10-20 Buenaventura',    'CIU002', '6022013013', '3013013013', 'ventas@licorespacifico.com',   'DISTRIBUIDOR', TRUE),
('CLI014', 'NIT', '901414014-4', 'Distribuciones Cafeteras Ltda.',            '901414014-4', 'Cra 23 # 31-20 Bucaramanga',   'CIU009', '6077014014', '3014014014', 'pedidos@distcafeteras.com',    'DISTRIBUIDOR', TRUE),
('CLI015', 'NIT', '901515015-5', 'Red de Licores Soledad S.A.S.',             '901515015-5', 'Cl 18 # 20-30 Soledad',        'CIU008', '6053015015', '3015015015', 'info@licoressoldad.com',       'MINORISTA',    TRUE);

-- ============================================================
-- DISTRIBUIDOR
-- ============================================================
INSERT INTO Distribuidor (idDistribuidor, nitDistribuidor, razonSocial, telefono, correo, direccion, idCiudad, tipoDistribuidor, estado) VALUES
('DIS001', '830001001-1', 'Gran Distribuidora Nacional S.A.',       '6023100001', 'ventas@grandistnacional.com',   'Zona Industrial Cali Av 3N # 50-10', 'CIU001', 'NACIONAL',  'ACTIVO'),
('DIS002', '830002002-2', 'Distribuciones Bogotá Capital S.A.S.',   '6014200002', 'pedidos@distbogotacap.com',     'Av Boyacá # 12-30 Bogotá',            'CIU005', 'NACIONAL',  'ACTIVO'),
('DIS003', '830003003-3', 'Distribuidora Regional Antioquia Ltda.', '6044300003', 'info@distrantioquia.com',       'Cra 50 # 28-40 Medellín',             'CIU003', 'REGIONAL',  'ACTIVO'),
('DIS004', '830004004-4', 'Distribuciones Costa Caribe S.A.S.',     '6053400004', 'ventas@distcostacaribe.com',    'Cl 17 # 5-30 Barranquilla',           'CIU007', 'REGIONAL',  'ACTIVO'),
('DIS005', '830005005-5', 'Licores y Más Bucaramanga Ltda.',        '6077500005', 'pedidos@licoresymasbuc.com',    'Cra 15 # 40-20 Bucaramanga',          'CIU009', 'LOCAL',     'ACTIVO'),
('DIS006', '830006006-6', 'Distribuidora del Pacífico S.A.S.',      '6022600006', 'info@distpacifico.com',         'Cl 3 # 2-15 Buenaventura',            'CIU002', 'LOCAL',     'ACTIVO');

-- ============================================================
-- PUNTO DE VENTA
-- ============================================================
INSERT INTO PuntoDeVenta (idPuntoVenta, nombreRazonSocial, nit, direccion, idCiudad, telefono, correo, tipoPunto, capacidadAlmacenamiento, estado, idDistribuidor) VALUES
('PDV001', 'ILV Punto Cali Centro',        '900700001-1', 'Cl 12 # 6-40 Cali',             'CIU001', '6023700001', 'calient@ilv.com.co',     'PROPIO',      2000, 'ACTIVO',   NULL),
('PDV002', 'ILV Punto Cali Norte',         '900700002-2', 'Av 6N # 38-10 Cali',            'CIU001', '6023700002', 'calinor@ilv.com.co',     'PROPIO',      2500, 'ACTIVO',   NULL),
('PDV003', 'Franquicia Medellín El Poblado','900700003-3', 'El Poblado Cra 35 # 8-10 Med.', 'CIU003', '6044700003', 'medellin@ilv.com.co',    'FRANQUICIA',  1500, 'ACTIVO',   'DIS003'),
('PDV004', 'Franquicia Bogotá Chapinero',  '900700004-4', 'Cra 13 # 63-40 Bogotá',         'CIU005', '6014700004', 'bogota@ilv.com.co',      'FRANQUICIA',  1800, 'ACTIVO',   'DIS002'),
('PDV005', 'Aliado Barranquilla Centro',   '900700005-5', 'Cl 34 # 43-10 Barranquilla',    'CIU007', '6053700005', 'barranq@ilv.com.co',     'ALIADO',      1000, 'ACTIVO',   'DIS004'),
('PDV006', 'Aliado Bucaramanga',           '900700006-6', 'Cl 56 # 24-30 Bucaramanga',     'CIU009', '6077700006', 'bucara@ilv.com.co',      'ALIADO',       800, 'ACTIVO',   'DIS005'),
('PDV007', 'ILV Punto Buenaventura',       '900700007-7', 'Cl 1 # 3-20 Buenaventura',      'CIU002', '6022700007', 'bvtura@ilv.com.co',      'PROPIO',       600, 'ACTIVO',   NULL),
('PDV008', 'Franquicia Bello Antioquia',   '900700008-8', 'Cra 50 # 30-10 Bello',          'CIU004', '6044700008', 'bello@ilv.com.co',       'FRANQUICIA',  1200, 'ACTIVO',   'DIS003'),
('PDV009', 'Aliado Floridablanca',         '900700009-9', 'Cra 9 # 15-40 Floridablanca',   'CIU010', '6077700009', 'florida@ilv.com.co',     'ALIADO',       500, 'INACTIVO', 'DIS005'),
('PDV010', 'Aliado Soledad Atlántico',     '900700010-0', 'Cl 20 # 18-30 Soledad',         'CIU008', '6053700010', 'soledad@ilv.com.co',     'ALIADO',       700, 'ACTIVO',   'DIS004');

-- ============================================================
-- INVENTARIO INSUMO (1 por insumo)
-- ============================================================
INSERT INTO InventarioInsumo (idInventarioInsumo, idInsumo, cantidadDisponible, stockMinimo, stockMaximo, ubicacionBodega) VALUES
('IINS001', 'INS001', 15000.00, 2000.00, 25000.00, 'BODEGA-A'),
('IINS002', 'INS002', 20000.00, 3000.00, 30000.00, 'BODEGA-A'),
('IINS003', 'INS003',  8000.00, 1000.00, 15000.00, 'BODEGA-A'),
('IINS004', 'INS004',   500.00,   50.00,  1000.00, 'BODEGA-B'),
('IINS005', 'INS005',  1200.00,  200.00,  3000.00, 'BODEGA-B'),
('IINS006', 'INS006', 12000.00, 2000.00, 20000.00, 'BODEGA-A'),
('IINS007', 'INS007',   300.00,   50.00,   800.00, 'BODEGA-B'),
('IINS008', 'INS008', 50000.00, 5000.00, 80000.00, 'BODEGA-C'),
('IINS009', 'INS009', 30000.00, 3000.00, 50000.00, 'BODEGA-C'),
('IINS010', 'INS010', 60000.00, 8000.00, 90000.00, 'BODEGA-C'),
('IINS011', 'INS011', 10000.00, 1000.00, 20000.00, 'BODEGA-C'),
('IINS012', 'INS012', 55000.00, 5000.00, 80000.00, 'BODEGA-C'),
('IINS013', 'INS013', 20000.00, 2000.00, 35000.00, 'BODEGA-C'),
('IINS014', 'INS014', 15000.00, 2000.00, 25000.00, 'BODEGA-C'),
('IINS015', 'INS015',  2000.00,  200.00,  5000.00, 'BODEGA-B');

-- ============================================================
-- INVENTARIO PRODUCTO (1 por producto)
-- ============================================================
INSERT INTO inventarioProducto (idInventarioProducto, idProducto, stockActual, stockMaximo, ubicacionBodega) VALUES
('IPRO001', 'PRO001', 8500.00, 15000.00, 'BODEGA-C'),
('IPRO002', 'PRO002', 7200.00, 12000.00, 'BODEGA-C'),
('IPRO003', 'PRO003', 4000.00,  8000.00, 'BODEGA-C'),
('IPRO004', 'PRO004', 3500.00,  7000.00, 'BODEGA-C'),
('IPRO005', 'PRO005', 1800.00,  4000.00, 'BODEGA-C'),
('IPRO006', 'PRO006', 2200.00,  5000.00, 'BODEGA-C'),
('IPRO007', 'PRO007', 1500.00,  3500.00, 'BODEGA-C'),
('IPRO008', 'PRO008', 1200.00,  3000.00, 'BODEGA-C'),
('IPRO009', 'PRO009',  600.00,  2000.00, 'BODEGA-C'),
('IPRO010', 'PRO010',  900.00,  2500.00, 'BODEGA-C'),
('IPRO011', 'PRO011',  800.00,  2000.00, 'BODEGA-C'),
('IPRO012', 'PRO012',  700.00,  2000.00, 'BODEGA-C');

SELECT 'Pais'               AS tabla, COUNT(*) AS registros FROM Pais
UNION ALL SELECT 'Departamento',  COUNT(*) FROM Departamento
UNION ALL SELECT 'Ciudad',        COUNT(*) FROM Ciudad
UNION ALL SELECT 'Cargo',         COUNT(*) FROM Cargo
UNION ALL SELECT 'CategoriaProducto', COUNT(*) FROM CategoriaProducto
UNION ALL SELECT 'Insumo',        COUNT(*) FROM Insumo
UNION ALL SELECT 'Empleado',      COUNT(*) FROM Empleado
UNION ALL SELECT 'Producto',      COUNT(*) FROM Producto
UNION ALL SELECT 'Proveedor',     COUNT(*) FROM Proveedor
UNION ALL SELECT 'ClienteEmpresa',COUNT(*) FROM ClienteEmpresa
UNION ALL SELECT 'Distribuidor',  COUNT(*) FROM Distribuidor
UNION ALL SELECT 'PuntoDeVenta',  COUNT(*) FROM PuntoDeVenta
UNION ALL SELECT 'InventarioInsumo',   COUNT(*) FROM InventarioInsumo
UNION ALL SELECT 'inventarioProducto', COUNT(*) FROM inventarioProducto;