/* Create the Demographics Clinical Study Report (CSR) as shown below 
as a mock table in the Statistical Analysis Plan (SAP). */

/*====================== 1. Import Raw Demographics Data ======================*/
FILENAME REFFILE '/home/u63463818/Clinical trial data analysis with SAS_Udemy/finalProject_demog.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.demog;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=demog; /* Check types of each variable */
RUN;
PROC MEANS DATA=demog; /* Check sample size and missing data */
RUN;
PROC PRINT DATA=demog; /* Check sample size and missing data */
RUN;

/*================== 2. Convert to SDTM-Compatible Format ====================*/
/* HEML-01 to HEML01 */
PROC SQL;
	SELECT DISTINCT STUDY
	FROM demog;
QUIT;
DATA sdtm_dm;
	SET demog;
	STUDYID = "HEML01";
	DOMAIN = "DM";
	RENAME RACE = RACE0;
RUN;

DATA sdtm_dm;
	SET sdtm_dm;
	/* Create SDTM standard variables */
	USUBJID = CATX('-', STUDYID, PUT(SITENO, Z3.), PUT(PATNO, Z3.));
	SITEID = SITENO;
	SUBJID = PATNO;

	/* Recode GENDER to CDISC terminology */
	IF GENDER = 1 THEN SEX = "M";
	ELSE IF GENDER = 2 THEN SEX = "F";

	/* Recode RACE to CDISC terminology */
	SELECT (race0);
        WHEN (1) DO;
            RACE = "WHITE";
            ETHNIC = "NOT HISPANIC OR LATINO";
        END;
        WHEN (2) DO;
            RACE = "BLACK OR AFRICAN AMERICAN";
            ETHNIC = "NOT HISPANIC OR LATINO";
        END;
        WHEN (3) DO;
            RACE = "WHITE"; /* Assume hispanic are white, given limited information */
            ETHNIC = "HISPANIC OR LATINO";
        END;
        WHEN (4) DO;
            RACE = "ASIAN";
            ETHNIC = "NOT HISPANIC OR LATINO";
        END;
        WHEN (5) DO;
            RACE = "OTHER";
            ETHNIC = "NOT HISPANIC OR LATINO";
        END;
        OTHERWISE DO;
            RACE = "UNKNOWN";
            ETHNIC = "UNKNOWN";
        END;
    END;
	
	/* Construct BRTHDTC from separate fields */
	BRTHDTC_RAW = CATX('/', MONTH, DAY, YEAR);
	BRTHDTC = INPUT(BRTHDTC_RAW, MMDDYY10.);
	FORMAT BRTHDTC yymmdd10.;

	/* Convert DIAGDT to proper date format */
	FORMAT DIAGDT yymmdd10.;

	/* Calculate AGE */
	AGE = INT((DIAGDT - BRTHDTC) / 365.25);
	AGEU = "YEARS";

	/* Treatment Grouping */
	IF TRT = 0 THEN DO;
		ARMCD = "P";
		ARM = "Placebo";
	END;
	ELSE IF TRT = 1 THEN DO;
		ARMCD = "A";
		ARM = "Drug A";
	END;

	/* Keep only SDTM-relevant variables */
	KEEP STUDYID DOMAIN USUBJID SITEID SUBJID SEX RACE ETHNIC BRTHDTC AGE AGEU ARMCD ARM;
RUN;

/*========= 3. Summary Statistics: Age, Gender, Race (CSR Table 1.1) =========*/
/*
   Derive numeric and categorical summaries of baseline variables by treatment group:
   - Includes mean/SD/min/max for age
   - Frequency distributions for age groups, sex, and race
   - Outputs intermediate tables for stacking
*/

/*------------ 3.1 Summary Stats for Age (Continuous and Categorical) -----------*/
DATA demog1 REPLACE;
	SET demog;
	dob = INPUT(COMPRESS(CAT(month, '/', day, '/', year)), mmddyy10.);
	age = (diagdt - dob)/365.24;
	IF age <= 18 THEN agec = 0;
	ELSE if age <= 65 THEN agec = 1;
	ELSE agec = 2;
	OUTPUT;
	trt = 2;
	OUTPUT;
