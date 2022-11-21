-- The Bike Peddler - DML
-- --------------------------
-- Script contents:
--     1. WHERE ... IN
--     2. WHERE ... BETWEEN
--     3. WHERE ... LIKE
--     4. Date Functions
--     5. Aggregate Functions
--     6. GROUP BY
--     7. GROUP BY ... HAVING
--     8. ORDER BY
--     9. JOIN
--     10. Sub-Queries
--     11. Users & Privileges
-- --------------------------

USE the_bike_peddler;

-- ----------------------------------------------------------------------
-- 1. WHERE ... IN
-- ----------------------------------------------------------------------

SELECT
    CONCAT(first_name, ' ', last_name) AS name,
    email_address
FROM person
WHERE county IN ('Waterford', 'Wexford', 'Kilkenny');


SELECT *
FROM `order`
WHERE status NOT IN ('Delivered', 'Cancelled');


SELECT email_address
FROM
    customer
    JOIN person ON customer.id = person.id
WHERE loyalty_status IN ('Green', 'Bronze');


-- ----------------------------------------------------------------------
-- 2. WHERE ... BETWEEN
-- ----------------------------------------------------------------------

SELECT *
FROM person
WHERE last_name BETWEEN 'A' AND 'L';


SELECT *
FROM enquiry
WHERE datetime BETWEEN '2020-1-1' AND CURRENT_TIMESTAMP;


SELECT *
FROM `order`
WHERE total_price BETWEEN 1000 AND 3000;


-- ----------------------------------------------------------------------
-- 3. WHERE ... LIKE
-- ----------------------------------------------------------------------

SELECT CONCAT(first_name, ' ', last_name) AS name
FROM person
WHERE last_name LIKE '%an';


SELECT last_name
FROM person
WHERE last_name LIKE '____y';


SELECT *
FROM product
WHERE description LIKE '%bike%';


-- ----------------------------------------------------------------------
-- 4. Date Functions
-- ----------------------------------------------------------------------

SELECT
    employee_id,
    amount,
    DATEDIFF(CURDATE(), start_date) AS 'Days at Current Salary'
FROM salary
WHERE end_date IS NULL;


SELECT
    employee_id,
    DATE_FORMAT(MIN(start_date), '%a %e %b, %Y') AS 'Date of Employment'
FROM employee_department
GROUP BY employee_id;


SELECT TIMESTAMPDIFF(SECOND, MAX(datetime), NOW()) AS 'Time Since Last Order'
FROM `order`;


SELECT
    CONCAT(first_name, ' ', last_name) AS 'Name',
    loyalty_status AS 'Loyalty Status',
    product.name AS 'Product Name',
    DATE_FORMAT(datetime, '%l:%i %p, %M %D %Y') AS 'Enquiry Date & Time'
FROM enquiry
    JOIN customer on enquiry.customer_id = customer.id
    JOIN person on customer.id = person.id
    JOIN product on enquiry.product_id = product.id;


-- ----------------------------------------------------------------------
-- 5. Aggregate Functions (AVG, MIN, MAX, SUM, COUNT)
-- ----------------------------------------------------------------------

SELECT ROUND(AVG(total_price), 2) AS 'Average Order Total'
FROM `order`;


SELECT MIN(amount) AS 'Lowest Current Salary'
FROM salary
WHERE end_date IS NULL;


SELECT
    customer_id,
    product_id,
    datetime AS 'Date & Time of Latest Enquiry'
FROM enquiry
WHERE datetime = (SELECT MAX(datetime) FROM enquiry);


SELECT
    customer_id,
    MAX(datetime) AS 'Date & Time of Latest Enquiry'
FROM enquiry
GROUP BY customer_id;


SELECT COUNT(*) AS 'Count of Green-Status Customers'
FROM customer
WHERE loyalty_status = 'Green';


SELECT COUNT(DISTINCT picker_id) AS 'Count of Employees Used as Pickers'
FROM `order`;


SELECT SUM(current_salary) AS 'Total Current Salary Spend'
FROM current_employee_hr_view;


