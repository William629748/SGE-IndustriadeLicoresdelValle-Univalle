\# 📓 Bitácora de Uso de IA - Proyecto ILV



\*\*Grupo:\*\* 01



\*\*Empresa:\*\* Industria de Licores del Valle (ILV)



\*\*Fecha:\*\* 13 de julio de 2026



\## 1. Fase de Diseño Conceptual: Definición de Entidades del MER



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "hola, necesito crear una representación conceptual de alto nivel de los datos del negocio de ILV, identificando las entidades principales y cómo se relacionan entre sí. algunas fuentes del negocio son: \[sitio web y redes sociales de ILV]. Ahora bien, estaba pensando en las entidades y necesito que me digas si las que pensé están bien y si consideras que faltan agréguelas: Sede, Cliente, Productor, Producto, InventarioProducto, Proveedor, CompraInsumo, Insumo, InventarioInsumo, ConsumoInsumo, Maquinaria, Venta, DetalleVenta, PuntoDeVenta, ControlCalidad, Envio."



\- \*\*Resultado de la IA:\*\* La IA validó la lista propuesta como una buena base, pero señaló observaciones puntuales: sugirió aclarar si "Productor" se refería a un empleado interno de producción (recomendando renombrarla `Empleado` u `OperarioProduccion`) y confirmó que `PuntoDeVenta` sí aplicaba como entidad distinta de `Sede`. Propuso agregar seis entidades adicionales no contempladas: `Distribuidor` (canal mayorista/minorista propio del modelo de negocio de ILV), `LoteProduccion` (trazabilidad por lote), `Empleado`, `TipoLicor/CategoriaProducto`, `Contrato` y `Patrocinio`. También indicó que, dado que ILV tiene instalaciones industriales específicas y no oficinas genéricas, la entidad debía llamarse `Destileria` en vez de `Sede`.



\- \*\*Ajuste Manual / Validación:\*\* Se aceptaron las seis entidades sugeridas y el cambio de nombre de `Sede` a `Destileria`, consolidando la lista final de 20 entidades usada en el Diagrama MER del Avance 1 (`Destileria`, `Empleado`, `Cliente`, `Distribuidor`, `Producto`, `CategoriaProducto`, `InventarioProducto`, `LoteProduccion`, `Proveedor`, `Insumo`, `CompraInsumo`, `InventarioInsumo`, `ConsumoInsumo`, `Maquinaria`, `ControlCalidad`, `Venta`, `DetalleVenta`, `PuntoDeVenta`, `Envio`, `Contrato`, `Patrocinio`).



\## 2. Fase de Implementación: Generación de Datos Sintéticos con Sesgos Estadísticos (Avance 3)



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\* Se entregó el DDL completo de PostgreSQL y se solicitó generar la carga de datos en 3 bloques de PL/pgSQL idempotentes (borrado propio antes de insertar), respetando todas las FK y CHECK del esquema, sin tocar columnas `GENERATED` (`total` en `CompraInsumo`, `subtotalLinea` en `DetalleCompraInsumo`), y garantizando sesgos intencionales de negocio: los aguardientes como productos más vendidos (regla 80/20), estacionalidad real de ventas (diciembre con 3 veces más ventas que febrero), y mayor volumen de compras de insumos en octubre-noviembre previo a temporada alta. Se especificó el volumen exacto por tabla (Bloque 1: datos maestros; Bloque 2: 30 compras y 60 detalles; Bloque 3: 80 lotes de producción, 200 consumos de insumo, 300 ventas y 600 detalles de venta, cumpliendo el mínimo de 1.000 registros de transacciones exigido por el PDF).



