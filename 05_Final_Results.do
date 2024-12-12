/* Change the working directory: This is the only change required to run this do-file on any computer */
cd "" 


          *********************************************************************************
          *********************************************************************************
	      ***********                                                           ***********
	      ***********          RECODING AND REDEFINING THE VARIABLES            ***********
	      ***********                                                           ***********
	      *********************************************************************************
	      ********************************************************************************* 
/* We first need to reformat the dataset obtained with "04_Structural_Gravity.Rmd", and to change how "Welfare" and "Price" variables are expressed
Remark: This reformatting step only needs to be run once, while all other lines of code enclosed between a "preserve" and a "restore" command can be re-run separately as many times as wanted */  		  
use "Results\Final Results.dta", clear
decode Product, gen(product)
drop Product
destring product, replace
rename product Product
decode Exporter, gen(exporter)
drop Exporter
rename exporter Exporter
decode Importer, gen(importer)
drop Importer
rename importer Importer

gen Welfare = 100 * (Wi_hat - 1) //We express Welfare change as a percentage change
gen Price = 100 * (Pi_hat - 1) //We express Price increase as a percentage change
drop Wi_hat Pi_hat
label variable Welfare "Welfare Change (%)"
label variable Price "Price Change (%)"
save "Results\Final Results.dta", replace


          *******************************************************************************************
          *******************************************************************************************
	      ***********                                                                     ***********
	      ***********   IMPACT ON WELFARE, PRICES, AND MARGINAL COST OF FUNDS BY COUNTRY  ***********
	      ***********                                                                     ***********
	      *******************************************************************************************
	      *******************************************************************************************

use "Results\Final Results.dta", clear


          ****************************************************************************
          ***** Table 4: Impact of a Carbon Tax on Welfare by Country (% Change) *****
          ****************************************************************************
preserve
keep Exporter Welfare
duplicates drop		  
rename Exporter Code
merge 1:1 Code using "Refined data\Country Codes.dta"
drop if _merge == 2
drop _merge
sort Welfare
export excel Country Welfare using "Results\Tables\Table 4.xlsx" if _n <= 50, sheet("Sheet1", replace) firstrow(varlabels) cell(A1)
export excel Country Welfare using "Results\Tables\Table 4.xlsx" if (_n >= 51 & _n < 101), sheet("Sheet1", modify) firstrow(varlabels) cell(C1)
export excel Country Welfare using "Results\Tables\Table 4.xlsx" if (_n >= 101 & _n < 151), sheet("Sheet1", modify) firstrow(varlabels) cell(E1)
export excel Country Welfare using "Results\Tables\Table 4.xlsx" if _n >= 151, sheet("Sheet1", modify) firstrow(varlabels) cell(G1)

quietly putexcel set "Results\Main Results.xlsx", sheet("Welfare Loss") replace
quietly putexcel A1 = "Simple Average of Welfare Loss (%)" 
quietly putexcel B1 = "Mean"
quietly putexcel C1 = "Std. Dev."

quietly putexcel A2 = "World" 
quietly sum Welfare
quietly putexcel B2 = `r(mean)', nformat(number_d2)
quietly putexcel C2 = `r(sd)', nformat(number_d2)

quietly putexcel A3 = "OECD"
quietly su Welfare if (Code == "DEU" | Code == "AUS" | Code == "AUT" | Code == "BEL" | Code == "CAN" | Code == "CHL" | Code == "COL" | Code == "KOR" | Code == "CRI" | Code == "DNK" | Code == "ESP" | Code == "EST" | Code == "USA" | Code == "FIN" | Code == "FRA" | Code == "GRC" | Code == "HUN" | Code == "IRL" | Code == "ISL" | Code == "ISR" | Code == "ITA" | Code == "JPN" | Code == "LVA" | Code == "LTU" | Code == "LUX" | Code == "MEX" | Code == "NOR" | Code == "NZL" | Code == "NLD" | Code == "POL" | Code == "PRT" | Code == "SVK" | Code == "CZE" | Code == "GBR" | Code == "SVN" | Code == "SWE" | Code == "CHE" | Code == "TUR") // List of OECD Countries
quietly putexcel B3 = `r(mean)', nformat(number_d2)
quietly putexcel C3 = `r(sd)', nformat(number_d2)

