-- The Bike Peddler - DDL
-- ----------------------
-- Script contents:
--     1. Create Tables
--     2. Create Triggers
--     3. Create Indexes
--     4. Create Views
--     5. Populate Tables
-- ----------------------

DROP DATABASE IF EXISTS the_bike_peddler;

CREATE DATABASE IF NOT EXISTS the_bike_peddler;

USE the_bike_peddler;

-- ----------------------------------------------------------------------
--  1. Create Tables
-- ----------------------------------------------------------------------

DROP TABLE IF EXISTS person;
DROP TABLE IF EXISTS phone;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS product_audit;
DROP TABLE IF EXISTS product_subproduct;
DROP TABLE IF EXISTS `order`;
DROP TABLE IF EXISTS order_product;
DROP TABLE IF EXISTS enquiry;
DROP TABLE IF EXISTS salary;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS employee_department;


CREATE TABLE IF NOT EXISTS person (
    id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    gender VARCHAR(20),
    street VARCHAR(20) NOT NULL,
    town VARCHAR(20) NOT NULL,
    county ENUM(
        'Antrim', 'Armagh', 'Carlow', 'Cavan', 'Clare', 'Cork', 'Derry',
        'Donegal', 'Down', 'Dublin', 'Fermanagh', 'Galway', 'Kerry',
        'Kildare', 'Kilkenny', 'Laois', 'Leitrim', 'Limerick', 'Longford',
        'Louth', 'Mayo', 'Meath', 'Monaghan', 'Offaly', 'Roscommon',
        'Sligo', 'Tipperary', 'Tyrone', 'Waterford', 'Westmeath',
        'Wexford', 'Wicklow'
        ) NOT NULL,
    postcode CHAR(7) NOT NULL,
    email_address VARCHAR(50) NOT NULL,
    UNIQUE (email_address),
    PRIMARY KEY (id)
);