\- \*\*Resultado de la IA:\*\* Se entregaron los 3 scripts SQL solicitados. El Bloque 1 con INSERT directos de datos maestros coherentes con el mercado colombiano (departamentos y ciudades con códigos DANE reales, cargos con salarios de mercado, productos con grados alcohólicos y precios realistas). El Bloque 2 con las 30 compras concentradas en oct-nov y sus 60 detalles, sin incluir las columnas generadas. El Bloque 3 con los 80 lotes de producción (más grandes en oct/nov/dic/jun), \~240 consumos de insumo, 300 ventas con la estacionalidad pedida (84 en diciembre frente a 10 en febrero) y 600 detalles de venta con el 70% concentrado en los productos más populares, además de un `SELECT COUNT(\*)` final por tabla para verificar el volumen cargado.



\- \*\*Ajuste Manual / Validación:\*\* Se ejecutaron los tres bloques en orden en la base de datos real del proyecto y se verificaron los conteos finales antes de dar por cerrada la carga de datos.



\## 3. Fase de Normalización: Justificación de 3FN — Módulo de Ventas y Distribución



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "Hola, necesito que de este pdf, observes solo la parte de: Distribuidor, PuntoDeVenta, Venta, DetalleVenta, Factura, Envio, para realizar este punto del avance 3: Reglas de Normalización: Aplicación del proceso de normalización, explicando y justificando por qué el diseño alcanza al menos la Tercera Forma Normal (3NF)."



\- \*\*Resultado de la IA:\*\* Se entregó el análisis progresivo 1FN → 2FN → 3FN de las seis tablas del módulo. En 1FN se confirmó que todos los atributos son atómicos y cada tabla tiene PK definida. En 2FN se señaló que, al ser todas las PK simples (no compuestas), la dependencia parcial es imposible por construcción. En 3FN se revisó tabla por tabla en busca de dependencias transitivas, identificando como punto crítico que `total` en `Venta` y `Factura` podría verse como derivado de `subTotal + iva`, justificando su almacenamiento explícito por el contexto de facturación electrónica DIAN (valor documentado e inmutable que puede incluir redondeos o retenciones), y que `precio\_unitario` en `DetalleVenta` se congela en el momento de la transacción en vez de heredarse en tiempo real de `Producto.precio\_base`, eliminando así una posible dependencia transitiva.



\- \*\*Ajuste Manual / Validación:\*\* Se incorporó este análisis, con la tabla resumen de cumplimiento de 1FN/2FN/3FN, directamente en la sección de "Reglas de Normalización" del reporte del Avance 3, dejando explícita la aclaración de que el diseño no alcanza BCNF en sentido estricto por los campos calculados, pero que esto es una decisión de diseño válida y reconocida en sistemas contables.



\## 4. Fase de Depuración: Diagnóstico de Consulta sin Resultados (Tabla Envío vacía)



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\* Se reportó que, al ejecutar las 10 consultas SQL de validación en la propia máquina, la Consulta 10 (que hace `INNER JOIN` entre `Factura`, `Venta`, `ClienteEmpresa`, `Envio` y `Ciudad`) no devolvía filas, mientras que a un compañero de equipo sí le funcionaba correctamente con las mismas consultas.



\- \*\*Resultado de la IA:\*\* Se determinó, antes de tocar la consulta, que el problema era de datos y no de SQL: la consulta ejecuta correctamente pero la tabla `Envio` estaba vacía o sin coincidencias en esa instancia local. Se propusieron consultas de diagnóstico (`SELECT COUNT(\*) FROM Envio/Factura/Venta`) para confirmarlo. Al compartir los archivos de carga de datos (`Bloque1`, `Bloque2`, `Bloque3` y el DDL), se identificó la causa raíz exacta en la línea `'CIU00' || (1 + (envio\_count % 9))::TEXT` del Bloque 3: la expresión generaba IDs de ciudad hasta `CIU009`, pero si en esa base de datos solo existían 8 ciudades cargadas, el módulo `% 9` producía un ID de ciudad inexistente, la FK fallaba y el bloque `DO $$` completo abortaba de forma silenciosa, dejando `Envio` sin registros.