quietly putexcel A4 = "LDC"
quietly su Welfare if LDC == 1
quietly putexcel B4 = `r(mean)', nformat(number_d2)
quietly putexcel C4 = `r(sd)', nformat(number_d2)

quietly putexcel A5 = "SIDS"
quietly su Welfare if SIDS == 1
quietly putexcel B5 = `r(mean)', nformat(number_d2)
quietly putexcel C5 = `r(sd)', nformat(number_d2)
restore


          *************************************************************************************
          ***** Figure 3: Impact of a Carbon Tax on Welfare by Country Depending on GDPPC *****
          *************************************************************************************
preserve
keep Exporter Welfare
duplicates drop	
rename Exporter Code
merge 1:1 Code using "Refined data\GDPPC.dta"
keep if _merge == 3
replace Welfare = -Welfare //We change the sign of the welfare loss (to have a loss expressed in positive terms) for graph readibility purposes
twoway (scatter Welfare GDPPC, mlabel(Code) msymbol(smcircle) mlabsize(vsmall) mcolor(midblue) mlabcolor(midblue) ytitle("Welfare Loss (% Change)") legend(off)) (lfit Welfare GDPPC, lcolor(midblue)), xscale(r(0 121000)) xlabel(0 40000 80000 120000)
graph export "Results\Figures\Fig 3.png", as(png) replace

quietly putexcel set "Results\Main Results.xlsx", sheet("Linear Regression - Welfare") modify
quietly putexcel B1 = "Coef."
quietly putexcel A2 = "GDPPC"
quietly putexcel A3 = "Constant"
quietly reg Welfare GDPPC
quietly putexcel B2 = _b[GDPPC], nformat(scientific_d2)
quietly putexcel B3 = _b[_cons], nformat(scientific_d2)
restore


          ********************************************************************
          ***** Figure C2: World Map of Countries by Welfare Change **********
          ********************************************************************
preserve
keep Exporter Welfare
duplicates drop	
rename Exporter Code
merge 1:1 Code using "Refined data\Map Countries"
colorpalette Reds, select(0 1 3 5 7 9) nograph reverse
local colors `r(p)'
spmap Welfare using "Refined data\Map Coordinates", id(id) fcolor("`colors'") ndfcolor(gs10) clmethod(custom) clbreaks(-4 -2 -1 -0.5 -0.25 0 0.5)
graph export "Results\Figures\Fig C2.png", as(png) replace
restore


          *********************************************************************************
          ***** Table 5: Impact of a Carbon Tax on Import Prices by Country (% Change) ****
          *********************************************************************************
preserve
keep Exporter Price
duplicates drop		  
rename Exporter Code
merge 1:1 Code using "Refined data\Country Codes.dta"
drop if _merge == 2
drop _merge
gsort -Price
export excel Country Price using "Results\Tables\Table 5.xlsx" if _n <= 50, sheet("Sheet1", replace) firstrow(varlabels) cell(A1)
export excel Country Price using "Results\Tables\Table 5.xlsx" if (_n >= 51 & _n < 101), sheet("Sheet1", modify) firstrow(varlabels) cell(C1)
export excel Country Price using "Results\Tables\Table 5.xlsx" if (_n >= 101 & _n < 151), sheet("Sheet1", modify) firstrow(varlabels) cell(E1)
export excel Country Price using "Results\Tables\Table 5.xlsx" if _n >= 151, sheet("Sheet1", modify) firstrow(varlabels) cell(G1)

quietly putexcel set "Results\Main Results.xlsx", sheet("Price Increase") modify
quietly putexcel A1 = "Simple Average of Price Increase (%)" 
quietly putexcel B1 = "Mean"
quietly putexcel C1 = "Std. Dev."

quietly putexcel A2 = "World" 
quietly sum Price
quietly putexcel B2 = `r(mean)', nformat(number_d2)
quietly putexcel C2 = `r(sd)', nformat(number_d2)

quietly putexcel A3 = "OECD"
quietly su Price if (Code == "DEU" | Code == "AUS" | Code == "AUT" | Code == "BEL" | Code == "CAN" | Code == "CHL" | Code == "COL" | Code == "KOR" | Code == "CRI" | Code == "DNK" | Code == "ESP" | Code == "EST" | Code == "USA" | Code == "FIN" | Code == "FRA" | Code == "GRC" | Code == "HUN" | Code == "IRL" | Code == "ISL" | Code == "ISR" | Code == "ITA" | Code == "JPN" | Code == "LVA" | Code == "LTU" | Code == "LUX" | Code == "MEX" | Code == "NOR" | Code == "NZL" | Code == "NLD" | Code == "POL" | Code == "PRT" | Code == "SVK" | Code == "CZE" | Code == "GBR" | Code == "SVN" | Code == "SWE" | Code == "CHE" | Code == "TUR") // List of OECD Countries
quietly putexcel B3 = `r(mean)', nformat(number_d2)
quietly putexcel C3 = `r(sd)', nformat(number_d2)

