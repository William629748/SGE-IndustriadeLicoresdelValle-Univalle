SELECT
    nombreRazonSocial,
    telefono,
    correo
FROM ClienteEmpresa

INNER JOIN Ciudad
ON ClienteEmpresa.idCiudad=Ciudad.idCiudad

WHERE Ciudad.idCiudad='CIU001';

SELECT
    Ciudad.nombre,
    COUNT(*) clientes
FROM ClienteEmpresa
INNER JOIN Ciudad
ON ClienteEmpresa.idCiudad=Ciudad.idCiudad
GROUP BY Ciudad.nombre
HAVING COUNT(*) > 2;