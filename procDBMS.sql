USE QLPHONGKHAMNHAKHOA
GO
--thêm tài khoản --cài proc cho status
--chỉnh sửa tài khoản -- cài view
--thêm nhân viên trong bệnh viện -- nếu là bác sĩ thì thêm vào bảng bác sĩ
--thêm người nếu là bệnh nhân thì thêm người đó vào bảng bệnh nhân
--thêm medical record cho bệnh nhân phải có appointment có trc và bệnh nhân đã tồn tại -- sau khi thêm medical record thì appointment status phải được cập nhật
--không đc thêm appointment mới trùng với appointment đã có sẵn -- kiểm tra thông tin bệnh nhân bác sĩ khi thêm
--dịch vụ và thuốc phải tồn tại, chưa hết hạn thì mới được thêm và đơn thuốc và danh sách dịch vụ khám cho bệnh nhân
--bill tính cho phiếu khám của bệnh nhân đã được lập và gí tiền phải trùng khớp với tiền của dịch vụ và tiền tiền thuốc (kiểm tra và tính)
----nếu bác sĩ thay đổi thuốc cho bệnh nhân thì bill phải được cập nhật lại
--tạo function để hiển thị lịch rảnh của bác sĩ vào thời gian mà bệnh nhân đã chọn trước

CREATE or alter PROCEDURE insertPersonalAppointment
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
		SELECT @new_personal_appointment_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(personal_appointment_id) from personalAppointment), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
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
CREATE or alter PROCEDURE deletePersonalAppointment
	@personalAppointmentID char(5)
AS
BEGIN
DELETE FROM personalAppointment
WHERE personal_appointment_id = @personalAppointmentID;
END;

go
CREATE or alter PROCEDURE updatePersonalAppointment
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
		SELECT @new_account_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(account_id) from Account), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
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
CREATE or alter PROCEDURE insertPerson
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
		SELECT @new_person_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(person_id) from Person), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
	END

    INSERT INTO PERSON
    (person_id, person_name, person_phone ,person_birthday, person_address, person_gender, person_type)
    VALUES
    (@new_person_id, @person_name, @person_phone, @person_birthday, @person_address, @person_gender, @person_type)
END;

go
CREATE or alter PROCEDURE updatePerson
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
CREATE or alter PROCEDURE insertPatient
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
    SELECT @new_patient_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(person_id) from Person), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
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
CREATE or alter PROCEDURE updatePatient
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
CREATE or alter PROCEDURE insertAppointment
	@patientID char(5),
	@dentistID char(5),
	@appointmentStartTime time,
	@appointmentDate date
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM Patient WHERE patient_id = @patientID)
	BEGIN
		raiserror(N'Bệnh nhân không tồn tại', 16, 1)
		RETURN
	END
	IF NOT EXISTS (SELECT * FROM Dentist WHERE dentist_id = @dentistID)
	BEGIN
		raiserror(N'Bác sĩ không tồn tại', 16, 1)
		RETURN
	END
	DECLARE @new_appointment_id char(5);

	IF NOT EXISTS (SELECT * FROM Appointment)
    BEGIN
        SET @new_appointment_id = '00001';
    END
    ELSE
    BEGIN
		SELECT @new_appointment_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(appointment_id) from Appointment), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
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
	(@patientID,
	@dentistID,
	@new_appointment_id,
	@appointmentStartTime,
	0,
	DATEDIFF(MINUTE, '09:00:00', @appointmentStartTime)/30 + 1,
	@appointmentDate);
END;

go
CREATE or alter PROCEDURE insertMedicalRecord
	@examinationDate date,
	@payStatus bit,
	@patientID char(5),
	@dentistID char(5),
	@appointmentID char(5)
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM Appointment WHERE appointment_id = @appointmentID)
		RETURN
	DECLARE @new_medical_record_id char(5);
	IF NOT EXISTS (SELECT * FROM MedicalRecord)
    BEGIN
        SET @new_medical_record_id = '00001';
    END
    ELSE
    BEGIN
	SELECT @new_medical_record_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(medical_record_id) from MedicalRecord), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
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

	UPDATE Appointment
	SET appointment_status = 1
	WHERE appointment_id = @appointmentID
END;

go
CREATE or alter PROCEDURE insertBill
	@paymentDate date,
	@patientID char(5),
	@medicalRecordID char(5)
