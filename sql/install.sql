-- ════════════════════════════════════════════════════════════════════
-- MEDIT8Z MDT - DATABASE STRUCTURE
-- Version: 0.1.0
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
-- PROFILES TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_profiles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizen_id` varchar(50) NOT NULL,
    `first_name` varchar(50) NOT NULL,
    `last_name` varchar(50) NOT NULL,
    `dob` date DEFAULT NULL,
    `gender` varchar(10) DEFAULT NULL,
    `phone` varchar(20) DEFAULT NULL,
    `address` varchar(255) DEFAULT NULL,
    `photo` text DEFAULT NULL,
    `fingerprint` varchar(50) DEFAULT NULL,
    `dna` varchar(50) DEFAULT NULL,
    `notes` text DEFAULT NULL,
    `flags` text DEFAULT NULL, -- JSON array of flags
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizen_id` (`citizen_id`),
    INDEX `idx_name` (`first_name`, `last_name`),
    INDEX `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- INCIDENTS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_incidents` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `incident_number` varchar(50) NOT NULL,
    `title` varchar(255) NOT NULL,
    `type` varchar(50) DEFAULT NULL,
    `location` varchar(255) DEFAULT NULL,
    `description` text DEFAULT NULL,
    `evidence` text DEFAULT NULL, -- JSON array
    `officers` text DEFAULT NULL, -- JSON array
    `citizens` text DEFAULT NULL, -- JSON array
    `vehicles` text DEFAULT NULL, -- JSON array
    `status` varchar(50) DEFAULT 'open',
    `created_by` varchar(50) NOT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `incident_number` (`incident_number`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- REPORTS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_reports` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `report_number` varchar(50) NOT NULL,
    `incident_id` int(11) DEFAULT NULL,
    `type` varchar(50) NOT NULL,
    `title` varchar(255) NOT NULL,
    `content` text NOT NULL,
    `charges` text DEFAULT NULL, -- JSON array
    `fine_amount` decimal(10,2) DEFAULT 0,
    `jail_time` int(11) DEFAULT 0,
    `created_by` varchar(50) NOT NULL,
    `created_by_name` varchar(100) NOT NULL,
    `status` varchar(50) DEFAULT 'pending',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `report_number` (`report_number`),
    FOREIGN KEY (`incident_id`) REFERENCES `medit8z_mdt_incidents`(`id`) ON DELETE SET NULL,
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- WARRANTS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_warrants` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `warrant_number` varchar(50) NOT NULL,
    `citizen_id` varchar(50) NOT NULL,
    `citizen_name` varchar(100) NOT NULL,
    `reason` text NOT NULL,
    `incident_id` int(11) DEFAULT NULL,
    `status` varchar(50) DEFAULT 'pending', -- pending, active, served, expired, denied
    `requested_by` varchar(50) NOT NULL,
    `requested_by_name` varchar(100) NOT NULL,
    `approved_by` varchar(50) DEFAULT NULL,
    `approved_by_name` varchar(100) DEFAULT NULL,
    `approved_at` timestamp NULL DEFAULT NULL,
    `expires_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `warrant_number` (`warrant_number`),
    INDEX `idx_citizen` (`citizen_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- BOLOS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_bolos` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `bolo_number` varchar(50) NOT NULL,
    `type` varchar(50) NOT NULL, -- person, vehicle, item
    `title` varchar(255) NOT NULL,
    `description` text NOT NULL,
    `images` text DEFAULT NULL, -- JSON array
    `plate` varchar(20) DEFAULT NULL,
    `vehicle_info` text DEFAULT NULL,
    `citizen_id` varchar(50) DEFAULT NULL,
    `citizen_name` varchar(100) DEFAULT NULL,
    `status` varchar(50) DEFAULT 'active',
    `created_by` varchar(50) NOT NULL,
    `created_by_name` varchar(100) NOT NULL,
    `expires_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `bolo_number` (`bolo_number`),
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- VEHICLES TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `plate` varchar(20) NOT NULL,
    `owner_id` varchar(50) NOT NULL,
    `owner_name` varchar(100) NOT NULL,
    `make` varchar(50) DEFAULT NULL,
    `model` varchar(50) DEFAULT NULL,
    `color` varchar(50) DEFAULT NULL,
    `year` int(4) DEFAULT NULL,
    `vin` varchar(50) DEFAULT NULL,
    `status` varchar(50) DEFAULT 'valid', -- valid, stolen, impounded
    `insurance_status` varchar(50) DEFAULT 'valid',
    `registration_status` varchar(50) DEFAULT 'valid',
    `points` int(11) DEFAULT 0,
    `flags` text DEFAULT NULL, -- JSON array
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    INDEX `idx_owner` (`owner_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- WEAPONS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_weapons` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `serial_number` varchar(50) NOT NULL,
    `owner_id` varchar(50) NOT NULL,
    `owner_name` varchar(100) NOT NULL,
    `weapon_type` varchar(50) NOT NULL,
    `weapon_name` varchar(100) NOT NULL,
    `status` varchar(50) DEFAULT 'valid', -- valid, stolen, confiscated
    `permit_number` varchar(50) DEFAULT NULL,
    `permit_expires` date DEFAULT NULL,
    `registered_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `serial_number` (`serial_number`),
    INDEX `idx_owner` (`owner_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- EVIDENCE TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_evidence` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `evidence_number` varchar(50) NOT NULL,
    `incident_id` int(11) DEFAULT NULL,
    `type` varchar(50) NOT NULL,
    `description` text NOT NULL,
    `location` varchar(255) DEFAULT NULL,
    `photos` text DEFAULT NULL, -- JSON array
    `chain_of_custody` text DEFAULT NULL, -- JSON array
    `status` varchar(50) DEFAULT 'collected',
    `collected_by` varchar(50) NOT NULL,
    `collected_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `evidence_number` (`evidence_number`),
    FOREIGN KEY (`incident_id`) REFERENCES `medit8z_mdt_incidents`(`id`) ON DELETE SET NULL,
    INDEX `idx_incident` (`incident_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- LOGS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` varchar(50) NOT NULL,
    `user_name` varchar(100) NOT NULL,
    `action` varchar(50) NOT NULL, -- create, update, delete, view
    `target_type` varchar(50) NOT NULL, -- profile, incident, report, etc.
    `target_id` varchar(50) NOT NULL,
    `details` text DEFAULT NULL,
    `ip_address` varchar(45) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_action` (`action`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- TOWING TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_towing` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `request_number` varchar(50) NOT NULL,
    `vehicle_plate` varchar(20) DEFAULT NULL,
    `vehicle_info` text DEFAULT NULL,
    `location` varchar(255) NOT NULL,
    `reason` varchar(100) NOT NULL,
    `requested_by` varchar(50) NOT NULL,
    `requested_by_name` varchar(100) NOT NULL,
    `company` varchar(50) DEFAULT NULL,
    `driver` varchar(100) DEFAULT NULL,
    `status` varchar(50) DEFAULT 'pending',
    `fee` decimal(10,2) DEFAULT 0,
    `paid_by` varchar(100) DEFAULT NULL,
    `receipt_number` varchar(50) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `completed_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `request_number` (`request_number`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- MEDICAL RECORDS TABLE (EMS)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_medical` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `patient_id` varchar(50) NOT NULL,
    `patient_name` varchar(100) NOT NULL,
    `blood_type` varchar(10) DEFAULT NULL,
    `allergies` text DEFAULT NULL,
    `medications` text DEFAULT NULL,
    `conditions` text DEFAULT NULL,
    `emergency_contact` varchar(255) DEFAULT NULL,
    `notes` text DEFAULT NULL,
    `last_visit` timestamp NULL DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `patient_id` (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- COURT CASES TABLE (DOJ)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_court` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `case_number` varchar(50) NOT NULL,
    `defendant_id` varchar(50) NOT NULL,
    `defendant_name` varchar(100) NOT NULL,
    `charges` text NOT NULL, -- JSON array
    `plea` varchar(50) DEFAULT NULL,
    `verdict` varchar(50) DEFAULT NULL,
    `sentence` text DEFAULT NULL,
    `fine` decimal(10,2) DEFAULT 0,
    `jail_time` int(11) DEFAULT 0,
    `judge` varchar(100) DEFAULT NULL,
    `prosecutor` varchar(100) DEFAULT NULL,
    `defender` varchar(100) DEFAULT NULL,
    `scheduled_date` timestamp NULL DEFAULT NULL,
    `status` varchar(50) DEFAULT 'scheduled',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `case_number` (`case_number`),
    INDEX `idx_defendant` (`defendant_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- DEFAULT DATA
-- ════════════════════════════════════════════════════════════════════
-- Add any default data here if needed

-- Installation complete
SELECT 'Medit8z MDT Database Installation Complete!' as Status;

-- ════════════════════════════════════════════════════════════════════
-- PHASE 2: ADDITIONAL DATABASE TABLES
-- Run this after the initial install.sql
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
-- PROBATION TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_probation` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizen_id` varchar(50) NOT NULL,
    `citizen_name` varchar(100) NOT NULL,
    `start_date` timestamp DEFAULT CURRENT_TIMESTAMP,
    `end_date` timestamp NOT NULL,
    `conditions` text DEFAULT NULL, -- JSON array of conditions
    `officer_id` varchar(50) NOT NULL,
    `officer_name` varchar(100) NOT NULL,
    `violations` text DEFAULT NULL, -- JSON array of violations
    `status` varchar(50) DEFAULT 'active', -- active, completed, violated, revoked
    `notes` text DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizen` (`citizen_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_end_date` (`end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- UNIT STATUS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_unit_status` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `unit_id` varchar(50) NOT NULL,
    `unit_name` varchar(100) NOT NULL,
    `callsign` varchar(20) DEFAULT NULL,
    `status` varchar(20) DEFAULT '10-8', -- 10-8, 10-7, 10-6, 10-97, 10-23
    `department` varchar(50) DEFAULT NULL,
    `location` varchar(255) DEFAULT NULL,
    `last_update` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unit_id` (`unit_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- DISPATCH CALLS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_calls` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `call_number` varchar(50) NOT NULL,
    `type` varchar(50) NOT NULL, -- 911, 311, 10-99, etc.
    `priority` int(1) DEFAULT 3, -- 1 (highest) to 5 (lowest)
    `location` varchar(255) NOT NULL,
    `description` text NOT NULL,
    `caller_name` varchar(100) DEFAULT NULL,
    `caller_number` varchar(20) DEFAULT NULL,
    `assigned_units` text DEFAULT NULL, -- JSON array
    `status` varchar(50) DEFAULT 'pending', -- pending, dispatched, enroute, onscene, completed
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `dispatched_at` timestamp NULL DEFAULT NULL,
    `completed_at` timestamp NULL DEFAULT NULL,
    `response_time` int(11) DEFAULT NULL, -- in seconds
    PRIMARY KEY (`id`),
    UNIQUE KEY `call_number` (`call_number`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- DEPARTMENT STATISTICS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_statistics` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `date` date NOT NULL,
    `department` varchar(50) NOT NULL,
    `arrests` int(11) DEFAULT 0,
    `citations` int(11) DEFAULT 0,
    `reports` int(11) DEFAULT 0,
    `warrants_served` int(11) DEFAULT 0,
    `calls_responded` int(11) DEFAULT 0,
    `avg_response_time` int(11) DEFAULT NULL, -- in seconds
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `date_dept` (`date`, `department`),
    INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS TABLE
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_notifications` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `recipient_id` varchar(50) NOT NULL,
    `type` varchar(50) NOT NULL, -- info, call, emergency, warrant, etc.
    `title` varchar(255) NOT NULL,
    `message` text NOT NULL,
    `data` text DEFAULT NULL, -- JSON data for actions
    `read` tinyint(1) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_recipient` (`recipient_id`),
    INDEX `idx_read` (`read`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- ACTIVITY LOG TABLE (For Recent Activity Feed)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `medit8z_mdt_activity` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `type` varchar(50) NOT NULL, -- arrest, report, warrant, bolo, etc.
    `action` varchar(50) NOT NULL, -- created, updated, deleted, served, etc.
    `user_id` varchar(50) NOT NULL,
    `user_name` varchar(100) NOT NULL,
    `target_type` varchar(50) DEFAULT NULL,
    `target_id` varchar(50) DEFAULT NULL,
    `description` text DEFAULT NULL,
    `metadata` text DEFAULT NULL, -- JSON for additional data
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ════════════════════════════════════════════════════════════════════
-- Sample Data for Testing
-- ════════════════════════════════════════════════════════════════════

-- Add sample probation records
INSERT INTO `medit8z_mdt_probation` (`citizen_id`, `citizen_name`, `end_date`, `conditions`, `officer_id`, `officer_name`, `status`) VALUES
('ABC123', 'John Doe', DATE_ADD(NOW(), INTERVAL 30 DAY), '["No alcohol","Weekly check-ins","Community service"]', 'OFF001', 'Officer Smith', 'active'),
('DEF456', 'Jane Smith', DATE_ADD(NOW(), INTERVAL 60 DAY), '["House arrest","Drug testing"]', 'OFF002', 'Officer Johnson', 'active');

-- Add sample statistics for today
INSERT INTO `medit8z_mdt_statistics` (`date`, `department`, `arrests`, `citations`, `reports`, `calls_responded`) VALUES
(CURDATE(), 'Police', 5, 12, 8, 25);

SELECT 'Phase 2 Database Tables Added Successfully!' as Status;