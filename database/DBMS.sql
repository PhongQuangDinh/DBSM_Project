USE MASTER
GO
IF DB_ID('QLPHONGKHAMNHAKHOA') IS NOT NULL
	DROP DATABASE QLPHONGKHAMNHAKHOA
GO

CREATE DATABASE QLPHONGKHAMNHAKHOA
GO

USE QLPHONGKHAMNHAKHOA
GO

--table ACCOUNT
CREATE TABLE Account
(
	account_id char(5),
	username varchar(10) NOT NULL UNIQUE,
	[password] varchar(32) NOT NULL,
	account_status BIT NOT NULL,


	CONSTRAINT PK_Account
	PRIMARY KEY (account_id)
)

--table Person
CREATE TABLE Person
(
	person_id char(5), 
	person_name nvarchar(30) NOT NULL,
	person_phone char(10) NOT NULL,
	person_birthday DATE,
	person_address nvarchar(40),
	person_gender nvarchar(3) NOT NULL,
	person_type char(2) NOT NULL,
	account_id char(5)

	CONSTRAINT PK_Person
	PRIMARY KEY (person_id)
)
ALTER TABLE Person
ADD CONSTRAINT gender_person CHECK (person_gender in (N'Nam', N'Nữ'))

--table personalAppointment
CREATE TABLE personalAppointment
(
	personal_appointment_id char(5),
	personal_appointment_start_time time NOT NULL,
	personal_appointment_end_time time NOT NULL,
	personal_appointment_date date,
	dentist_id char(5)

	CONSTRAINT PK_personalAppointment
	PRIMARY KEY(personal_appointment_id)
)

--table APPOINTMENT
CREATE TABLE Appointment
(
	appointment_id char(5),
	patient_id char(5),
	dentist_id char(5),
	appointment_start_time time NOT NULL,
	appointment_status bit NOT NULL,
	appointment_number int NOT NULL,
	appointment_date date

	CONSTRAINT PK_Appointment
	PRIMARY KEY(appointment_id)
)

--table MEDICAL_RECORD
CREATE TABLE MedicalRecord
(
	medical_record_id char(5),
	examination_date date,
	pay_status bit NOT NULL,
	patient_id char(5) NOT NULL,
	dentist_id char(5) NOT NULL,
	appointment_id char(5) NOT NULL

	CONSTRAINT PK_MedicalRecord
	PRIMARY KEY (medical_record_id)
)

--table BILL
CREATE TABLE Bill
(
	bill_id char(5),
	service_cost float,
	appointment_cost float,
	drugs_cost float,
	cost_total float,
	payment_date date,
	patient_id char(5) NOT NULL,
	medical_record_id char(5) NOT NULL

	CONSTRAINT PK_Bill
	PRIMARY KEY(bill_id)
)

--table SERVICE
CREATE TABLE [Service]
(
	service_id char(5),
	[service_name] nvarchar(30),
	cost float NOT NULL

	CONSTRAINT PK_Service
	PRIMARY KEY(service_id)
)


--table service_list
CREATE TABLE ServiceList
(
	service_id char(5),
	medical_record_id char(5) NOT NULL,
	service_quantity int

	CONSTRAINT PK_SERVICES
	PRIMARY KEY	(medical_record_id, service_id)
)
--table PRESCRIPTION
CREATE TABLE Prescription
(
	drug_id char(5),
	medical_record_id char(5) NOT NULL,
	drug_quantity int NOT NULL Check (drug_quantity>=1),
	drug_price float

	CONSTRAINT PK_Prescription
	PRIMARY KEY(medical_record_id, drug_id)
)

--table DRUG 
CREATE TABLE Drug
(
	drug_id char(5),
	unit varchar(5),
	drug_name nvarchar(30),
	indication nvarchar(50),
	expiration_date date,
	price float,
	drug_stock_quantity int

	CONSTRAINT PK_Drug
	PRIMARY KEY (drug_id)
)

--rang buoc
ALTER TABLE Person
ADD
	CONSTRAINT FK_Person_Account
	FOREIGN KEY (account_id)
	REFERENCES Account

ALTER TABLE personalAppointment
ADD
	CONSTRAINT FK_personalAppointment_Dentist
	FOREIGN KEY (dentist_id)
	REFERENCES Person

ALTER TABLE Bill
ADD
	CONSTRAINT FK_Bill_Patient
	FOREIGN KEY (patient_id)
	REFERENCES Person,

	CONSTRAINT FK_Bill_MedicalRecord
	FOREIGN KEY (medical_record_id)
	REFERENCES MedicalRecord

ALTER TABLE MedicalRecord
ADD
	CONSTRAINT FK_MedicalRecord_Patient
	FOREIGN KEY (patient_id)
	REFERENCES Person,

	CONSTRAINT FK_MedicalRecord_Dentist
	FOREIGN KEY (dentist_id)
	REFERENCES Person,
	
	CONSTRAINT FK_MedicalRecord_Appointment
	FOREIGN KEY (appointment_id)
	REFERENCES Appointment