-- ----------------------------------------------------------------------
-- 6. GROUP BY
-- ----------------------------------------------------------------------

SELECT
    product.name,
    SUM(product_quantity) AS 'Quantity Sold to Date'
FROM
    order_product
    JOIN `order` ON order_product.order_number = `order`.order_number
    JOIN product ON order_product.product_id = product.id
WHERE `order`.status != 'Cancelled'
GROUP BY product_id;


SELECT
    loyalty_status,
    COUNT(*) AS 'Count of Customers'
FROM customer
GROUP BY loyalty_status
ORDER BY `Count of Customers` DESC;


-- ----------------------------------------------------------------------
-- 7. GROUP BY ... HAVING
-- ----------------------------------------------------------------------

SELECT
    customer_id,
    SUM(total_price) AS 'Total Spent to Date'
FROM `order`
WHERE status != 'Cancelled'
GROUP BY customer_id
HAVING `Total Spent to Date` > 1000
ORDER BY `Total Spent to Date` DESC;


SELECT
    department.name AS 'Department Name',
    COUNT(employee_id) AS 'Count of Current Employees'
FROM
    employee_department
    JOIN department ON employee_department.department_id = department.id
WHERE end_date IS NULL
GROUP BY department_id
HAVING department_id IN (1, 2, 4)
ORDER BY department.name;


-- ----------------------------------------------------------------------
-- 8. ORDER BY
-- ----------------------------------------------------------------------

SELECT
    CONCAT(first_name, ' ', last_name) AS 'Employee Name',
    MIN(start_date) AS 'Start of Employment'
FROM
    employee_department
    JOIN employee ON employee_department.employee_id = employee.id
    JOIN person ON employee.id = person.id
GROUP BY employee_id
ORDER BY `Start of Employment` DESC, `Employee Name` ASC;


SELECT
    customer_id,
    CONCAT(first_name, ' ', last_name) AS name,
    organisation,
    total_price
FROM
    `order`
    JOIN customer ON `order`.customer_id = customer.id
    JOIN person ON customer.id = person.id
ORDER BY total_price DESC
LIMIT 3;


-- ----------------------------------------------------------------------
-- 9. JOIN (multi-table, outer, and NATURAL)
-- ----------------------------------------------------------------------

-- Gets various details of current employees
SELECT
    first_name,
    last_name,
    person.email_address,
    phone_number,
    manager_id,
    amount AS 'Current Salary',
    DATEDIFF(CURRENT_TIMESTAMP, salary.start_date) AS 'Days at Current Salary',
    department.name,
    DATEDIFF(CURRENT_TIMESTAMP, employee_department.start_date) AS 'Days at Current Dept'
FROM
    person
    JOIN phone ON person.id = phone.person_id
    JOIN employee ON person.id = employee.id
    JOIN employee_department ON employee.id = employee_department.employee_id
    JOIN department ON employee_department.department_id = department.id
    JOIN salary ON employee.id = salary.employee_id
WHERE
    employee_department.end_date IS NULL
    AND salary.end_date IS NULL;

    
-- Get every customer's name and ID, as well as their support employee's
-- name and ID if they have been assigned one
SELECT
    customer.id AS 'Customer ID',
    CONCAT(person_customer.first_name, ' ', person_customer.last_name) AS 'Customer Name',
    support_employee_id AS 'Support Employee ID',
    CONCAT(person_employee.first_name, ' ', person_employee.last_name) AS 'Support Employee Name'
FROM
    customer
    JOIN person AS person_customer
        ON customer.id = person_customer.id
    LEFT JOIN employee ON customer.support_employee_id = employee.id
    LEFT JOIN person AS person_employee
        ON employee.id = person_employee.id;

        
-- Get name and ID of each product, as well as names and IDs of associated subproducts
SELECT
    product.id,
    product.name,
    subproduct_id,
    subproduct.name AS 'Subproduct Name',
    subproduct_quantity
FROM
    product
    LEFT JOIN product_subproduct ON product_subproduct.product_id = product.id
    LEFT JOIN product AS subproduct ON product_subproduct.subproduct_id = subproduct.id;


