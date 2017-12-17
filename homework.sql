conn chinook/p4ssw0rd

/*2.1 SELECT*/
SELECT * FROM EMPLOYEE;
SELECT * FROM EMPLOYEE WHERE LASTNAME='King';
SELECT * FROM EMPLOYEE WHERE FIRSTNAME='Andrew' AND REPORTSTO IS NULL;


/*2.2 ORDER BY*/
SELECT * FROM ALBUM ORDER BY TITLE DESC;
SELECT FIRSTNAME FROM CUSTOMER ORDER BY CITY ASC;


/*2.3 INSERT INTO*/
INSERT INTO GENRE (GENREID, NAME) VALUES (26, 'Electroswing');
INSERT INTO GENRE VALUES (27, 'House');

INSERT INTO EMPLOYEE (EMPLOYEEID, LASTNAME, FIRSTNAME, TITLE, EMAIL)  VALUES (9, 'Duck', 'Daffy', 'Mascot', 'daffy@chinookcorp.com');
INSERT INTO EMPLOYEE (EMPLOYEEID, LASTNAME, FIRSTNAME, EMAIL) VALUES (10, 'Cena', 'John', 'john@chinookcorp.com');

INSERT ALL
    INTO CUSTOMER (CUSTOMERID, FIRSTNAME, LASTNAME, EMAIL, SUPPORTREPID) VALUES (60, 'Ronald', 'McDonald', 'ronald@mcdonald', 4)
    INTO CUSTOMER (CUSTOMERID, FIRSTNAME, LASTNAME, EMAIL) VALUES (61, 'Bob', 'Doe', 'bobdoe@ordinaryman.com')
SELECT * FROM DUAL;


/*2.4 UPDATE*/
UPDATE CUSTOMER
SET FIRSTNAME='Robert', LASTNAME='Walter'
WHERE FIRSTNAME='Aaron' AND LASTNAME='Mitchell';

UPDATE ARTIST
SET NAME='CCR'
WHERE NAME='Creedence Clearwater Revival';


/*2.5 LIKE*/
SELECT * FROM INVOICE WHERE BILLINGADDRESS LIKE 'T%';


/*2.6 BETWEEN */
SELECT * FROM INVOICE WHERE TOTAL > 15 AND TOTAL < 50;
SELECT * FROM EMPLOYEE WHERE HIREDATE > '01-JUN-03' AND HIREDATE < '01-MAR-04';


/*2.7 DELETE */
DELETE FROM INVOICELINE WHERE INVOICEID IN
    (SELECT INVOICEID FROM INVOICE WHERE CUSTOMERID IN 
        (SELECT CUSTOMERID FROM CUSTOMER WHERE FIRSTNAME='Robert' AND LASTNAME='Walter'));
DELETE FROM INVOICE WHERE CUSTOMERID IN
    (SELECT CUSTOMERID FROM CUSTOMER WHERE FIRSTNAME='Robert' AND LASTNAME='Walter');
DELETE FROM CUSTOMER WHERE FIRSTNAME='Robert' AND LASTNAME='Walter';


/*3.1 SQL Functions*/
CREATE OR REPLACE FUNCTION GET_CURRENT_TIME
    RETURN TIMESTAMP
    IS CUR_DAY TIMESTAMP;
    BEGIN
        SELECT LOCALTIMESTAMP
        INTO CUR_DAY
        FROM DUAL;
        RETURN CUR_DAY;
    END GET_CURRENT_TIME;
/

DECLARE
    CUR TIMESTAMP;
BEGIN
    CUR := GET_CURRENT_TIME;
    DBMS_OUTPUT.PUT_LINE('Current time is ' || CUR);
END;
/

/*3.1b*/
CREATE OR REPLACE FUNCTION FETCH_MEDIA_NAME(REQ_ID IN NUMBER)
    RETURN VARCHAR2
    IS MEDIA_NAME MEDIATYPE.NAME%TYPE;
    BEGIN
        SELECT NAME INTO MEDIA_NAME
        FROM MEDIATYPE WHERE MEDIATYPEID = REQ_ID;
        RETURN MEDIA_NAME;
    END FETCH_MEDIA_NAME;
/

CREATE OR REPLACE FUNCTION MEDIATYPE_LENGTH(REQ_ID IN NUMBER)
    RETURN NUMBER
    AS LEN NUMBER;
    BEGIN
        SELECT LENGTH(FETCH_MEDIA_NAME(REQ_ID)) INTO LEN
        FROM DUAL;
        RETURN LEN;
    END MEDIATYPE_LENGTH;
/