ALTER TABLE Appointment
ADD
	CONSTRAINT FK_Appointment_Patient
	FOREIGN KEY (patient_id)
	REFERENCES Person,

	CONSTRAINT FK_Appointment_Dentist
	FOREIGN KEY (dentist_id)
	REFERENCES Person

ALTER TABLE Prescription
ADD
	CONSTRAINT FK_Prescription_Drug
	FOREIGN KEY (drug_id)
	REFERENCES Drug,

	CONSTRAINT FK_Prescription_MedicalRecord
	FOREIGN KEY (medical_record_id)
	REFERENCES MedicalRecord

ALTER TABLE ServiceList
ADD
	CONSTRAINT FK_ServiceList_Service
	FOREIGN KEY (service_id)
	REFERENCES [Service],

	CONSTRAINT FK_ServiceList_MedicalRecord
	FOREIGN KEY (medical_record_id)
	REFERENCES MedicalRecord

-- Tìm các khung giờ làm việc còn trống trong personalAppointment của một nhân viên
-- Mỗi cuộc hẹn có thời lượng là 30 phút

--DECLARE @dentistId CHAR(5) = '00012'; -- Replace with the specific dentist_id you are interested in

---- Common Table Expression (CTE) to get booked time slots
--WITH BookedSlots AS (
--  SELECT
--    dentist_id,
--    appointment_start_time AS booked_start_time,
--    DATEADD(MINUTE, 30, appointment_start_time) AS booked_end_time
--  FROM
--    Appointment
--  WHERE
--    dentist_id = @dentistId
--)

---- Select available time slots
--SELECT
--  TIME AS available_start_time,
--  DATEADD(MINUTE, 30, TIME) AS available_end_time
--FROM
--(
--    SELECT
--        TOP 48
--        ROW_NUMBER() OVER (ORDER BY number) AS row_number,
--        DATEADD(MINUTE, 30 * (ROW_NUMBER() - 1), CAST('00:00' AS TIME)) AS TIME
--    FROM
--        master.dbo.spt_values
--    WHERE
--        TYPE = 'P'
--  ) AS AllSlots
--WHERE
--  NOT EXISTS (
--    -- Exclude booked time slots
--    SELECT
--      1
--    FROM
--      BookedSlots
--    WHERE
--      AllSlots.TIME BETWEEN BookedSlots.booked_start_time AND BookedSlots.booked_end_time
--  )
--ORDER BY
--  available_start_time;

--SELECT
--  FORMAT(personal_appointment_start_time, 'hh:mm:ss') AS start_time,
--  FORMAT(personal_appointment_end_time, 'hh:mm:ss') AS end_time,
--  personal_appointment_start_time, personal_appointment_end_time
--FROM personalAppointment
--ORDER BY personal_appointment_start_time;

--SELECT
--  CONVERT(VARCHAR(19), personal_appointment_start_time, 108) AS start_time,
--  CONVERT(VARCHAR(19), personal_appointment_end_time, 108) AS end_time,
--  personal_appointment_start_time, personal_appointment_end_time
--FROM personalAppointment
--ORDER BY personal_appointment_start_time;


--SELECT
--  FORMAT(personal_appointment_start_time, 'HH:mm') AS start_time,
--  FORMAT(personal_appointment_end_time, 'HH:mm') AS end_time
--FROM personalAppointment
--WHERE personal_appointment_start_time > GETDATE() -- Only show future appointments
--ORDER BY personal_appointment_start_time;

--DECLARE @startTime TIME = CAST('00:00' AS TIME);
--DECLARE @endTime TIME = CAST('23:59' AS TIME);

--SELECT
--  FORMAT(@startTime, 'HH:mm') AS start_time,
--  FORMAT(DATEADD(MINUTE, 30, @startTime), 'HH:mm') AS end_time
--FROM master..spt_values
--WHERE @startTime <= @endTime
--AND NOT EXISTS (
--  SELECT 1
--  FROM personalAppointment
--  WHERE
--    personal_appointment_start_time BETWEEN @startTime AND DATEADD(MINUTE, 30, @startTime)
--    OR personal_appointment_end_time BETWEEN @startTime AND DATEADD(MINUTE, 30, @startTime)
--);

--SET @startTime = DATEADD(MINUTE, 30, @startTime);

--WHILE @startTime <= @endTime
--BEGIN
--  SELECT
--    FORMAT(@startTime, 'HH:mm') AS start_time,
--    FORMAT(DATEADD(MINUTE, 30, @startTime), 'HH:mm') AS end_time
--  FROM master..spt_values
--  WHERE @startTime <= @endTime
--  AND NOT EXISTS (
--    SELECT 1
--    FROM personalAppointment
--    WHERE
--      personal_appointment_start_time BETWEEN @startTime AND DATEADD(MINUTE, 30, @startTime)
--      OR personal_appointment_end_time BETWEEN @startTime AND DATEADD(MINUTE, 30, @startTime)
--  );
--  SET @startTime = DATEADD(MINUTE, 30, @startTime);
--END;