quietly putexcel A4 = "LDC"
quietly su Price if LDC == 1
quietly putexcel B4 = `r(mean)', nformat(number_d2)
quietly putexcel C4 = `r(sd)', nformat(number_d2)

quietly putexcel A5 = "SIDS"
quietly su Price if SIDS == 1
quietly putexcel B5 = `r(mean)', nformat(number_d2)
quietly putexcel C5 = `r(sd)', nformat(number_d2)
restore


          *******************************************************************************************
          ***** Figure 4: Impact of a Carbon Tax on Import Prices by Country Depending on GDPPC *****
          *******************************************************************************************
preserve
keep Exporter Price
duplicates drop
rename Exporter Code
merge 1:1 Code using "Refined data\GDPPC.dta"
keep if _merge == 3
twoway (scatter Price GDPPC, mlabel(Code) msymbol(smcircle) mlabsize(vsmall) mcolor(midblue) mlabcolor(midblue) ytitle("Price Variation (% Change)") legend(off)) (lfit Price GDPPC, lcolor(midblue)), xscale(r(0 121000)) xlabel(0 40000 80000 120000)
graph export "Results\Figures\Fig 4.png", as(png) replace

quietly putexcel set "Results\Main Results.xlsx", sheet("Linear Regression - Prices") modify
quietly putexcel B1 = "Coef."
quietly putexcel A2 = "GDPPC"
quietly putexcel A3 = "Constant"
quietly reg Price GDPPC
quietly putexcel B2 = _b[GDPPC], nformat(scientific_d2)
quietly putexcel B3 = _b[_cons], nformat(scientific_d2)
restore

  
          **********************************************************************
          ***** Table 6: Economic Cost of the Tax by Country (Billion US$) *****
          **********************************************************************
use "Results\Final Results.dta", clear
egen Ej = sum(Yijk), by(Importer)
rename Importer Code
keep if Home == 1
keep Exporter Welfare Ej
rename Exporter Code
duplicates drop
merge 1:1 Code using "Refined data\Country Codes.dta"
drop if _merge == 2
drop _merge
gen MCF = Welfare * Ej / 100 / 1000000 //We divide by 100 because Welfare is in percentage and we divide by 1000000 because Yijk is in thousand USD and we want to express it in billion USD
sort MCF
label variable MCF "Loss"
export excel Country MCF using "Results\Tables\Table 6.xlsx" if _n <= 50, sheet("Sheet1", replace) firstrow(varlabels) cell(A1)
export excel Country MCF using "Results\Tables\Table 6.xlsx" if (_n >= 51 & _n < 101), sheet("Sheet1", modify) firstrow(varlabels) cell(C1)
export excel Country MCF using "Results\Tables\Table 6.xlsx" if (_n >= 101 & _n < 151), sheet("Sheet1", modify) firstrow(varlabels) cell(E1)
export excel Country MCF using "Results\Tables\Table 6.xlsx" if _n >= 151, sheet("Sheet1", modify) firstrow(varlabels) cell(G1)

