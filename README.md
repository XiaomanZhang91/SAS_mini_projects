This repository showcases my SAS programming skills through a collection of mini projects, including macros and code examples for different types of statistical analyses.

## Current Projects

### 1. Demographics Clinical Study Report (CSR)

**Project Overview:**

This project demonstrates how to generate a mock demographics table (Table 1.1) for a clinical study report (CSR) based on raw case report form (CRF) data. It walks through the process of transforming raw input into CDISC SDTM-compliant format, calculating key demographic summaries (age, gender, race), and generating a publication-ready table stratified by treatment groups (Placebo, Drug A, and All Patients). 

This project was completed as part of the Udemy course *The Simplest Guide to Clinical Trials Data Analysis with SAS*, using data provided in the course materials.

**Key Features:**

- Converts raw demographics data to CDISC-compliant SDTM `DM` domain format
- Derives subject-level identifiers (`USUBJID`, `SITEID`, `AGE`, `SEX`, `RACE`, `ETHNIC`) using CDISC/FDA terminology
- Generates age summaries (mean, SD, min, max) and stratified frequency distributions for categorical age groups, sex, and race
- Constructs a formatted Table 1.1 in PDF using `PROC REPORT`, ready for CSR or SAP documentation

**Repository Structure:**

- `code/`: SAS programs for importing raw data, transforming into SDTM format, summarizing demographics, and generating reports
- `data/`: Includes raw mock case report form (CRF) data used for demonstration
- `output/`: Contains generated PDF reports, including previews of raw data, CDISC-compliant data and the final Table 1.1.

### 2. Linear Regression Macro

This project demonstrates a SAS macro for automating linear regression analysis.

**Macro Features:**

* **Automated Variable Selection:** The macro includes stepwise selection to identify significant predictors.
* **Output Generation:** It generates detailed output including parameter estimates, fit statistics, and diagnostic plots.
* **Customization:** The macro allows for easy customization of input datasets, dependent and independent variables, and model selection criteria, while handling highly correlated predictors.

**Files:**
* `linear_regression_macro.sas`:  The SAS macro code.


**Usage:**
1.  Clone this repository to your local machine.
2.  Open `example_usage.sas` in SAS.
3.  Modify the input dataset and variable names as needed.
4.  Run the code to execute the macro and generate the output.




## Future Projects
* **Longitudinal Data Analysis:** This project will showcase SAS code for analyzing longitudinal data using generalized estimating equations (GEEs).

**Stay tuned for updates!**



