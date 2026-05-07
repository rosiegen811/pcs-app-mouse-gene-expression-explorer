# PCS App Mouse Gene Expression Explorer

Interactive Flask web application for exploring RNA-seq gene expression and differential expression results from AppNL-G-F Alzheimer's disease model mice with perinatal choline supplementation.

## Overview

This application allows users to:

- Search and visualize individual gene expression
- Explore differential expression results across experimental contrasts
- Filter by genotype, sex, age, diet, and tissue
- Access external resources for genes of interest 

The application was developed using:
- Flask
- MariaDB
- HTML/CSS
- Chart.js

The application was tested primarily in Google Chrome. 

---

## Reference Dataset 

This project is based on RNA-seq data from:

**Bellio et al.**
*Perinatal Choline Supplementation Promotes Resilience Against Progression of Alzheimer's Disease-Like Brain Transcriptomic Signatures in AppNL-G-F Mice.*

The reference article PDF is included in:

```text
static/Bellio_2025_Aging_Cell.pdf
```

---

## Repository Structure

```text
.
├── app.py
├── requirements.txt
├── FinalProjectSQLFile.sql
├── Team10_dump.sql.gz
├── data_processing/
├── static/
├── templates/
└── README.md
``` 

### Important Files

| File | Purpose |
|---|---|
| `app.py` | Main Flask application |
| `FinalProjectSQLFile.sql` | Database schema |
| `Team10_dump.sql.gz` | Full compressed MariaDB database export |
| `requirements.txt` | Python package dependencies |
| `data_processing/` | R scripts used to preprocess and organize the given data |
| `static/` | CSS, downloadable files, assets |
| `templates/` | HTML templates for Flask | 

---

## Installation and Setup

### 1. Install Python

Install Python 3.10+.

Check installation:

```bash
python3 --version
``` 

---

### 2. Install MariaDB

Install the free MariaDB Community Server.

Download:
- Windows/macOS/Linux: https://mariadb.org/download/ 

During installation:
- Set a root/admin password when prompted.
- Keep the default port unless you have a reason to change it. The default MariaDB/MySQL port is usually `3306`.

Verify installation:

```bash
mariadb --version
```

---

### 3. Clone the Repository

```bash
git clone https://github.com/rosiegen811/pcs-app-mouse-gene-expression-explorer.git
cd pcs-app-mouse-gene-expression-explorer
```

--- 

### 4. Install Python Dependencies

```bash
pip install -r requirements.txt
```

---

## Database Setup 

### Option A: Import Full Database Dump (Recommended)

The repository includes a compressed export of the full MariaDB database used by the application. 

```bash
gunzip Team10_dump.sql.gz
```

Log into MariaDB as the root/admin user:

```bash
mariadb -u root -p
```

Create the database and a project user:

```sql
CREATE DATABASE pcs_mouse_expression;

CREATE USER 'pcs_user'@'localhost'
IDENTIFIED BY 'your_password_here';

GRANT ALL PRIVILEGES
ON pcs_mouse_expression.*
TO 'pcs_user'@'localhost';

FLUSH PRIVILEGES;
```

Exit MariaDB:

```sql
EXIT;
```

Import the database dump:

```bash
mariadb -u pcs_user -p pcs_mouse_expression < Team10_dump.sql
```

---

### Option B: Import Schema Only

To create only the database structure without data:

```bash
mariadb -u pcs_user -p pcs_mouse_expression < FinalProjectSQLFile.sql
```


---

## Environment Variables 


Create a file named `.env` in the project root directory:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=pcs_user
DB_PASSWORD=your_password_here
DB_NAME=pcs_mouse_expression
``` 

---

## Running the Application 

Start the Flask application:

```bash
python3 app.py
```

Then open the displayed local address in your browser.

Example:

```text
http://127.0.0.1:5000
``` 

---

## Troubleshooting

### MariaDB connection errors

If the application cannot connect to the database:

- Confirm MariaDB is running
- Verify the `.env` credentials are correct
- Verify the database name matches the imported database
- Ensure the database user has privileges on the database

### Missing Python packages

If required Python modules are missing, reinstall dependencies using:

```bash
pip install -r requirements.txt
```

---

## Features 

### Single Gene Lookup

- Search for genes by symbol
- Visualize expression across experimental conditions
- Access external gene resources

### Differential Expression Explorer

- Compare experimental groups
- Filter results dynamically
- View fold change and adjusted p-values

---

## Future Improvements

Potential future extensions include:

- Pathway enrichment analysis
- DNA methylation integration
- Additional visualization options
- Expanded external annotation support 

---

## Authors

Developed as part of a bioinformatics/database systems project.

Contributors:
- Alan Castro 
- Rosalynn Genel
- Swathy Selvakumar
