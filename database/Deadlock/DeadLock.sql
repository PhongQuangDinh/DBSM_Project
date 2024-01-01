use QLPHONGKHAMNHAKHOA
go

--bệnh nhân xem lịch rảnh của bác sĩ để thêm lịch hẹn

CREATE or alter PROCEDURE BenhNhanThemCuocHen
	@patientPhone char(10),
	@dentistID char(5),
	@appointmentStartTime time,
	@appointmentDate date
AS
BEGIN tran
	SET TRANSACTION ISOLATION LEVEL Serializable
	begin try

		IF NOT EXISTS (SELECT * FROM Patient pa join Person pe on pe.person_id = pa.patient_id WHERE pe.person_phone = @patientPhone)
		begin	
			raiserror(N'Bệnh nhân không tồn tại', 16, 1)
			rollback
			RETURN
		end

		IF NOT EXISTS (SELECT * FROM Dentist WHERE dentist_id = @dentistID)
		begin
			raiserror(N'Bác sĩ không tồn tại', 16, 1)
			rollback
			RETURN
		end
		

		if not exists (SELECT 1
						FROM personalAppointment per
						  WHERE per.dentist_id = @dentistID
							AND per.personal_appointment_date = @appointmentDate
							AND LEFT(CONVERT(VARCHAR(5), @appointmentStartTime), 5) 
								NOT IN (SELECT LEFT(CONVERT(VARCHAR(5), app1.appointment_start_time), 5)
										FROM Appointment app1
										WHERE app1.dentist_id = per.dentist_id AND @appointmentDate = app1.appointment_date))
			begin
				raiserror(N'Bác sĩ không rảnh vào thời gian đã chọn', 16, 1)
				rollback
				return
			end


		declare @patientID char(5)
		SELECT @patientID = pe.person_id FROM Person pe WHERE pe.person_phone = @patientPhone

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

		waitfor DELAY '0:0:10'

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
	end try

	BEGIN CATCH 
		DECLARE @ErrorMsg VARCHAR(2000)
		SELECT @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE()
		RAISERROR(@ErrorMsg, 16,1)
		ROLLBACK TRAN
		RETURN
	END CATCH
commit tran
go


--bác sĩ thêm cuộc hẹn cá nhân của mình
CREATE or alter PROCEDURE BacSiThemCuocHen
	@dentistID char(5),
	@appointmentStartTime time,
	@appointmentDate date
AS
BEGIN tran
	SET TRANSACTION ISOLATION LEVEL Serializable
	begin try
		IF NOT EXISTS (SELECT * FROM Dentist WHERE dentist_id = @dentistID)
		begin	
			raiserror(N'Bác sĩ không tồn tại', 16, 1)
			rollback
			RETURN
		end
		if not exists (SELECT 1
						FROM personalAppointment per
						  WHERE per.dentist_id = @dentistID
							AND per.personal_appointment_date = @appointmentDate
							AND LEFT(CONVERT(VARCHAR(5), @appointmentStartTime), 5) 
								NOT IN (SELECT LEFT(CONVERT(VARCHAR(5), app1.appointment_start_time), 5)
										FROM Appointment app1
										WHERE app1.dentist_id = per.dentist_id AND @appointmentDate = app1.appointment_date))
			begin
				raiserror(N'Bác sĩ không rảnh vào thời gian đã chọn', 16, 1)
				rollback
				return
			end

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

		waitfor DELAY '0:0:10'

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
		(null,
		@dentistID,
		@new_appointment_id,
		@appointmentStartTime,
		0,
		DATEDIFF(MINUTE, '09:00:00', @appointmentStartTime)/30 + 1,
		@appointmentDate);
	end try

	BEGIN CATCH 
		DECLARE @ErrorMsg VARCHAR(2000)
		SELECT @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE()
		RAISERROR(@ErrorMsg, 16,1)
		ROLLBACK TRAN
		RETURN
	END CATCH
commit tran
go


-- xử lý deadlock

CREATE or alter PROCEDURE BenhNhanThemCuocHen
	@patientPhone char(10),
	@dentistID char(5),
	@appointmentStartTime time,
	@appointmentDate date
