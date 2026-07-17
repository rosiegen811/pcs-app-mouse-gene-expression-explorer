/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.4.10-MariaDB, for Linux (x86_64)
--
-- Host: bioed-new.bu.edu    Database: Team10
-- ------------------------------------------------------
-- Server version	11.4.10-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `Contrasts`
--

DROP TABLE IF EXISTS `Contrasts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `Contrasts` (
  `ContrastID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) NOT NULL,
  `Description` varchar(100) NOT NULL,
  `Age` enum('3','6','9','12') NOT NULL,
  `Tissue` enum('Cortex','Hippocampus') NOT NULL,
  `ContrastGroup1` enum('APP','APP Supplemented','WT Supplemented') NOT NULL,
  `ContrastGroup2` enum('WT','APP Control','WT Control') NOT NULL,
  PRIMARY KEY (`ContrastID`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DifferentialExpressionData`
--

DROP TABLE IF EXISTS `DifferentialExpressionData`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `DifferentialExpressionData` (
  `GeneID` int(11) NOT NULL,
  `ContrastID` int(11) NOT NULL,
  `Log2FC` decimal(20,10) DEFAULT NULL,
  `PAdj` decimal(20,10) DEFAULT NULL,
  PRIMARY KEY (`GeneID`,`ContrastID`),
  KEY `ContrastID` (`ContrastID`),
  KEY `idx_de_padj` (`PAdj`),
  CONSTRAINT `DifferentialExpressionData_ibfk_1` FOREIGN KEY (`GeneID`) REFERENCES `Genes` (`GeneID`),
  CONSTRAINT `DifferentialExpressionData_ibfk_2` FOREIGN KEY (`ContrastID`) REFERENCES `Contrasts` (`ContrastID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Genes`
--

DROP TABLE IF EXISTS `Genes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `Genes` (
  `GeneID` int(11) NOT NULL AUTO_INCREMENT,
  `GeneName` varchar(250) NOT NULL,
  PRIMARY KEY (`GeneID`)
) ENGINE=InnoDB AUTO_INCREMENT=19369 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `NormalisedCounts`
--

DROP TABLE IF EXISTS `NormalisedCounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `NormalisedCounts` (
  `GeneID` int(11) NOT NULL,
  `MouseID` int(11) NOT NULL,
  `NormalisedValue` decimal(25,12) DEFAULT NULL,
  `TissueLocation` enum('Cortex','Hippocampus') DEFAULT NULL,
  PRIMARY KEY (`GeneID`,`MouseID`),
  KEY `idx_counts_gene` (`GeneID`),
  KEY `idx_counts_mouse` (`MouseID`),
  CONSTRAINT `NormalisedCounts_ibfk_1` FOREIGN KEY (`GeneID`) REFERENCES `Genes` (`GeneID`),
  CONSTRAINT `NormalisedCounts_ibfk_2` FOREIGN KEY (`MouseID`) REFERENCES `SampleMetadata` (`MouseID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SampleMetadata`
--

DROP TABLE IF EXISTS `SampleMetadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `SampleMetadata` (
  `MouseID` int(11) NOT NULL,
  `Sex` enum('M','F') NOT NULL,
  `Age` enum('3','6','9','12') NOT NULL,
  `Genotype` enum('WT','APP') NOT NULL,
  `Diet` enum('Control','Supplemented') NOT NULL,
  `HippocampusPathology` int(11) DEFAULT NULL,
  `CortexPathology` int(11) DEFAULT NULL,
  PRIMARY KEY (`MouseID`),
  KEY `idx_metadata_mouse` (`MouseID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-05-06 16:16:04