quietly putexcel set "Results\Main Results.xlsx", sheet("Marginal Cost of Funds") modify
egen Worldwide_Cost = sum(MCF)
quietly putexcel A1 = "Worldwide Marginal Cost of Funds"
su Worldwide_Cost
quietly putexcel B1 = `r(mean)', nformat(number)


          *********************************************************************************
          *********************************************************************************
     	  ***********                                                           ***********
	      ***********   ESTIMATION OF CHANGE IN INTERNATIONAL MARITIME FLOWS    ***********
     	  ***********                                                           ***********
	      *********************************************************************************
	      ********************************************************************************* 

use "Results\Final Results.dta", clear



          *********************************************************************************
          ***** Table C3: List of HS2 Products and Variation in Average Seadistance *******
		  ***** Figure 5: Change in Average Seadistance Traveled by Products (% Change) ***
          *********************************************************************************		   
preserve
drop if Product == 99

egen Yk = sum(Yijk), by(Product)
egen Yk_prime = sum(Yijk_prime), by(Product)
gen Yk_hat = Yk_prime / Yk

gen Yijk_Seadistance = Yijk * Seadistance
gen Yijk_prime_Seadistance = Yijk_prime * Seadistance

egen Yk_Seadistance = sum(Yijk_Seadistance), by(Product)
egen Yk_prime_Seadistance = sum(Yijk_prime_Seadistance), by(Product)

gen ASD = Yk_Seadistance / Yk
gen ASD_hat = Yk_prime_Seadistance / (Yk_Seadistance * Yk_hat)
gen Change_Seadistance = (ASD_hat - 1) * 100

keep Product ASD Change_Seadistance Yk
duplicates drop
merge 1:1 Product using "Refined data\HS2 Codes.dta"
drop _merge
order Product Definition Change_Seadistance ASD

twoway (scatter Change_Seadistance ASD, mlabel(Product) msymbol(smcircle) mlabsize(vsmall) mcolor(midblue) mlabcolor(midblue) legend(off) ytitle("") xtitle("")), yline(0)
graph save "Results\Figures\Fig 5a.gph", replace
twoway (scatter Change_Seadistance ASD [w=Yk], msymbol(Oh) mcolor(midblue) mlabcolor(midblue) legend(off) ytitle("") xtitle("")) (lfit Change_Seadistance ASD [w=Yk], legend(off) ytitle("") xtitle("")), yline(0)
graph save "Results\Figures\Fig 5b.gph", replace
graph combine "Results\Figures\Fig 5a.gph" "Results\Figures\Fig 5b.gph", l1("Change in Average Seadistance (in %)") b1("Original Average Seadistance (in km)") rows(2) 
graph export "Results\Figures\Fig 5.png", as(png) replace

label variable Product "HS2"
label variable Definition "Definition"
label variable Change_Seadistance "Change (in %)"
label variable ASD "Baseline distance (in km)"
sort Change_Seadistance
export excel Product Definition Change_Seadistance ASD using "Results\Tables\Table C3.xlsx", replace firstrow(varlabels)
restore

preserve
drop if Product == 99
gen Yijk_Seadistance = Yijk * Seadistance
egen Y_SD = sum(Yijk_Seadistance)
egen Y = sum(Yijk)
gen AverageSeaDist = Y_SD / Y
gen Yijk_prime_Seadistance = Yijk_prime * Seadistance
egen Y_prime_SD = sum(Yijk_prime_Seadistance)
gen AverageSeaDist_hat = Y_prime_SD / Y_SD
gen AverageSeaDist_prime = AverageSeaDist * AverageSeaDist_hat
gen Change_AverageSeaDist = (AverageSeaDist_hat - 1) * 100 
keep AverageSeaDist AverageSeaDist_prime Change_AverageSeaDist

quietly putexcel set "Results\Main Results.xlsx", sheet("Change in Maritime Distance") modify
quietly putexcel A1 = "Average Maritime Distance in Baseline (km)"
sum AverageSeaDist
quietly putexcel B1 = `r(mean)', nformat(number)
quietly putexcel A2 = "Average Maritime Distance with Tax (km)"
sum AverageSeaDist_prime
quietly putexcel B2 = `r(mean)', nformat(number)
quietly putexcel A3 = "Change in Average Maritime Distance (%)"
sum Change_AverageSeaDist
quietly putexcel B3 = `r(mean)', nformat(number_d2)
restore


          *********************************************************************************
          *********************************************************************************
     	  ***********                                                           ***********
	      ***********   ESTIMATION OF TAX REVENUES AND CHANGE IN CO2 EMISSIONS  ***********
     	  ***********                                                           ***********
	      *********************************************************************************
	      ********************************************************************************* 

use "Results\Final Results.dta", clear  

		  
          *******************************************************************
          ***** Table 7: Revenue Collection and Change in CO2 Emissions *****
          *******************************************************************   
preserve
replace Seadistance = 0 if Product == 99

