use QLPHONGKHAMNHAKHOA
go


--unrepeatable read: 
----BÁC SĨ xem hồ sơ bệnh án của bệnh nhân mà mình điều trị
create or alter proc sp_XemHoSoBenhNhan
					@DENTIST_ID char(5)
as
begin tran
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	begin try
		if not exists(select 1 from Person de where de.person_id = @DENTIST_ID)
		begin
			raiserror(N'Bác sĩ không tồn tại', 16, 1)
			rollback tran
			return
		end
		if not exists(select 1 from Person de where de.person_id = @DENTIST_ID and de.person_type!='DE')
			begin
				raiserror(N'Không phải là bác sĩ', 16, 1)
				rollback tran
				return
			end
			select pa.person_name as patientName, pa.person_birthday, pa.person_address, pa.person_phone, mr.examination_date
			from MedicalRecord mr join Person pa on pa.person_id = mr.patient_id
			where mr.dentist_id = @DENTIST_ID

			waitfor DELAY '0:0:05'

			select pa.person_name as patientName, pa.person_birthday, pa.person_address, pa.person_phone, mr.examination_date
			from MedicalRecord mr join Person pa on pa.person_id = mr.patient_id
			where mr.dentist_id = @DENTIST_ID
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


----bệnh nhân cập nhật thông tin cá nhân của mình
create or alter proc sp_CapNhatThongTinCaNhan
						@personName nvarchar(30),
						@personPhone char(10),
						@personBirthday DATE,
						@personAddress nvarchar(40)
as
begin tran
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	begin try
		if not exists(select 1 from Person pa where pa.person_phone = @personPhone and pa.person_type = 'PA')
			begin
				raiserror(N'Bệnh nhân không tồn tại', 16, 1)
				rollback tran
				return
			end
		else 
			begin
				update Person
				set person_name = @personName, person_birthday = @personBirthday, person_address = @personAddress
				where person_phone = @personPhone
			end
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

-- CYCLE DEADLOCK

-- --bệnh nhân xem lịch rảnh của bác sĩ để đặt lịch hẹn
-- --admin kiểm tra lịch cá nhân của mình và 

--create or alter proc XemLichRanhBacSi
--				@dateAppointment DATE,
--				@timeAppointment TIME,
--				@dentistID char(5),
--				@patientID char(5)
--as
--begin tran
--	begin try
--		--xem bác sĩ có rảnh vào thời gian đó không
--		begin
--			if not exists(select 1 from Person de where de.person_id = @dentistID)
--			begin
--				raiserror(N'Bác sĩ không tồn tại', 16, 1)
--				rollback tran
--				return
--			end
--			else if not exists(select 1 from Person de where de.person_id = @dentistID and de.person_type!='DE')
--				begin
--					raiserror(N'Không phải bác sĩ', 16, 1)
--					rollback tran
--					return
--				end
--			if not exists(select 1 from personalAppointment per where per.dentist_id = @dentistID and per.personal_appointment_date = @dateAppointment and 
--					LEFT(CONVERT(varchar(5), @timeAppointment), 5) not in (select LEFT(CONVERT(varchar(5), app1.appointment_start_time), 5)
--											from Appointment app1
--											where app1.dentist_id = @dentistID and @dateAppointment = app1.appointment_date))
--							print N'Bác sĩ không có thời gian rảnh vào: ' + LEFT(CONVERT(varchar(5), @timeAppointment), 5) + ' ' + @dateAppointment
--			else
--				print N'Bác sĩ có thời gian rảnh vào: ' + LEFT(CONVERT(varchar(5), @timeAppointment), 5) + ' ' + @dateAppointment
--				rollback
--				return

--			waitfor DELAY '0:0:05'

--			exec insertAppointment @patientID, @dentistID, @timeAppointment, @dateAppointment
--		end
--	end try
--	BEGIN CATCH 
--		DECLARE @ErrorMsg VARCHAR(2000)
--		SELECT @ErrorMsg = N'Lỗi: ' + ERROR_MESSAGE()
--		RAISERROR(@ErrorMsg, 16,1)
--		ROLLBACK TRAN
--		RETURN
--	END CATCH
--commit tran
--go


--lost update
-- bác sĩ cấp thuốc cho bệnh nhân
create or alter proc sp_CapThuocChoBenhNhan
	@medical_record_id char(5),
	@drug_id char(5),
	@drug_quantity int
AS
begin tran
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	begin try
	  IF NOT EXISTS (SELECT * FROM Drug WHERE drug_id = @drug_id)
	  BEGIN
		RAISERROR(N'Thuốc không tồn tại.', 16, 1);
		RETURN;
	  END
	  if (@drug_quantity>(select drug_stock_quantity from Drug where drug_id = @drug_id))
	  begin
		RAISERROR(N'Thuốc trong kho không đủ cấp', 16, 1);
		RETURN;
	  end
	  -- Check if expiry date is valid
	  IF (SELECT expiration_date FROM Drug WHERE drug_id = @drug_id) < GETDATE()
	  BEGIN
		RAISERROR(N'Thuốc đã hết hạn.', 16, 1, @drug_id);
		RETURN;
	  END

	  declare @drug_stock_quantity int
	  select @drug_stock_quantity = drug_stock_quantity from drug where @drug_id = drug_id

	  waitfor DELAY '0:0:05'

	  set @drug_stock_quantity = @drug_stock_quantity - @drug_quantity
	  update Drug 
	  set drug_stock_quantity = @drug_stock_quantity
	  where @drug_id = drug_id

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
	select drug_stock_quantity from drug where @drug_id = drug_id
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

--admin thêm thuốc vào kho 
create or alter proc sp_CapNhatThuoc
	@drug_id char(5),
	@drug_quantity int
AS
BEGIN tran
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	begin try
	  IF NOT EXISTS (SELECT * FROM Drug WHERE drug_id = @drug_id)
	  BEGIN
		RAISERROR(N'Thuốc không tồn tại.', 16, 1);
		RETURN;
	  END
 
	  -- Check if expiry date is valid
	  IF (SELECT expiration_date FROM Drug WHERE drug_id = @drug_id) < GETDATE()
	  BEGIN
		RAISERROR(N'Thuốc đã hết hạn.', 16, 1, @drug_id);
		RETURN;
	  END

	  declare @drug_stock_quantity int
	  select @drug_stock_quantity = drug_stock_quantity from drug where @drug_id = drug_id

	  waitfor DELAY '0:0:05'

	  set @drug_stock_quantity = @drug_stock_quantity + @drug_quantity
	  update Drug 
	  set drug_stock_quantity = @drug_stock_quantity
	  where @drug_id = drug_id

	  select drug_stock_quantity from drug where @drug_id = drug_id
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