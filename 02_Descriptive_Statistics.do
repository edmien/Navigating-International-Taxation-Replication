** Change the working directory: This is the only change required to run this do-file on any computer **
cd ""


     *********************************************************************************
     *********************************************************************************
	 **************                                                     **************
	 **************     STORAGE OF DESCRIPTIVE TABLES AND FIGURES       **************
	 **************                                                     **************
	 *********************************************************************************
	 *********************************************************************************
	 

          *****************************************************************************
          **** Figure 1: Shares of U.S. + E.U. Seaborne Trade (Average 2012-2019) *****
	      *****************************************************************************
use "Refined data\US+EU Trade.dta", clear
preserve
egen ROWTotal = sum(Trade_Total_ROW)
gen Share_Trade_Total_ROW = Trade_Total_ROW / ROWTotal * 100
sort Seashare
gen CumulatedTotalROW = 0
replace CumulatedTotalROW = Share_Trade_Total_ROW in 1
forvalues i = 2/`=_N' {
	quietly replace CumulatedTotalROW = Share_Trade_Total_ROW + CumulatedTotalROW[_n-1] in `i'
}
line Seashare CumulatedTotalROW, ytitle(Share of Trade by Sea) xtitle(Cumulative Share of Trade) title("Trade with non-neighboring countries")
graph save "Results\Figures\Fig 1a.gph", replace
restore

use "Refined data\US+EU Trade.dta", clear
preserve
gen Seashare_Neighbors = Trade_Sea_Neighbors / Trade_Total_Neighbors * 100
egen NeighborsTotal = sum(Trade_Total_Neighbors) 
gen Share_Total_Neighbors = Trade_Total_Neighbors / NeighborsTotal * 100
sort Seashare_Neighbors
gen CumulatedTotalNeighbors = 0
replace CumulatedTotalNeighbors = Share_Total_Neighbors in 1
forvalues i = 2/`=_N' {
	quietly replace CumulatedTotalNeighbors = Share_Total_Neighbors + CumulatedTotalNeighbors[_n-1] in `i'
}
line Seashare_Neighbors CumulatedTotalNeighbors, ytitle(Share of Trade by Sea) xtitle(Cumulative Share of Trade) title("Trade with neighboring countries")
graph save "Results\Figures\Fig 1b.gph", replace
restore

graph combine "Results\Figures\Fig 1a.gph" "Results\Figures\Fig 1b.gph"
graph export "Results\Figures\Fig 1.png", replace


          ***********************************************************
          **** Table 1: Modified Dataset Descriptive Statistics *****
	      ***********************************************************
use "Refined data\Flows.dta", clear

quietly putexcel set "Results\Tables\Table 1.xlsx", replace
quietly putexcel A1 = "Variable"
quietly putexcel B1 = "Unit"
quietly putexcel C1 = "Mean"
quietly putexcel D1 = "Std. Dev."
quietly putexcel E1 = "Min."
quietly putexcel F1 = "Max."
quietly putexcel G1 = "Source"

quietly summarize Ytot
quietly putexcel A2 = "Total Flows"
quietly putexcel B2 = "1,000 USD"
quietly putexcel C2 = `r(mean)', nformat(number_sep)
quietly putexcel D2 = `r(sd)', nformat(number_sep)
quietly putexcel E2 = `r(min)', nformat(number)
quietly putexcel F2 = `r(max)', nformat(scientific_d2)
quietly putexcel G2 = "CEPII"

