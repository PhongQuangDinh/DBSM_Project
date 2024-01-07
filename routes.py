from flask import Flask, render_template, redirect, request, session, jsonify
from flask_session import Session
from db import *
import secrets
import re
from datetime import datetime

app = Flask(__name__)
# key = secrets.token_urlsafe(32) # create one time only, avoid cant create pyodbc.ROW instance error
# print(key)
app.secret_key = "13RPk7SDKm9jwEt2vd7rJM1TWs1N1CvAI9WWd1_wYBc"
app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)

current_patient = ''
# userList = []
@app.route('/', methods = ['POST','GET'])
def homepage():
    person_detail = None
    isLogOut = True
    # print('get started')
    # return render_template('homepage.html')
    if not session.get("user"):
        # if not there in the session then redirect to the login page
        isLogOut = True
        return redirect("/login")
    else:
        print('get info')
        empID = session["user"].account_id
        cursor.execute('SELECT * from Person where account_id = ?', (empID))
        session['user_detail'] = cursor.fetchone()
        person_detail = session['user_detail']
        isLogOut = False
    return render_template('homepage.html', isLogOut=isLogOut, person = person_detail)

@app.route("/logout")
def logout():
    session['user'] = None # reset session
    return redirect("/")


@app.route('/employeeIn4', methods = ['POST','GET'])
def PatientIn4Test():
    employeeInfo = session['user_detail']
    if employeeInfo == None:
        return redirect('/login')
    print(employeeInfo.person_name)
    return render_template('employeein4.html',employee = employeeInfo)

@app.route('/login', methods = ['POST','GET'])
def login():
    error = ""
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        try:
            # Check if the username and password are correct
            cursor.execute('SELECT ac.account_id as account_id, p.person_type as person_type, ac.password as password FROM Account ac join person p on ac.account_id = p.account_id WHERE username = ?', username)
            user = cursor.fetchone()
            if user == None:
                error = 'Invalid username or password. Please try again.'
            elif user.password == password:
                session["user"] = user
                return redirect('/')
            else:
                error = 'Invalid username or password. Please try again.'
                return render_template('login.html', error=error)
        except Exception as e:
            error = f'Error: {str(e)}'
    return render_template('login.html', error=error)

@app.route('/signup', methods = ['POST','GET'])
def signup():
    error = ""
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        confirm_password = request.form['confirm_password']

        if password != confirm_password:
            return render_template('signup.html', error='Password does not match')

        cursor.execute('INSERT INTO users (username, password) VALUES (%s, %s)', (username, password))
        return redirect('/login')
    else:
        return render_template('signup.html', error = error)

@app.route('/accountlist', methods = ['POST','GET'])
def accountlist():
    if request.method == 'POST':
        account_id = request.form.get('account_id')
        new_status = request.form.get('new_status')
        print(account_id)
        if account_id is not None:
            cursor.execute("EXEC updateaccount ?, ?", (account_id, new_status))

    cursor.execute('SELECT * FROM Account a join person p on a.account_id = p.account_id')
    accounts = cursor.fetchall()

    return render_template('accountlist.html', accounts=accounts)

@app.route('/addaccount', methods = ['POST','GET'])
def addaccount():
    if request.method == 'POST':
        # Retrieve data from the form
        username = request.form['username']
        patient_name = request.form['person_name']
        patient_birthday = request.form['person_birthday']
        patient_address = request.form['person_address']
        patient_phone = request.form['person_phone']
        patient_gender = request.form['person_gender']

        #Insert into the Account table
        cursor.execute("EXEC insertAccount ?, '123456'", (username,))
        conn.commit()

        cursor.execute("select max(account_id) from Account")
        account_id = cursor.fetchone()[0]
        print(account_id)
        # Insert into the Person table
        cursor.execute("EXEC insertPerson ?, ?, ?, ?, ?, ?, ?",  # Assuming account_id is NULL initially
                       (patient_name, patient_phone, patient_birthday, patient_address, patient_gender, 'DE',account_id))
        conn.commit()
        # Retrieve the generated person_id
        # cursor.execute("select max(person_id) from Person")
        # person_id = cursor.fetchone()
        # print(person_id)

        # # Retrieve the generated account_id
        # cursor.execute("select max(account_id) from Account")
        # account_id = cursor.fetchone()
        # print(account_id)
        # # Update the Person table with the generated account_id
        # cursor.execute("UPDATE Person SET account_id = ? WHERE person_id = ?", (account_id, person_id))

    return render_template('addaccount.html')


