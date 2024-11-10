/**************************************************************************************
* Macro Name: model_selection
* 
* Description: This SAS macro automates the process of selecting the best linear 
*              regression model based on the Akaike Information Criterion (AIC). 
*              It handles potential multicollinearity by allowing you to specify 
*              groups of correlated predictors and explores different combinations.
*
* Parameters:
*   - dataset:    The name of the input dataset.
*   - dep_var:    The name of the dependent variable.
*   - vol_preds:  A space-separated list of volume-related predictor variables.
*   - R_preds:    A space-separated list of predictor variables related to the steepness of the dose distribution.
*   - PAR_preds:  A space-separated list of predictor variables related to the shape complexity of the tumor (Relative Perimeter Area Ratio).
*   - other_preds: A space-separated list of other predictor variables that are indep
*
* Usage:  This macro is particularly useful when you have several potential predictor
*         variables, some of which are highly correlated. It systematically explores
*         different combinations of predictors from each group, fits models using
*         PROC GLMSELECT with stepwise selection, and identifies the model with the
*         lowest AIC.
*
* Example:
*   %model_selection(dataset=mydata, dep_var=y, 
*                    vol_preds=volume IV_100, 
*                    R_preds=R50 R100, 
*                    PAR_preds=average_PAR weighted_PAR, 
*                    other_preds=coverage selectivity);
*
* Notes:
*   - This macro assumes that the input dataset is already prepared and that the
*     specified predictor variables exist in the dataset.
*   - The macro uses PROC GLMSELECT with stepwise selection and the AIC criterion
*     to choose the best model.
*   - The final selected model is printed to the log, and diagnostic plots are
*     produced using PROC REG.
**************************************************************************************/
OPTIONS MPRINT MLOGIC;

%MACRO model_selection(dataset=, dep_var=, vol_preds=, R_preds=, PAR_preds=, other_preds=);

  /* Get the length of vol_preds, R_preds, and PAR_preds */
  %LET vol_len = %SYSFUNC(COUNTW(&vol_preds));
  %LET R_len = %SYSFUNC(COUNTW(&R_preds));
  %LET PAR_len = %SYSFUNC(COUNTW(&PAR_preds));

  %DO i = 1 %TO &vol_len;
    %LET vol_pred = %SCAN(&vol_preds, &i);
    %DO j = 1 %TO &R_len;
      %LET R_pred = %SCAN(&R_preds, &j);
      %DO t = 1 %TO &PAR_len;
        %LET PAR_pred = %SCAN(&PAR_preds, &t);

        /* Concatenate all predictors for this model */
        %LET model_vars = &vol_pred &R_pred &PAR_pred &other_preds;

        /* For debugging */
        %PUT "i=" &i "j=" &j "t=" &t "model_vars=" &model_vars;

        /* Run regression for this combination of predictors */
        PROC GLMSELECT DATA=&dataset;
          MODEL &dep_var = &model_vars / SELECTION=STEPWISE;
          ODS OUTPUT FitStatistics=fitstats&i&j&t;
          ODS OUTPUT SelectedEffects=selected_effects&i&j&t;
        RUN;

        /* Check if fitstats and selected_effects datasets were created */
        %IF %SYSFUNC(EXIST(fitstats&i&j&t)) AND %SYSFUNC(EXIST(selected_effects&i&j&t)) %THEN %DO;
          DATA model&i&j&t;
            MERGE fitstats&i&j&t(WHERE=(LABEL1='R-Square') RENAME=(nvalue1=R_Squared))
                  fitstats&i&j&t(WHERE=(LABEL1='Adj R-Sq') RENAME=(nvalue1=Adj_R_Squared))
                  fitstats&i&j&t(WHERE=(LABEL1='AIC') RENAME=(nvalue1=AIC))
                  fitstats&i&j&t(WHERE=(LABEL1='SBC') RENAME=(nvalue1=BIC))
                  selected_effects&i&j&t(WHERE=(LABEL='Effects:'));
            KEEP Effects R_Squared Adj_R_Squared AIC BIC;
          RUN;
        %END;
      %END;
    %END;
  %END;

  /* Combine all selected models into a single dataset */
  DATA ALL_SELECTED_MODELS;
    LENGTH Effects $60;
    SET 
      %DO i = 1 %TO &vol_len;
        %DO j = 1 %TO &R_len;
          %DO t = 1 %TO &PAR_len;
            model&i&j&t
          %END;
        %END;
      %END;
    ;
    FORMAT R_SQUARED ADJ_R_SQUARED 6.4 AIC BIC 10.2;
  RUN;

  /* Sort by AIC in ascending order */
  PROC SORT DATA=ALL_SELECTED_MODELS;
    BY AIC;
  RUN;

  /* Print the combined dataset */
  PROC PRINT DATA=ALL_SELECTED_MODELS NOOBS;
    TITLE "Combined Best Models Sorted by AIC Ascending";
  RUN;

  /* Select the best model (lowest AIC) */
  DATA _NULL_;
    SET ALL_SELECTED_MODELS(OBS=1);
    /* Remove 'Intercept' from the 'Effects' string */
    effects_no_int = TRIM(TRANWRD(Effects, 'Intercept', ' '));
    CALL SYMPUTX('best_model_vars', effects_no_int);
  RUN;

  /* Run the best model with PROC REG and produce diagnostic plots */
  PROC REG DATA=&dataset PLOTS=(DiagnosticsPanel ResidualPlot(SMOOTH));
    MODEL &dep_var = &best_model_vars / VIF;
    TITLE "The Best Model with &best_model_vars";
  RUN;

%MEND model_selection;

/* Call the macro */
%model_selection(dataset=bot.cleaned, dep_var=bot_gy,
                 vol_preds=volume IV_100 IV_50,
                 R_preds=R50 R100,
                 PAR_preds=average_PAR weighted_PAR,
                 other_preds=coverage selectivity)
