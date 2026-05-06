-- Drop Table Statements
DROP TABLE IF EXISTS DifferentialExpressionData;
DROP TABLE IF EXISTS NormalisedCounts;
-- ALWAYS drop above tables before dropping ANY below
DROP TABLE IF EXISTS Contrasts;
DROP TABLE IF EXISTS SampleMetadata;
DROP TABLE IF EXISTS Genes;

-- Create Table Statements
CREATE TABLE Genes(
	GeneID integer NOT NULL AUTO_INCREMENT,
    GeneName VARCHAR(250) NOT NULL,
    PRIMARY KEY (GeneID)
)ENGINE = InnoDB;

CREATE TABLE SampleMetadata(
	MouseID integer NOT NULL,
	Sex enum('M','F') NOT NULL,
	Age enum('3','6','9','12')  NOT NULL,
	Genotype enum('WT','APP') NOT NULL,
	Diet enum('Control','Supplemented') NOT NULL,
	HippocampusPathology integer,
	CortexPathology integer,
	PRIMARY KEY (MouseID)
)ENGINE = InnoDB;

CREATE TABLE Contrasts(
	ContrastID integer NOT NULL AUTO_INCREMENT,
	Name varchar (100) NOT NULL,
	Description varchar(100) NOT NULL,
	Age enum('3','6','9','12')  NOT NULL,
	Tissue enum('Cortex','Hippocampus') NOT NULL,
	ContrastGroup1 enum('APP','APP Supplemented', 'WT Supplemented') NOT NULL,
	ContrastGroup2 enum('WT','APP Control','WT Control') NOT NULL,
	PRIMARY KEY (ContrastID)
)ENGINE = InnoDB;
 -- Above tables need to exist before below tables can be created
CREATE TABLE NormalisedCounts(
	GeneID integer,
	MouseID integer,
	NormalisedValue DECIMAL(25, 12),
	TissueLocation enum('Cortex','Hippocampus'),
	primary key (GeneID, MouseID),
	foreign key (GeneID) references Genes(GeneID),
	foreign key (MouseID) references SampleMetadata(MouseID)
)ENGINE = InnoDB;

CREATE TABLE DifferentialExpressionData(
	GeneID integer ,
	ContrastID integer ,
	Log2FC DECIMAL(20, 10),
	PAdj DECIMAL(20, 10),
	primary key (GeneID, ContrastID),
	foreign key (GeneID) references Genes(GeneID),
	foreign key (ContrastID) references Contrasts(ContrastID)
)ENGINE = InnoDB;

-- Bulk Insert Statement. To Use, make sure CSV file column names match Database column names exactly
LOAD DATA LOCAL INFILE -- '/path/to/your/file.csv'
INTO TABLE -- table name
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
 
-- Delete ALL DATA from table statements
DELETE FROM NormalisedCounts ;
DELETE FROM DifferentialExpressionData ;
-- ALWAYS run above two statements before running ANY below
DELETE FROM Contrasts ;
DELETE FROM SampleMetadata ;
DELETE FROM Genes ;
