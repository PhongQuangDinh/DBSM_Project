use QLPHONGKHAMNHAKHOA
go

--xử lý tranh chấp đồng thời
create or alter proc XemHoSoBenhNhan
					@DENTIST_ID char(5)
as
begin tran
	SET TRAN ISOLATION LEVEL REPEATABLE READ
	begin try
		if not exists(select 1 from Person de where de.person_id = @DENTIST_ID)
			begin
				raiserror(N'Bác sĩ không tồn tại', 16, 1)
				rollback tran
				return
			end
		else if not exists(select 1 from Person de where de.person_id = @DENTIST_ID and de.person_type!='DE')
			begin
				raiserror(N'Bác sĩ không tồn tại', 16, 1)
				rollback tran
				return
			end
		else 
			begin
				select pa.person_name as patientName, pa.person_birthday, pa.person_address, pa.person_phone, mr.examination_date
				from MedicalRecord mr join Person pa on pa.person_id = mr.patient_id
				where mr.dentist_id = @DENTIST_ID

				waitfor DELAY '0:0:05'

				select pa.person_name as patientName, pa.person_birthday, pa.person_address, pa.person_phone, mr.examination_date
				from MedicalRecord mr join Person pa on pa.person_id = mr.patient_id
				where mr.dentist_id = @DENTIST_ID
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

create or alter proc CapNhatThongTinCaNhan
						@personName nvarchar(30),
						@personPhone char(10),
						@personBirthday DATE,
						@personAddress nvarchar(40)
as
begin tran
	begin try
		if not exists(select 1 from Person pa where pa.person_phone = @personPhone)
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

--lost update
-- bác sĩ cấp thuốc cho bệnh nhân
create or alter proc CapThuocChoBenhNhan
	@medical_record_id char(5),
	@drug_id char(5),
	@drug_quantity int
AS
begin tran
	SET TRANSACTION ISOLATION LEVEL Serializable
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

	  --SET LOCK_MODE  UPDLOCK

	  declare @drug_stock_quantity int
	  select @drug_stock_quantity = drug_stock_quantity from drug WITH (TABLOCK, UPDLOCK) where @drug_id = drug_id 

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
create or alter proc CapNhatThuoc
	@drug_id char(5),
	@drug_quantity int
AS
BEGIN tran
	SET TRANSACTION ISOLATION LEVEL Serializable
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
	  select @drug_stock_quantity = drug_stock_quantity from drug WITH (TABLOCK, UPDLOCK) where @drug_id = drug_id

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