--go
--CREATE or alter PROCEDURE sp_updateDrug
--(
--	@drugID char(5),
--	@unit varchar(5),
--	@drugName nvarchar(30),
--	@indication nvarchar(50),
--	@expirationDate date,
--	@price money,
--	@drugStockQuantity int
--)
--AS
----SET TRAN ISOLATION LEVEL REPEATABLE READ
--SET TRAN ISOLATION LEVEL SERIALIZABLE
--BEGIN TRAN
--	BEGIN TRY
--	IF NOT EXISTS (SELECT * FROM Drug WHERE drug_id = @drugID)
--	BEGIN
--		RAISERROR('Thuốc không tồn tại.', 16, 1);
--		ROLLBACK TRAN
--		RETURN;
--	END

--	WAITFOR DELAY '0:0:05'
--	UPDATE Drug
--	SET unit = @unit,
--	drug_name = @drugName,
--	indication = @indication,
--	expiration_date = @expirationDate,
--	price = @price,
--	drug_stock_quantity = @drugStockQuantity
--	WHERE drug_id = @drugID;
--	END TRY
--	BEGIN CATCH
--		PRINT N'LỖI HỆ THỐNG'
--		ROLLBACK TRAN
--		RETURN 1
--	END CATCH
--COMMIT TRAN 

go
CREATE or alter PROCEDURE sp_deleteDrug
(
	@drugID char(5)
)
AS
BEGIN TRAN
	--SET TRAN ISOLATION LEVEL SERIALIZABLE
	Begin try
	IF NOT EXISTS (SELECT * FROM Drug WHERE drug_id = @drugID)
	BEGIN
		RAISERROR('Thuốc không tồn tại.', 16, 1);
		ROLLBACK TRAN
		RETURN;
	END
	IF EXISTS (SELECT * FROM Prescription WHERE drug_id = @drugID)
	BEGIN
		RAISERROR('Thuốc đã có trong đơn thuốc, không thể xóa.', 16, 1);
		ROLLBACK TRAN
		RETURN;
	END
	WAITFOR DELAY '0:0:05'
	DELETE Drug
	WHERE drug_id = @drugID;
	END TRY
	BEGIN CATCH
		PRINT N'LỖI HỆ THỐNG'
		ROLLBACK TRAN
		RETURN 1
	END CATCH
COMMIT

go
CREATE or alter PROCEDURE sp_AddPrescription(
  @medical_record_id char(5),
  @drug_id char(5),
  @drug_quantity int
)
AS
--SET TRAN ISOLATION LEVEL SERIALIZABLE
BEGIN TRAN
  BEGIN TRY
  IF NOT EXISTS (SELECT * FROM Drug WHERE drug_id = @drug_id)
  BEGIN
    RAISERROR('Thuốc không tồn tại.', 16, 1);
	ROLLBACK TRAN
    RETURN;
  END
  
  IF NOT EXISTS (SELECT * FROM MedicalRecord WHERE medical_record_id = @medical_record_id)
  BEGIN
    RAISERROR(N'Record không tồn tại.', 16, 1);
    RETURN;
  END

  DECLARE @expiryDate date;
  SELECT @expiryDate = expiration_date FROM Drug WHERE drug_id = @drug_id;
  IF @expiryDate < GETDATE()
  BEGIN
    RAISERROR('Thuốc đã hết hạn.', 16, 1, @drug_id);
	ROLLBACK TRAN
    RETURN;
  END
  
  if(@drug_quantity > (select drug_stock_quantity from Drug where drug_id = @drug_id))
  begin
	raiserror(N'Số lượng thuốc không đủ cấp', 16, 1)
	rollback
	return
  end
  DECLARE @drug_price float
  SET @drug_price = (
    SELECT price
    FROM Drug
    WHERE drug_id = @drug_id
) * @drug_quantity;
  -- Insert prescription and quantity
  update Drug
  set drug_stock_quantity = drug_stock_quantity - @drug_quantity
  where drug_id = @drug_id
  INSERT INTO Prescription (
    medical_record_id,
    drug_id,
    drug_quantity,
	drug_price
  )
  VALUES (
    @medical_record_id,
    @drug_id,
    @drug_quantity,
	@drug_price
  );
  END TRY
  BEGIN CATCH
		PRINT N'LỖI HỆ THỐNG'
		ROLLBACK TRAN
		RETURN 1	
   END CATCH
COMMIT TRAN

--EXEC AddPrescription '00001','DR001',1
--select * from Prescription where medical_record_id = '00001' and drug_id = 'DR001'

--EXEC updateDrug 'DR001', N'viên', N'Paracetamol', N'Giảm đau, hạ sốt', '2024-07-20', 10000, 100
--select * from drug where drug_id = 'DR001'


--DELETE Prescription 
--where medical_record_id = '00001' and drug_id = 'DR001'

