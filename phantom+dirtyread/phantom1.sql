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
      RAISERROR(N'Dịch vụ không tồn tại', 16, 1);
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
    RAISERROR(N'Thuốc không tồn tại.', 16, 1);
    RETURN;
  END

  if (@drug_quantity > (select drug_stock_quantity from Drug where drug_id = @drug_id))
  begin
    RAISERROR(N'Thuốc trong kho không đủ cấp', 16, 1);
    RETURN;
  end
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

go
create or alter proc sp_XemHoSoBenhNhan
					@patient_id char(5)
as
begin tran
	begin try
		if not exists(select 1 from Person de where de.person_id = @patient_id)
		begin
			raiserror(N'Bệnh nhân không tồn tại', 16, 1)
			rollback tran
			return
		end
		if not exists(select 1 from Person de where de.person_id = @patient_id and de.person_type = 'PA')
			begin
				raiserror(N'Không phải là bệnh nhân', 16, 1)
				rollback tran
				return
			end
			select mr.medical_record_id, pa.person_name as patientName, pa.person_birthday, pa.person_address, 
						pa.person_phone, mr.examination_date, (select person_name from Person where person_id = mr.dentist_id) as dentist
						from MedicalRecord mr join Person pa on pa.person_id = mr.patient_id
						where mr.patient_id = @patient_id

			SELECT mr.medical_record_id,mr.examination_date, sl.service_quantity, s.service_name
				FROM MedicalRecord mr
				INNER JOIN ServiceList sl ON mr.medical_record_id = sl.medical_record_id
				INNER JOIN Service s ON sl.service_id = s.service_id
				where mr.patient_id = @patient_id

			-- Show medical records with prescribed drugs and details
			SELECT mr.medical_record_id,mr.examination_date, p.drug_quantity, d.drug_name
				FROM MedicalRecord mr
				INNER JOIN Prescription p ON mr.medical_record_id = p.medical_record_id
				INNER JOIN Drug d ON p.drug_id = d.drug_id
				where mr.patient_id = @patient_id

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

go
CREATE or alter PROCEDURE insertMedicalRecord
	@examinationDate date,
	@payStatus bit,
	@patientID char(5),
	@dentistID char(5),
	@appointmentID char(5)
AS
SET TRAN ISOLATION LEVEL REPEATABLE READ
--SET TRAN ISOLATION LEVEL SERIALIZABLE
BEGIN TRAN
	BEGIN TRY
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
	WAITFOR DELAY '0:0:05'
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
	END TRY
	BEGIN CATCH
		PRINT N'LỖI HỆ THỐNG'
		ROLLBACK TRAN
		RETURN 1
	END CATCH
COMMIT TRAN
RETURN 0

exec sp_XemHoSoBenhNhan '00021'
exec insertMedicalRecord '2023-11-29',1,'00021','00016','00050'
exec AddPrescription '00041','DR001',1
exec AddServiceList '00041','SV001',1
exec sp_XemHoSoBenhNhan '00021'

delete Prescription
where medical_record_id = '00041'
delete ServiceList 
where medical_record_id = '00041'
delete MedicalRecord
where medical_record_id = '00041'

select * from MedicalRecord where medical_record_id = '00041'

--select mr.medical_record_id, pa.person_name as patientName, pa.person_birthday, pa.person_address, 
--			pa.person_phone, mr.examination_date, (select person_name from Person where person_id = mr.dentist_id) as dentist
--			from MedicalRecord mr join Person pa on pa.person_id = mr.patient_id
--			where mr.patient_id = '00021'

--SELECT mr.medical_record_id,mr.examination_date, sl.service_quantity, s.service_name
--	FROM MedicalRecord mr
--	INNER JOIN ServiceList sl ON mr.medical_record_id = sl.medical_record_id
--	INNER JOIN Service s ON sl.service_id = s.service_id
--	where mr.patient_id = '00021'

---- Show medical records with prescribed drugs and details
--SELECT mr.medical_record_id,mr.examination_date, p.drug_quantity, d.drug_name
--	FROM MedicalRecord mr
--	INNER JOIN Prescription p ON mr.medical_record_id = p.medical_record_id
--	INNER JOIN Drug d ON p.drug_id = d.drug_id
--	where mr.patient_id = '00021'

select * from MedicalRecord where patient_id = '00021'