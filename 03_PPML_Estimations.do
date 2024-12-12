/* 
/!\ Read Carefully the following:
For the baseline results (i.e., with Y60 as maritime flows), the replicator is expected to change the working directory: this is the only change required to run this do-file on any computer.
For the alternative scenarios (i.e., with Y50, Y60, or Y0), 3 changes are required:
   - Change the directory
   - Change the local flows variable at line 12: replace 60 by 50, 70, or 0 respectively
   - Change the list following "foreach k of numlist..." at lines 39-41
The last change is required to prevent Stata from returning an error message. Indeed, depending on the of 'maritime' flows variable used (Y50, Y60, Y70, or Y0), the list of HS2-digits products in which all HS6-digits goods are classified as maritime varies. As PPML are estimated product-by-product, and because trying to estimate PPML on a sub-sample with only null values ofr the outcome leads to an error message and stops the loop, we must exclude these HS2 products from our PPML estimations. In the following, the list of products following "foreach k of numlist..." is therefore constructed accordingly. To replicate the results with each alternative scenario, one must simply select the 'correct' list of products specified near the command line below.
*/ 

cd ""
local flow = 60
		
     *********************************************************************************
     *********************************************************************************
	 ***********                                                           ***********
	 ***********      POISSON PSEUDO MAXIMUM LIKELIHOOD ESTIMATIONS        ***********
	 ***********                                                           ***********
	 *********************************************************************************
	 ********************************************************************************* 
 
