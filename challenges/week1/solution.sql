-- set up objects
---- database
CREATE DATABASE IF NOT EXISTS "FROSTY_FRIDAY";
USE DATABASE "FROSTY_FRIDAY";
----- schema
CREATE SCHEMA IF NOT EXISTS "FROSTY_FRIDAY"."CHALLENGES";
USE SCHEMA "CHALLENGES";
----- warehouse
CREATE OR REPLACE WAREHOUSE "WAREHOUSE_CHALLENGES" WITH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;
USE WAREHOUSE "WAREHOUSE_CHALLENGES";

-- create CSV file format (assuming files contain the header)
CREATE OR REPLACE FILE FORMAT "CUSTOM_CSV"
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1;

-- assuming a storage integration is not required
-- create external stage
CREATE STAGE IF NOT EXISTS "FROSTY_S3_CSV_STAGE"
  FILE_FORMAT = CUSTOM_CSV
  URL = 's3://frostyfridaychallenges/challenge_1/';

-- validate that there are files in the stage
LIST @FROSTY_S3_CSV_STAGE;

-- check file structure and data schema: since you cannot select all the columns of a staged file,
-- removed the `SKIP_HEADER=1` in the FILE FORMAT and tried to print the values until one gave NULL.
-- in this case, the second returned NULL right away, so there is only one field.

-- check values inside the files, ordered by file name and file row number
-- result: you have gotten it right NULL totally_empty congratulations
SELECT
    $1 AS "FIELD_VAL",
    METADATA$FILENAME AS "FILENAME",
    METADATA$FILE_ROW_NUMBER AS "FILE_ROW_NR"
FROM @FROSTY_S3_CSV_STAGE (FILE_FORMAT => 'CUSTOM_CSV')
ORDER BY 2, 3;

-- create table based on the previous query: `result` field + metadata: `filename` field and `file_row_nr` fields
CREATE TABLE IF NOT EXISTS "WEEK1" (
    "RESULT" STRING,
    "FILENAME" STRING,
    "FILE_ROW_NR" NUMERIC
);

-- bulk load data from stage into table
COPY INTO "WEEK1"
  FROM (
    SELECT
        $1 AS "FIELD_VAL",
        METADATA$FILENAME AS "FILENAME",
        METADATA$FILE_ROW_NUMBER AS "FILE_ROW_NR"
    FROM @FROSTY_S3_CSV_STAGE (FILE_FORMAT => 'CUSTOM_CSV')
  ) ON_ERROR = 'skip_file';

-- check data was successfully loaded
SELECT
    *
FROM "WEEK1"
ORDER BY 2, 3;

-- won't remove the NULL and 'totally_empty' string values, as they might be valuable for analysis
