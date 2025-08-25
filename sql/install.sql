-- Medit8z MDT Database Structure
-- Version: 0.1.0

CREATE TABLE IF NOT EXISTS medit8z_mdt_profiles (
    id int(11) NOT NULL AUTO_INCREMENT,
    citizen_id varchar(50) NOT NULL,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
