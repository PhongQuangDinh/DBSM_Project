use QLPHONGKHAMNHAKHOA
go

create view Admin_Account
as
select username, account_status
from Account

create view User_Account
as
select username, password
from Account
where account_id = CURRENT_USER

create or alter view Dentist_or_Patient_Person
as
select person_name, person_gender, person_address, person_birthday, person_phone
from Person pe
where person_type = CURRENT_USER

create or alter view Admin_or_Staff_Person
as
select person_name, person_gender, person_address, person_birthday, person_phone
from Person pe

create view Dentist_PersonalAppointment
as
select personal_appointment_start_time, personal_appointment_end_time, personal_appointment_date
from personalAppointment 
where dentist_id = CURRENT_USER

create view Admin_PersonalAppointment
as
select personal_appointment_start_time, personal_appointment_end_time, personal_appointment_date
from personalAppointment 

create view Patient_MedicalRecord
as
select examination_date, pay_status, de.person_name as DentistName, pa.person_name as PatientName, pa.person_address, pa.person_gender, pa.person_phone as PatientPhone
from MedicalRecord mr join Person de on de.person_id= mr.dentist_id join Person pa on pa.person_id = mr.patient_id
where mr.patient_id = CURRENT_USER

create view Dentist_MedicalRecord
as
select examination_date, pay_status, de.person_name as DentistName, pa.person_name as PatientName, pa.person_address, pa.person_gender, pa.person_phone as PatientPhone
from MedicalRecord mr join Person de on de.person_id= mr.dentist_id join Person pa on pa.person_id = mr.patient_id
where mr.dentist_id = CURRENT_USER

create view User_MedicalRecord
as
select examination_date, pay_status, de.person_name as DentistName, pa.person_name as PatientName, pa.person_address, pa.person_gender, pa.person_phone as PatientPhone
from MedicalRecord mr join Person de on de.person_id= mr.dentist_id join Person pa on pa.person_id = mr.patient_id

create view Dentist_Appointment
as
select appointment_start_time, appointment_status, appointment_number, appointment_date, de.person_name as DentistName, pa.person_name as PatientName, pa.person_address, pa.person_gender, pa.person_phone as PatientPhone
from Appointment app join Person de on de.person_id= app.dentist_id join Person pa on pa.person_id = app.patient_id
where app.dentist_id = CURRENT_USER

create view Patient_Appointment
as
select appointment_start_time, appointment_status, appointment_number, appointment_date, de.person_name as DentistName, pa.person_name as PatientName, pa.person_address, pa.person_gender, pa.person_phone as PatientPhone
from Appointment app join Person de on de.person_id= app.dentist_id join Person pa on pa.person_id = app.patient_id
where app.patient_id = CURRENT_USER

create view User_Appointment
as
select appointment_start_time, appointment_status, appointment_number, appointment_date, de.person_name as DentistName, pa.person_name as PatientName, pa.person_address, pa.person_gender, pa.person_phone as PatientPhone
from Appointment app join Person de on de.person_id= app.dentist_id join Person pa on pa.person_id = app.patient_id

create view Patient_Bill
as
select appointment_cost, service_cost, drugs_cost, cost_total, payment_date, pe.person_name as PatientName, pe.person_address, pe.person_gender, pe.person_phone
from Bill bi join Person pe on pe.person_id = bi.patient_id
where bi.patient_id = CURRENT_USER

create view User_Bill
as
select appointment_cost, service_cost, drugs_cost, cost_total, payment_date, pe.person_name as PatientName, pe.person_address, pe.person_gender, pe.person_phone
from Bill bi join Person pe on pe.person_id = bi.patient_id

create view Patient_Prescription
as
select dr.drug_name, pr.drug_quantity, pe.person_name as PatientName, pe.person_phone
from MedicalRecord me join Prescription pr on pr.medical_record_id = me.medical_record_id join Person pe on pe.person_id = me.patient_id join Drug dr on dr.drug_id = pr.drug_id
where me.patient_id = CURRENT_USER

create view User_Prescription
as
select dr.drug_name, pr.drug_quantity, pe.person_name as PatientName, pe.person_phone
from MedicalRecord me join Prescription pr on pr.medical_record_id = me.medical_record_id join Person pe on pe.person_id = me.patient_id join Drug dr on dr.drug_id = pr.drug_id

create view User_Drug
as
select drug_name, unit, indication, expiration_date, price, drug_stock_quantity
from Drug

create view Patient_Service
as
select se.[service_name], sl.service_quantity, pe.person_name as PatientName, pe.person_phone
from MedicalRecord me join ServiceList sl on sl.medical_record_id = me.medical_record_id join Person pe on pe.person_id = me.patient_id join [Service] se on se.service_id = sl.service_id
where me.patient_id = CURRENT_USER

create view User_Service
as
select se.[service_name], sl.service_quantity, pe.person_name as PatientName, pe.person_phone
from MedicalRecord me join ServiceList sl on sl.medical_record_id = me.medical_record_id join Person pe on pe.person_id = me.patient_id join [Service] se on se.service_id = sl.service_id

--create view User_Service
--as
--select [service_name], cost
--from [Service]

--tìm tất cả bác sĩ có thời gian rảnh vào ngày h đó
create or alter proc View_Patient_PersonalAppointment
					@dateAppointment DATE,
					@timeAppointment time
as
begin
	select de.person_id, de.person_name, per.personal_appointment_id
	from Person de join personalAppointment per on de.person_id = per.dentist_id
	where de.person_type = 'DE' and per.personal_appointment_date = @dateAppointment and 
			LEFT(CONVERT(varchar(5), @timeAppointment), 5) not in (select LEFT(CONVERT(varchar(5), app1.appointment_start_time), 5)
									from Appointment app1
									where app1.dentist_id = de.person_id and @dateAppointment = app1.appointment_date)
	
end
go

exec View_Patient_PersonalAppointment '2023-11-28', '11:00'