\- \*\*Ajuste Manual / Validación:\*\* Se verificó con `SELECT COUNT(\*) FROM Ciudad;` la cantidad real de ciudades cargadas en la instancia local antes de aplicar cualquier corrección, confirmando la discrepancia frente a las 9 esperadas por el script, para luego ajustar el operador módulo del Bloque 3 al número real de ciudades y volver a cargar los datos de envíos correctamente.



\## 5. Fase de Validación: Normalización de Consultas SQL y Almacenamiento de Precios



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "Hola, quiero saber si está consulta se encuentra correctamente normalizada:

&#x20; > --Consulta 4

&#x20; > SELECT Insumo.nombre, Insumo.unidadMedida, SUM(DetalleCompraInsumo.cantidad) AS cantidadTotalComprada, SUM(DetalleCompraInsumo.subtotalLinea) AS valorTotalComprado FROM Insumo INNER JOIN DetalleCompraInsumo ON Insumo.idInsumo = DetalleCompraInsumo.idInsumo GROUP BY Insumo.nombre, Insumo.unidadMedida ORDER BY cantidadTotalComprada DESC;

&#x20; > --Consulta 5

&#x20; > SELECT Insumo.nombre, Insumo.tipoInsumo, InventarioInsumo.cantidadDisponible, InventarioInsumo.stockMinimo, InventarioInsumo.stockMaximo, InventarioInsumo.ubicacionBodega FROM Insumo INNER JOIN InventarioInsumo ON Insumo.idInsumo=InventarioInsumo.idInsumo WHERE InventarioInsumo.cantidadDisponible < InventarioInsumo.stockMinimo ORDER BY InventarioInsumo.cantidadDisponible ASC;

&#x20; > --Consulta 6

&#x20; > SELECT ClienteEmpresa.nombreRazonSocial, COUNT(Venta.idVenta) AS totalVentas, SUM(Venta.total) AS valorTotalComprado FROM ClienteEmpresa INNER JOIN Venta ON ClienteEmpresa.idCliente = Venta.idCliente GROUP BY ClienteEmpresa.nombreRazonSocial ORDER BY valorTotalComprado DESC;

&#x20; >

&#x20; > Había una duda que tenía, es la forma en la que almacené los precios para evitar redundancias, que opinas? viola la FN?"



\- \*\*Resultado de la IA:\*\* La IA separó el análisis en dos planos: las consultas en sí y el diseño de las tablas de precios. Confirmó que las Consultas 4, 5 y 6 están bien construidas (JOIN correctos, GROUP BY completo, alias claros) y que un SELECT de lectura no normaliza ni desnormaliza nada. Sobre el diseño, indicó que guardar `precioUnitario` en `DetalleCompraInsumo` (en vez de solo referenciar `Insumo`) \*\*no viola la FN\*\* — es lo correcto, porque el precio pagado en una compra es un hecho histórico de esa transacción y no del insumo como entidad. En cambio, señaló que `subtotalLinea` como columna calculada (`cantidad \* precioUnitario`) sí es un atributo derivado y una redundancia funcional, aunque no una violación clásica de 1FN/2FN/3FN, y que es aceptable si se documenta como una desnormalización intencional por rendimiento en reportes.



\- \*\*Ajuste Manual / Validación:\*\* Se tomó esta distinción para redactar la sección de "Reglas de Normalización" del Avance 3, dejando explícito que `subtotalLinea` (y de forma análoga `subtotalProducto` en `DetalleVenta`) es una desnormalización intencional para evitar recalcular el subtotal en cada consulta de reportes, y no un error de diseño que rompa la 3FN. Se mantuvo `precioUnitario` como el dato histórico de la transacción, sin modificarlo, para no perder la trazabilidad de precios pasados.



