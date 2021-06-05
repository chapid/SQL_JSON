/******************************************************************
******************************************************************/
/**
Como usuario system se crea el directorio donde se guarda el archivo
generado y se otorgan los permisos al usuario repuestos para que pueda
tener permisos de lectura y escritura.
*/
--CREATE OR REPLACE DIRECTORY UTL_DIR_T AS 'C:\Temp';
--GRANT read, write ON DIRECTORY UTL_DIR_T TO repuestos;
--select * from dba_directories where directory_name like 'UTL_%'; 
select directory_name, directory_path from all_directories;

/******************************************************************
******************************************************************/
/**
Crear tabla json_clientes. (En esta tabla se guarda el json generado de la
consulta solicitada).
*/
CREATE TABLE json_clientes(
 id NUMBER NOT NULL PRIMARY KEY,
 info CLOB CONSTRAINT is_json CHECK (info IS JSON ))

/******************************************************************
******************************************************************/
/***
Se desarrolla un procedimiento para crear el json con los datos de la
consulta solicitada.
*/
CREATE OR REPLACE PROCEDURE p_registrar_res_clientes
is
begin
    INSERT INTO json_clientes
    VALUES (1, (SELECT JSON_OBJECT (
    KEY 'departamentos' VALUE(
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
            KEY 'nombre_departamento' VALUE dep.nombre,
            KEY 'no_departamento' VALUE dep.id,
            KEY 'municipios' VALUE (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                    KEY 'no_municipio' VALUE mun.id, 
                    KEY 'municipio' VALUE mun.nombre,
                    KEY 'clientes' VALUE (
                        SELECT JSON_ARRAYAGG(
                            JSON_OBJECT(
                            KEY 'codigo' value cl.nit,
                            KEY 'nombre' value cl.nombre,
                            KEY 'monto_credito' value cl.monto_credito
                            )
                        )FROM clientes cl
                         where cl.lugar = mun.id
                        )
                    )
                )
                FROM lugares mun
                WHERE mun.ubicado = dep.id
                ) 
             )
        )
        FROM lugares dep
        where dep.tipo_lugar = 'D'
    )
)
FROM dual));
end p_registrar_res_clientes;

/******************************************************************
******************************************************************/
/***
Se llama al procedimiento desde un bloque anónimo, para guardar el json
en la tabla json_clientes.
*/
begin
p_registrar_res_clientes;
end;

/******************************************************************
******************************************************************/
/***
bloque anónimo que se encarga de consultar la tabla
json_clientes y cargar un archivo plano con el json generado en el
procedimiento p_registrar_res_clientes.
*/
DECLARE
v_res_clientes clob;
v_archivo UTL_FILE.FILE_TYPE;
BEGIN
SELECT INFO
INTO v_res_clientes
FROM json_clientes;
v_archivo:= UTL_FILE.FOPEN('UTL_DIR_T','info_clientes.json','W');
utl_file.put_line(v_archivo,v_res_clientes);
utl_file.fclose(v_archivo);
DBMS_OUTPUT.PUT_LINE(v_res_clientes);
END;

/******************************************************************
******************************************************************/

SELECT CL.nit,CL.nombre,CL.monto_credito,mun.nombre MUNICIPIO,dep.nombre DEPARTAMENTO
FROM clientes CL, lugares dep,lugares mun
WHERE mun.ubicado = dep.ID
AND mun.ID = CL.lugar
ORDER BY dep.nombre;



/******************************************************************
******************************************************************/
/**
codigo inicial
*/
SELECT JSON_OBJECT (
    KEY 'departamentos' VALUE(
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
            KEY 'nombre_departamento' VALUE dep.nombre,
            KEY 'no_departamento' VALUE dep.id,
            KEY 'municipios' VALUE (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                    KEY 'no_municipio' VALUE mun.id, 
                    KEY 'municipio' VALUE mun.nombre,
                    KEY 'clientes' VALUE (
                        SELECT JSON_ARRAYAGG(
                            JSON_OBJECT(
                            KEY 'codigo' value cl.nit,
                            KEY 'nombre' value cl.nombre,
                            KEY 'monto_credito' value cl.monto_credito
                            )
                        )FROM clientes cl
                         where cl.lugar = mun.id
                        )
                    )
                )
                FROM lugares mun
                WHERE mun.ubicado = dep.id
                ) 
             )
        )
        FROM lugares dep
        where dep.tipo_lugar = 'D'
    )
)
FROM dual;