AS
BEGIN tran
	SET TRANSACTION ISOLATION LEVEL Serializable
	begin try

		IF NOT EXISTS (SELECT * FROM Patient pa join Person pe on pe.person_id = pa.patient_id WHERE pe.person_phone = @patientPhone)
		begin	
			raiserror(N'Bệnh nhân không tồn tại', 16, 1)
			rollback
			RETURN
		end

		IF NOT EXISTS (SELECT * FROM Dentist WHERE dentist_id = @dentistID)
		begin
			raiserror(N'Bác sĩ không tồn tại', 16, 1)
			rollback
			RETURN
		end
		

		if not exists (SELECT 1
						FROM personalAppointment per
						  WHERE per.dentist_id = @dentistID
							AND per.personal_appointment_date = @appointmentDate
							AND LEFT(CONVERT(VARCHAR(5), @appointmentStartTime), 5) 
								NOT IN (SELECT LEFT(CONVERT(VARCHAR(5), app1.appointment_start_time), 5)
										FROM Appointment app1
										WHERE app1.dentist_id = per.dentist_id AND @appointmentDate = app1.appointment_date))
			begin
				raiserror(N'Bác sĩ không rảnh vào thời gian đã chọn', 16, 1)
				rollback
				return
			end


		declare @patientID char(5)
		SELECT @patientID = pe.person_id FROM Person pe WHERE pe.person_phone = @patientPhone

		DECLARE @new_appointment_id char(5);

		IF NOT EXISTS (SELECT * FROM Appointment WITH (TABLOCK, UPDLOCK))
		BEGIN
			SET @new_appointment_id = '00001';
		END
		ELSE
		BEGIN
			SELECT @new_appointment_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(appointment_id) from Appointment), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
		FROM Appointment;
		END

		waitfor DELAY '0:0:10'

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
	end try

	BEGIN CATCH 
		DECLARE @ErrorMsg VARCHAR(2000)
		SELECT @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE()
		RAISERROR(@ErrorMsg, 16,1)
		ROLLBACK TRAN
		RETURN
	END CATCH
commit tran
go


--bác sĩ thêm cuộc hẹn cá nhân của mình
CREATE or alter PROCEDURE BacSiThemCuocHen
	@dentistID char(5),
	@appointmentStartTime time,
	@appointmentDate date
AS
BEGIN tran
	SET TRANSACTION ISOLATION LEVEL Serializable
	begin try
		IF NOT EXISTS (SELECT * FROM Dentist WHERE dentist_id = @dentistID)
		begin	
			raiserror(N'Bác sĩ không tồn tại', 16, 1)
			rollback
			RETURN
		end
		if not exists (SELECT 1
						FROM personalAppointment per
						  WHERE per.dentist_id = @dentistID
							AND per.personal_appointment_date = @appointmentDate
							AND LEFT(CONVERT(VARCHAR(5), @appointmentStartTime), 5) 
								NOT IN (SELECT LEFT(CONVERT(VARCHAR(5), app1.appointment_start_time), 5)
										FROM Appointment app1
										WHERE app1.dentist_id = per.dentist_id AND @appointmentDate = app1.appointment_date))
			begin
				raiserror(N'Bác sĩ không rảnh vào thời gian đã chọn', 16, 1)
				rollback
				return
			end

		DECLARE @new_appointment_id char(5);

		IF NOT EXISTS (SELECT * FROM Appointment WITH (TABLOCK, UPDLOCK))
		BEGIN
			SET @new_appointment_id = '00001';
		END
		ELSE
		BEGIN
			SELECT @new_appointment_id = RIGHT('00000' + CAST(CAST(SUBSTRING((SELECT MAX(appointment_id) from Appointment), 2, 4) AS INT) + 1 AS VARCHAR(5)), 5)
		FROM Appointment;
		END

		waitfor DELAY '0:0:10'

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
		(null,
		@dentistID,
		@new_appointment_id,
		@appointmentStartTime,
		0,
		DATEDIFF(MINUTE, '09:00:00', @appointmentStartTime)/30 + 1,
		@appointmentDate);
	end try

	BEGIN CATCH 
		DECLARE @ErrorMsg VARCHAR(2000)
		SELECT @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE()
		RAISERROR(@ErrorMsg, 16,1)
		ROLLBACK TRAN
		RETURN
	END CATCH
commit tran
go