USE QLPHONGKHAMNHAKHOA
GO
--thêm tài khoản --cài proc cho status
--chỉnh sửa tài khoản -- cài view
--thêm nhân viên trong bệnh viện -- nếu là bác sĩ thì thêm vào bảng bác sĩ
--thêm người nếu là bệnh nhân thì thêm người đó vào bảng bệnh nhân
--thêm medical record cho bệnh nhân phải có appointment có trc và bệnh nhân đã tồn tại
--không đc thêm appointment mới trùng với appointment đã có sẵn -- kiểm tra thông tin bệnh nhân bác sĩ khi thêm
--dịch vụ và thuốc phải tồn tại, chưa hết hạn thì mới được thêm và đơn thuốc và danh sách dịch vụ khám cho bệnh nhân
--bill tính cho phiếu khám của bệnh nhân đã được lập và gí tiền phải trùng khớp với tiền của dịch vụ và tiền tiền thuốc (kiểm tra và tính)
--nếu bác sĩ thay đổi thuốc cho bệnh nhân thì bill phải được cập nhật lại
--tạo function để hiển thị lịch rảnh của bác sĩ vào thời gian mà bệnh nhân đã chọn trước

CREATE PROCEDURE insertPersonalAppointment
	@personalAppointmentStartTime time,
	@personalAppointmentEndTime time,
	@personalAppointmentDate date,
	@dentistID char(5)