@app.route('/dentistlist', methods = ['POST','GET'])
def dentistlist():
    cursor.execute('SELECT * FROM Person WHERE person_type = ?', ('DE',))
    dentists = cursor.fetchall()

    return render_template('dentistlist.html', dentists=dentists)

@app.route('/stafflist', methods = ['POST','GET'])
def stafflist():
    cursor.execute('SELECT * FROM Employee WHERE employee_type = ?', ('ST',))
    staffs = cursor.fetchall()

    return render_template('stafflist.html', staffs=staffs)

@app.route('/patientinfo', methods = ['POST','GET'])
def patientinfo():
    account_id = session["user"].account_id
    account_type = session["user"].person_type
    if (account_type == 'PA'):
        cursor.execute('SELECT * FROM Person where person_type =? and account_id = ?', ('PA',account_id,))
    else:
        cursor.execute("SELECT * FROM Person where person_type = 'PA'")
    patients = cursor.fetchall()

    return render_template('patientinfo.html', persons=patients)

@app.route('/sessionreport', methods = ['POST','GET'])
def index():
    if request.method == 'POST':
        selected_date = request.form['selectedDate']
        print(selected_date)
        # Assuming you have a function to query treatment sessions for the selected date
        treatment_sessions = get_treatment_sessions(selected_date)

        return jsonify({'treatmentSessions': treatment_sessions})
    return render_template('sessionreport.html')
def get_treatment_sessions(selected_date):
    # Perform a SQL query to get treatment sessions for the selected date
    # Adapt this query based on your database schema and requirements
    cursor.execute('SELECT treatment_session_id,treatment_session_created_date,treatment_session_description, t.treatment_plan_id, dentist_id FROM TreatmentSession s join TreatmentPlan t on s.treatment_plan_id = t.treatment_plan_id WHERE CAST(treatment_session_created_date AS DATE) = ? order by dentist_id', selected_date)
    treatment_sessions = cursor.fetchall()

    # Convert the result to a list of dictionaries for JSON serialization
    treatment_sessions_list = []
    for session in treatment_sessions:
        session_dict = {
            'treatment_session_id': session.treatment_session_id,
            'treatment_session_created_date': session.treatment_session_created_date,
            'treatment_session_description': session.treatment_session_description,
            'treatment_plan_id': session.treatment_plan_id,
            'dentist_id': session.dentist_id
        }
        treatment_sessions_list.append(session_dict)

    return treatment_sessions_list

@app.route('/appointmentreport', methods=['POST', 'GET'])
def index1():
    if request.method == 'POST':
        start_date = request.form['startDate']
        end_date = request.form['endDate']
        # Assuming you have a function to query appointments for the date range
        appointments = get_appointments(start_date, end_date)

        return jsonify({'appointments': appointments})
    return render_template('appointmentreport.html')

def get_appointments(start_date, end_date):
    # Replace this with your database connection and query
    # For demonstration purposes, I'm using a list instead of a database query
    cursor.execute('''
        SELECT appointment_id, appointment_date, appointment_time, appointment_state,
               numerical_order, room_id, patient_id, dentist_id, nurse_id
        FROM Appointment
        WHERE CAST(appointment_date AS DATE) BETWEEN ? AND ?
        ORDER BY dentist_id
    ''', (start_date, end_date))

    appointments = cursor.fetchall()

    # Convert the result to a list of dictionaries for JSON serialization
    appointments_list = []
    for appointment in appointments:
        appointment_dict = {
            'appointment_id': appointment.appointment_id,
            'appointment_date': appointment.appointment_date,
            'appointment_time': appointment.appointment_time.strftime('%H:%M:%S'),
            'appointment_state': appointment.appointment_state,
            'numerical_order': appointment.numerical_order,
            'room_id': appointment.room_id,
            'patient_id': appointment.patient_id,
            'dentist_id': appointment.dentist_id,
            'nurse_id': appointment.nurse_id
        }
        appointments_list.append(appointment_dict)

    return appointments_list
