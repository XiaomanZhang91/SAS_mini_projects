# SAS_Projects

This repository is a showcase of my SAS programming skills, featuring a collection of SAS macros and code examples for various statistical analysis projects.

## Current Projects

### 1. Linear Regression Macro

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


### 2. Demographics Clinical Study Report (CSR)

**Project Overview:**

This project demonstrates how to create a mock demographics table for a clinical study report (CSR) with raw data from case report forms(CRF). The report summarizes key demographic characteristics (e.g., age, gender, race) by treatment groups (Placebo, Active Treatment, All Patients). The final report includes formatted demographics table and raw data previews. This project was completed as part of the Udemy course The Simplest Guide to Clinical Trials Data Analysis with SAS, and the raw data is sourced from the course materials.

**Repository Structure:**

* `code/`: Contains SAS scripts for deriving key variables, generating summary statistics, and creating formatted reports.
* `data/`: Includes raw data from case report forms(CRF).
* `output/`: Generated reports in PDF, showing the structure of the original dataset and the generated demographics table. 


## Future Projects

* **Survival Analysis:**  This project will feature SAS macros for survival analysis, including Kaplan-Meier curves and Cox proportional hazards models.
* **Longitudinal Data Analysis:** This project will showcase SAS code for analyzing longitudinal data using techniques like mixed models and generalized estimating equations (GEEs).

**Stay tuned for updates!**