\## 6. Fase de Arquitectura: Auditoría Inicial y Plan de Trabajo Full Stack (Flask + PostgreSQL)



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "Quiero que actúes como un desarrollador Senior Full Stack especializado en Python, Flask, PostgreSQL, SQLAlchemy, HTML, CSS, Bootstrap, JavaScript y Ubuntu Linux. NO quiero que hagas el proyecto completo de una vez, quiero que seas mi mentor y me guíes paso a paso \[...] Cuando analices el proyecto, primero responde únicamente con: 1. Resumen del proyecto, 2. Tecnologías recomendadas, 3. Arquitectura, 4. Lista de módulos, 5. Plan de trabajo completo. No escribas código todavía \[...] Analiza TODO el proyecto antes de responder. Quiero que leas: el PDF, todos los archivos SQL, todo el código Python, HTML, CSS, JavaScript, README, estructura de carpetas. Haz una auditoría completa. Después dime: qué está terminado, qué falta, qué errores tiene, qué módulos cumplen el PDF, qué módulos faltan, qué debo programar primero, y dame un porcentaje de avance del proyecto."



\- \*\*Resultado de la IA:\*\* Se revisó el repositorio completo (DDL, bloques de datos sintéticos, consultas, diagrama y README), confirmando mediante una búsqueda de archivos que aún no existía ningún archivo de código de aplicación (`.py`, `.html`, `.css`, `.js`). Se identificaron campos obligatorios faltantes en el esquema frente al PDF y se estimó un avance global de 30-35%, dejando claro que antes de escribir la app web había que corregir el esquema de base de datos. Se propuso además el stack definitivo: Flask organizado en Blueprints por módulo, con SQL parametrizado vía `psycopg2` en lugar de un ORM, para mantener control directo sobre cada consulta.



\- \*\*Ajuste Manual / Validación:\*\* El autor usó esta auditoría como base para decidir primero el ajuste de esquema (documentado en la Fase 3 de esta bitácora) antes de escribir cualquier línea de la aplicación web, y confirmó el stack Flask + Blueprints + psycopg2 (sin ORM) como la arquitectura definitiva del proyecto.



\## 7. Fase de Configuración: Entorno de Desarrollo y Conexión a PostgreSQL



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "si porfa y tambien clonar el repositorio vamos a hacer esto rapido tengo solo 3 horas vamos a darle"



\- \*\*Resultado de la IA:\*\* Se guio la instalación de PostgreSQL 16 y pgAdmin4, la creación de un usuario y una base de datos dedicados para la aplicación (en vez de usar el superusuario `postgres` directamente), la creación de un entorno virtual de Python (`venv`) y la instalación de `flask`, `psycopg2-binary` y `python-dotenv` como dependencias base de la conexión Flask–PostgreSQL, generando `requirements.txt` para que el resto del equipo replicara el mismo entorno.



\- \*\*Ajuste Manual / Validación:\*\* El autor ejecutó cada comando en su propia máquina y confirmó la salida real en cada paso (creación de usuario y base de datos, conexión de prueba con `psql`) antes de continuar, sin que la IA asumiera que algo había funcionado sin verificación explícita.



\## 8. Fase de Frontend: Patrón de Módulos (Blueprints) y Primer CRUD Conectado a la BD



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "Aquí está el enunciado completo del proyecto de Bases de Datos y el código que ya tenemos del sistema de gestión de Industria de Licores del Valle. Revisa a fondo el DDL y los módulos ya construidos (Clientes, Proveedores, Insumos) y dime, según lo que exige el PDF de la profesora, cuál debería ser el siguiente módulo lógico a construir. No avances todavía, solo dame tu recomendación y por qué, para decidir juntos."



\- \*\*Resultado de la IA:\*\* Se recomendó construir el módulo de Inventario de Insumos como siguiente paso lógico, replicando el mismo patrón ya usado para los módulos anteriores: un Blueprint de Flask por módulo, una función `generar\_siguiente\_id()` para los identificadores, consultas parametrizadas con `psycopg2` hacia PostgreSQL, y templates HTML reutilizando el mismo estilo visual ya definido para el resto de la aplicación.



\- \*\*Ajuste Manual / Validación:\*\* Se aprobó el patrón propuesto y se mantuvo como estándar para todos los módulos posteriores del frontend (Categorías, Productos, Producción, Compras y Ventas), verificando en cada caso que el cálculo de estado de inventario no se almacenara en la base de datos, sino que se recalculara en cada consulta.