AS
BEGIN

	declare @drugsCost float = 
	(select SUM(drug.price * pres.drug_quantity)
	from MedicalRecord md join Prescription pres on pres.medical_record_id = md.medical_record_id
	join Drug drug on drug.drug_id = pres.drug_id
	where md.medical_record_id = @medicalRecordID)

	declare @serviceCost float = 
	(select SUM(sv.cost * svl.service_quantity)
	from MedicalRecord md join ServiceList svl on svl.medical_record_id = md.medical_record_id
	join Service sv on sv.service_id = svl.service_id
	where md.medical_record_id = @medicalRecordID)

	declare @appointmentCost float
	set @appointmentCost = 50000

	declare @costTotal float
	set @costTotal = @appointmentCost + @drugsCost + @serviceCost

	DECLARE @new_bill_id char(5);
	IF NOT EXISTS (SELECT * FROM Bill)
    BEGIN
        SET @new_bill_id = '00001';
    END
    ELSE
    BEGIN
	SELECT @new_bill_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(bill_id) from Bill), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
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
CREATE or alter PROCEDURE insertService
	@serviceName nvarchar(30),
	@cost money
AS
BEGIN
	DECLARE @new_service_id char(5);
	IF NOT EXISTS (SELECT * FROM Service)
    BEGIN
        SET @new_service_id = 'SV001';
    END
    ELSE
    BEGIN
		SET @new_service_id = 'SV' + RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(service_id) FROM Service), 3, 3) AS INT) + 1 AS VARCHAR(3)), 3)
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
CREATE or alter PROCEDURE insertDrug
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
        SET @new_drug_id = 'DR001';
    END
    ELSE
    BEGIN
		SET @new_drug_id = 'DR' + RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(drug_id) FROM Drug), 3, 3) AS INT) + 1 AS VARCHAR(3)), 3)
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
CREATE or alter PROCEDURE updateDrug
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
CREATE or alter PROCEDURE deleteDrug
(
	@drugID char(5)
)
AS
BEGIN
	DELETE FROM Drug
	WHERE drug_id = @drugID;
END;


go
CREATE or alter PROCEDURE listDentist
	@date date,
	@time time
AS
BEGIN
	declare @tmp time
	set @tmp = DATEADD(minute, -30, @time)
	select pa.dentist_id from personalAppointment pa join Appointment a on pa.dentist_id = a.dentist_id
	where personal_appointment_date = @date and personal_appointment_start_time <= @time and personal_appointment_end_time >= @tmp
	and @time != a.appointment_start_time
END;

--exec listDentist @date = '2023-11-28', @time = '10:00:00'

go
CREATE or alter PROCEDURE AddServiceList(
   @medical_record_id char(5),
   @service_id char(5),
   @service_quantity int
)
AS
BEGIN
   IF NOT EXISTS (SELECT *
   FROM Service
   WHERE service_id = @service_id)
   BEGIN
      RAISERROR('Dịch vụ không tồn tại', 16, 1);
      RETURN;
   END

   INSERT INTO ServiceList
   (
      medical_record_id,
      service_id,
      service_quantity
   )
   VALUES
   (
      @medical_record_id,
      @service_id,
      @service_quantity
   );
END;

go
CREATE or alter PROCEDURE AddPrescription(
  @medical_record_id char(5),
  @drug_id char(5),
  @drug_quantity int
)
AS
BEGIN
  IF NOT EXISTS (SELECT * FROM Drug WHERE drug_id = @drug_id)
  BEGIN
    RAISERROR('Thuốc không tồn tại.', 16, 1);
    RETURN;
  END

  -- Check if expiry date is valid
  DECLARE @expiryDate date;
  SELECT @expiryDate = expiration_date FROM Drug WHERE drug_id = @drug_id;
  IF @expiryDate < GETDATE()
  BEGIN
    RAISERROR('Thuốc đã hết hạn.', 16, 1, @drug_id);
    RETURN;
  END

  -- Insert prescription and quantity
  INSERT INTO Prescription (
    medical_record_id,
    drug_id,
    drug_quantity
  )
  VALUES (
    @medical_record_id,
    @drug_id,
    @drug_quantity
  );
END;


exec insertMedicalRecord
	@examinationDate = '2023-12-05',
	@payStatus = 0, -- 1: Paid, 0: Unpaid
	@patientID = '00018',
	@dentistID = '00012',
	@appointmentID = '00001'

exec AddServiceList
	@medical_record_id = '00001',
	@service_id = 'SV300',
	@service_quantity = 2;


exec AddPrescription
	@medical_record_id = '00001',
	@drug_id = 'DR001',
	@drug_quantity = 2;
