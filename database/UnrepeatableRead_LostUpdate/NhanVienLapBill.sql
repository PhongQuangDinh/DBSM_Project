USE QLPHONGKHAMNHAKHOA
GO

--Nhân viên lập giao dịch trong khi chưa cập nhật dữ liệu vào hệ thống.
create or alter proc sp_LapGiaoDich
	@medical_recordid char(5),
	@appointmentcost float
as
begin tran
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	begin try
		select * 
		from MedicalRecord with (HOLDLOCK)
		where medical_record_id  = @medical_recordid

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
drop procedure  sp_LapGiaoDich
exec sp_LapGiaoDich 'MD002' , '100'
select * from Bill where medical_record_id = 'MD002'
select * from ServiceList where medical_record_id = 'MD002'
select * from Prescription where medical_record_id = 'MD002'