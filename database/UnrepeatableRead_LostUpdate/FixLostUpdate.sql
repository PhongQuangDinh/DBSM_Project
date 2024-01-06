USE QLPHONGKHAMNHAKHOA
GO
--Nha si cap nhat lich ca nhan
create or alter proc sp_BacSiCapNhatLichCaNhan
	@dentist_id char(5),
	@personal_appointment_start_time time,
	@personal_appointment_end_time time,
	@personal_appointment_date date
as
begin tran
	begin try
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
		IF EXISTS (SELECT * FROM Account WHERE account_id = @dentist_id AND account_status = 0)
		BEGIN
			raiserror(N'Tài khoản của Nha sĩ đã bị khóa', 16, 1)
			return 
		END
		if @personal_appointment_date <getdate()
		begin
			raiserror(N'Ngày không hợp lệ. Vui lòng chọn một ngày trong tương lai.',16,1)
			return
		end
		IF NOT EXISTS (SELECT * FROM personalAppointment with (XLOCK) WHERE dentist_id = @dentist_id and personal_appointment_date= @personal_appointment_date)
		BEGIN
			RAISERROR(N'Nha sĩ không có lịch hẹn cá nhân trong ngày đó.', 16, 1)
			RETURN
		END
		waitfor delay '00:00:20'
		UPDATE personalAppointment
		SET personal_appointment_start_time = @personal_appointment_start_time 
		WHERE dentist_id = @dentist_id and personal_appointment_date = @personal_appointment_date

		UPDATE personalAppointment
		SET personal_appointment_end_time = @personal_appointment_end_time
		WHERE dentist_id = @dentist_id and personal_appointment_date = @personal_appointment_date

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

-- admin cập nhật lịch hẹn cá nhân của nha sĩ
create or alter proc sp_AdminCapNhatLichCaNhanBacSi
	@dentist_id char(5),
	@personal_appointment_start_time time,
	@personal_appointment_end_time time,
	@personal_appointment_date date
as
begin tran
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	begin try
		if not exists (select 1 from Person where person_id = @dentist_id and person_type='DE')
		begin
			raiserror(N'Bác sĩ không tồn tại', 16, 1)
			return
		end

		IF EXISTS (SELECT * FROM Account WHERE account_id = @dentist_id AND account_status = 0)
		BEGIN
			raiserror(N'Tài khoản của bác sĩ đã bị khóa', 16, 1)
			return 
		END
		if @personal_appointment_date <getdate()
		begin
			raiserror(N'Ngày không hợp lệ. Vui lòng chọn một ngày trong tương lai.',16,1)
			return
		end
		IF NOT EXISTS (SELECT * FROM personalAppointment WHERE dentist_id = @dentist_id and @personal_appointment_date= @personal_appointment_date)
		BEGIN
			RAISERROR(N'Bác sĩ không có lịch hẹn cá nhân trong ngày đó.', 16, 1)
			RETURN
		END

		UPDATE personalAppointment
		SET personal_appointment_start_time = @personal_appointment_start_time 
		WHERE dentist_id = @dentist_id and personal_appointment_date = @personal_appointment_date

		UPDATE personalAppointment
		SET personal_appointment_end_time = @personal_appointment_end_time
		WHERE dentist_id = @dentist_id and personal_appointment_date = @personal_appointment_date

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
