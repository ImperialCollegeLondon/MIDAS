BEGIN TRANSACTION;
CREATE TABLE user (
  username varchar(64) NOT NULL,
  passphrase varchar(128) NOT NULL,
  displayname varchar(64),
  email varchar(128) NOT NULL,
  roles varchar(128) DEFAULT 'user',
  api_key char(32),
  PRIMARY KEY (username)
);
INSERT INTO "user" VALUES('testuser','{SSHA}lWIeBZcOIiXSwd/GdaxpEoEqgFfG5JCdau/gqjPQ6y96JM+RrT0khQ==','Test User','testuser@sanger.ac.uk','user','HrZIg2JG53r236okEhHpBrCRa9U1L4fm');
COMMIT;
