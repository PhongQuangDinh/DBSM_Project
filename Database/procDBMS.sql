USE QLPHONGKHAMNHAKHOA
GO

CREATE PROCEDURE insertPersonalAppointment
	@personalAppointmentID char(5),
	@personalAppointmentStartTime time,
	@personalAppointmentEndTime time,
	@personalAppointmentDate date,
	@dentistID char(5)
AS
BEGIN
	INSERT INTO personalAppointment(
		personal_appointment_id,
		personal_appointment_start_time,
		personal_appointment_end_time,
		personal_appointment_date,
		dentist_id)
	VALUES
	(@personalAppointmentID,
	@personalAppointmentStartTime,
	@personalAppointmentEndTime,
	@personalAppointmentDate,
	@dentistID);
END;

go
CREATE PROCEDURE deletePersonalAppointment
	@personalAppointmentID char(5)
AS
BEGIN
DELETE FROM personalAppointment
WHERE personal_appointment_id = @personalAppointmentID;
END;

go
CREATE PROCEDURE updatePersonalAppointment
	@personalAppointmentID char(5),
	@personalAppointmentStartTime time,
	@personalAppointmentEndTime time,
	@personalAppointmentDate date,
	@dentistID char(5)
AS
BEGIN
	UPDATE personalAppointment
	SET personal_appointment_start_time = @personalAppointmentStartTime,
	personal_appointment_end_time = @personalAppointmentEndTime,
	personal_appointment_date = @personalAppointmentDate,
	dentist_id = @dentistID
	WHERE personal_appointment_id = @personalAppointmentID;
END;

go
CREATE PROCEDURE insertAccount
	@accountId char(5),
	@username varchar(10),
	@password varchar(15),
	@accountStatus BIT
AS
BEGIN
	INSERT INTO Account (
	account_id,
	username,
	password,
	account_status
	)
	VALUES
	(@accountId,
	@username,
	@password,
	@accountStatus
	);
END;

go
CREATE PROCEDURE updateAccount
	@accountId char(5),
	@username varchar(10),
	@password varchar(15),
	@accountStatus BIT
AS
BEGIN
	UPDATE Account
	SET username = @username,
	password = @password,
	account_status = @accountStatus
	WHERE account_id = @accountId;
END;

go
CREATE PROCEDURE insertPerson
	@person_id char(5),
	@person_name nvarchar(30),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_type char(2)
AS
BEGIN
    INSERT INTO PERSON
    (person_id, person_name, person_birthday, person_address, person_gender, person_type)
    VALUES
    (@person_id, @person_name, @person_birthday, @person_address, @person_gender, @person_type)
END;

go
CREATE PROCEDURE updatePerson
	@person_id char(5),
	@person_name nvarchar(30),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_type char(2)
AS
BEGIN
    UPDATE PERSON
    SET person_name = @person_name,
        person_birthday = @person_birthday,
        person_address = @person_address,
        person_gender = @person_gender,
        person_type = @person_type
    WHERE person_id = @person_id

END;

go
CREATE PROCEDURE insertPatient
	@person_id char(5),
	@person_name nvarchar(30),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_type char(2),
	@person_phone char(10)
AS
BEGIN
    INSERT INTO PERSON
    (person_id, person_name, person_birthday, person_address, person_gender, person_type, person_phone)
    VALUES
    (@person_id, @person_name, @person_birthday, @person_address, @person_gender, @person_type, @person_phone)
	INSERT INTO PATIENT
    (patient_id, patient_phone)
    VALUES
    (@person_id, @person_phone)
END;

go
CREATE PROCEDURE updatePatient
	@person_id char(5),
	@person_name nvarchar(30),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_type char(2),
	@person_phone char(10)
AS
BEGIN
    UPDATE PERSON
    SET person_name = @person_name,
        person_birthday = @person_birthday,
        person_address = @person_address,
        person_gender = @person_gender,
        person_type = @person_type,
        person_phone = @person_phone
    WHERE person_id = @person_id
	UPDATE PATIENT
	SET patient_phone = @person_phone
	WHERE patient_id = @person_id