CREATE TABLE IF NOT EXISTS phone (
    phone_number VARCHAR(15) NOT NULL,
    person_id INT NOT NULL,
    PRIMARY KEY (phone_number),
    FOREIGN KEY (person_id)
        REFERENCES person(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS employee (
    id INT NOT NULL,
    manager_id INT,
    pps CHAR(8) NOT NULL,
    contract_type ENUM('Temporary', 'Permanent', 'Part-Time') NOT NULL,
    UNIQUE (pps),
    PRIMARY KEY (id),
    FOREIGN KEY (id)
        REFERENCES person(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (manager_id)
        REFERENCES employee(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS customer (
    id INT NOT NULL,
    support_employee_id INT,
    organisation VARCHAR(20),
    vat_number CHAR(9),
    loyalty_status ENUM(
        'Green', 'Bronze', 'Silver', 'Gold'
        ) NOT NULL DEFAULT 'Green',
    PRIMARY KEY (id),
    FOREIGN KEY (id)
        REFERENCES person(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (support_employee_id)
        REFERENCES employee(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS product (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL,
    description TINYTEXT NOT NULL,
    price DECIMAL(8, 2) NOT NULL,
    weight INT,
    height INT,
    width INT,
    depth INT,
    PRIMARY KEY (id)
);


CREATE TABLE IF NOT EXISTS product_audit (
    id INT NOT NULL AUTO_INCREMENT,
    product_id INT NOT NULL,
    name VARCHAR(20) NOT NULL,
    description TINYTEXT NOT NULL,
    price DECIMAL(8, 2) NOT NULL,
    weight INT,
    height INT,
    width INT,
    depth INT,
    changedate DATETIME DEFAULT NULL,
    action VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS product_subproduct (
    product_id INT NOT NULL,
    subproduct_id INT NOT NULL,
    subproduct_quantity INT NOT NULL CHECK (subproduct_quantity > 0),
    PRIMARY KEY (product_id, subproduct_id),
    FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (subproduct_id)
        REFERENCES product(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS `order` (
    order_number INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    picker_id INT NOT NULL,
    total_price DECIMAL(8, 2) NOT NULL DEFAULT 0,
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'Pending', 'Picked', 'Out for Delivery', 'Delivered', 'Cancelled'
        ) NOT NULL DEFAULT 'Pending',
    PRIMARY KEY (order_number),
    FOREIGN KEY (customer_id)
        REFERENCES customer(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (picker_id)
        REFERENCES employee(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS order_product (
    order_number INT NOT NULL,
    product_id INT NOT NULL,
    product_quantity INT NOT NULL CHECK (product_quantity > 0),
    PRIMARY KEY (order_number, product_id),
    FOREIGN KEY (order_number)
        REFERENCES `order`(order_number)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS enquiry (
    customer_id INT NOT NULL,
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    product_id INT NOT NULL,
    PRIMARY KEY (customer_id, datetime),
    FOREIGN KEY (customer_id)
        REFERENCES customer(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES product(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS salary (
    id INT NOT NULL AUTO_INCREMENT,
    employee_id INT NOT NULL,
    amount DECIMAL(8, 2) NOT NULL CHECK (amount > 0),
    payment_type ENUM('Weekly', 'Fortnightly', 'Monthly') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (id),
    FOREIGN KEY (employee_id)
        REFERENCES employee(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS department (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL,
    email_address VARCHAR(50) NOT NULL,
    PRIMARY KEY (id)
);


CREATE TABLE IF NOT EXISTS employee_department (
    employee_id INT NOT NULL,
    department_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (employee_id, department_id, start_date),
    FOREIGN KEY (employee_id)
        REFERENCES employee(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (department_id)
        REFERENCES department(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- ----------------------------------------------------------------------
--  2. Create Triggers
-- ----------------------------------------------------------------------

DROP TRIGGER IF EXISTS before_phone_insert;
DROP TRIGGER IF EXISTS after_order_insert;
DROP TRIGGER IF EXISTS after_order_product_insert;
DROP TRIGGER IF EXISTS before_salary_insert;
DROP TRIGGER IF EXISTS before_product_update;


-- Throw error and prevent insert if person's ID appears in phone table three times
DELIMITER $$
CREATE TRIGGER before_phone_insert
    BEFORE INSERT ON phone
    FOR EACH ROW 
BEGIN
    IF
        (SELECT COUNT(*) FROM phone
        WHERE person_id = NEW.person_id) >= 3
    THEN
        SIGNAL SQLSTATE "45000"
        SET MESSAGE_TEXT = "A person cannot have more than three phone numbers";
    END IF;
END $$
DELIMITER ;


-- Update customer loyalty status if new count of order has hit threshold
DELIMITER $$
CREATE TRIGGER after_order_insert
    AFTER INSERT ON `order`
    FOR EACH ROW 
BEGIN
    SET @count_of_orders = (SELECT COUNT(*) FROM `order`
                            WHERE customer_id = NEW.customer_id
                            AND STATUS != 'Cancelled');
    CASE
        WHEN @count_of_orders = 2 THEN SET @new_customer_loyalty_status = 'Bronze';
        WHEN @count_of_orders = 4 THEN SET @new_customer_loyalty_status = 'Silver';
        WHEN @count_of_orders = 7 THEN SET @new_customer_loyalty_status = 'Gold';
        ELSE SET @new_customer_loyalty_status = NULL;
    END CASE;
    IF
        @new_customer_loyalty_status IS NOT NULL
    THEN
        UPDATE customer
            SET loyalty_status = @new_customer_loyalty_status
            WHERE id = NEW.customer_id;
    END IF;
END $$
DELIMITER ;


-- Update total order price by adding to it the new product's price multiplied by
-- new product's quantity after inserting record into order_product table
DELIMITER $$
CREATE TRIGGER after_order_product_insert
    AFTER INSERT ON order_product
    FOR EACH ROW 
BEGIN
    SET @old_order_total_price = (SELECT total_price FROM `order` WHERE order_number = NEW.order_number);
    SET @product_price = (SELECT price FROM product WHERE id = NEW.product_id);
    UPDATE `order`
        SET total_price = @old_order_total_price + (@product_price * NEW.product_quantity)
        WHERE order_number = NEW.order_number;
END $$
DELIMITER ;


-- Prevent salary table from containing more than 1 null value for salary end date per employee
DELIMITER $$
CREATE TRIGGER before_salary_insert
    BEFORE INSERT ON salary
    FOR EACH ROW
BEGIN
    IF
        (SELECT COUNT(*) FROM salary
        WHERE end_date IS NULL
        AND employee_id = NEW.employee_id) > 0
    THEN
        SIGNAL SQLSTATE "45000"
        SET MESSAGE_TEXT = "Salary table cannot contain more than 1 null value for salary end date per employee";
    END IF;
END $$
DELIMITER ;


-- Prevent employee_department table from containing more than 1 null value
-- for employee_department end date per employee
DELIMITER $$
CREATE TRIGGER before_employee_department_insert
    BEFORE INSERT ON employee_department
    FOR EACH ROW
BEGIN
    IF
        (SELECT COUNT(*) FROM employee_department
        WHERE end_date IS NULL
        AND employee_id = NEW.employee_id) > 0
    THEN
        SIGNAL SQLSTATE "45000"
        SET MESSAGE_TEXT = "employee_department table cannot contain more than 1 entry containing a null end date for each employee";
    END IF;
END $$
DELIMITER ;


-- Populate book_audit table with old product details before updating product table
DELIMITER $$
CREATE TRIGGER before_product_update
    BEFORE UPDATE ON product
    FOR EACH ROW
BEGIN
    INSERT INTO book_audit
    SET action = 'update',
        product_id = OLD.id,
        name = OLD.name,
        description = OLD.description,
        price = OLD.price,
        weight = OLD.weight,
        height = OLD.height,
        width = OLD.width,
        depth = OLD.depth,
        change_date = CURRENT_TIMESTAMP;
END $$
DELIMITER ;


-- ----------------------------------------------------------------------
--  3. Create Indexes
-- ----------------------------------------------------------------------

CREATE INDEX person_last_name_index ON person(last_name);

CREATE INDEX salary_amount_index ON salary(amount);

CREATE UNIQUE INDEX department_name_index ON department(name);

CREATE INDEX order_datetime_index ON `order`(datetime DESC);

CREATE INDEX product_name_index ON product(name);

CREATE INDEX product_price_index ON product(price);


-- ----------------------------------------------------------------------
--  4. Create Views
-- ----------------------------------------------------------------------

DROP VIEW IF EXISTS current_employee_hr_view;
DROP VIEW IF EXISTS open_order_view;


CREATE OR REPLACE VIEW current_employee_hr_view AS
    SELECT
        person.id,
        CONCAT(person.first_name, ' ', person.last_name) AS name,
        person.gender,
        person.email_address,
        employee.manager_id,
        employee.contract_type,
        salary.amount AS current_salary,
        salary.payment_type,
        salary.start_date AS salary_start_date,
        employee_department.start_date AS department_start_date,
        department.name AS department_name
    FROM person
    JOIN employee ON person.id = employee.id
    JOIN salary ON employee.id = salary.employee_id
    JOIN employee_department ON employee.id = employee_department.employee_id
    JOIN department ON employee_department.department_id = department.id
    WHERE
        salary.end_date IS NULL
        AND employee_department.end_date IS NULL
    ORDER BY person.last_name
    WITH CHECK OPTION;


CREATE OR REPLACE VIEW open_order_view AS
    SELECT
        `order`.order_number,
        customer_id,
        picker_id,
        total_price,
        datetime,
        status,
        product_id,
        product_quantity
    FROM `order`
    JOIN order_product on `order`.order_number = order_product.order_number
    WHERE status NOT IN ('Delivered', 'Cancelled')
    ORDER BY datetime DESC
    WITH CHECK OPTION;


-- ----------------------------------------------------------------------
--  5. Populate Tables
-- ----------------------------------------------------------------------

INSERT INTO person
    (first_name, last_name, gender, street, town, county, postcode, email_address)
VALUES
    ('Eoin', 'Fennessy', 'Male', '123 Main St.', 'Woodstown', 'Waterford', 'X91AB12', 'eoin@fennessy.com'),
    ('Mary', 'Ryan', 'Female', '614 John St.', 'New Ross', 'Wexford', 'X1734FE', 'mary@ryan.com'),
    ('Jenny', 'Phelan', 'Female', '21 Manor Ave.', 'Slieverue', 'Kilkenny', 'B35DF7A', 'jenny@phelan.com'),
    ('John', 'Smith', NULL, '21 Lady Lane', 'Waterford', 'Waterford', 'X9153H1', 'john@smith.com'),
    ('Grace', 'Jones', 'Female', '1 Holly Ave.', 'Mallow', 'Cork', 'B172F1H', 'grace@jones.com'),
    ('Magda', 'O\'Brien', 'Non-Binary', '12 Barrack St.', 'Waterford', 'Waterford', 'X9135CE', 'magda@obrien.com'),
    ('Sam', 'Sullivan', 'Pangender', '2 Church St.', 'Doolin', 'Clare', 'X1737FG', 'sam@sullivan.com'),
    ('Jim', 'Kelly', 'Male', '172 Broad St.', 'Thurles', 'Tipperary', 'J1171FL', 'jim@kelly.com'),
    ('Nora', 'Riley', 'Female', '1 Shortcourse Rd.', 'Ballybricken', 'Waterford', 'X91GT71', 'nora@riley.com');


INSERT INTO phone
    (phone_number, person_id)
VALUES
    ('0860000001', 1),
    ('0860000011', 1),
    ('0860000021', 1),
    ('0860000002', 2),
    ('0860000003', 3),
    ('0860000004', 4),
    ('0860000005', 5),
    ('0860000006', 6),
    ('0860000007', 7),
    ('0860000008', 8),
    ('0860000009', 9);


INSERT INTO employee
    (id, manager_id, pps, contract_type)
VALUES
    (1, NULL, '123BK54K', 'Permanent'),
    (3, 1, '523AS54R', 'Permanent'),
    (5, 3, '156BK54H', 'Temporary'),
    (7, 1, '893BK54L', 'Permanent'),
    (9, 3, '2M3BK54A', 'Part-Time');


INSERT INTO customer
    -- Use default 'Green' loyalty_status
    (id, support_employee_id, organisation, vat_number)
VALUES
    (2, 3, 'Wexford Cycling Club', NULL),
    (4, NULL, 'The Biscuit Club', NULL),
    (5, NULL, 'SETU', NULL),
    (6, 3, 'Spokes', '1234FG234'),
    (7, NULL, 'Waterford Tri Club', NULL),
    (8, 7, 'City Cycles', '5678BM334');


INSERT INTO product
    (name, description, price, weight, height, width, depth)
VALUES
    ('Carrera C1000', 'A very well built bike for the price', 350.99, 9763, 1200, 2850, 150),
    ('Raleigh X100', 'A mid-priced mountain bike', 635.50, 10535, 1104, 2622, 170),
    ('€50 Gift Voucher', 'A gift voucher code emailed to you', 50.00, NULL, NULL, NULL, NULL),
    ('Shimano Z35', 'High-performance gear set for racing bikes', 179.95, 268, 352, 512, 92),
    ('SRAM DB17', 'Professional disc brake', 220.50, 158, 402, 380, 102),
    ('Claude Butler F1', 'Lightweight racing bike frame', 1999.99, 3970, 1350, 2018, 165),
    ('Claude Butler Custom', 'Assembled in-store using our best racing bike components', 2499.99, 4975, 1350, 2650, 170),
    ('Bike Service', 'Our experienced staff clean and oil your bike', 80.00, NULL, NULL, NULL, NULL);


INSERT INTO product_subproduct
    (product_id, subproduct_id, subproduct_quantity)
VALUES
    (7, 4, 1),
    (7, 5, 2),
    (7, 6, 1);


INSERT INTO `order`
    -- Use default value of 0 for total_price - this will be updated when products are inserted into to order
    (customer_id, picker_id, datetime, status)
VALUES
    (2, 5, '2019-3-31 23:15:12', 'Delivered'),
    (2, 3, '2020-6-20 16:35:01', 'Delivered'),
    (2, 5, '2021-9-15 13:21:25', 'Delivered'),
    (2, 7, '2022-11-19 19:17:42', 'Picked'),
    (4, 7, '2015-5-17 12:11:16', 'Delivered'),
    (4, 5, '2019-7-30 15:01:40', 'Cancelled'),
    (5, 3, '2020-4-27 11:50:29', 'Delivered'),
    (5, 7, '2022-11-17 17:41:25', 'Out for Delivery'),
    (6, 1, '2022-5-10 13:21:25', 'Delivered'),
    (7, 9, '2022-11-21 18:20:02', 'Pending'),
    (8, 5, '2018-6-12 15:10:44', 'Delivered'),
    (8, 1, '2022-3-20 12:21:59', 'Delivered');


INSERT INTO order_product
    (order_number, product_id, product_quantity)
VALUES
    (1, 2, 1),
    (1, 3, 2),
    (2, 5, 2),
    (3, 8, 1),
    (4, 3, 1),
    (5, 1, 1),
    (6, 4, 1),
    (6, 3, 1),
    (7, 4, 2),
    (8, 7, 1),
    (9, 6, 1),
    (9, 2, 1),
    (10, 1, 1),
    (11, 1, 1),
    (12, 2, 2),
    (12, 4, 1);


INSERT INTO enquiry
    (customer_id, datetime, product_id)
VALUES
    (2, '2019-2-28 21:07:42', 6),
    (2, '2019-3-20 22:10:50', 5),
    (4, '2020-5-30 11:07:15', 2);


INSERT INTO salary
    (employee_id, amount, payment_type, start_date, end_date)
VALUES
    (1, 35000.00, 'Weekly', '2015-3-28', '2017-1-11'),
    (1, 38000.00, 'Weekly', '2017-1-11', '2019-3-31'),
    (1, 42000.00, 'Weekly', '2019-3-31', NULL),
    (3, 38500.00, 'Monthly', '2016-11-21', '2018-3-15'),
    (3, 45300.00, 'Monthly', '2018-3-15', NULL),
    (5, 32000.00, 'Fortnightly', '2019-12-21', '2020-12-23'),
    (5, 37000.00, 'Fortnightly', '2020-12-23', NULL),
    (7, 55900.00, 'Weekly', '2020-5-16', '2021-6-9'),
    (7, 58500.00, 'Weekly', '2021-6-9', NULL),
    (9, 41000.00, 'Monthly', '2019-12-21', NULL);


INSERT INTO department
    (name, email_address)
VALUES
    ('Sales', 'sales@thebikepeddler.ie'),
    ('Repairs', 'repairs@thebikepeddler.ie'),
    ('Stores', 'stores@thebikepeddler.ie'),
    ('Customer Service', 'customerservice@thebikepeddler.ie'),
    ('HR', 'hr@thebikepeddler.ie');


INSERT INTO employee_department
    (employee_id, department_id, start_date, end_date)
VALUES
    (1, 1, '2015-3-28', NULL),
    (3, 2, '2016-11-21', '2019-4-20'),
    (3, 4, '2019-4-20', NULL),
    (5, 3, '2019-12-21', NULL),
    (7, 5, '2020-5-16', '2021-10-4'),
    (7, 2, '2021-10-4', NULL),
    (9, 5, '2019-12-21', NULL);


-- ROLLBACK;
COMMIT;