/*3.2 System Defined Aggregate Function*/
CREATE OR REPLACE FUNCTION AVERAGE_TOTAL_OF_INVOICES
    RETURN NUMBER
    AS AVERAGE NUMBER;
    BEGIN
        SELECT AVG(TOTAL) INTO AVERAGE
        FROM INVOICE;
        RETURN AVERAGE;
    END AVERAGE_TOTAL_OF_INVOICES;
/

DECLARE
    RES NUMBER;
BEGIN
    RES := AVERAGE_TOTAL_OF_INVOICES;
    DBMS_OUTPUT.PUT_LINE(RES);
END;
/

/*3.2b*/
CREATE OR REPLACE FUNCTION MOST_EXPENSIVE
    RETURN VARCHAR2
    AS NAMES VARCHAR2(200);
    BEGIN
        SELECT NAME INTO NAMES
        FROM TRACK WHERE rownum = 1 AND UNITPRICE IN
            (SELECT MAX(UNITPRICE) FROM TRACK);
        RETURN NAMES;
    END MOST_EXPENSIVE;
/


/*3.3 User Defined Functions*/
CREATE OR REPLACE FUNCTION AVERAGE_INVOICELINE_ITEM_PRICE
    RETURN NUMBER
    AS AVERAGE NUMBER;
    TOTAL NUMBER := 0;
    CUR NUMBER;
    CNT NUMBER := 0;
    CURSOR S IS
        SELECT UNITPRICE FROM INVOICELINE;
    BEGIN
        OPEN S;
        LOOP
            FETCH S INTO CUR;
            TOTAL := TOTAL + CUR;
            CNT := CNT + 1;
            EXIT WHEN S%NOTFOUND;
        END LOOP;
        CLOSE S;
        AVERAGE := TOTAL / CNT;
        RETURN AVERAGE;
    END AVERAGE_INVOICELINE_ITEM_PRICE;
/

DECLARE
    RES NUMBER;
BEGIN
    RES := AVERAGE_INVOICELINE_ITEM_PRICE();
    DBMS_OUTPUT.PUT_LINE('AVERAGE PRICE OF INVOICELINE ITEMS IS: ' || RES);
END;
/


/*3.4 User Defined Table Valued Functions*/
CREATE OR REPLACE TYPE EMPLOYEE_OBJ IS OBJECT 
    (EID NUMBER, FNAME VARCHAR2(20), LNAME VARCHAR2(20));
/

CREATE OR REPLACE TYPE EMPLOYEE_SET AS TABLE OF EMPLOYEE_OBJ;
/

CREATE OR REPLACE FUNCTION EMPLOYEE_BORN_AFTER_1968
    RETURN EMPLOYEE_SET
    IS ESET EMPLOYEE_SET := EMPLOYEE_SET(null);
    CURSOR S IS
        SELECT EMPLOYEEID, FIRSTNAME, LASTNAME
        FROM EMPLOYEE E
        WHERE EXTRACT(YEAR FROM E.BIRTHDATE) > 1968;
    EOBJ EMPLOYEE_OBJ := EMPLOYEE_OBJ(null, null, null);
    CNT NUMBER := 0;
BEGIN
    OPEN S;
    LOOP
        FETCH S INTO EOBJ.EID, EOBJ.FNAME, EOBJ.LNAME;
        CNT := CNT + 1;
        ESET.EXTEND;
        ESET(CNT):= EMPLOYEE_OBJ(EOBJ.EID, EOBJ.FNAME, EOBJ.LNAME);
        EXIT WHEN S%NOTFOUND;
    END LOOP;
    CLOSE S;
    RETURN ESET;
END EMPLOYEE_BORN_AFTER_1968;
/

DECLARE
    EE EMPLOYEE_SET := EMPLOYEE_SET(null);
BEGIN
    EE := EMPLOYEE_BORN_AFTER_1968;
    
    FOR I IN 1 .. EE.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Employee ' ||
                             EE(I).FNAME || ' ' || 
                             EE(I).LNAME || ' with ID:' ||
                             EE(I).EID);
    END LOOP;
END;
/


/*4.1 Basic Stored Procedure*/
CREATE OR REPLACE PROCEDURE FIRST_AND_LAST
IS
    CURSOR S IS SELECT FIRSTNAME, LASTNAME FROM EMPLOYEE;
    F_NAME EMPLOYEE.FIRSTNAME%TYPE;
    L_NAME EMPLOYEE.LASTNAME%TYPE;
BEGIN
    OPEN S;
    LOOP
        FETCH S INTO F_NAME, L_NAME;
        DBMS_OUTPUT.PUT_LINE('EMPLOYEE NAME: ' || F_NAME || ' ' || L_NAME);
        EXIT WHEN S%NOTFOUND;
    END LOOP;
    CLOSE S;
END FIRST_AND_LAST;
/

BEGIN
    FIRST_AND_LAST;
