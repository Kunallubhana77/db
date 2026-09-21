-- ====================================================================
-- Hospital Patient & Appointment Management System
-- Database Schema, Data Ingestion & Queries
-- PostgreSQL 18+
-- ====================================================================

-- 1. DROP EXISTING TABLES (CASCADE)
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- ====================================================================
-- 2. DDL: TABLE DEFINITIONS & INTEGRITY CONSTRAINTS
-- ====================================================================

-- Departments Table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    floor_number INT
);

-- Doctors Table
CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    department_id INT NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    specialization VARCHAR(100),
    consultation_fee NUMERIC(8, 2),
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
);

-- Patients Table (with JSONB semi-structured medical details)
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    phone VARCHAR(15) UNIQUE NOT NULL,
    medical_details JSONB
);

-- Appointments Table (Composite candidate key prevents double-booking)
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    UNIQUE (doctor_id, appointment_date, appointment_time)
);

-- Prescriptions Table
CREATE TABLE prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL,
    medicine_name VARCHAR(100) NOT NULL,
    dosage VARCHAR(50),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE
);

-- ====================================================================
-- 3. DML: SAMPLE DATA INGESTION
-- ====================================================================

-- Ingest Departments
INSERT INTO departments (department_id, department_name, floor_number) VALUES
(1, 'Cardiology', 2),
(2, 'Orthopedics', 3),
(3, 'Pediatrics', 1);

-- Ingest Doctors
INSERT INTO doctors (doctor_id, department_id, email, specialization, consultation_fee) VALUES
(1, 1, 'asha.rao@hosp.com', 'Cardiologist', 800.00),
(2, 1, 'vikram.singh@hosp.com', 'Cardiologist', 650.00),
(3, 2, 'neha.jain@hosp.com', 'Orthopedic Surgeon', 700.00),
(4, 2, 'rohit.mehta@hosp.com', 'Orthopedic Surgeon', 550.00),
(5, 3, 'priya.desai@hosp.com', 'Pediatrician', 500.00);

-- Ingest Patients
INSERT INTO patients (patient_id, phone, medical_details) VALUES
(1, '9876543210', '{"blood_group": "O+", "allergies": ["penicillin", "peanuts"], "emergency_contact": {"name": "Ramesh Kumar", "phone": "9876543210"}}'),
(2, '9123456780', '{"blood_group": "B+", "allergies": ["dust"], "emergency_contact": {"name": "Sunita Kumar", "phone": "9123456780"}}'),
(3, '9988776655', '{"blood_group": "A+", "allergies": [], "emergency_contact": {"name": "Amit Shah", "phone": "9988776655"}}');

-- Ingest Appointments
INSERT INTO appointments (appointment_id, patient_id, doctor_id, appointment_date, appointment_time, status) VALUES
(1, 1, 1, '2026-09-20', '10:00:00', 'Scheduled'),
(2, 2, 3, '2026-09-20', '11:30:00', 'Scheduled'),
(3, 1, 1, '2026-09-21', '09:00:00', 'Completed'),
(4, 3, 5, '2026-09-22', '14:00:00', 'Scheduled');

-- Ingest Prescriptions
INSERT INTO prescriptions (prescription_id, appointment_id, medicine_name, dosage) VALUES
(1, 3, 'Amoxicillin', '500mg twice daily'),
(2, 3, 'Paracetamol', '650mg as needed');

-- Synchronize sequences with max existing IDs
SELECT setval('departments_department_id_seq', (SELECT MAX(department_id) FROM departments));
SELECT setval('doctors_doctor_id_seq', (SELECT MAX(doctor_id) FROM doctors));
SELECT setval('patients_patient_id_seq', (SELECT MAX(patient_id) FROM patients));
SELECT setval('appointments_appointment_id_seq', (SELECT MAX(appointment_id) FROM appointments));
SELECT setval('prescriptions_prescription_id_seq', (SELECT MAX(prescription_id) FROM prescriptions));

-- ====================================================================
-- 4. ANALYTICAL QUERIES (PART C)
-- ====================================================================

-- Q1: Correlated Subquery - Doctors with fee > dept average
SELECT 
    d.doctor_id, 
    d.department_id, 
    d.email, 
    d.specialization, 
    d.consultation_fee
FROM doctors d
WHERE d.consultation_fee > (
    SELECT AVG(d2.consultation_fee)
    FROM doctors d2
    WHERE d2.department_id = d.department_id
);

-- Q2: LEFT JOIN - Count of appointments per doctor (including zero)
SELECT 
    d.doctor_id,
    d.email,
    COUNT(a.appointment_id) AS appointment_count
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.email
ORDER BY d.doctor_id;

-- Q3: JSONB querying - Find patients allergic to 'penicillin'
SELECT 
    patient_id,
    phone,
    medical_details
FROM patients
WHERE medical_details->'allergies' ? 'penicillin';

-- Q4: Transaction / ACID Safety with SAVEPOINT
BEGIN;
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (1, 2, '2026-09-23', '10:30:00', 'Scheduled');

SAVEPOINT prescription_savepoint;

-- Attempting medication contraindicated by patient allergy
INSERT INTO prescriptions (appointment_id, medicine_name, dosage)
VALUES (5, 'Penicillin', '500mg twice daily');

-- Rollback ONLY the dangerous prescription
ROLLBACK TO SAVEPOINT prescription_savepoint;

-- Commit the appointment booking
COMMIT;
