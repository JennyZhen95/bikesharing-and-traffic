-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


drop schema if exists `mydb`;
-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;
-- -----------------------------------------------------
-- Table `mydb`.`neighborhood`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`neighborhood` ;

CREATE TABLE IF NOT EXISTS `mydb`.`neighborhood` (
  `neighborhood_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(45) NULL,
  PRIMARY KEY (`neighborhood_id`)
  )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`stations`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`stations` ;

CREATE TABLE IF NOT EXISTS `mydb`.`stations` (
  `station_id` INT UNSIGNED NOT NULL,
  `station_name` VARCHAR(45) NOT NULL,
  `address` VARCHAR(45) NOT NULL,
  `total_docks` INT NULL,
  `docks_in_service` INT NULL,
  `status` VARCHAR(20) NULL,
  `lat` DECIMAL(20,11) NOT NULL,
  `long` DECIMAL(20,11) NOT NULL,
  `neighborhood_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`station_id`),
  UNIQUE INDEX `station_id_UNIQUE` (`station_id` ASC),
  constraint `fk_stations_neighborhood`
	foreign key (`neighborhood_id`)
    references `mydb`.`neighborhood` (`neighborhood_id`)
    on delete no action
    on update no action
  )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`datetime`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`datetime` ;

CREATE TABLE IF NOT EXISTS `mydb`.`datetime` (
  `datetime_id` INT UNSIGNED NOT NULL,
  `datetime` DATE NOT NULL,
  `month` INT NULL,
  `year` INT NULL,
  `hour` INT NULL,
  `day_of_week` INT NULL,
  `day` INT NULL,
  PRIMARY KEY (`datetime_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`trips`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`trips` ;

CREATE TABLE IF NOT EXISTS `mydb`.`trips` (
  `trip_id` INT UNSIGNED NOT NULL,
  `start_datetime_id` INT UNSIGNED NOT NULL,
  `end_datetime_id` INT UNSIGNED NOT NULL,
  `tripduration` INT UNSIGNED NULL,
  `from_station_id` INT UNSIGNED NOT NULL,
  `to_station_id` INT UNSIGNED NOT NULL,
  `bikeid` INT NOT NULL,
  `gender` VARCHAR(45) NULL,
  `birthyear` INT NULL,
  PRIMARY KEY (`trip_id`),
  UNIQUE INDEX `trip_id_UNIQUE` (`trip_id` ASC),
  constraint `fk_trips_datetime`
	foreign key (`start_datetime_id`)
    references `mydb`.`datetime` (`datetime_id`)
    on delete no action
    on update no action,
  constraint `fk_trips_datetime2`
	foreign key (`end_datetime_id`)
    references `mydb`.`datetime` (`datetime_id`)
    on delete no action
    on update no action,
  constraint `fk_trips_stations`
	foreign key (`from_station_id`)
    references `mydb`.`stations` (`station_id`)
    on delete no action
    on update no action,
  constraint `fk_trips_stations2`
	foreign key (`to_station_id`)
    references `mydb`.`stations` (`station_id`)
    on delete no action
    on update no action
  )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`segments`
-- -----------------------------------------------------


DROP TABLE IF EXISTS `mydb`.`segments` ;

CREATE TABLE IF NOT EXISTS `mydb`.`segments` (
  `segment_id` INT UNSIGNED NOT NULL,
  `street` VARCHAR(45) NULL,
  `start_lat` DECIMAL(20,11) NOT NULL,
  `end_lat` DECIMAL(20,11) NOT NULL,
  `start_long` DECIMAL(20,11) NOT NULL,
  `end_long` DECIMAL(20,11) NOT NULL,
  `direction` VARCHAR(45) NULL,
  `start_neighborhood_id` INT UNSIGNED,
  `end_neighborhood_id` INT UNSIGNED,
  `neighborhood_id` INT UNSIGNED,
  PRIMARY KEY (`segment_id`),
  constraint `fk_segments_neighborhood`
	foreign key (`neighborhood_id`)
    references `mydb`.`neighborhood` (`neighborhood_id`)
    on delete no action
    on update no action,
  constraint `fk_segments_neighborhood2`
	foreign key (`start_neighborhood_id`)
    references `mydb`.`neighborhood` (`neighborhood_id`)
    on delete no action
    on update no action,
  constraint `fk_segments_neighborhood3`
	foreign key (`end_neighborhood_id`)
    references `mydb`.`neighborhood` (`neighborhood_id`)
    on delete no action
    on update no action
  )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`records`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`records` ;

CREATE TABLE IF NOT EXISTS `mydb`.`records` (
  `record_id` INT UNSIGNED NOT NULL,
  `speed` FLOAT NOT NULL,
  `bus_count` INT NULL,
  `message_count` INT NULL,
  `segment_id` INT UNSIGNED NOT NULL,
  `datetime_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`record_id`),
  constraint `fk_records_segments`
	foreign key (`segment_id`)
    references `mydb`.`segments` (`segment_id`)
    on delete no action
    on update no action,
  constraint `fk_records_datetime`
	foreign key (`datetime_id`)
    references `mydb`.`datetime` (`datetime_id`)
    on delete no action
    on update no action
  )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`crash`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`crash` ;

CREATE TABLE IF NOT EXISTS `mydb`.`crash` (
  `datetime_id` INT UNSIGNED NOT NULL,
  `first_crash_type` VARCHAR(45) NULL,
  `type` VARCHAR(45) NULL,
  `damage` VARCHAR(45) NULL,
  `street_name` VARCHAR(45) NULL,
  `num_units` INT NULL,
  `lat` DECIMAL(20,11) NULL,
  `long` DECIMAL(20,11) NULL,
  `neighborhood_id` INT UNSIGNED,
  `crash_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`crash_id`),
  constraint `fk_crash_datetime`
	foreign key (`datetime_id`)
    references `mydb`.`datetime` (`datetime_id`)
    on delete no action
    on update no action,
  constraint `fk_crash_neighborhood`
	foreign key (`neighborhood_id`)
    references `mydb`.`neighborhood` (`neighborhood_id`)
    on delete no action
    on update no action
    )
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
