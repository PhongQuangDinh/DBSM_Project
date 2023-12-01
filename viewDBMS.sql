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

create or alter view Patient_Person
as
select person_name, person_gender, person_address, person_birthday, pa.patient_phone
from Person pe join Patient pa on person_id = patient_id
where person_type = 'PA'

create or alter view User_Person
as
select person_name, person_gender, person_address, person_birthday, pa.patient_phone
from Person pe join Patient pa on person_id = patient_id
where account_id = CURRENT_USER

create view Dentist_PersonalAppointment
as
select personal_appointment_start_time, personal_appointment_end_time, personal_appointment_date
from personalAppointment 
where dentist_id = CURRENT_USER

create view Admin_PersonalAppointment
as
select personal_appointment_start_time, personal_appointment_end_time, personal_appointment_date
from personalAppointment 

-- there is a problem that personalAppointmenr'-'Appointment of dentist
create view Patient_PersonalAppointment
as
select personal_appointment_start_time, personal_appointment_end_time, personal_appointment_date
from personalAppointment perApp