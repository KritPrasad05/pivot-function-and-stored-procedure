/*pivot
*/


CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    product VARCHAR(50),
    amount DECIMAL(10, 2)
);
INSERT INTO sales (sale_id, sale_date, product, amount) VALUES
(1, '2023-01-05', 'Product A', 150.00),
(2, '2023-01-15', 'Product B', 200.00),
(3, '2023-02-03', 'Product A', 100.00),
(4, '2023-02-20', 'Product C', 300.00),
(5, '2023-03-01', 'Product B', 250.00),
(6, '2023-03-15', 'Product A', 180.00),
(7, '2023-04-05', 'Product D', 220.00),
(8, '2023-04-20', 'Product C', 130.00),
(9, '2023-05-10', 'Product B', 160.00),
(10, '2023-05-25', 'Product D', 210.00);

select * 
from sales;

--------------------------------------------------------------------------------------------------

SELECT 
    product,
    SUM(CASE WHEN MONTH(sale_date) = 1 THEN amount ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(sale_date) = 2 THEN amount ELSE 0 END) AS Feb,
	SUM(CASE WHEN MONTH(sale_date) = 3 THEN amount ELSE 0 END) AS mar,
	SUM(CASE WHEN MONTH(sale_date) = 4 THEN amount ELSE 0 END) AS apr,
	SUM(CASE WHEN MONTH(sale_date) = 5 THEN amount ELSE 0 END) AS may
FROM sales
GROUP BY product;

----------------------------------------------------------------------------------------------------------------

SELECT product, 
       SUM(CASE WHEN sale_date BETWEEN '2023-01-01' AND '2023-01-31' THEN amount ELSE 0 END) AS Jan,
       SUM(CASE WHEN sale_date BETWEEN '2023-02-01' AND '2023-02-28' THEN amount ELSE 0 END) AS Feb,
	   SUM(CASE WHEN sale_date BETWEEN '2023-03-01' AND '2023-03-31' THEN amount ELSE 0 END) AS mar,
	   SUM(CASE WHEN sale_date BETWEEN '2023-04-01' AND '2023-04-30' THEN amount ELSE 0 END) AS Apr,
	   SUM(CASE WHEN sale_date BETWEEN '2023-05-01' AND '2023-05-31' THEN amount ELSE 0 END) AS may
FROM sales
GROUP BY product;

----------------------------------------------------------------------------------------------------------------------

