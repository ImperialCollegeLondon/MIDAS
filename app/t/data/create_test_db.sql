PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE antimicrobial (
  name varchar(100) NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime,
  PRIMARY KEY (name)
);
INSERT INTO "antimicrobial" VALUES('am1','2014-10-12T12:15:00',NULL,NULL);
INSERT INTO "antimicrobial" VALUES('am2','2014-11-12T12:15:00',NULL,NULL);
CREATE TABLE antimicrobial_resistance (
  sample_id integer NOT NULL,
  antimicrobial_name varchar(100) NOT NULL,
  susceptibility enum NOT NULL,
  mic varchar(45) NOT NULL,
  equality enum NOT NULL DEFAULT 'eq',
  method varchar(45),
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime,
  PRIMARY KEY (antimicrobial_name, susceptibility, mic, sample_id),
  FOREIGN KEY (antimicrobial_name) REFERENCES antimicrobial(name) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (sample_id) REFERENCES sample(sample_id) ON DELETE CASCADE ON UPDATE NO ACTION
);
INSERT INTO "antimicrobial_resistance" VALUES(1,'am1','S','50','eq','WTSI','2014-12-02T16:55:00',NULL,NULL);
CREATE TABLE brenda (
  id varchar(15) NOT NULL,
  description varchar(45),
  PRIMARY KEY (id)
);
INSERT INTO "brenda" VALUES('BTO:0000645','Lung');
CREATE TABLE envo (
  id varchar(15) NOT NULL,
  description varchar(45),
  PRIMARY KEY (id)
);
INSERT INTO "envo" VALUES('ENVO:00002148','coarse');
CREATE TABLE external_resources (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(45) NOT NULL,
  source varchar(255),
  retrieved_at datetime NOT NULL,
  checksum varchar(45) NOT NULL,
  version varchar(45),
  created_at datetime
);
CREATE TABLE file (
  file_id integer NOT NULL,
  run_id integer NOT NULL,
  version varchar(45),
  path varchar(45),
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime,
  PRIMARY KEY (file_id, run_id),
  FOREIGN KEY (run_id) REFERENCES run(run_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE TABLE gazetteer (
  id varchar(15) NOT NULL,
  description varchar(45),
  PRIMARY KEY (id)
);
INSERT INTO "gazetteer" VALUES('GAZ:00444180','Hinxton');
CREATE TABLE manifest (
  manifest_id char(36) NOT NULL,
  config_id integer NOT NULL,
  md5 char(32) NOT NULL,
  ticket integer,
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime,
  PRIMARY KEY (manifest_id),
  FOREIGN KEY (config_id) REFERENCES manifest_config(config_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
INSERT INTO "manifest" VALUES('4162F712-1DD2-11B2-B17E-C09EFE1DC403',1,'8fb372b3d14392b8a21dd296dc7d9f5a',NULL,'2015-01-29T09_30_00',NULL,NULL);
CREATE TABLE manifest_config (
  config_id INTEGER PRIMARY KEY NOT NULL,
  config mediumtext NOT NULL,
  name tinytext,
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime
);
INSERT INTO "manifest_config" VALUES(1,'hicf>','header_row','"raw',NULL,NULL);
CREATE TABLE midas_session (
  id varchar(32) NOT NULL,
  session_data longtext,
  created_at datetime,
  updated_at datetime,
  PRIMARY KEY (id)
);
CREATE TABLE role (
  username integer NOT NULL,
  role enum NOT NULL,
  user_username varchar(64) NOT NULL,
  PRIMARY KEY (role, username, user_username),
  FOREIGN KEY (user_username) REFERENCES user(username) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE TABLE run (
  run_id integer NOT NULL,
  sample_id integer NOT NULL,
  sequencing_centre varchar(45),
  err_accession_number varchar(45),
  global_unique_name varchar(45),
  qc_status enum,
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime,
  PRIMARY KEY (run_id, sample_id),
  FOREIGN KEY (sample_id) REFERENCES sample(sample_id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE TABLE sample (
  sample_id INTEGER PRIMARY KEY NOT NULL,
  manifest_id char(36) NOT NULL,
  raw_data_accession varchar(45) NOT NULL,
  sample_accession varchar(45) NOT NULL,
  sample_description tinytext,
  submitted_by enum,
  tax_id integer NOT NULL,
  scientific_name varchar(200),
  collected_by varchar(200),
  source varchar(45),
  collection_date datetime NOT NULL,
  location varchar(15) NOT NULL,
  host_associated tinyint NOT NULL,
  specific_host varchar(200),
  host_disease_status enum,
  host_isolation_source varchar(15),
  patient_location enum,
  isolation_source varchar(15),
  serovar text,
  other_classification text,
  strain text,
  isolate text,
  withdrawn varchar(45),
  created_at datetime NOT NULL,
  updated_at datetime,
  deleted_at datetime,
  FOREIGN KEY (manifest_id) REFERENCES manifest(manifest_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
INSERT INTO "sample" VALUES(1,'4162F712-1DD2-11B2-B17E-C09EFE1DC403','data:1','sample:1','New sample','CAMBRIDGE',9606,NULL,'Tate JG',NULL,'2015-01-10T14:30:00','GAZ:00444180',1,'Homo sapiens','healthy','BTO:0000645','inpatient',NULL,'serovar',NULL,'strain',NULL,NULL,'2014-12-02T16:55:00','2014-12-02T16:55:00',NULL);
CREATE TABLE taxonomy (
  tax_id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  lft integer NOT NULL,
  rgt integer NOT NULL,
  parent_tax_id integer NOT NULL
);
INSERT INTO "taxonomy" VALUES(9606,'Homo sapiens',1,1,1);
INSERT INTO "taxonomy" VALUES(63221,'Homo sapiens neanderthalensis',1,1,1);
CREATE TABLE user (
  username varchar(64) NOT NULL,
  passphrase varchar(128) NOT NULL,
  displayname varchar(64),
  email varchar(128) NOT NULL,
  roles varchar(128) DEFAULT 'user',
  api_key char(32),
  created_at datetime NOT NULL,
  deleted_at datetime,
  PRIMARY KEY (username)
);
-- API key hash corresponds to key "2566ZD3k4SVdJfGkdXJQUj6B4aPoq2Rf"
INSERT INTO "user" VALUES('testuser','{SSHA}lWIeBZcOIiXSwd/GdaxpEoEqgFfG5JCdau/gqjPQ6y96JM+RrT0khQ==','Test User','testuser@sanger.ac.uk','user','{SSHA}G6DXGyWZIP4fUJVK9wclh81+2O3Y44KckvdDpH6fkAwE7jhSyV+qjg==','2014-12-02T16:55:00',NULL);
CREATE INDEX antimicrobial_resistance_idx_antimicrobial_name ON antimicrobial_resistance (antimicrobial_name);
CREATE INDEX antimicrobial_resistance_idx_sample_id ON antimicrobial_resistance (sample_id);
CREATE INDEX file_idx_run_id ON file (run_id);
CREATE INDEX manifest_idx_config_id ON manifest (config_id);
CREATE INDEX role_idx_user_username ON role (user_username);
CREATE INDEX run_idx_sample_id ON run (sample_id);
CREATE INDEX sample_idx_manifest_id ON sample (manifest_id);
CREATE UNIQUE INDEX sample_uc ON sample (manifest_id, raw_data_accession, sample_accession);
CREATE UNIQUE INDEX name_uq ON taxonomy (name);
COMMIT;
