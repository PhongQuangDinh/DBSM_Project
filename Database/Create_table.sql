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
	[password] varchar(15),
	account_status BIT,
	[role] char(2)

	CONSTRAINT PK_Account
	PRIMARY KEY (account_id)
)

--table ADMIN
CREATE TABLE [Admin]
(
	account_id char(5),
	admin_name nvarchar(30)

	CONSTRAINT PK_Admin
	PRIMARY KEY(account_id)
)

--table STAFF
CREATE TABLE Staff
(
	account_id char(5),
	staff_name nvarchar(30)

	CONSTRAINT PK_Staff
	PRIMARY KEY(account_id)
)

--table DENTIST
CREATE TABLE Dentist
(
	account_id char(5),
	dentist_name nvarchar(30)

	CONSTRAINT PK_Dentist
	PRIMARY KEY(account_id)
)

--table PersionalAppointment
CREATE TABLE PersionalAppointment
(
	persional_appointment_id char(5),
	persional_appointment_start_time time NOT NULL,
	persional_appointment_end_time time NOT NULL,
	persional_appointment_date date,
	dentist_id char(5)

	CONSTRAINT PK_PersionalAppointment
	PRIMARY KEY(persional_appointment_id)
)
--table PATIENT
CREATE TABLE Patient
(
	patient_id char(5),
	patient_name nvarchar(30),
	patient_birthday DATE,
	patient_address nvarchar(40),
	patient_phone char(10),
	patient_gender nvarchar(3)

	CONSTRAINT PK_Patient
	PRIMARY KEY(patient_id)
)


--table APPOINTMENT
CREATE TABLE Appointment
(
	patient_id char(5),
	dentist_id char(5),
	appointment_id char(5),
	appointment_start_time time NOT NULL,
	appointment_end_time time NOT NULL,
	appointment_date date

	CONSTRAINT PK_Appointment
	PRIMARY KEY(patient_id, dentist_id, appointment_id)
)

--table MEDICAL_RECORD
CREATE TABLE MedicalRecord
(
	medical_record_id char(5),
	examination_date date,
	pay_status bit,
	patient_id char(5),
	dentist_id char(5),
	appointment_id char(5)

	CONSTRAINT PK_MedicalRecord
	PRIMARY KEY (medical_record_id)
)

--table BILL
CREATE TABLE Bill
(
	bill_id char(5),
	service_cost money,
	appointment_cost money,
	drugs_cost money,
	cost_total money,
	payment_date date,
	patient_id char(5),
	medical_record_id char(5)

	CONSTRAINT PK_Bill
	PRIMARY KEY(bill_id)
)

--table SERVICE
CREATE TABLE [Service]
(
	service_id char(5),
	[service_name] nvarchar(15),
	cost money

	CONSTRAINT PK_Service
	PRIMARY KEY(service_id)
)


--table service_list
CREATE TABLE ServiceList
(
	service_id char(5),
	medical_record_id char(5),
	service_quantity int

	CONSTRAINT PK_SERVICES
	PRIMARY KEY	(medical_record_id, service_id)
)
--table PRESCRIPTION
CREATE TABLE Prescription
(
	drug_id char(5),
	medical_record_id char(5),
	drug_quantity int NOT NULL Check (drug_quantity>=1)

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
	price money,
	drug_stock_quantity int

	CONSTRAINT PK_Drug
	PRIMARY KEY (drug_id)
)


--rang buoc
ALTER TABLE [Admin]
ADD
	CONSTRAINT FK_Admin_Account
	FOREIGN KEY (account_id)
	REFERENCES Account
ALTER TABLE Staff
ADD
	CONSTRAINT FK_Staff_Account
	FOREIGN KEY (account_id)
	REFERENCES Account
ALTER TABLE Dentist
ADD
	CONSTRAINT FK_Dentist_Account
	FOREIGN KEY (account_id)
	REFERENCES Account
ALTER TABLE Patient
ADD
	CONSTRAINT FK_Patinet_Account
	FOREIGN KEY (patient_id)
	REFERENCES Account
ALTER TABLE PersionalAppointment
ADD
	CONSTRAINT FK_PersionalAppointment_Dentist
	FOREIGN KEY (dentist_id)
	REFERENCES Dentist

ALTER TABLE Bill
ADD
	CONSTRAINT FK_Bill_Patient
	FOREIGN KEY (patient_id)
	REFERENCES Patient,

	CONSTRAINT FK_Bill_MedicalRecord
	FOREIGN KEY (medical_record_id)
	REFERENCES MedicalRecord

ALTER TABLE MedicalRecord
ADD
	CONSTRAINT FK_MedicalRecord_Patient
	FOREIGN KEY (patient_id)
	REFERENCES Patient,

	CONSTRAINT FK_MedicalRecord_Dentist
	FOREIGN KEY (dentist_id)
	REFERENCES Dentist,
	
	CONSTRAINT FK_MedicalRecord_Appointment
	FOREIGN KEY (patient_id, dentist_id, appointment_id)
	REFERENCES Appointment


ALTER TABLE Appointment
ADD
	CONSTRAINT FK_Appointment_Patient
	FOREIGN KEY (patient_id)
	REFERENCES Patient,

	CONSTRAINT FK_Appointment_Dentist
	FOREIGN KEY (dentist_id)
	REFERENCES Dentist

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