\## 9. Fase de Depuración: Registro de Blueprints en Flask (errores 404 / BuildError)



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\*

&#x20; > "Ya activé el entorno virtual y corrí la app, pero cuando entro a /inventario/ me sale 404 Not Found y no carga nada. No adivines la causa: pídeme el log completo de la terminal y el contenido de los archivos que consideres necesarios antes de proponer una solución."



\- \*\*Resultado de la IA:\*\* Se solicitó el log completo de la terminal y el contenido de `app.py` y `templates/base.html` antes de proponer cualquier solución. Se identificó que el Blueprint del módulo nunca se había registrado con `app.register\_blueprint()` en `app.py`, ni se había agregado el enlace correspondiente en el menú lateral — el archivo del Blueprint en sí ya estaba completo, el problema era exclusivamente de conexión entre el módulo y la aplicación principal de Flask, no de código roto. El mismo tipo de error (`BuildError` por `url\_for` apuntando a un endpoint no registrado) se repitió más adelante con otros módulos y se diagnosticó de la misma manera: revisando primero si el Blueprint estaba importado y registrado en `app.py` antes de suponer un error de nombres.



\- \*\*Ajuste Manual / Validación:\*\* Se agregaron manualmente las líneas faltantes de `import` y `register\_blueprint()` en `app.py`, junto con el enlace en el sidebar, verificando el archivo antes de volver a probar en el navegador. Esta lección se aplicó de forma preventiva en los módulos siguientes, revisando siempre que cada `url\_for()` usado en un template correspondiera a una ruta ya registrada.



\## 10. Fase de Frontend: Formularios de Ventas Conectados al Backend (selector de canal, precios no editables y cierre transaccional)



\- \*\*Herramienta utilizada:\*\* Claude (Anthropic)



\- \*\*Prompt:\*\* Continuación del desarrollo del módulo de Ventas y Facturas, aportando el contenido de `app.py` para que la IA conociera el patrón exacto de registro de Blueprints ya usado en los módulos anteriores, y confirmando avanzar con la propuesta de construirlo en 3 pasos (cabecera, líneas de producto, cierre de venta).



\- \*\*Resultado de la IA:\*\* Se revisaron primero los prefijos reales de ID de los datos ya cargados y la restricción `CHECK` de la tabla `Venta` (que exige un canal de venta por Punto de Venta o por Distribuidor, nunca ambos ni ninguno). En el frontend se resolvió con un único campo de selección de "Canal de venta" que combina ambas opciones, separándolas en el servidor antes de insertar en la base de datos, en vez de exponer dos campos independientes que el usuario pudiera diligenciar mal. Se decidió también que el precio unitario de cada línea se tomara automáticamente del precio base del producto en el servidor, sin mostrarlo como campo editable en el formulario, para impedir que el precio de venta se manipulara desde el navegador. El botón de "Completar venta" se conectó a una función transaccional que descuenta stock, genera la Factura y, si aplica, el Envío, dentro de una misma transacción con reversa completa ante cualquier fallo.



\- \*\*Ajuste Manual / Validación:\*\* El autor aprobó el diseño del selector combinado de canal y la decisión de precio no editable, y probó cada paso del formulario en el navegador (creación de la venta, adición de líneas, cierre con generación de factura) antes de dar el módulo por terminado, confirmando que el frontend quedara correctamente conectado end-to-end con la base de datos PostgreSQL a través de Flask.



\### Recordatorios:



1\. \*\*Honestidad Técnica:\*\* No se penaliza el uso de IA, se penaliza la falta de documentación o la falta de comprensión de lo que la IA generó.



2\. \*\*Ubicación:\*\* Guardar este archivo como \*\*DOC\_IA.md\*\* en la raíz del repositorio de GitHub.



3\. \*\*Sustentación:\*\* Durante la muestra final, el profesor podrá preguntar sobre cualquier ajuste manual registrado en esta bitácora.