# def index1():
#     if request.method == 'POST':
#         startDate = request.form['startDate']
#         endDate = request.form['endDate']
#         # Assuming you have a function to query treatment sessions for the selected date
#         treatment_sessions = get_treatment_sessions_1(startDate,endDate)

#         return jsonify({'treatmentSessions': treatment_sessions})
#     return render_template('appointmentreport.html')
# def get_treatment_sessions_1(start_date, end_date):
#     # Perform a SQL query to get treatment sessions for the selected date
#     # Adapt this query based on your database schema and requirements
#     cursor.execute('''
#     SELECT treatment_session_id, treatment_session_created_date, treatment_session_description, t.treatment_plan_id, dentist_id
#     FROM TreatmentSession s
#     JOIN TreatmentPlan t ON s.treatment_plan_id = t.treatment_plan_id
#     WHERE CAST(treatment_session_created_date AS DATE) BETWEEN ? AND ?
#     ORDER BY dentist_id
#     ''', (start_date, end_date))
#     treatment_sessions = cursor.fetchall()

#     # Convert the result to a list of dictionaries for JSON serialization
#     treatment_sessions_list = []
#     for session in treatment_sessions:
#         session_dict = {
#             'treatment_session_id': session.treatment_session_id,
#             'treatment_session_created_date': session.treatment_session_created_date,
#             'treatment_session_description': session.treatment_session_description,
#             'treatment_plan_id': session.treatment_plan_id,
#             'dentist_id': session.dentist_id
#         }
#         treatment_sessions_list.append(session_dict)

#     return treatment_sessions_list

@app.route('/addpatient', methods = ['POST','GET'])
def addpatient():
    if request.method == 'POST':
        # Lấy thông tin từ form
        patient_name = request.form['patient_name']
        patient_birthday = request.form['patient_birthday']
        patient_address = request.form['patient_address']
        patient_phone = request.form['patient_phone']
        patient_gender = request.form['patient_gender']
        patient_email = request.form['patient_email']

        cursor.execute("EXEC insertPatient ?, ?, ?, ?, ?, ?",
                       (patient_name, patient_birthday, patient_address,
                        patient_phone, patient_gender, patient_email))
    return render_template('addpatient.html')

@app.route('/adddentist', methods = ['POST','GET'])
def adddentist():
    if request.method == 'POST':
        # Lấy thông tin từ form
        dentist_name = request.form['dentist_name']
        dentist_birthday = request.form['dentist_birthday']
        dentist_address = request.form['dentist_address']
        dentist_phone = request.form['dentist_phone']
        dentist_gender = request.form['dentist_gender']
        dentist_email = request.form['dentist_email']

        # cursor.execute("EXEC insertdentist ?, ?, ?, ?, ?, ?",
        #                (dentist_name, dentist_birthday, dentist_address,
        #                 dentist_phone, dentist_gender, dentist_email))
    return render_template('addDentist.html')