gen str Vessel = "Bulk" if (Product == 10 | Product == 12 | Product == 15 | Product == 17 | Product == 22 | Product == 23 | Product == 25 | Product == 26 | Product == 31 | Product == 44 | Product == 47 | Product == 72) /* Bulk Carriers and Grain Trucks */
replace Vessel = "Container" if ((Product >=  1 & Product <= 9) | Product == 11 | Product == 13 | Product == 14 | Product == 16 | Product == 18 | Product == 19 | Product == 20 | Product == 21 | Product == 24 | Product == 30 | Product == 32 | Product == 33 | Product == 34 | Product == 35 | Product == 36 | Product == 37 | Product == 39 | Product == 40 | Product == 41 | Product == 42 | Product == 43 | Product == 45 | Product == 46 | (Product >= 48 & Product <= 71) | (Product >= 73 & Product <= 85) | (Product >= 90 & Product < 99)) /* Container Ships and Container Trucks */
replace Vessel = "Tanker" if (Product == 27) /* Oil Tankers and Tanker Trucks */
replace Vessel = "Chemical" if (Product == 28 | Product == 29 | Product == 38) /* Chemical Tankers and Tanker Trucks */
replace Vessel = "RoRo" if (Product >= 86 & Product <= 89) /* Ro-Ro Ships and Car Carriers */

** CI of maritime transportation for the different scenarios **
gen float Sea_CI_s1 = 3.65 if Vessel == "Bulk"
replace Sea_CI_s1 = 10.20 if Vessel == "Container"
replace Sea_CI_s1 = 3.36 if Vessel == "Tanker"
replace Sea_CI_s1 = 14.70 if Vessel == "Chemical"
replace Sea_CI_s1 = 103 if Vessel == "RoRO"

gen float Sea_CI_s2 = 11.10 if Vessel == "Bulk"
replace Sea_CI_s2 = 21.90 if Vessel == "Container"
replace Sea_CI_s2 = 18.70 if Vessel == "Tanker"
replace Sea_CI_s2 = 54.70 if Vessel == "Chemical"
replace Sea_CI_s2 = 103 if Vessel == "RoRO"

gen float Sea_CI_shapiro = 9.53

** CI of air transportation for the different scenarios **
gen float Air_CI_s1 = 1549
gen float Air_CI_s2 = 653
gen float Air_CI_shapiro = 985.87

** CI of land transportation for the different scenarios **
gen float Land_CI_s1 = 102 if Vessel == "Bulk"
replace Land_CI_s1 = 94 if Vessel == "Container"
replace Land_CI_s1 = 89 if Vessel == "Tanker"
replace Land_CI_s1 = 89 if Vessel == "Chemical"
replace Land_CI_s1 = 195 if Vessel == "RoRO"

gen float Land_CI_s2 = 13.5 //Rail transportation

gen float Land_CI_shapiro = 119
**gen float Land_CI_shapiro = 23


** Estimation of Total Carbon Emissions **
gen Yijk_hat = Yijk_prime / Yijk 
replace Yijk_hat = 1 if (Yijk == 0 & Yijk_prime == 0)
egen Yik = sum(Yijk), by(Exporter Product)
egen Yik_prime = sum(Yijk_prime), by(Exporter Product)
gen Yik_hat = Yik_prime / Yik
gen Qijk_prime = (Yijk_hat / Yik_hat) * Qijk

