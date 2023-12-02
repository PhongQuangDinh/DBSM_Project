use QLPHONGKHAMNHAKHOA
go

--tạo role bệnh nhân
create role Patient
-- tạo login cho toàn bộ bệnh nhân
sp_addlogin 'PA', '123', 'QLPHONGKHAMNHAKHOA'
sp_grantdbaccess 'PA', 'QLPHONGKHAMNHAKHOA'
grant connect to guest

--tạo user với login tương ứng
CREATE USER [00020] FOR LOGIN PA

-- thêm user vào role bệnh nhân
sp_addrolemember 'Patient', '00020'

-------------------------------------------
--tạo role bác sĩ
create role Dentist
-- tạo login cho toàn bộ bác sĩ
sp_addlogin 'DE', '123', 'QLPHONGKHAMNHAKHOA'
sp_grantdbaccess 'DE', 'QLPHONGKHAMNHAKHOA'
grant connect to guest

--tạo user với login tương ứng
CREATE USER [00015] FOR LOGIN DE

-- thêm user vào role bác sĩ
sp_addrolemember 'Dentist', '00015'

-------------------------------------------
--tạo role nhân viên
create role Staff
-- tạo login cho toàn bộ bệnh nhân
sp_addlogin 'ST', '123', 'QLPHONGKHAMNHAKHOA'
sp_grantdbaccess 'ST', 'QLPHONGKHAMNHAKHOA'
grant connect to guest

--tạo user với login tương ứng
CREATE USER [00010] FOR LOGIN ST

-- thêm user vào role NhanVien
sp_addrolemember 'Staff', '00010'

-------------------------------------------
--tạo role admin
create role [Admin]
-- tạo login cho toàn bộ bệnh nhân
sp_addlogin 'AD', '123', 'QLPHONGKHAMNHAKHOA'
sp_grantdbaccess 'AD', 'QLPHONGKHAMNHAKHOA'
grant connect to guest

--tạo user với login tương ứng
CREATE USER [00001] FOR LOGIN AD

-- thêm user vào role NhanVien
sp_addrolemember 'Admin', '00001'