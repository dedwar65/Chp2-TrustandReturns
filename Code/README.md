---
# Workflow

The workflow for this is repository is the following: i) Raw data,  ii) Cleaned data,  iii) Processing,  iv) Descriptive,  and v) Regressions.

    * Raw data: This folder contains all the raw data files needed to execute the analysis of this repository. Specifically, the [RAND version of the HRS data](https://hrsdata.isr.umich.edu/data-products/rand), both the longitudinal file and the fat files (for merging in variables not processed in the longitudinal file), and the documentation for the variables are present in the zip files.

    * Cleaned data: This folder contains the .do files necessary to compute returns, prepare the **trust** regressor and relevant control variables, and the .dta files containing the final set of variables needed for the proceeding statistical analysis. The wide and long version of the final dataset is here. 

    * Processing: This folder goes a step further than cleaning and creating the .dta files by applying numerous data processing techniques (such as Windsorization) to the relevant variables in the final set. The .do files in this folder will be used to export a final .dta dataset to the Cleaned folder.

    * Descriptive: This folder produces desriptive statistics of the relevant processed variables.  

    * Regressions: This folder will contain the .do files describing all of the relevant statistical techniques used to analyze the data. Much work will be done in the paper and in the structuring of the code to describe the three analyses that are conducted here. 

