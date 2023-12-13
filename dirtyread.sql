go
CREATE or alter PROCEDURE updateAccount
	@username varchar(10),
	@password varchar(15),
	@accountStatus BIT
AS
BEGIN TRAN
	BEGIN TRY
	IF NOT EXISTS((SELECT * FROM Account WHERE username = @username))
	BEGIN
        RAISERROR(N'Tên tài khoản không tồn tại', 16, 1)
		ROLLBACK TRAN
		RETURN
    END
	UPDATE Account
	SET
		password = @password,
		account_status = @accountStatus
	WHERE username = @username;
	WAITFOR DELAY '0:0:05'
	ROLLBACK TRAN 
	RETURN
	END TRY
	BEGIN CATCH
		PRINT N'LỖI HỆ THỐNG'
		ROLLBACK TRAN
		RETURN 1
	END CATCH
COMMIT TRAN
RETURN

go
CREATE or alter PROCEDURE insertAppointment
	@patientID char(5),
	@dentistID char(5),
	@appointmentStartTime time,
	@appointmentDate date
AS
--SET TRAN ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRAN
	BEGIN TRY
	IF EXISTS (SELECT * FROM Account WHERE account_id = @patientID AND account_status = 0)
	BEGIN
			PRINT N'TÀI KHOẢN BỆNH NHÂN ĐÃ BỊ KHÓA'
			ROLLBACK TRAN
			RETURN 
	END
	IF EXISTS (SELECT * FROM Account WHERE account_id = @dentistID AND account_status = 0)
	BEGIN
			PRINT N'TÀI KHOẢN NHA SĨ ĐÃ BỊ KHÓA'
			ROLLBACK TRAN
			RETURN 
	END
	IF NOT EXISTS (SELECT * FROM Account WHERE account_id = @patientID)
	BEGIN
		PRINT  N'Bệnh nhân không tồn tại'
		rollback tran
		RETURN
	END
	IF NOT EXISTS (SELECT * FROM Account WHERE account_id = @dentistID)
	BEGIN
		PRINT  N'Bác sĩ không tồn tại'
		rollback tran
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
	appointment_id,
	patient_id,
	dentist_id,
	appointment_start_time,
	appointment_status,
	appointment_number,
	appointment_date
	)
	VALUES
	(@new_appointment_id,
	@patientID,
	@dentistID,
	@appointmentStartTime,
	0,
	DATEDIFF(MINUTE, '09:00:00', @appointmentStartTime)/30 + 1,
	@appointmentDate);
	END TRY
	BEGIN CATCH
		PRINT N'LỖI HỆ THỐNG'
		ROLLBACK TRAN
	END CATCH
COMMIT TRAN

EXEC updateAccount 'dentist1','123456', 1
EXEC insertAppointment '00033', '00012', '16:30:00', '2023-10-01'
SELECT * FROM	Account WHERE account_id = '00012'
SELECT * FROM Appointment WHERE appointment_id = '00050'


delete Appointment where appointment_id = '00050'