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
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	begin try
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

--Nhân viên lập giao dịch trong khi chưa cập nhật dữ liệu vào hệ thống.
create or alter proc sp_LapGiaoDich
	@medical_recordid char(5),
	@appointmentcost float
as
begin tran
	begin try

	if not exists (select 1 from MedicalRecord where medical_record_id= @medical_recordid)
	begin
		raiserror (N'Không tồn tại bệnh án',16,1)
		rollback tran
		return
	end
	declare @patientid char(5)  = (select patient_id from MedicalRecord where medical_record_id = @medical_recordid)
	declare @new_bill_id char(5)
	if not exists (select 1 from Bill)
	begin
		set @new_bill_id = '00001'
	end
	else
	begin
		select @new_bill_id = RIGHT('00000' + CAST(CAST(SUBSTRING((select max(bill_id) from Bill),1,5) as int)+1 as varchar(5)),5)
	end

	declare @total_cost float
	declare @drug_cost float
	declare @servicecost float
	if not exists (select 1 from ServiceList where medical_record_id = @medical_recordid)
	begin
		set @servicecost = 0
	end
	else
	begin
		set @servicecost = (select sum(SL.service_quantity*S.cost) from ServiceList SL join [Service] S on SL.service_id = S.service_id where SL.medical_record_id = @medical_recordid)
	end

	if not exists (select 1 from Prescription where medical_record_id = @medical_recordid)
	begin
		set @drug_cost = 0
	end
	else
	begin
		set @drug_cost = (select sum(P.drug_quantity*D.price) from Prescription P join Drug D on P.drug_id = D.drug_id where P.medical_record_id = @medical_recordid)
	end

	set @total_cost = @servicecost + @drug_cost + @appointmentcost

	insert into Bill
	(
		bill_id,
		service_cost,
		appointment_cost,
		drugs_cost,
		cost_total,
		patient_id,
		medical_record_id
	)
	values 
	(
		@new_bill_id,
		@servicecost,
		@appointmentcost,
		@drug_cost,
		@total_cost,
		@patientid,
		@medical_recordid
	)
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