SELECT *
FROM (SELECT product, amount, MONTH(sale_date) AS sale_month FROM sales) AS SourceTable
PIVOT (SUM(amount) FOR sale_month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS PivotTable;

--------------------------------------------------------------------------------------------------------------------------

DECLARE @cols AS NVARCHAR(MAX),
        @query AS NVARCHAR(MAX);

SET @cols = STUFF((SELECT DISTINCT ',' + QUOTENAME(MONTH(sale_date)) FROM sales FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

SET @query = 'SELECT product, ' + @cols + ' FROM 
             (SELECT product, amount, MONTH(sale_date) AS sale_month FROM sales) AS SourceTable
             PIVOT (SUM(amount) FOR sale_month IN (' + @cols + ')) AS PivotTable';

EXEC sp_executesql @query;

--------------------------------------------------------------------------------------------------------------------

/*procedure*/


CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    salary DECIMAL(10, 2)
);

INSERT INTO employees (employee_id, first_name, last_name, department_id, salary) VALUES
(1, 'John', 'Doe', 1, 60000.00),
(2, 'Jane', 'Smith', 2, 75000.00),
(3, 'Michael', 'Brown', 1, 80000.00),
(4, 'Emily', 'Davis', 3, 72000.00),
(5, 'David', 'Wilson', 2, 68000.00),
(6, 'Linda', 'Johnson', 3, 85000.00),
(7, 'Robert', 'Jones', 1, 62000.00),
(8, 'Maria', 'Garcia', 2, 77000.00),
(9, 'James', 'Martinez', 3, 64000.00),
(10, 'Patricia', 'Rodriguez', 1, 81000.00);



CREATE PROCEDURE GetEmployeeById1
    @EmployeeId INT
AS
BEGIN
    SELECT * FROM employees WHERE employee_id = @EmployeeId;
END;

EXEC GetEmployeeById1 @EmployeeId = 2;

--------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE GetEmployeesByDepartment
    @DepartmentId INT
AS
BEGIN
    SELECT * FROM employees WHERE department_id = @DepartmentId;
END;


EXEC GetEmployeesByDepartment @DepartmentId = 2;

---------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE GetEmployeeSalary
    @EmployeeId INT,
    @Salary DECIMAL(10, 2) OUTPUT
AS
BEGIN
    SELECT @Salary = salary FROM employees WHERE employee_id = @EmployeeId;
END;

DECLARE @EmpSalary DECIMAL(10, 2);
EXEC GetEmployeeSalary @EmployeeId = 1, @Salary = @EmpSalary OUTPUT;
SELECT @EmpSalary AS EmployeeSalary;

---------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE GetEmployeesBySalary
    @MinSalary DECIMAL(10, 2) = 0,
    @MaxSalary DECIMAL(10, 2) = 1000000
AS
BEGIN
    SELECT * FROM employees WHERE salary BETWEEN @MinSalary AND @MaxSalary;
END;

exec GetEmployeesBySalary;

EXEC GetEmployeesBySalary @MinSalary = 70000, @MaxSalary = 80000;

-------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE UpdateEmployeeSalary
    @EmployeeId INT,
    @NewSalary DECIMAL(10, 2)
AS
BEGIN
    BEGIN TRY
        UPDATE employees
        SET salary = @NewSalary
        WHERE employee_id = @EmployeeId;
    END TRY
    BEGIN CATCH
        PRINT 'An error occurred';
    END CATCH
END;

EXEC UpdateEmployeeSalary @EmployeeId = 1, @NewSalary = 65000.00;

-------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE TransferSalary
    @FromEmployeeId INT,
    @ToEmployeeId INT,
    @Amount DECIMAL(10, 2)
AS
BEGIN
    BEGIN TRANSACTION;

    UPDATE employees SET salary = salary - @Amount WHERE employee_id = @FromEmployeeId;
    UPDATE employees SET salary = salary + @Amount WHERE employee_id = @ToEmployeeId;

    COMMIT;
END;

exec TransferSalary @FromEmployeeId=1,@ToEmployeeId=2,@Amount=10;
select * 
from employees;

---------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE GetEmployeesByCondition
    @Condition NVARCHAR(100)
AS
BEGIN
    DECLARE @SQL NVARCHAR(4000);
    SET @SQL = 'SELECT * FROM employees WHERE ' + @Condition;
    EXEC sp_executesql @SQL;
END;

exec GetEmployeesByCondition  @Condition= 'salary>70000';

------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE UpdateEmployeeBonuses
AS
BEGIN
    DECLARE @EmployeeId INT,
            @Bonus DECIMAL(10, 2);

    DECLARE cur CURSOR FOR
    SELECT employee_id, salary * 0.10 AS bonus FROM employees;

    OPEN cur;
    FETCH NEXT FROM cur INTO @EmployeeId, @Bonus;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE employees SET salary = salary + @Bonus WHERE employee_id = @EmployeeId;
        FETCH NEXT FROM cur INTO @EmployeeId, @Bonus;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;

EXEC UpdateEmployeeBonuses;
select *
from employees;

-----------------------------------------------------------------------------------------------------------

CREATE PROCEDURE UpdateEmployeeInfo
    @EmployeeId INT,
    @NewSalary DECIMAL(10, 2),
    @NewDepartmentId INT
AS
BEGIN
    UPDATE employees
    SET salary = @NewSalary,
        department_id = @NewDepartmentId
    WHERE employee_id = @EmployeeId;
END;

exec UpdateEmployeeInfo @EmployeeId =2,@NewSalary =98765,@NewDepartmentId=4;
select *
from employees;

-------------------------------------------------------------------------------------------------------

CREATE PROCEDURE PromoteEmployees
AS
BEGIN
    DECLARE @EmployeeId INT,
            @NewSalary DECIMAL(10, 2);

    DECLARE cur CURSOR FOR
    SELECT employee_id, salary * 1.20 AS new_salary FROM employees WHERE salary < 50000;

    OPEN cur;
    FETCH NEXT FROM cur INTO @EmployeeId, @NewSalary;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE employees SET salary = @NewSalary WHERE employee_id = @EmployeeId;
        FETCH NEXT FROM cur INTO @EmployeeId, @NewSalary;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;

EXEC PromoteEmployees;
select *
from employees;