AS
BEGIN
	DECLARE @new_personal_appointment_id char(5); 
	IF NOT EXISTS (SELECT * FROM personalAppointment)
	BEGIN
		SET @new_personal_appointment_id = '00001'
	END
	ELSE
	BEGIN
    SELECT @new_personal_appointment_id = RIGHT(MAX(personal_appointment_id) + 1, 5) FROM personalAppointment
	END
	
	INSERT INTO personalAppointment(
		personal_appointment_id,
		personal_appointment_start_time,
		personal_appointment_end_time,
		personal_appointment_date,
		dentist_id)
	VALUES
	(@new_personal_appointment_id,
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
	@username varchar(10),
	@password varchar(15)
AS
BEGIN
	IF EXISTS((SELECT * FROM Account WHERE username = @username))
	BEGIN
        RAISERROR(N'Tên tài khoản đã tồn tại', 16, 1)
		ROLLBACK
		RETURN
    END
	DECLARE @new_account_id char(5);
	IF NOT EXISTS (SELECT * FROM Account)
    BEGIN
        SET @new_account_id = '00001';
    END
    ELSE
		BEGIN
		SELECT @new_account_id = RIGHT(MAX(account_id) + 1, 5)
		FROM Account;
		END

	INSERT INTO Account (
	account_id,
	username,
	password,
	account_status
	)
	VALUES
	(@new_account_id, @username, @password, 1
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
	IF NOT EXISTS((SELECT * FROM Account WHERE username = @username))
	BEGIN
        RAISERROR(N'Tên tài khoản không tồn tại', 16, 1)
		RETURN
    END
	UPDATE Account
	SET username = @username,
	password = @password,
	account_status = @accountStatus
	WHERE account_id = @accountId;
END;

go
CREATE PROCEDURE insertPerson
	@person_name nvarchar(30),
	@person_phone char(10),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_type char(2)
AS
BEGIN
	DECLARE @new_person_id char(5);
	IF NOT EXISTS (SELECT * FROM Person)
    BEGIN
        SET @new_person_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_person_id = RIGHT(MAX(person_id) + 1, 5)
    FROM Person;
	END

    INSERT INTO PERSON
    (person_id, person_name, person_phone ,person_birthday, person_address, person_gender, person_type)
    VALUES
    (@new_person_id, @person_name, @person_phone, @person_birthday, @person_address, @person_gender, @person_type)
END;

go
CREATE PROCEDURE updatePerson
	@person_id char(5),
	@person_name nvarchar(30),
	@person_phone char(10),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_type char(2)
AS
BEGIN
	IF NOT EXISTS((SELECT * FROM Person WHERE person_id = @person_id))
	BEGIN
        RAISERROR(N'ID của người không tồn tại', 16, 1)
		RETURN
    END
    UPDATE PERSON
    SET person_name = @person_name,
		person_phone = @person_phone,
        person_birthday = @person_birthday,
        person_address = @person_address,
        person_gender = @person_gender,
        person_type = @person_type
    WHERE person_id = @person_id

END;

go
CREATE PROCEDURE insertPatient
	@person_name nvarchar(30),
	@person_birthday DATE,
	@person_address nvarchar(40),
	@person_gender nvarchar(3),
	@person_phone char(10)
AS
BEGIN
	DECLARE @new_patient_id char(5);
	IF NOT EXISTS (SELECT * FROM PATIENT)
    BEGIN
        SET @new_patient_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_patient_id = RIGHT(MAX(account_id) + 1, 5)
    FROM Account;
	END

    INSERT INTO PERSON
    (person_id, person_name, person_phone, person_birthday, person_address, person_gender, person_type)
    VALUES
    (@new_patient_id, @person_name, @person_phone, @person_birthday, @person_address, @person_gender, 'PA')
	INSERT INTO PATIENT
    (patient_id)
    VALUES
    (@new_patient_id)
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
	IF NOT EXISTS((SELECT * FROM Person WHERE person_id = @person_id))
	BEGIN
        RAISERROR(N'ID của bệnh nhân không tồn tại', 16, 1)
		RETURN
    END
    UPDATE PERSON
    SET person_name = @person_name,
		person_phone = @person_phone,
        person_birthday = @person_birthday,
        person_address = @person_address,
        person_gender = @person_gender,
        person_type = @person_type
    WHERE person_id = @person_id

END;

go
CREATE PROCEDURE insertAppointment
	@patientID char(5),
	@dentistID char(5),
	@appointmentID char(5),
	@appointmentStartTime time,
	@appointmentStatus bit,
	@appointmentNumber int,
	@appointmentDate date
AS
BEGIN
	DECLARE @new_appointment_id char(5);

	IF NOT EXISTS (SELECT * FROM Appointment)
    BEGIN
        SET @new_appointment_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_appointment_id = RIGHT(MAX(appointment_id) + 1, 5)
    FROM Appointment;
	END

	INSERT INTO Appointment (
	patient_id,
	dentist_id,
	appointment_id,
	appointment_start_time,
	appointment_status,
	appointment_number,
	appointment_date
	)
	VALUES
	(@new_appointment_id,
	@dentistID,
	@appointmentID,
	@appointmentStartTime,
	@appointmentStatus,
	@appointmentNumber,
	@appointmentDate);
END;

go
CREATE PROCEDURE insertMedicalRecord
	@examinationDate date,
	@payStatus bit,
	@patientID char(5),
	@dentistID char(5),
	@appointmentID char(5)
AS
BEGIN
	DECLARE @new_medical_record_id char(5);
	IF NOT EXISTS (SELECT * FROM MedicalRecord)
    BEGIN
        SET @new_medical_record_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_medical_record_id = RIGHT(MAX(medical_record_id) + 1, 5)
    FROM MedicalRecord;
	END

	INSERT INTO MedicalRecord (
	medical_record_id,
	examination_date,
	pay_status,
	patient_id,
	dentist_id,
	appointment_id
	)
	VALUES
	(@new_medical_record_id,
	@examinationDate,
	@payStatus,
	@patientID,
	@dentistID,
	@appointmentID);
END;

go
CREATE PROCEDURE insertBill
	@serviceCost money,
	@appointmentCost money,
	@drugsCost money,
	@costTotal money,
	@paymentDate date,
	@patientID char(5),
	@medicalRecordID char(5)
AS
BEGIN
	DECLARE @new_bill_id char(5);
	IF NOT EXISTS (SELECT * FROM Bill)
    BEGIN
        SET @new_bill_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_bill_id = RIGHT(MAX(bill_id) + 1, 5)
    FROM Bill;
	END 

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
	(@new_bill_id,
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
	@serviceName nvarchar(30),
	@cost money
AS
BEGIN
	DECLARE @new_service_id char(5);
	IF NOT EXISTS (SELECT * FROM Service)
    BEGIN
        SET @new_service_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_service_id = RIGHT(MAX(service_id) + 1, 5)
    FROM Service;
	END
	INSERT INTO [Service] (
	service_id,
	service_name,
	cost
	)
	VALUES
	(@new_service_id,
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
	@unit varchar(5),
	@drugName nvarchar(30),
	@indication nvarchar(50),
	@expirationDate date,
	@price money,
	@drugStockQuantity int
)
AS
BEGIN
	DECLARE @new_drug_id char(5);
	IF NOT EXISTS (SELECT * FROM DRUG)
    BEGIN
        SET @new_drug_id = '00001';
    END
    ELSE
    BEGIN
    SELECT @new_drug_id = RIGHT(MAX(drug_id) + 1, 5)
    FROM Drug;
	END

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
	@new_drug_id,
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
