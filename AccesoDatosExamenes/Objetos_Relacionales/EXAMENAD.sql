--- COMIENZO CREAR TABLAS ---
CREATE OR REPLACE TYPE TALUMNO AS OBJECT(
  aCodAlu NUMBER,
  aNombre VARCHAR(50),
  aGrupo VARCHAR(10)
);

CREATE OR REPLACE TABLE ALUMNOS OF TALUMNO(aCodAlu PRIMARY KEY);

CREATE OR REPLACE TYPE TPRESTAMO AS OBJECT(
  pCodAlu REF TALUMNO,
  pFecha DATE,
  pDevuelto VARCHAR(1)
);

CREATE OR REPLACE TYPE PRESTAMOS AS TABLE OF TPRESTAMO;

CREATE OR REPLACE TYPE TLIBRO AS OBJECT(
  ISBN NUMBER,
  lNombre VARCHAR(100),
  lEjemplares NUMBER,
  lPrestamos PRESTAMOS,
  MEMBER FUNCTION Get_Ejemplares RETURN NUMBER,
  MEMBER PROCEDURE Get_Datos
);

CREATE OR REPLACE TYPE BODY TLIBRO AS
  MEMBER FUNCTION Get_Ejemplares RETURN NUMBER
  IS
    total NUMBER;
    xPrestamo TPRESTAMO;
  BEGIN
    total := lEjemplares;
    FOR i IN 1..lPrestamos.COUNT LOOP
      IF(lPrestamos(i).pDevuelto='N')THEN
        total := total - 1;
      END IF;
    END LOOP;
    RETURN total;
  END;
  
  MEMBER PROCEDURE Get_Datos
  IS
    alumno TALUMNO;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ISBN..' || ISBN || ' Nombre..' || lNombre || ' Ejemplares..' || lEjemplares);
    DBMS_OUTPUT.PUT_LINE('Prestamos no devueltos:');
    FOR i IN 1..lPrestamos.COUNT LOOP
      IF(lPrestamos(i).pDevuelto='N')THEN
        SELECT DEREF(lPrestamos(i).pCodAlu) INTO alumno FROM DUAL;
        DBMS_OUTPUT.PUT_LINE('Codigo_Alumno..' || alumno.aCodAlu || ' Nombre..' || alumno.aNombre || ' Grupo..' || alumno.aGrupo || ' Fecha_Prestamo..' || lPrestamos(i).pFecha);
      END IF;
    END LOOP;
  END;
END;

CREATE TABLE LIBROS OF TLIBRO(ISBN PRIMARY KEY)
NESTED TABLE lPrestamos STORE AS PRESTAMOS_AUX;

--- FIN CREAR TABLAS ---

--- COMIENZO PROCEDIMIENTO ---

CREATE OR REPLACE PROCEDURE SP_PRESTAMOS(codAlu ALUMNOS.aCodAlu%type) AS
  CURSOR cLib IS SELECT VALUE(a) FROM LIBROS a;
  xLib TLIBRO;
  alu TALUMNO;
BEGIN
  OPEN cLib;
  FETCH cLib INTO xLib;
    LOOP
      EXIT WHEN cLib%NOTFOUND;
      FOR i IN 1..xLib.lPrestamos.COUNT LOOP
        SELECT DEREF(xLib.lPrestamos(i).pCodAlu) INTO alu FROM DUAL;
        IF(alu.aCodAlu = codAlu) THEN
          DBMS_OUTPUT.PUT_LINE('ISBN..' || xLib.ISBN || ', Nombre_Libro..' || xLib.lNombre || ', Fecha_Prestamo..' || xLib.lPrestamos(i).pFecha || ', Devuelto.. ' || xLib.lPrestamos(i).pDevuelto);
        END IF;
      END LOOP;
      FETCH cLib INTO xLib;
    END LOOP;
  CLOSE cLib;
END;

--- FIN PROCEDIMIENTO ---

--- COMIENZO INSERT DE DATOS ---

--- ALUMNOS ---
INSERT INTO ALUMNOS VALUES(1, 'David', '2DAM');
INSERT INTO ALUMNOS VALUES(2, 'Armando', '2DAM');
INSERT INTO ALUMNOS VALUES(3, 'Iñigo', '1DAM');

--- LIBROS ---
INSERT INTO LIBROS VALUES(1, 'Narnia', 2, PRESTAMOS(
    TPRESTAMO((SELECT REF(A) FROM ALUMNOS A WHERE aCodAlu = '1') , SYSDATE, 'S'),
    TPRESTAMO((SELECT REF(A) FROM ALUMNOS A WHERE aCodAlu = '2') , SYSDATE, 'N')
  )
);
INSERT INTO LIBROS VALUES(2, 'La bruja piruja', 3, PRESTAMOS());
INSERT INTO LIBROS VALUES(3, 'Programacion: Acceso a datos', 1, PRESTAMOS(
    TPRESTAMO((SELECT REF(A) FROM ALUMNOS A WHERE aCodAlu = '3') , SYSDATE, 'N')
  )
);
--- FIN INSERT DE DATOS ---

--- COMIENZO PROBAR SP_PRESTAMOS Y METODOS ---

SET SERVEROUTPUT ON;
DECLARE
BEGIN
  SP_PRESTAMOS(1);
  SP_PRESTAMOS(3);
END;

SET SERVEROUTPUT ON;
DECLARE
  libro TLIBRO;
BEGIN
  SELECT VALUE(l) INTO libro FROM LIBROS l WHERE ISBN=1;
  DBMS_OUTPUT.PUT_LINE('Get_Ejemplares..' || libro.Get_Ejemplares);
  libro.Get_Datos;
END;
  

--- FIN PROBAR SP_PRESTAMOS Y METODOS ---

--- COMIENZO ACTUALIZAR PRESTAMO ---

UPDATE THE (
  SELECT L.lPrestamos FROM LIBROS L WHERE ISBN = 3
)
SET pDevuelto = 'N'
WHERE pCodAlu = (SELECT REF(A) FROM ALUMNOS A WHERE A.aCodAlu = 3);
  
SET SERVEROUTPUT ON;
DECLARE
  libro TLIBRO;
BEGIN
  SELECT VALUE(l) INTO libro FROM LIBROS l WHERE ISBN=3;
  SP_PRESTAMOS(3);
  DBMS_OUTPUT.PUT_LINE('Get_Ejemplares..' || libro.Get_Ejemplares);
  libro.Get_Datos;
END;
  
--- FIN ACTUALIZAR PRESTAMO ---

--- COMIENZO MOSTRAR TODOS LOS LIBROS ---
SET SERVEROUTPUT ON;
DECLARE
  CURSOR cLib IS SELECT VALUE(l) FROM LIBROS l;
  xLib TLIBRO;
BEGIN
  DBMS_OUTPUT.PUT_LINE('ISBN..........' || ' Nombre.........' || ' Ejemplares_Disponibles');
  OPEN cLib;
  FETCH cLib INTO xLib;
    LOOP
      EXIT WHEN cLib%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(xLib.ISBN || '........' || xLib.lNombre || '........' || xLib.Get_Ejemplares);
      FETCH cLib INTO xLib;
    END LOOP;
  CLOSE cLib;
END;
--- FIN MOSTRAR TODOS LOS LIBROS ---

