import pyodbc
conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                      'Server=LAPTOP-6KGH4NMD;'
                      'Database=QLPHONGKHAMNHAKHOA;'
                      'Trusted_Connection=yes;', autocommit=True) # autocommit for fast transaction


cursor = conn.cursor()