use "Database.dta", clear
gen beta = .
gen std_err = .
foreach x in Border Language Colonization FTA Custom EU WTO Home {
	gen gamma_`x' = .
}
keep if Year == 2019
keep Exporter Importer Product beta std_err gamma_*
save "Results\Betas.dta", replace //We create a separated dataset in which we will store all betas associated to our product-specific cost variables as well as the gammas associated with our control variables

use "Database.dta", clear
rename Y`=`flow'' Yijk //The local variable 'flow' is defined above and can be changed to test alternative scenarios
rename Q`=`flow'' Qijk //The local variable 'flow' is defined above and can be changed to test alternative scenarios

drop Y*0 Q*0 //We don't need the other maritime flows and drop them to reduce size and increase the speed of estimations

/* Remark: In the HS2 Classification rev12, there are 96 products numbered 1-97 and no product #77 so it is always excluded */
foreach k of numlist 1(1)76 78(1)96 {              //For Y60 and Y50: we exclude product #97 as it contains only non-maritime flows
**foreach k of numlist 1(1)76 78(1)87 89(1)96 {    //For Y70: we exclude products #88 and #97 as they contain only non-maritime flows
**foreach k of numlist 2(1)7 9(1)76 78(1)96 {      //For Y0: we exclude products #1, #8, and #97 as they contain only non-maritime flows
	preserve
	quietly keep if Product == `k' //We rune the regressions for each product separately
	quietly ppmlhdfe Yijk cost Border Language Colonization FTA Custom EU WTO Home, absorb(exporter#Year importer#Year region_exporter#region_importer) cluster(exporter#importer) d 
	quietly keep if Year == 2019
	
	quietly merge 1:1 Exporter Importer Product using "Results\Betas.dta"
	quietly replace beta = _b[cost] if Product == `k' //We store the coefficient of interest and name it beta
	quietly replace std_err = _se[cost] if Product == `k' //We store the standard error associated with our beta of interest and name it std_err
	
	foreach x in Border Language Colonization FTA Custom EU WTO Home {
		quietly replace gamma_`x' = _b[`x'] if Product == `k'  //We store the coefficients associated with each control variable and name them gamma_*
	}
	
	quietly keep Exporter Importer Product beta std_err gamma_*
	quietly save "Results\Betas.dta", replace
	restore
	display "Estimation for Product #`k' Complete"
}

keep if Year == 2019
merge 1:1 Exporter Importer Product using "Results\Betas.dta"
replace beta = 0 if Product == 99 //We replace beta by 0 for Products transported by air (not affected by maritime taxation)
gen significant10 = ((abs(beta) > (1.645*std_err)))
gen significant05 = ((abs(beta) > (1.960*std_err)))
gen significant01 = ((abs(beta) > (2.576*std_err)))

drop if beta == .
keep Exporter Importer Product Yijk Qijk beta significant* Seadistance Airdistance Roaddistance Border Home
replace Yijk = 0.001 if (Yijk < 0.001 & Exporter == Importer) //As our Yijk have been contructed and not directly estimated (see "03_Construction.do"), some values take values below the minimum value possible (i.e., $1) so we replace them by this minimum value in those cases (remark: Yijk are expressed in $1,000 thus 0.001 = $1)
replace Qijk = 0.001 if (Qijk < 0.001 & Exporter == Importer)
sort Exporter Importer Product
save "Results\Estimation Results.dta", replace

merge n:1 Product using "Refined data\Elasticities.dta"
drop if _merge == 2
drop _merge
sort Exporter Importer Product
save "Results\Estimation Results.dta", replace

use "Results\Betas.dta", clear
drop Exporter Importer
duplicates drop
sort Product
save "Results\Betas.dta", replace


	 *********************************************************************************
     *********************************************************************************
	 ***********                                                           ***********
	 ***********        PRESENTATION OF MAIN PPML ESTIMATION RESULTS       ***********
	 ***********                                                           ***********
	 *********************************************************************************
	 ********************************************************************************* 
	 
          *****************************************************
          ***** Table C1: Results of Main PPML Estimations *****
          *****************************************************
use "Results\Betas.dta", clear
quietly putexcel set "Results\Tables\Table C1.xlsx", replace
quietly putexcel A1 = "Variable"
quietly putexcel B1 = "Min"
quietly putexcel C1 = "Max"
quietly putexcel D1 = "Mean"
quietly putexcel E1 = "Median"

quietly summarize beta, d
quietly putexcel A2 = "Cost"
quietly putexcel B2 = `r(min)', nformat(number_d2)
quietly putexcel C2 = `r(max)', nformat(number_d2)
quietly putexcel D2 = `r(mean)', nformat(number_d2)
quietly putexcel E2 = `r(p50)', nformat(number_d2)

quietly gen byte line = 3
foreach x in Border Language Colonization FTA Custom EU WTO Home {
	quietly sum gamma_`x', d
	quietly putexcel A`=line' = "`x'"
    quietly putexcel B`=line' = `r(min)', nformat(number_d2)
    quietly putexcel C`=line' = `r(max)', nformat(number_d2)
    quietly putexcel D`=line' = `r(mean)', nformat(number_d2)
    quietly putexcel E`=line' = `r(p50)', nformat(number_d2)
	quietly replace line = line + 1
}
quietly drop line


          *****************************************************************************************
          ***** Figure 2: Distribution of Partial Elasticities (% of Maritime Flows in Value) *****
		  ***** Figure C1: Distribution of Partial Elasticities (% of HS2 Codes) ******************
          *****************************************************************************************
use "Results\Estimation Results.dta", clear
hist beta, percent width(0.04) ytitle("% of {&beta}{subscript:k}") xtitle("Values of {&beta}{subscript:k}") 
graph export "Results\Figures\Fig C1.png", as(png) replace

preserve
drop if Product == 99
drop if Border == 1
egen Yk = sum(Yijk), by(beta)
keep Yk beta
duplicates drop
egen Y = sum(Yk)
gen int Share = round(Yk / Y * 100000, 1)
twoway hist beta [fweight = Share], percent width(0.04) ytitle("% of All Maritime Trade Flows") xtitle("Values of {&beta}{subscript:k}")
graph export "Results\Figures\Fig 2.png", as(png) replace
restore


          **************************************************************************************************************
          ***** Table 3: List of HS2 Products, Partial Elasticities, and International Flows in 2019 (Billion US$) *****
		  ***** Table C2: List of Partial Elasticities by Product ******************************************************
          **************************************************************************************************************
use "Results\Betas.dta", clear
preserve
drop if Product == 99
merge 1:n Product using "Refined data\Flows.dta"
rename Y`=`flow'' Yijk //The local variable 'flow' is defined above and can be changed to test alternative scenarios
drop Y*0 Q*0 //We don't need the other maritime flows and drop them to reduce size and increase speed of estimations.

keep if Year == 2019
drop if Home == 1
egen Sum_Ytot = sum(Ytot), by(Product)
egen Sum_Yijk = sum(Yijk), by(Product)
keep Product beta std_err Sum_Yijk Sum_Ytot
rename Sum_Ytot Ytot
replace Ytot = Ytot / 1000000 //Flows are already expressed in 1,000 USD and we want them expressed in billion USD
rename Sum_Yijk Yijk
replace Yijk = Yijk / 1000000 //Flows are already expressed in 1,000 USD and we want them expressed in billion USD
duplicates drop
merge 1:1 Product using "Refined data\HS2 Codes.dta"
drop if _merge == 2
drop _merge
rename Product HS2
sort beta 
gen int Beta = abs(round(beta, 0.001) * 1000)
tostring Beta, replace
replace Beta = "0" + Beta if abs(beta) < 0.1
replace Beta = "0" + Beta if abs(beta) < 0.01
replace Beta = "-" + "0." + Beta if beta < 0
replace Beta = "0." + Beta if beta > 0
replace Beta = Beta + "*" if (abs(beta) > 1.645*std_err & abs(beta) < 1.960*std_err)
replace Beta = Beta + "**" if (abs(beta) > 1.960*std_err & abs(beta) < 2.576*std_err)
replace Beta = Beta + "***" if (abs(beta) > 2.576*std_err)
replace Beta = "NA" if beta == .
export excel HS2 Definition Beta Yijk Ytot using "Results\Tables\Table 3.xlsx", firstrow(variables) replace
sort HS2 
export excel HS2 Definition Beta using "Results\Tables\Table C2.xlsx", firstrow(variables) replace
restore