quietly gen byte line = 3
foreach x in 50 60 70 {
	quietly sum Y`x'
	quietly putexcel A`=line' = "Maritime Flows (>`x'%)"
	quietly putexcel B`=line' = "1,000 USD"
	quietly putexcel C`=line' = `r(mean)', nformat(number_sep)
	quietly putexcel D`=line' = `r(sd)', nformat(number_sep)
	quietly putexcel E`=line' = `r(min)', nformat(number)
	quietly putexcel F`=line' = `r(max)', nformat(scientific_d2)
	quietly putexcel G`=line' = "CEPII + Authors"
	quietly replace line = line + 1
}

quietly summarize Y0
quietly putexcel A6 = "Maritime Flows (HS)"
quietly putexcel B6 = "1,000 USD"
quietly putexcel C6 = `r(mean)', nformat(number_sep)
quietly putexcel D6 = `r(sd)', nformat(number_sep)
quietly putexcel E6 = `r(min)', nformat(number)
quietly putexcel F6 = `r(max)', nformat(scientific_d2)
quietly putexcel G6 = "CEPII + Authors"

quietly summarize HFO
quietly putexcel A7 = "Fuel Price (1.0% sulph.)"
quietly putexcel B7 = "USD/ton"
quietly putexcel C7 = `r(mean)', nformat(number)
quietly putexcel D7 = `r(sd)', nformat(number)
quietly putexcel E7 = `r(min)', nformat(number)
quietly putexcel F7 = `r(max)', nformat(number)
quietly putexcel G7 = "INSEE"

quietly summarize Seadistance
quietly putexcel A8 = "Seadistance"
quietly putexcel B8 = "km"
quietly putexcel C8 = `r(mean)', nformat(number_sep)
quietly putexcel D8 = `r(sd)', nformat(number_sep)
quietly putexcel E8 = `r(min)', nformat(number)
quietly putexcel F8 = `r(max)', nformat(number_sep)
quietly putexcel G8 = "CERDI"

quietly replace line = 9
foreach x in Border Language Colonization FTA Custom EU WTO Home {
	quietly sum `x'
	quietly putexcel A`=line' = "`x'"
	quietly putexcel B`=line' = "Binary"
	quietly putexcel C`=line' = `r(mean)', nformat(number_d2)
	quietly putexcel D`=line' = `r(sd)', nformat(number_d2)
	quietly putexcel E`=line' = `r(min)', nformat(number)
	quietly putexcel F`=line' = `r(max)', nformat(number)
	quietly putexcel G`=line' = "CEPII"
	quietly replace line = line + 1
}
quietly drop line


          **********************************************************************
          **** Table 2: Spotted International Flows Descriptive Statistics *****
	      **********************************************************************
use "Refined data\Flows.dta", clear
preserve
drop if Home == 1
keep Year Exporter Importer Product Ytot Y0 Y50 Y60 Y70
foreach x in Ytot Y0 Y50 Y60 Y70 {
	gen byte nonzero_`x' = (`x'!=0)
	egen frequency_`x' = mean(nonzero_`x')
	egen global_`x' = sum(`x')
	gen share_`x' = global_`x' / global_Ytot
}
quietly putexcel set "Results\Tables\Table 2.xlsx", replace
putexcel A1 = "Variable"
putexcel B1 = "Global International Flows 2012-2019 (1,000 USD, sum over the period)"
putexcel C1 = "Share of Global International Flows (% of Total Flows)"
putexcel D1 = "Share of non-Zero Values (% of Observations)"
putexcel A2 = "Total Flows"
putexcel A3 = "Y50"
putexcel A4 = "Y60"
putexcel A5 = "Y70"
putexcel A6 = "YHS"

gen byte line = 2
foreach x in Ytot Y50 Y60 Y70 Y0 {
	putexcel B`=line' = global_`x', nformat(scientific_d2)
	putexcel C`=line' = share_`x', nformat(percent)
	putexcel  D`=line' = frequency_`x', nformat(percent)
	replace line = line + 1
}
restore


          **********************************************************
          **** Table A.5: Sectoral Elasticities of Substitution ****
	      **********************************************************
use "Refined data\Elasticities.dta", clear
merge 1:1 Product using "Refined data\HS2 Codes.dta"
drop if _merge == 2
rename sigma_0 sigma_HS
export excel Product Definition sigma_50 sigma_60 sigma_70 sigma_HS sigma_60_low sigma_60_high using "Results\Tables\Table A5.xlsx", replace firstrow(variables)


          ***********************************************************
          **** Table C.4: Ranking of the 30 Most Remote Countries ***
	      ***********************************************************
use "Database.dta", clear	  
keep if Year == 2019
drop if Importer == Exporter
drop if Product == 99
rename Y60 Yijk
egen Yij = sum(Yijk), by(Exporter Importer)
keep Exporter Importer Yij Seadistance
duplicates drop
rename Exporter Intermediate
rename Importer Exporter
rename Intermediate Importer
rename Yij Xij
save "Results\Remoteness.dta", replace

use "Database.dta", clear
keep if Year == 2019
drop if Importer == Exporter
drop if Product == 99
rename Y60 Yijk
egen Yij = sum(Yijk), by(Exporter Importer)
keep Exporter Importer Yij Seadistance
duplicates drop
merge 1:1 Exporter Importer using "Results\Remoteness.dta"
drop _merge
egen Yi = sum(Yij), by(Exporter)
egen Xi = sum(Xij), by(Exporter)
gen Numerator = Yij + Xij
gen Denominator = Yi + Xi
gen Weighted_Seadistance = (Numerator / Denominator) * Seadistance
egen Sea_Remoteness = sum(Weighted_Seadistance), by(Exporter)
keep Exporter Sea_Remoteness
duplicates drop

rename Exporter Code
merge 1:1 Code using "Refined data\REM.dta"
drop if _merge == 2
replace REM = 0 if _merge == 1
drop _merge

merge 1:1 Code using "Refined data\Country Codes.dta"
drop if _merge == 2
drop _merge
save "Results\Remoteness.dta", replace

preserve
quietly putexcel set "Results\Tables\Table C3.xlsx", replace
putexcel A1 = "Sea Remoteness Index (2019)"
putexcel D1 = "UN Remoteness Index (2019)"

label variable Code "Country"
label variable Sea_Remoteness "Index"
label variable REM "Index"
gsort -Sea_Remoteness
gen Rank = _n
label variable Rank "Rank"
export excel Rank Country Sea_Remoteness using "Results\Tables\Table C4.xlsx" if _n <= 30, sheet("Sheet1", modify) firstrow(varlabels) cell(A2)
gsort -REM
replace Rank = _n
export excel Rank Country REM using "Results\Tables\Table C4.xlsx" if _n <= 30, sheet("Sheet1", modify) firstrow(varlabels) cell(D2)
restore