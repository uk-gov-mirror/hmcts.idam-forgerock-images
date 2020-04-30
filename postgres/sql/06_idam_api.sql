--TODO move to seperate database
DROP SCHEMA IF EXISTS idamapi CASCADE;
CREATE SCHEMA idamapi AUTHORIZATION openidm;

CREATE TABLE idamapi.service
(
   label text NOT NULL,
   description text NOT NULL,
   allowedroles text[],
   onboardingendpoint text,
   onboardingroles text[],
   oauth2clientid text NOT NULL,
   CONSTRAINT service_pk PRIMARY KEY (label)
);

CREATE TABLE idamapi.clustercache
(
   key text NOT NULL,
   assignments text[] NOT NULL,
   CONSTRAINT clustercache_pkey PRIMARY KEY (key)
);


-- Add new columns to service table
ALTER TABLE idamapi.service ADD COLUMN activationredirecturl text;
ALTER TABLE idamapi.service ADD COLUMN selfregistrationallowed boolean DEFAULT false;

-- Enable self registration for specified services
UPDATE idamapi.service SET selfregistrationallowed = true WHERE oauth2clientid IN ('divorce', 'cmc_citizen');

-- Reset conditions on column
ALTER TABLE idamapi.service ALTER COLUMN selfregistrationallowed DROP DEFAULT;
ALTER TABLE idamapi.service ALTER COLUMN selfregistrationallowed SET NOT NULL;


-- Add created date column to clustercache table
ALTER TABLE idamapi.clustercache ADD COLUMN created_date TIMESTAMP DEFAULT NOW();
ALTER TABLE idamapi.clustercache ADD COLUMN updated_date TIMESTAMP DEFAULT NOW();
ALTER TABLE idamapi.clustercache ALTER COLUMN created_date DROP DEFAULT;
ALTER TABLE idamapi.clustercache ALTER COLUMN updated_date DROP DEFAULT;
