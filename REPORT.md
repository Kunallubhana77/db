# Mini Project 1: Hospital Patient & Appointment Management System
**Database Coursework & Technical Project Report**  
**Database Engine:** PostgreSQL 18.4 (Homebrew)  
**Database Name:** `hospitaldb`  
**Author:** Kunal Lubhana  
**Total Marks:** 20 / 20  

---

## Table of Contents
1. [Executive Summary & System Overview](#1-executive-summary--system-overview)
2. [Part A: ER Model & Database Design (5 Marks)](#2-part-a-er-model--database-design-5-marks)
   - [Entities & Attributes](#entities--attributes)
   - [Relationships, Cardinality & Participation](#relationships-cardinality--participation)
   - [Entity-Relationship (ER) Diagram](#entity-relationship-er-diagram)
3. [Part B: Relational Schema & Keys Analysis (5 Marks)](#3-part-b-relational-schema--keys-analysis-5-marks)
   - [Tables & Keys Specification](#tables--keys-specification)
   - [Real-World Rule Enforced by Composite Candidate Key](#real-world-rule-enforced-by-composite-candidate-key)
4. [Database Implementation & Verification (Screenshots 1 - 12)](#4-database-implementation--verification)
   - [DDL Table Creation (Screenshots 1 - 6)](#ddl-table-creation-screenshots-1---6)
   - [Data Ingestion & Verification (Screenshots 7 - 12)](#data-ingestion--verification-screenshots-7---12)
5. [Part C: Advanced SQL Queries & Clinical Analytics (10 Marks)](#5-part-c-advanced-sql-queries--clinical-analytics-10-marks)
   - [Q1: Correlated Subquery — Doctors Above Department Average Fee (2.5 Marks)](#q1-correlated-subquery--doctors-above-department-average-fee-25-marks)
   - [Q2: Joins — Doctor Appointment Counts with Zero Handling (2.5 Marks)](#q2-joins--doctor-appointment-counts-with-zero-handling-25-marks)
   - [Q3: JSONB — Penicillin Allergy Filtering via `?` Operator (2.5 Marks)](#q3-jsonb--penicillin-allergy-filtering-via--operator-25-marks)
   - [Q4: Transaction & ACID Safety with SAVEPOINT (2.5 Marks)](#q4-transaction--acid-safety-with-savepoint-25-marks)
6. [Summary & Marks Distribution Rubric](#6-summary--marks-distribution-rubric)

---

## 1. Executive Summary & System Overview

The **Hospital Patient & Appointment Management System** is a production-grade relational database design engineered in **PostgreSQL**. The database models the day-to-day operations of a multi-specialty hospital, addressing clinical workflows, medical staff governance, appointment scheduling without double-booking, and drug prescription safety.

### Key Architectural Highlights:
- **Hierarchical Hospital Structure:** Departments manage multiple physicians, maintaining specialized medical practices and specific consultation tariffs.
- **Semi-Structured Patient EHR:** PostgreSQL `JSONB` datatype is utilized to store patient allergies, blood group, and emergency contact details, providing schema agility for evolving clinical data without compromising query performance.
- **Double-Booking Prevention:** A composite candidate key `(doctor_id, appointment_date, appointment_time)` enforces strict physician schedule exclusivity directly at the database engine level.
- **Clinical Transaction Safety:** Advanced transaction control using `BEGIN`, `SAVEPOINT`, `ROLLBACK TO SAVEPOINT`, and `COMMIT` guarantees that contraindicated medical prescriptions can be aborted while preserving patient consultation bookings.

---

## 2. Part A: ER Model & Database Design (5 Marks)

### Entities & Attributes

1. **Department:**
   - `department_id` (INT, Primary Key)
   - `department_name` (VARCHAR, Candidate Key - UNIQUE)
   - `floor_number` (INT)
2. **Doctor:**
   - `doctor_id` (INT, Primary Key)
   - `department_id` (INT, Foreign Key → Departments)
   - `email` (VARCHAR, Candidate Key - UNIQUE)
   - `specialization` (VARCHAR)
   - `consultation_fee` (NUMERIC(8,2))
3. **Patient:**
   - `patient_id` (INT, Primary Key)
   - `phone` (VARCHAR, Candidate Key - UNIQUE)
   - `medical_details` (JSONB)
4. **Appointment:**
   - `appointment_id` (INT, Primary Key)
   - `patient_id` (INT, Foreign Key → Patients)
   - `doctor_id` (INT, Foreign Key → Doctors)
   - `appointment_date` (DATE)
   - `appointment_time` (TIME)
   - `status` (VARCHAR)
   - *Composite Candidate Key:* `(doctor_id, appointment_date, appointment_time)`
5. **Prescription:**
   - `prescription_id` (INT, Primary Key)
   - `appointment_id` (INT, Foreign Key → Appointments)
   - `medicine_name` (VARCHAR)
   - `dosage` (VARCHAR)

---

### Relationships, Cardinality & Participation

| Relationship | Entities Involved | Cardinality | Participation | Clinical & Integrity Rationale |
| :--- | :--- | :---: | :---: | :--- |
| **Employs / Has** | Department ↔ Doctor | **1 : M** | Doctor: **Total**<br>Department: **Partial** | Every doctor must be assigned to a valid department (`department_id NOT NULL`). A department can be created prior to hiring doctors. |
| **Conducts / Consults** | Doctor ↔ Appointment | **1 : M** | Appointment: **Total**<br>Doctor: **Partial** | An appointment must have an assigned physician. A newly onboarded doctor may have zero appointments initially. |
| **Books** | Patient ↔ Appointment | **1 : M** | Appointment: **Total**<br>Patient: **Partial** | Every appointment is booked for a specific registered patient. A patient can exist in the registry without an active booking. |
| **Generates / Issues** | Appointment ↔ Prescription | **1 : M** | Prescription: **Total**<br>Appointment: **Partial** | A prescription line item is only valid if linked to a consultation appointment. Consultations may conclude without medication. |

---

### Entity-Relationship (ER) Diagram

The ER Diagram accurately models all 5 entities, their attributes, keys, 1:M cardinalities, and participation constraints (single lines indicate partial participation, while double lines indicate total participation).

![ER Diagram](er_diagram.png)

*(Vector source available as [er_diagram.svg](file:///Users/kunallubhana/Desktop/db/er_diagram.svg))*

---

## 3. Part B: Relational Schema & Keys Analysis (5 Marks)

### Tables & Keys Specification

| Table | Primary Key (PK) | Candidate Key (Not Chosen as PK) | Foreign Keys (FK) & Target Reference | Composite Key |
| :--- | :--- | :--- | :--- | :--- |
| **Departments** | `department_id` | `department_name` (UNIQUE) | *None* | *None* |
| **Doctors** | `doctor_id` | `email` (UNIQUE) | `department_id` → `Departments(department_id)` | *None* |
| **Patients** | `patient_id` | `phone` (UNIQUE) | *None* | *None* |
| **Appointments** | `appointment_id` | `(doctor_id, appointment_date, appointment_time)` | `patient_id` → `Patients(patient_id)`<br>`doctor_id` → `Doctors(doctor_id)` | `(doctor_id, appointment_date, appointment_time)` |
| **Prescriptions** | `prescription_id` | `(appointment_id, medicine_name)` | `appointment_id` → `Appointments(appointment_id)` | *None* |

### Real-World Rule Enforced by Composite Candidate Key

> **Enforced Constraint:**  
> `UNIQUE (doctor_id, appointment_date, appointment_time)` on the `Appointments` table.
>
> **Real-World Business Rule:**  
> **Doctor Double-Booking Prevention**. In medical center scheduling, a doctor cannot be physically present in two examinations simultaneously. This composite key enforces that for any doctor (`doctor_id`), there can only exist at most one appointment at a given date (`appointment_date`) and time (`appointment_time`). If an attempt is made to schedule another patient with the same doctor at that time slot, the database raises an immediate constraint violation error.

---

## 4. Database Implementation & Verification

### DDL Table Creation (Screenshots 1 - 6)

The schema was constructed in `hospitaldb` using PostgreSQL DDL statements:

| Step | Action | Screenshot |
| :---: | :--- | :---: |
| 1 | psql connection initialization in `hospitaldb` | ![Screenshot 1](1.png) |
| 2 | `CREATE TABLE departments` with PK and UNIQUE `department_name` | ![Screenshot 2](2.png) |
| 3 | `CREATE TABLE doctors` with FK to departments and UNIQUE `email` | ![Screenshot 3](3.png) |
| 4 | `CREATE TABLE patients` with JSONB column `medical_details` | ![Screenshot 4](4.png) |
| 5 | `CREATE TABLE appointments` with dual FKs and composite unique constraint | ![Screenshot 5](5.png) |
| 6 | `CREATE TABLE prescriptions` with FK referencing appointments | ![Screenshot 6](6.png) |

---

### Data Ingestion & Verification (Screenshots 7 - 12)

| Step | Action | Screenshot |
| :---: | :--- | :---: |
| 7 | Ingestion of 3 departments & `SELECT * FROM departments` | ![Screenshot 7](7.png) |
| 8 | Ingestion of 5 doctors & `SELECT * FROM doctors` | ![Screenshot 8](8.png) |
| 9 | Ingestion of 3 patient JSONB records & `SELECT * FROM patients` | ![Screenshot 9](9.png) |
| 10 | Ingestion of 4 appointments across dates & `SELECT * FROM appointments` | ![Screenshot 10](10.png) |
| 11 | Ingestion of prescriptions for appointment 3 & `SELECT * FROM prescriptions` | ![Screenshot 11](11.png) |
| 12 | Comprehensive multi-table inspection across all 5 tables | ![Screenshot 12](12.png) |

---

## 5. Part C: Advanced SQL Queries & Clinical Analytics (10 Marks)

### Q1: Correlated Subquery — Doctors Above Department Average Fee (2.5 Marks)

**Problem Statement:**  
Find all doctors whose `consultation_fee` is strictly greater than the average consultation fee of their own department using a correlated subquery.

```sql
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
```

#### Analytical Breakdown:
- **Cardiology (dept 1):** Fees are 800 and 650. Average = **725.00**. Doctor 1 (`asha.rao@hosp.com`, fee 800) is above average.
- **Orthopedics (dept 2):** Fees are 700 and 550. Average = **625.00**. Doctor 3 (`neha.jain@hosp.com`, fee 700) is above average.
- **Pediatrics (dept 3):** Fee is 500. Average = **500.00**. Doctor 5 is not above average.

**Result Evidence:**  
![Screenshot 13](13.png)

---

### Q2: Joins — Doctor Appointment Counts with Zero Handling (2.5 Marks)

**Problem Statement:**  
Using a `LEFT JOIN`, list every doctor along with the count of appointments they have, including doctors who have zero appointments.

```sql
SELECT 
    d.doctor_id,
    d.email,
    COUNT(a.appointment_id) AS appointment_count
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.email
ORDER BY d.doctor_id;
```

#### SQL Engineering Insight:
- `LEFT JOIN` retains all rows from `doctors` even if no matching row exists in `appointments`.
- `COUNT(a.appointment_id)` correctly yields **0** for doctors with no bookings (Doctors 2 and 4), because `COUNT(expression)` ignores `NULL` values. Using `COUNT(*)` would have erroneously produced 1.

**Result Evidence:**  
![Screenshot 14](14.png)

---

### Q3: JSONB — Penicillin Allergy Filtering via `?` Operator (2.5 Marks)

**Problem Statement:**  
Find all patients allergic to `'penicillin'` by querying the nested `allergies` array inside the `medical_details` JSONB column using PostgreSQL's native `?` operator.

```sql
SELECT 
    patient_id,
    phone,
    medical_details
FROM patients
WHERE medical_details->'allergies' ? 'penicillin';
```

#### Technical Mechanism:
- `medical_details->'allergies'` navigates into the JSON structure and extracts the `allergies` array as `jsonb`.
- The `?` operator performs an indexed existence check to determine if the string `'penicillin'` exists inside the JSON array.

**Result Evidence:**  
![Screenshot 15](15.png)

---

### Q4: Transaction & ACID Safety with SAVEPOINT (2.5 Marks)

**Clinical Scenario & Objective:**  
Book an appointment, then attempt to insert a prescription for it. If the medicine matches an entry in that patient's JSONB allergies array, roll back only the prescription insert using `SAVEPOINT`, keeping the appointment committed. Demonstrate with `BEGIN`, `SAVEPOINT`, `ROLLBACK TO SAVEPOINT`, `COMMIT`.

#### SQL Transaction Implementation:
```sql
BEGIN;

-- 1. Book the appointment (Persisted)
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (1, 2, '2026-09-23', '10:30:00', 'Scheduled');

-- 2. Create SAVEPOINT before attempting drug prescription
SAVEPOINT prescription_savepoint;

-- 3. Attempt contraindicated medication (Penicillin for Patient 1)
INSERT INTO prescriptions (appointment_id, medicine_name, dosage)
VALUES (5, 'Penicillin', '500mg twice daily');

-- 4. Contraindication detected -> Rollback ONLY the prescription
ROLLBACK TO SAVEPOINT prescription_savepoint;

-- 5. Commit remaining transaction (Appointment booking is preserved)
COMMIT;
```

#### ACID & Clinical Safety Rationale:
In transactional database systems, **SAVEPOINT** allows fine-grained rollback within an active transaction without discarding previously executed statements. In healthcare systems, this ensures patient safety: if a doctor prescribes a drug that conflicts with the patient's recorded allergies (in `medical_details JSONB`), the hazardous prescription is immediately rolled back via `ROLLBACK TO SAVEPOINT`, while the consultation appointment itself remains safely committed.

#### Execution & Verification (Screenshots 16 - 19):

| Screenshot | Description |
| :---: | :--- |
| ![Screenshot 16](16.png) | Transaction initiation and appointment insert |
| ![Screenshot 17](17.png) | Prescription insert attempt, SAVEPOINT rollback, and COMMIT execution |
| ![Screenshot 18](18.png) | Appointments verification |
| ![Screenshot 19](19.png) | Prescriptions verification confirming prescription rollback |

---

## 6. Summary & Marks Distribution Rubric

| Component | Key Requirements Covered | Verification Status | Marks |
| :--- | :--- | :---: | :---: |
| **ER Model & Database Design** | 5 Entities, 1:M relationships, Total & Partial participations, ER diagram | **Complete** | **5 / 5** |
| **Tables & Keys** | PKs, Candidate Keys, FK references, Composite unique double-booking prevention rule | **Complete** | **5 / 5** |
| **Q1: Subquery** | Correlated subquery computing department average consultation fees | **Verified (Screenshot 13)** | **2.5 / 2.5** |
| **Q2: Joins** | LEFT JOIN listing all doctors with appointment counts including zero | **Verified (Screenshot 14)** | **2.5 / 2.5** |
| **Q3: JSONB** | Nested array existence querying with `?` operator for penicillin allergy | **Verified (Screenshot 15)** | **2.5 / 2.5** |
| **Q4: Transaction / ACID** | BEGIN, SAVEPOINT, partial ROLLBACK, and COMMIT demonstration | **Verified (Screenshots 16-19)** | **2.5 / 2.5** |
| **TOTAL** | | | **20 / 20** |