RUN;

* Summary Stat for Numeric Age;
PROC SORT DATA=demog1;
	BY trt;
PROC MEANS DATA=demog1 NOPRINT;
	VAR age;
	BY trt;
	OUTPUT OUT=agestats;
RUN;
PROC PRINT DATA=agestats;
RUN;

* Summary Stat for Categorical Age Group;
PROC FORMAT;
	VALUE agecfmt
    0 = '<=18 years'
    1 = '18 to 65 years'
    2 = '> 65 years';
RUN;

DATA demog1;
	SET demog1;
	agec1 = PUT(agec, agecfmt.); /* THM: must use a different name to store the output */
RUN;

PROC FREQ DATA=demog1 NOPRINT;
	TABLE trt*agec1 /OUTPCT OUT=agecstats;
RUN;

DATA agecstats;
	SET agecstats;
	value = CAT(count, ' (', STRIP(PUT(ROUND(pct_row, .1), 8.1)), '%)' );
RUN;

PROC PRINT DATA=agecstats;
RUN;

/*------------------------ 3.2 Summary Stats for Gender -------------------------*/
PROC FORMAT;
	VALUE genfmt
	1 = 'Male'
	2 = 'Female'
	;
RUN;
DATA demog1;
	SET demog1;
	sex = PUT(gender, genfmt.);
RUN;
PROC FREQ DATA=demog1 NOPRINT;
	TABLE trt*sex / OUTPCT OUT=genderstats;
RUN;
DATA genderstats;
	SET genderstats;
	value = CAT(count, " (", STRIP(PUT(ROUND(pct_row,.1), 8.1)), "%)");
RUN;

/*------------------------ 3.3 Summary Stats for Race ---------------------------*/
PROC FORMAT;
	VALUE racefmt
	1 = 'White' 
	2 = 'Black' 
	3 = 'Hispanic' 
	4 = 'Asian' 
	5 = 'Other' 
	;
RUN;

DATA demog1;
	SET demog1;
	racec = PUT(race, racefmt.);
RUN;

PROC FREQ DATA=demog1 NOPRINT;
	TABLE trt*racec / OUTPCT OUT=racestats;
RUN;

DATA racestats;
	SET racestats;
	value = CAT(count, " (", STRIP(PUT(ROUND(pct_row, .1),8.1)), "%)");
RUN;

/*================= 4. Combine and Transpose All Summary Tables =================*/
/*
   Combine the summary stats for age, gender, and race.
   Assign a reporting structure (ord, subord) and format them for CSR presentation.
*/
* Check variable types and length;
PROC CONTENTS DATA= agestats;
RUN; 
PROC CONTENTS DATA= agecstats;
RUN; 
PROC CONTENTS DATA= genderstats;
RUN; 
PROC CONTENTS DATA= racestats;
RUN; 

* Transform all tables into a same format and add orders;
* - Numeric Age;
DATA agestats1 REPLACE;
	LENGTH trt 8 stat $16 value $16;
	SET agestats;
	ord = 1;
	IF _stat_ = 'N' THEN DO; subord = 1; value = STRIP(PUT(age, 8.)); END;
	IF _stat_ = 'MEAN' THEN DO; subord = 2; value = STRIP(PUT(age, 8.1)); END;
	IF _stat_ = 'STD' THEN DO; subord = 3; value = STRIP(PUT(age, 8.2)); END;
	IF _stat_ = 'MIN' THEN DO; subord = 4; value = STRIP(PUT(age, 8.1)); END;
	IF _stat_ = 'MAX' THEN DO; subord = 5; value = STRIP(PUT(age, 8.1)); END;
	stat = _stat_ ; 
	KEEP ord subord trt stat value;
RUN;