@app.route('/updatepatient', methods = ['POST','GET'])
def updatepatient():
    patient_id = request.args.get('get_patient_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        patient_name = request.form['patient_name']
        patient_birthday = request.form['patient_birthday']
        patient_address = request.form['patient_address']
        patient_phone = request.form['patient_phone']
        patient_gender = request.form['patient_gender']
        patient_email = request.form['patient_email']

        cursor.execute("EXEC updatePatient ?, ?, ?, ?, ?, ?, ?",
                       (patient_id, patient_name, patient_birthday, patient_address,
                        patient_phone, patient_gender, patient_email))
    return render_template('updatepatient.html')

@app.route('/updategeneralhealth', methods = ['POST','GET'])
def updateGeneralHealth():
    patient_id = request.args.get('get_patient_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        note_date = request.form['note_date']
        health_description = request.form['health_description']

        # Thực thi stored procedure
        cursor.execute("EXEC updateGeneralHealth ?, ?, ?",
                       (patient_id, note_date, health_description))
    return render_template('updategeneralhealth.html')

@app.route('/patientrecord', methods = ['POST','GET'])
def patientrecord():
    patient_id = request.args.get('get_person_id')
    cursor.execute('SELECT * FROM Person where person_id = ?', patient_id)
    patient = cursor.fetchone()
    print(patient)
    return render_template('patientrecord.html', patient = patient)

@app.route('/treatmentplandetail', methods = ['POST','GET'])
def treatmentplandetail():
    treatment_plan_id = request.args.get('get_treatment_plan_id')
    cursor.execute('SELECT * FROM TreatmentPlan join Treatment on TreatmentPlan.treatment_id = Treatment.treatment_id where TreatmentPlan.treatment_plan_id = ?', treatment_plan_id)
    treatment = cursor.fetchone()
    cursor.execute('SELECT * FROM TreatmentPlan join TreatmentSession on TreatmentSession.treatment_plan_id = TreatmentPlan.treatment_plan_id  where TreatmentPlan.treatment_plan_id = ?', treatment_plan_id)
    treatmentsession = cursor.fetchall()
    cursor.execute('SELECT * from ToothSelection JOIN ToothSurface ON ToothSurface.tooth_surface_code = ToothSelection.tooth_surface_code JOIN ToothPosition ON ToothPosition.tooth_position_id = ToothSelection.tooth_position_id where treatment_plan_id = ?', treatment_plan_id)
    listtreatmenttooth = cursor.fetchall()
    return render_template('treatmentplandetail.html', treatment = treatment, treatmentsession = treatmentsession, listtreatmenttooth= listtreatmenttooth)

@app.route('/medicalrecorddetail', methods = ['POST','GET'])
def medicalrecorddetail():
    treatment_plan_id = request.args.get('get_medical_record_id')
    print(treatment_plan_id)
    cursor.execute('SELECT * FROM ServiceList join Service on ServiceList.service_id = Service.service_id where medical_record_id = ?', treatment_plan_id)
    treatment = cursor.fetchone()
    cursor.execute('SELECT * FROM Prescription join drug on Prescription.drug_id = drug.drug_id where medical_record_id =?', treatment_plan_id)
    prescription = cursor.fetchall()
    return render_template('medicalrecorddetail.html', treatment = treatment, prescription = prescription, medical_record_id = treatment_plan_id)


@app.route('/treatmentplanlist', methods = ['POST','GET'])
def treatmentplanlist():
    patient_id = request.args.get('get_patient_id')
    cursor.execute('SELECT * FROM MedicalRecord where patient_id = ?', patient_id)
    treatmentplanlist = cursor.fetchall()
    return render_template('treatmentplanlist.html', treatmentplanlist = treatmentplanlist)

@app.route('/addtreatmentplan', methods = ['POST','GET'])
def addtreatmentplan():
    patient_id = request.args.get('get_patient_id')
    print(patient_id)
    if request.method == 'POST':
        # Lấy giá trị từ form
        session_date = request.form['sessionDate']
        session_datetime = datetime.strptime(session_date, '%Y-%m-%dT%H:%M')
        session_datetime = session_datetime.replace(second=0)  # Set seconds to 0
        formatted_date = session_datetime.strftime('%Y-%m-%dT%H:%M:%S')

        dentist_id = request.form['dentistId']
        nurse_id = request.form.get('nurseId', None)  # Lấy nurse_id nếu có, nếu không thì mặc định là None
        selected_treatment = request.form['selectedTreatment']
        selected_surfaces = request.form.getlist('selectedSurfaces')

        # Xử lý các giá trị nhận được, ví dụ: in ra console
        print(f"Selected Surfaces: {selected_surfaces}")
        result = []
        for surface in selected_surfaces:
            match = re.match(r'(\d+)_([A-Za-z]+)', surface)
            if match:
                groups = match.groups()
                result.append({'number': groups[0], 'letter': groups[1]})

        time = datetime.now()
        cursor.execute("EXEC insertTreatmentPlan ?, ?, ?, ?, ?, ?, ?",
                time, None, None,
                selected_treatment, patient_id, dentist_id, nurse_id)
        conn.commit()
        # Lấy treatment_plan_id từ stored procedure insertTreatmentPlan
        # cursor.execute("SELECT * from treatmentplan where treatment_plan_created_date = ?",time)
        cursor.execute("SELECT TOP 1 * FROM TreatmentPlan ORDER BY treatment_plan_id DESC;")
        treatment_plan_id = cursor.fetchone()

        # Thực thi stored procedure insertTreatmentSession
        cursor.execute("EXEC insertTreatmentSession ?, ?, ?",
                    formatted_date, None, treatment_plan_id.treatment_plan_id)

        # Thực thi stored procedure insertToothSelection cho mỗi tooth được chọn
        for tooth_data in result:
            tooth_position_id = tooth_data['number']
            surface_code = tooth_data['letter']
            cursor.execute("EXEC insertToothSelection ?, ?, ?",
                        treatment_plan_id.treatment_plan_id, tooth_position_id, surface_code)

    cursor.execute('SELECT * FROM Treatment')
    treatment = cursor.fetchall()
    cursor.execute('SELECT * FROM ToothPosition')
    teeth = cursor.fetchall()
    cursor.execute('SELECT * FROM ToothSurface')
    surfaces = cursor.fetchall()
    return render_template('addtreatmentplan.html', treatment=treatment, teeth=teeth, surfaces=surfaces, patient_id=patient_id)

@app.route('/allergycontracdication', methods = ['POST','GET'])
def allergycontracdication():
    patient_id = request.args.get('get_patient_id')
    drug_id = request.args.get('get_drug_id')
    if drug_id != None:
        cursor.execute(f"Delete * from Contradication where patient_id = ? and drug_id = ?", patient_id, drug_id)
    cursor.execute('SELECT * FROM DrugAllergy where patient_id = ?', patient_id)
    allergy = cursor.fetchall()
    cursor.execute('SELECT * FROM Contradication where patient_id = ?', patient_id)
    contradication = cursor.fetchall()
    return render_template('allergycontracdication.html', allergy=allergy, contradication=contradication, patient_id=patient_id)

@app.route('/adddrugallergy', methods = ['POST','GET'])
def adddrugallergy():
    patient_id = request.args.get('get_patient_id')
    drug_id = request.args.get('get_drug_id')
    if drug_id != None:
        cursor.execute(f"Delete * from drugallergy where patient_id = ? and drug_id = ?", patient_id, drug_id)
    if request.method == 'POST':
        # Lấy thông tin từ form
        drug_id = request.form['drug_id']
        drug_allergy_description = request.form['drug_allergy_description']

        # Thực thi stored procedure
        cursor.execute("EXEC insertDrugAllergy ?, ?, ?",
                       (patient_id, drug_id, drug_allergy_description))
    return render_template('adddrugallergy.html')

@app.route('/addcontradication', methods = ['POST','GET'])
def addcontradication():
    patient_id = request.args.get('get_patient_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        drug_id = request.form['drug_id']
        drug_allergy_description = request.form['drug_allergy_description']

        # Thực thi stored procedure
        cursor.execute("EXEC insertContradiction ?, ?, ?",
                       (patient_id, drug_id, drug_allergy_description))
    return render_template('addcontradication.html')

@app.route('/updatedrugallergy', methods = ['POST','GET'])
def updatedrugallergy():
    patient_id = request.args.get('get_patient_id')
    drug_id = request.args.get('get_drug_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        drug_allergy_description = request.form['drug_allergy_description']

        # Thực thi stored procedure
        cursor.execute("EXEC insertDrugAllergy ?, ?, ?",
                       (patient_id, drug_id, drug_allergy_description))
    return render_template('updatedrugallergy.html')

@app.route('/updatecontradication', methods = ['POST','GET'])
def updatecontradication():
    patient_id = request.args.get('get_patient_id')
    drug_id = request.args.get('get_drug_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        drug_allergy_description = request.form['drug_allergy_description']

        # Thực thi stored procedure
        cursor.execute("EXEC insertContradiction ?, ?, ?",
                       (patient_id, drug_id, drug_allergy_description))
    return render_template('updatecontradication.html')

@app.route('/invoice', methods = ['POST','GET'])
def invoice():
    patient_id = request.args.get('get_patient_id')
    cursor.execute('''
        SELECT *
        FROM Bill 
        WHERE patient_id = ?
    ''', patient_id)
    invoices = cursor.fetchall()
    return render_template('invoice.html', invoices=invoices, patient_id = patient_id)

@app.route('/invoicedetail', methods = ['POST','GET'])
def invoicedetail():
    payment_id = request.args.get('get_payment_id')
    cursor.execute('''SELECT *
        FROM PaymentRecord
        JOIN TreatmentPlan ON TreatmentPlan.treatment_plan_id = PaymentRecord.treatment_plan_id
        JOIN Patient ON Patient.patient_id = TreatmentPlan.patient_id
        JOIN PaymentMethod ON PaymentMethod.payment_method_id = PaymentRecord.payment_method_id
        JOIN Treatment ON Treatment.treatment_id = TreatmentPlan.treatment_id
        WHERE PaymentRecord.payment_id = ?
    ''', payment_id)
    payinfo = cursor.fetchone()
    cursor.execute('''SELECT *
        FROM PaymentRecord
        JOIN TreatmentPlan ON TreatmentPlan.treatment_plan_id = PaymentRecord.treatment_plan_id
        JOIN ToothSelection ON ToothSelection.treatment_plan_id = TreatmentPlan.treatment_plan_id
        JOIN ToothSurface ON ToothSurface.tooth_surface_code = ToothSelection.tooth_surface_code
        JOIN ToothPosition ON ToothPosition.tooth_position_id = ToothSelection.tooth_position_id
        WHERE PaymentRecord.payment_id = ?
    ''', payment_id)
    treatment = cursor.fetchall()
    return render_template('invoicedetail.html', payinfo=payinfo, treatment=treatment)

@app.route('/addinvoice', methods = ['POST','GET'])
def addinvoice():
    patient_id = request.args.get('get_patient_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        paid_time = request.form['paid_time']
        medicalrecordid = request.form['medical_record_id']

        # Thực thi stored procedure
        cursor.execute("EXEC insertBill ?, ?, ?",
                       (paid_time,medicalrecordid
                        , patient_id))
    return render_template('addinvoice.html')

@app.route('/drug', methods = ['POST','GET'])
def drug():
    drug_id = request.args.get('get_drug_id')

    if(drug_id != None):
        cursor.execute(f"EXEC deleteDrug ?", drug_id)
    cursor.execute('SELECT * FROM Drug')
    drugs = cursor.fetchall()
    return render_template('drug.html', drugs=drugs)

@app.route('/adddrug', methods = ['POST','GET'])
def adddrug():
    if request.method == 'POST':
        medicine_name = request.form.get('medicineName')
        stock = request.form.get('stock')
        unit = request.form.get('unit')
        price = request.form.get('price')
        expiry_date = request.form.get('expiryDate')
        contraindications = request.form.get('contraindications')
        cursor.execute(f"EXEC insertDrug ?, ?, ?, ?, ?, ?",unit, medicine_name, contraindications, expiry_date, price, stock)
    return render_template('adddrug.html')

@app.route('/updatedrug', methods = ['POST','GET'])
def updatedrug():
    drug_id = request.args.get('get_drug_id')
    print(drug_id)
    if request.method == 'POST':
        medicine_name = request.form.get('medicineName')
        stock = request.form.get('stock')
        unit = request.form.get('unit')
        price = request.form.get('price')
        expiry_date = request.form.get('expiryDate')
        contraindications = request.form.get('contraindications')
        cursor.execute(f"EXEC updateDrug ?,?, ?, ?, ?, ?, ?",drug_id,unit, medicine_name, contraindications, expiry_date, price, stock)
    return render_template('updatedrug.html',drug_id = drug_id)

@app.route('/prescription', methods = ['POST','GET'])
def prescription():
    treatment_plan_id = request.args.get('get_treatment_plan_id')
    cursor.execute('SELECT * FROM Prescription where treatment_plan_id =?', treatment_plan_id)
    prescription = cursor.fetchall()
    return render_template('prescription.html', prescription=prescription)

@app.route('/addprescription', methods = ['POST','GET'])
def addprescription():
    treatment_plan_id = request.args.get('get_treatment_plan_id')
    if request.method == 'POST':
        # Lấy thông tin từ form
        drug_id = request.form['drug_id']
        drug_quantity = request.form['drug_quantity']

        # Thực thi stored procedure
        cursor.execute("EXEC AddPrescription ?, ?, ?",
                       (treatment_plan_id, drug_id, drug_quantity))
    return render_template('addprescription.html')

@app.route('/updateprescription', methods = ['POST','GET'])
def updateprescription():
    drug_id = request.args.get('get_drug_id')
    if request.method == 'POST':
        medicine_name = request.form.get('medicineName')
        stock = request.form.get('stock')
        price = request.form.get('price')
        expiry_date = request.form.get('expiryDate')
        contraindications = request.form.get('contraindications')
        cursor.execute(f"EXEC updateDrug ?, ?, ?, ?, ?, ?",drug_id, medicine_name, contraindications, expiry_date, price, stock)
    return render_template('updateprescription.html')

@app.route('/appointment', methods = ['POST','GET'])
def appointment():
    cursor.execute('SELECT * FROM Appointment')
    appointments = cursor.fetchall()
    return render_template('appointment.html', appointments = appointments)


@app.route('/addappointment', methods = ['POST','GET'])
def addappointment():
    if request.method == 'POST':
        patient_id = request.form.get('patient_id')
        dentist_id = request.form.get('dentist_id')
        appointment_start_time = request.form.get('appointment_start_time')
        appointment_date = request.form.get('appointment_date')

        # Execute the stored procedure
        cursor.execute("EXEC insertAppointment ?, ?, ?, ?", (patient_id, dentist_id, appointment_start_time, appointment_date))

    return render_template('addappointment.html')

@app.route('/selectAppointment', methods = (['POST', 'GET']))
def selectAppointment():
    # if request.method == 'POST':
    #     date = request.form.get('date')
    #     time = request.form.get('time')
    #     cursor.execute('''SELECT *
    #     FROM Appointment
    #     WHERE appointment_date = ? and appointment_time = ?
    #     ''', date, time)
    return render_template('selectAppointment.html')


@app.route('/personalappointment', methods = (['POST', 'GET']))
def personalappointment():
    employee_id = request.args.get('get_employee_id')
    cursor.execute('SELECT * FROM personalappointment where dentist_id = ?', employee_id)
    personalappointments = cursor.fetchall()
    return render_template('personalappointment.html', personalappointments= personalappointments)

# @app.route('/appointment', methods = (['POST', 'GET']))
# def appointment():
#     if request.method == 'POST':
#         date = request.form.get('date')
#         time = request.form.get('time')
#         cursor.execute('''SELECT *
#         FROM Appointment Join Employee on dentist_id = employee_id
#         WHERE appointment_date = ? and appointment_time = ?
#         ''', date, time)
#         appointments = cursor.fetchall()
#     return render_template('createAppointment.html', appointments = appointments)


# @app.route('/appointmentinfo', methods = ['POST','GET'])
# def appointmentinfo():
#     return render_template('thongtincuochen.html')