END;
/


/*4.2 Stored Procedure Input Parameters*/
CREATE OR REPLACE PROCEDURE 
UPDATE_EMPLOYEE (EID IN EMPLOYEE.EMPLOYEEID%TYPE,
                 UE IN OUT EMPLOYEE%ROWTYPE)
IS
    ERES EMPLOYEE%ROWTYPE;
BEGIN
    SELECT * INTO ERES
    FROM EMPLOYEE
    WHERE EMPLOYEE.EMPLOYEEID = EID;
    
    IF UE.LASTNAME IS NULL 
        THEN UE.LASTNAME := ERES.LASTNAME;
    END IF;
    
    IF UE.FIRSTNAME IS NULL 
        THEN UE.FIRSTNAME := ERES.FIRSTNAME;
    END IF;
    
    UPDATE EMPLOYEE E
    SET E.LASTNAME = UE.LASTNAME,
        E.FIRSTNAME = UE.FIRSTNAME,
        E.TITLE = UE.TITLE,
        E.BIRTHDATE = UE.BIRTHDATE,
        E.HIREDATE = UE.HIREDATE,
        E.ADDRESS = UE.ADDRESS,
        E.CITY = UE.CITY,
        E.STATE = UE.STATE,
        E.COUNTRY = UE.COUNTRY,
        E.POSTALCODE = UE.POSTALCODE,
        E.PHONE = UE.PHONE,
        E.FAX = UE.FAX,
        E.EMAIL = UE.EMAIL
    WHERE E.EMPLOYEEID = EID;
        
    DBMS_OUTPUT.PUT_LINE('Updated ' || EID);
END UPDATE_EMPLOYEE;
/

DECLARE
    CUR_EMP EMPLOYEE%ROWTYPE;
BEGIN
    SELECT * INTO CUR_EMP
    FROM EMPLOYEE
    WHERE EMPLOYEE.EMPLOYEEID = 4;
    
    CUR_EMP.LASTNAME := 'Parker';
    UPDATE_EMPLOYEE(4, CUR_EMP);
END;
/

/*4.2b*/
CREATE OR REPLACE PROCEDURE MANAGERS_OF_EMPLOYEES
IS
    CURSOR S IS 
        SELECT E1.FIRSTNAME, E2.LASTNAME 
        FROM EMPLOYEE E1 INNER JOIN EMPLOYEE E2 
        ON E1.EMPLOYEEID = E2.REPORTSTO;
    FNAME EMPLOYEE.FIRSTNAME%TYPE;
    LNAME EMPLOYEE.LASTNAME%TYPE;
BEGIN
    OPEN S;
    LOOP
        FETCH S INTO FNAME, LNAME;
        DBMS_OUTPUT.PUT_LINE('MANAGER NAME: ' || FNAME || ' ' || LNAME);
        EXIT WHEN S%NOTFOUND;
    END LOOP;
    CLOSE S;
END MANAGERS_OF_EMPLOYEES;
/

BEGIN
    MANAGERS_OF_EMPLOYEES;
END;
/


/*4.3 Stored Procedure Output Parameters*/
CREATE OR REPLACE PROCEDURE COMPANY_NAME
IS
    CURSOR S IS
        SELECT FIRSTNAME, LASTNAME, COMPANY
        FROM CUSTOMER;
    
    FNAME CUSTOMER.FIRSTNAME%TYPE;
    LNAME CUSTOMER.LASTNAME%TYPE;
    CMPY CUSTOMER.COMPANY%TYPE;
BEGIN
    OPEN S;
    LOOP
        FETCH S INTO FNAME, LNAME, CMPY;
        EXIT WHEN S%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(FNAME || ', ' || LNAME || ' at ' || CMPY);
    END LOOP;
    CLOSE S;
END COMPANY_NAME;
/

BEGIN
    COMPANY_NAME;
END;
/


/*5.0 Transactions*/
CREATE OR REPLACE PROCEDURE DELETE_INVOICE 
    (REQ_ID IN INVOICE.INVOICEID%TYPE)
IS
BEGIN
    DELETE FROM INVOICELINE WHERE INVOICEID = REQ_ID;
    DELETE FROM INVOICE WHERE INVOICEID = REQ_ID;
    COMMIT;
END DELETE_INVOICE;
/

BEGIN
    DELETE_INVOICE(10);
END;
/

/*5.0b*/
CREATE OR REPLACE PROCEDURE INSERT_CUSTOMER
    (NEW_CUSTOMER IN CUSTOMER%ROWTYPE)
IS
BEGIN
    INSERT INTO CUSTOMER VALUES NEW_CUSTOMER;
    COMMIT;
END INSERT_CUSTOMER;
/