* - Categorical age;	
DATA agecstats1;
    LENGTH trt 8 stat $16 value $16;
    SET agecstats;
    ord = 2;
    IF agec1 = '<=18 years' THEN subord = 1; 
    ELSE IF agec1 = '18 to 65 years' THEN subord = 2;
    ELSE subord = 3;
    stat = agec1;
    KEEP ord subord trt stat value;
RUN;

* - Gender;
DATA genderstats1;
	LENGTH trt 8 stat $16 value $16;
	SET genderstats;
	ord = 3;
	stat = sex;
	IF stat = 'Male' THEN subord=1;
	ELSE subord=2;
	KEEP ord subord trt stat value;
RUN;

* - Race;
DATA racestats1;
	LENGTH trt 8 stat $16 value $16;
	SET racestats;
	ord = 4;
	stat = racec;
	IF stat='Asian' THEN subord=1;
	ELSE IF stat='Black' THEN DO; stat='African American'; subord=2; END;
	ELSE IF stat='Hispanic' THEN subord=3;
	ELSE IF stat='White' THEN subord=4;
	ELSE IF stat='Other' THEN subord=5;
	KEEP ord subord trt stat value;
RUN;

* Put together 4 tables & transpose;
DATA allstats REPLACE;
	SET agestats1 agecstats1 genderstats1 racestats1;
RUN;
	
PROC SORT DATA=allstats;
	BY ord subord stat;
PROC TRANSPOSE DATA=allstats OUT=t_allstats PREFIX=trt_;
	VAR value;
	ID trt;
	BY ord subord stat;
RUN;

/*======================== 5. Generate Final PDF Report =========================*/
/*
   Output Table 1.1 (Demographics and Baseline Characteristics by Treatment Group)
   to a formatted PDF using PROC REPORT. Display counts and percentages by treatment arm.
*/
DATA final REPLACE;
	SET t_allstats;
	BY ord subord;
	OUTPUT;
	IF first.ord THEN DO;
		IF ord=1 THEN stat='Age (years)';
		IF ord=2 THEN stat='Age Groups';
		IF ord=3 THEN stat='Gender';
		IF ord=4 THEN stat='Race';
		subord=0;
		trt_0 = '';
		trt_1 = '';
		trt_2 = '';
		OUTPUT;
	END;

PROC SORT DATA=final;
	BY ord subord;
RUN;

PROC SQL NOPRINT;
	SELECT count(*) INTO :placebo FROM demog1 WHERE trt=0;
	SELECT count(*) INTO :active FROM demog1 WHERE trt=1;
	SELECT count(*) INTO :total FROM demog1 WHERE trt=2;
QUIT;

%LET placebo=&placebo;
%LET active=&active;
%LET total=&total;

ODS PDF file='/home/u63463818/Clinical trial data analysis with SAS_Udemy/report_with_raw_data.pdf';
TITLE 'Raw Data Preview';
PROC PRINT DATA=demog(OBS=10) NOOBS;
RUN;

TITLE 'Preview of SDTM-Compliant Demographics Dataset (DM Domain)';
PROC PRINT DATA=sdtm_dm(OBS=10) NOOBS;
RUN;

TITLE 'Table 1.1';
TITLE2 'Demographic and Baseline Characteristics by Treatment Group';
TITLE3 'Randomized Population';
FOOTNOTE 'Note: Percentages are based on the number of non-missing value.';

PROC REPORT DATA=final split='|';
	COLUMNS ord subord stat trt_0 trt_1 trt_2;
	DEFINE ORD/ NOPRINT ORDER;
	DEFINE SUBORD/ NOPRINT ORDER;
	DEFINE stat/ DISPLAY WIDTH=50 "";
	DEFINE trt_0/ DISPLAY WIDTH=30 "Placebo|(N=&placebo)";
	DEFINE trt_1/ DISPLAY WIDTH=30 "Drug A|(N=&active)";
	DEFINE trt_2/ DISPLAY WIDTH=30 "All patiens|(N=&total)";
RUN;
	
ODS PDF CLOSE;