END;

go
CREATE PROCEDURE insertAppointment
	@patientID char(5),
	@dentistID char(5),
	@appointmentID char(5),
	@appointmentStartTime time,
	@appointmentEndTime time,
	@appointmentDate date
AS
BEGIN
	INSERT INTO Appointment (
	patient_id,
	dentist_id,
	appointment_id,
	appointment_start_time,
	appointment_end_time,
	appointment_date
	)
	VALUES
	(@patientID,
	@dentistID,
	@appointmentID,
	@appointmentStartTime,
	@appointmentEndTime,
	@appointmentDate);
END;

go
CREATE PROCEDURE insertMedicalRecord
	@medicalRecordID char(5),
	@examinationDate date,
	@payStatus bit,
	@patientID char(5),
	@dentistID char(5),
	@appointmentID char(5)
AS
BEGIN
	INSERT INTO MedicalRecord (
	medical_record_id,
	examination_date,
	pay_status,
	patient_id,
	dentist_id,
	appointment_id
	)
	VALUES
	(@medicalRecordID,
	@examinationDate,
	@payStatus,
	@patientID,
	@dentistID,
	@appointmentID);
END;

go
CREATE PROCEDURE insertBill
	@billID char(5),
	@serviceCost money,
	@appointmentCost money,
	@drugsCost money,
	@costTotal money,
	@paymentDate date,
	@patientID char(5),
	@medicalRecordID char(5)
AS
BEGIN
	INSERT INTO Bill (
	bill_id,
	service_cost,
	appointment_cost,
	drugs_cost,
	cost_total,
	payment_date,
	patient_id,
	medical_record_id
	)
	VALUES
	(@billID,
	@serviceCost,
	@appointmentCost,
	@drugsCost,
	@costTotal,
	@paymentDate,
	@patientID,
	@medicalRecordID);
END;

go
CREATE PROCEDURE insertService
	@serviceID char(5),
	@serviceName nvarchar(30),
	@cost money
AS
BEGIN
	INSERT INTO [Service] (
	service_id,
	service_name,
	cost
	)
	VALUES
	(@serviceID,
	@serviceName,
	@cost);
END;

go
CREATE PROCEDURE updateService
	@serviceID char(5),
	@serviceName nvarchar(30),
	@cost money
AS
BEGIN
	UPDATE [Service]
	SET service_name = @serviceName,
	cost = @cost
	WHERE service_id = @serviceID;
END;

go
CREATE PROCEDURE deleteService
	@serviceID char(5)
AS
BEGIN
	DELETE FROM [Service]
	WHERE service_id = @serviceID;
END;

go
CREATE PROCEDURE insertDrug
(
	@drugID char(5),
	@unit varchar(5),
	@drugName nvarchar(30),
	@indication nvarchar(50),
	@expirationDate date,
	@price money,
	@drugStockQuantity int
)
AS
BEGIN
	INSERT INTO Drug (
	drug_id,
	unit,
	drug_name,
	indication,
	expiration_date,
	price,
	drug_stock_quantity
	)
	VALUES
	(
	@drugID,
	@unit,
	@drugName,
	@indication,
	@expirationDate,
	@price,
	@drugStockQuantity
	);
END;

go
CREATE PROCEDURE updateDrug
(
	@drugID char(5),
	@unit varchar(5),
	@drugName nvarchar(30),
	@indication nvarchar(50),
	@expirationDate date,
	@price money,
	@drugStockQuantity int
)
AS
BEGIN
	UPDATE Drug
	SET unit = @unit,
	drug_name = @drugName,
	indication = @indication,
	expiration_date = @expirationDate,
	price = @price,
	drug_stock_quantity = @drugStockQuantity
	WHERE drug_id = @drugID;
END;

go
CREATE PROCEDURE deleteDrug
(
	@drugID char(5)
)
AS
BEGIN
	DELETE FROM Drug
	WHERE drug_id = @drugID;
END;
