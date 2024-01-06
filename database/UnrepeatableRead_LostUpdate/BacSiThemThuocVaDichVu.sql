USE QLPHONGKHAMNHAKHOA
GO
--Nha sĩ đang thực hiện khám và thêm dịch vụ, thuốc vào bệnh án bệnh nhân. 
create or alter proc sp_CapNhatBenhAnBenhNhan
	@medical_recordid char(5),
	@serviceid char(5),
	@service_quant int,
	@drugid char(5),
	@drug_quant int
as
begin tran
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	--SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	begin try
		select *
		from MedicalRecord with (UPDLOCK, HOLDLOCK)
		where medical_record_id = @medical_recordid;
		if not exists (select 1 from MedicalRecord where medical_record_id= @medical_recordid)
		begin
			raiserror (N'Không tồn tại bệnh án',16,1)
		--	rollback tran
			return
		end
		if not exists (select * from [Service] where service_id = @serviceid)
		begin
			raiserror (N'Không tồn tại dịch vụ',16,1)
			return
		end
		if not exists (select * from Drug where drug_id = @drugid)
		begin
			raiserror (N'Không tồn tại thuốc',16,1)
			return
		end
		if (@drug_quant>(select drug_stock_quantity from Drug where drug_id = @drugid))
		begin
			raiserror (N'Thuốc trong kho không đủ cấp',16,1)
			return
		end
		if (select expiration_date from Drug where drug_id = @drugid) < GETDATE()
		begin
			raiserror(N'Thuốc đã hết hạn.', 16, 1)
			return
		end
		waitfor DELAY '0:0:20'
		declare @drug_stock_quantity int
		select @drug_stock_quantity = drug_stock_quantity from drug where drug_id = @drugid
		set @drug_stock_quantity = @drug_stock_quantity - @drug_quant
		update Drug 
		set drug_stock_quantity = @drug_stock_quantity
		where drug_id = @drugid

         if exists (select 1 from ServiceList where medical_record_id = @medical_recordid and service_id = @serviceid)
         begin
              update ServiceList 
              set service_id = @serviceid, service_quantity= service_quantity + @service_quant
              where medical_record_id = @medical_recordid and service_id = @serviceid
         end
         else
         begin

              insert into ServiceList (medical_record_id, service_id, service_quantity)
              values (@medical_recordid, @serviceid, @service_quant)
         end


         if exists (select 1 from Prescription where medical_record_id = @medical_recordid and drug_id = @drugid)
         begin
                update Prescription
                set drug_id = @drugid, drug_quantity = drug_quantity +  @drug_quant
                where medical_record_id = @medical_recordid and drug_id = @drugid
         end
         else
         begin
                insert into Prescription (medical_record_id, drug_id, drug_quantity)
                values (@medical_recordid, @drugid, @drug_quant)
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

drop procedure  sp_CapNhatHoSoBenhNhan
exec sp_CapNhatHoSoBenhNhan 'MD002' , 'SV003' , 1 , 'DR010' , 1
select * from ServiceList where medical_record_id = 'MD002'
select * from Prescription where medical_record_id = 'MD002'

select * from [Service] 