DECLARE
    ADD_ONE CUSTOMER%ROWTYPE;
    CURSOR S IS 
        SELECT * FROM CUSTOMER ORDER BY CUSTOMERID DESC;
BEGIN
    OPEN S;
    LOOP
        FETCH S INTO ADD_ONE;
        EXIT;
    END LOOP;
    CLOSE S;
    
    ADD_ONE.CUSTOMERID := ADD_ONE.CUSTOMERID + 1;
    INSERT_CUSTOMER(ADD_ONE);
    DBMS_OUTPUT.PUT_LINE('ADDED CUSTOMER WITH ID OF: ' || ADD_ONE.CUSTOMERID);
END;
/


/*6.1 Triggers*/
CREATE OR REPLACE TRIGGER TR_EMPLOYEE_INSERT 
AFTER INSERT
ON EMPLOYEE
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('After Insert');
END TR_EMPLOYEE_INSERT;
/

DECLARE
    EMP EMPLOYEE%ROWTYPE;
BEGIN
    SELECT * INTO EMP FROM
    (SELECT * FROM EMPLOYEE ORDER BY EMPLOYEEID DESC)
    WHERE rownum = 1;
    
    EMP.EMPLOYEEID := EMP.EMPLOYEEID + 1;
    
    INSERT INTO EMPLOYEE VALUES emp;
END;
/


/*6.1b*/
CREATE OR REPLACE TRIGGER TR_ALBUM_UPDATE
AFTER UPDATE ON ALBUM
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('After Update');
END TR_ALBUM_UPDATE;
/

BEGIN
    UPDATE ALBUM
    SET ALBUM.TITLE = 'Balls to the Wall Redux'
    WHERE ALBUM.ALBUMID = 2;
END;
/


/*6.1c*/
CREATE OR REPLACE TRIGGER TR_CUSTOMER_DELETE
AFTER DELETE ON CUSTOMER
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('After Delete');
END TR_CUSTOMER_DELETE;
/

DECLARE
    ADD_ONE CUSTOMER%ROWTYPE;
    CURSOR S IS SELECT * FROM CUSTOMER ORDER BY CUSTOMERID DESC;
BEGIN
    OPEN S;
    FETCH S INTO ADD_ONE;
    CLOSE S;
    
    ADD_ONE.CUSTOMERID := ADD_ONE.CUSTOMERID + 1;
    INSERT_CUSTOMER(ADD_ONE);
    
    DELETE FROM CUSTOMER WHERE CUSTOMER.CUSTOMERID = ADD_ONE.CUSTOMERID;
END;
/


/*7.1 Inner*/
SELECT C.FIRSTNAME, C.LASTNAME, I.INVOICEID
FROM CUSTOMER C
INNER JOIN INVOICE I
ON C.CUSTOMERID = I.CUSTOMERID;


/*7.2 Outer*/
SELECT C.CUSTOMERID, C.FIRSTNAME, C.LASTNAME, I.INVOICEID, I.TOTAL
FROM CUSTOMER C
LEFT OUTER JOIN INVOICE I ON C.CUSTOMERID = I.CUSTOMERID;


/*7.3 Right*/
SELECT ARTIST.NAME, ALBUM.TITLE
FROM ALBUM
RIGHT OUTER JOIN ARTIST ON ALBUM.ARTISTID = ARTIST.ARTISTID;


/*7.4 Cross*/
SELECT *
FROM ALBUM
CROSS JOIN ARTIST
ORDER BY ARTIST.NAME ASC;


/*7.5 Self*/
SELECT *
FROM EMPLOYEE E1
INNER JOIN EMPLOYEE E2
ON E1.REPORTSTO = E2.REPORTSTO;


/*7.6 Complicated Join assignment*/
SELECT * FROM ALBUM AL
INNER JOIN ARTIST AR
    ON AL.ARTISTID = AR.ARTISTID
INNER JOIN TRACK T
    ON T.ALBUMID = AL.ALBUMID
INNER JOIN PLAYLISTTRACK PT
    ON PT.TRACKID = T.TRACKID
INNER JOIN PLAYLIST PL
    ON PL.PLAYLISTID = PT.PLAYLISTID
INNER JOIN MEDIATYPE MT
    ON MT.MEDIATYPEID = T.MEDIATYPEID
INNER JOIN GENRE G
    ON G.GENREID = T.GENREID
INNER JOIN INVOICELINE IL
    ON IL.TRACKID = T.TRACKID
INNER JOIN INVOICE I
    ON I.INVOICEID = IL.INVOICEID
INNER JOIN CUSTOMER C
    ON C.CUSTOMERID = I.CUSTOMERID
INNER JOIN EMPLOYEE E
    ON C.SUPPORTREPID = E.EMPLOYEEID;

exit;