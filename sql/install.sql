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