foreach x in s1 s2 shapiro {
	gen maritime_emission_`x' = (Qijk * Seadistance * Sea_CI_`x' / 1000000) //We express Carbon intensity in tCO2.ton.km instead of gCO2.ton.km 
	egen Maritime_Emission_`x' = sum(maritime_emission_`x')
	replace Maritime_Emission_`x' = Maritime_Emission_`x' / 1000000000 //We express pre-tax Maritime emissions in billion tons
	gen maritime_emission_`x'_prime = (Qijk_prime * Seadistance * Sea_CI_`x' / 1000000)
	egen Maritime_Emission_`x'_prime = sum(maritime_emission_`x'_prime)
	replace Maritime_Emission_`x'_prime = Maritime_Emission_`x'_prime / 1000000000 //We express post-tax Maritime emissions in billion tons
	gen Revenues_`x' = 40 * Maritime_Emission_`x'_prime 
	
	gen Change_Maritime_Emission_`x' = (Maritime_Emission_`x'_prime - Maritime_Emission_`x') / Maritime_Emission_`x' * 100

	** We estimate now the decline in total emissions (from sea, air, and road transportation)
	gen total_emission_`x' = (Qijk * Seadistance * Sea_CI_`x' / 1000000)  + (Qijk * Roaddistance * Land_CI_`x' / 1000000) if (Border == 0 & Product != 99)
	replace total_emission_`x' = (Qijk * Airdistance * Air_CI_`x' / 1000000) if (Border == 0 & Product == 99)
	replace total_emission_`x' =  (Qijk * Airdistance * Land_CI_`x' / 1000000) if Border == 1
	egen Total_Emission_`x' = sum(total_emission_`x')
	
	gen total_emission_`x'_prime = (Qijk_prime  * Seadistance * Sea_CI_`x' / 1000000)  + (Qijk_prime  * Roaddistance * Land_CI_`x' / 1000000) if (Border == 0 & Product != 99)
	replace total_emission_`x'_prime  = (Qijk_prime  * Airdistance * Air_CI_`x' / 1000000) if (Border == 0 & Product == 99)
	replace total_emission_`x'_prime  =  (Qijk_prime  * Airdistance * Land_CI_`x' / 1000000) if Border == 1
	egen Total_Emission_`x'_prime = sum(total_emission_`x'_prime)
	
	gen Change_Total_Emission_`x' = (Total_Emission_`x'_prime - Total_Emission_`x') / Total_Emission_`x' * 100
}
quietly putexcel set "Results\Tables\Table 7.xlsx", replace
quietly putexcel B1 = "Conservative Scenario:"
quietly putexcel C1 = "Optimistic Scenario:"
quietly putexcel D1 = "Using CI from Shapiro (2016)"
quietly putexcel B2 = "Low CI of Ships and High CI of Land/Air"
quietly putexcel C2 = "High CI of Ships and Low CI of Land/Air"
quietly putexcel A3 = "Pre-tax CO2 Emissions (billion tons)"
quietly replace Maritime_Emission_s1 = round(Maritime_Emission_s1, 0.001)
su Maritime_Emission_s1
quietly putexcel B3 = `r(mean)'
quietly replace Maritime_Emission_s2 = round(Maritime_Emission_s2, 0.001)
su Maritime_Emission_s2
quietly putexcel C3 = `r(mean)'
quietly putexcel A4 = "Post-tax CO2 Emissions (billion tons)"
quietly replace Maritime_Emission_shapiro = round(Maritime_Emission_shapiro, 0.001)
su Maritime_Emission_shapiro
quietly putexcel D3 = `r(mean)'
quietly putexcel A4 = "Post-tax CO2 Emissions (billion tons)"
quietly replace Maritime_Emission_s1_prime = round(Maritime_Emission_s1_prime, 0.001)
su Maritime_Emission_s1_prime
quietly putexcel B4 = `r(mean)'
quietly replace Maritime_Emission_s2_prime = round(Maritime_Emission_s2_prime, 0.001)
su Maritime_Emission_s2_prime
quietly putexcel C4 = `r(mean)'
quietly replace Maritime_Emission_shapiro_prime = round(Maritime_Emission_shapiro_prime, 0.001)
su Maritime_Emission_shapiro_prime
quietly putexcel D4 = `r(mean)'
quietly putexcel A5 = "Change in Maritime Transport Emissions (%)"
su Change_Maritime_Emission_s1
quietly putexcel B5 = `r(mean)', nformat(number_d2)
su Change_Maritime_Emission_s2
quietly putexcel C5 = `r(mean)', nformat(number_d2)
su Change_Maritime_Emission_shapiro
quietly putexcel D5 = `r(mean)', nformat(number_d2)
quietly putexcel A6 = "Revenues Collected (billion US$)"
quietly replace Revenues_s1 = round(Revenues_s1, 0.001)
su Revenues_s1
quietly putexcel B6 = `r(mean)'
quietly replace Revenues_s2 = round(Revenues_s2, 0.001)
su Revenues_s2
quietly putexcel C6 = `r(mean)'
quietly replace Revenues_shapiro = round(Revenues_shapiro, 0.001)
su Revenues_shapiro
quietly putexcel D6 = `r(mean)'
quietly putexcel A7 = "Change in Total Transport Emissions (%)"
su Change_Total_Emission_s1
quietly putexcel B7 = `r(mean)', nformat(number_d2)
su Change_Total_Emission_s2
quietly putexcel C7 = `r(mean)', nformat(number_d2)
su Change_Total_Emission_shapiro
quietly putexcel D7 = `r(mean)', nformat(number_d2)
restore