-- Get name and ID of each employee, and name and ID of each's manager, if any
SELECT
    employee.id AS 'Employee ID',
    CONCAT(person_employee.first_name, ' ', person_employee.last_name) AS 'Employee Name',
    manager.id AS 'Manager ID',
    CONCAT(person_manager.first_name, ' ', person_manager.last_name) AS 'Manager Name'
FROM
    employee AS manager
    JOIN person AS person_manager
        ON manager.id = person_manager.id
    RIGHT JOIN employee ON manager.id = employee.manager_id
    JOIN person AS person_employee
        ON employee.id = person_employee.id
ORDER BY employee.id;


SELECT
    order_number,
    customer_id,
    product_id,
    product_quantity,
    product.name
FROM
    `order`
    NATURAL JOIN order_product
    JOIN product ON order_product.product_id = product.id
    ORDER BY order_number;


-- ----------------------------------------------------------------------
-- 10. Sub-Queries
-- ----------------------------------------------------------------------

-- Get all customer details for customers who have made enquiries
SELECT *
FROM customer
WHERE id IN (SELECT customer_id FROM enquiry);


SELECT 
    employee.id,
    contract_type,
    amount,
    payment_type,
    start_date,
    end_date
FROM
    employee
    JOIN salary on employee.id = salary.employee_id
WHERE employee_id IN
    (SELECT employee_id
    FROM employee_department
    WHERE department_id = 1);


-- Create stored procedure containing multiple sub-queries, conditions, joins, and aggregate functions
DROP PROCEDURE IF EXISTS get_department_details_on_date;

DELIMITER $$
CREATE PROCEDURE get_department_details_on_date(
    `dept_id` INT,
    `date` DATE
)
BEGIN
    SELECT
        (SELECT name FROM department WHERE id = dept_id) AS 'Department Name',
        DATE_FORMAT(`date`, '%a %e %b, %Y') AS 'Date',
        COUNT(*) AS 'Count of Employees',
        ROUND(AVG(amount), 2) AS 'Average Salary',
        SUM(amount) AS 'Total Salary Spend'
    FROM
        employee
        JOIN salary ON employee.id = salary.employee_id
    WHERE
        salary.start_date <= `date`
        AND (salary.end_date > `date` OR salary.end_date IS NULL)
        AND employee.id IN
            (SELECT employee_id
            FROM employee_department
            WHERE department_id = `dept_id`);
END $$
DELIMITER ;

CALL get_department_details_on_date(5, '2020-6-1');


-- ----------------------------------------------------------------------
-- 11. Users & Privileges
-- ----------------------------------------------------------------------

DROP USER IF EXISTS hr_manager;
DROP USER IF EXISTS hr_intern;
DROP USER IF EXISTS stores;

CREATE USER hr_manager IDENTIFIED BY 'password';
CREATE USER hr_intern IDENTIFIED BY 'password';
CREATE USER stores IDENTIFIED BY 'password';


-- hr_manager grants

GRANT SELECT, UPDATE
ON the_bike_peddler.current_employee_hr_view
TO hr_manager;


GRANT SELECT, INSERT, UPDATE
ON the_bike_peddler.person
TO hr_manager;


GRANT SELECT, INSERT, UPDATE
ON the_bike_peddler.phone
TO hr_manager;


GRANT SELECT, INSERT, UPDATE
ON the_bike_peddler.employee
TO hr_manager;


GRANT SELECT, INSERT, UPDATE
ON the_bike_peddler.salary
TO hr_manager;


GRANT SELECT, INSERT, UPDATE
ON the_bike_peddler.employee_department
TO hr_manager;


-- hr_intern grants

GRANT SELECT
ON the_bike_peddler.current_employee_hr_view
TO hr_intern;


GRANT UPDATE(manager_id)
ON the_bike_peddler.employee
TO hr_intern;


-- stores grants

GRANT SELECT
ON the_bike_peddler.open_order_view
TO stores;
