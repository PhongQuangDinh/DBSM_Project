use QLPHONGKHAMNHAKHOA
go
--trigger kiểm tra update số điện thoại của bệnh nhân
create or alter trigger TR_changePhoneNumber
on Person
for update
as
	begin
		if ((select person_type from inserted) = 'PA')
		begin
			declare @newPhoneNumber char(10)
			select @newPhoneNumber = person_phone
			from inserted

			if(@newPhoneNumber != (select acc.username from Account acc join inserted ins on acc.account_id = ins.account_id))
			begin
				raiserror(N'Số điện thoại cập nhật không hợp lệ', 16, 1)
				rollback
				return
			end
		end
	end
go

CREATE OR ALTER TRIGGER TR_insertPatient
ON Person
FOR INSERT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM inserted WHERE person_type = 'PA')
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM inserted ins
			JOIN Account acc ON acc.account_id = ins.account_id
			WHERE ins.person_phone != acc.username
		)
		BEGIN
			RAISERROR(N'Số điện thoại thêm vào không hợp lệ', 16, 1)
			ROLLBACK
			RETURN
		END
	END
END;
GO

create or alter trigger TR_cost1
on BILL
for insert
as
	declare @medRec_id char(5) = (select medical_record_id from inserted)

	declare @actualServiceCost float = (select SUM(sv.cost * svl.service_quantity)
										from MedicalRecord md join ServiceList svl on svl.medical_record_id = md.medical_record_id
										join Service sv on sv.service_id = svl.service_id
										where md.medical_record_id = @medRec_id)

	if @actualServiceCost != (select service_cost from inserted)
	begin
		raiserror(N'Tổng chi phí dịch vụ tính sai',16,1)
		rollback
		return
	end
	
	declare @actualDrugCost float = (select SUM(drug.price * pres.drug_quantity)
									from MedicalRecord md join Prescription pres on pres.medical_record_id = md.medical_record_id
									join Drug drug on drug.drug_id = pres.drug_id
									where md.medical_record_id = @medRec_id)

	if @actualDrugCost != (select drugs_cost from inserted)
	begin
		raiserror(N'Tổng chi phí thuốc tính sai',16,1)
		rollback
		return
	end
	declare @appointCost float = (select appointment_cost from inserted)
	if @actualDrugCost + @actualServiceCost + @appointCost != (select cost_total from inserted)
	begin
		raiserror(N'Tổng chi hóa đơn tính sai',16,1)
		rollback
		return
	end
go

-- for update
create or alter trigger TR_cost2
on BILL
for update
as
	declare @medRec_id char(5) = (select medical_record_id from inserted)

	declare @actualServiceCost float = (select SUM(sv.cost * svl.service_quantity)
										from MedicalRecord md join ServiceList svl on svl.medical_record_id = md.medical_record_id
										join Service sv on sv.service_id = svl.service_id
										where md.medical_record_id = @medRec_id)

	if @actualServiceCost != (select service_cost from inserted)
	begin
		raiserror(N'Tổng chi phí dịch vụ tính sai',16,1)
		rollback
		return
	end
	
	declare @actualDrugCost float = (select SUM(drug.price * pres.drug_quantity)
									from MedicalRecord md join Prescription pres on pres.medical_record_id = md.medical_record_id
									join Drug drug on drug.drug_id = pres.drug_id
									where md.medical_record_id = @medRec_id)

	if @actualDrugCost != (select drugs_cost from inserted)
	begin
		raiserror(N'Tổng chi phí thuốc tính sai',16,1)
		rollback
		return
	end

	declare @appointCost float = (select appointment_cost from inserted)
	if @actualDrugCost + @actualServiceCost + @appointCost != (select cost_total from inserted)
	begin
		raiserror(N'Tổng chi hóa đơn tính sai',16,1)
		rollback
		return
	end
go
