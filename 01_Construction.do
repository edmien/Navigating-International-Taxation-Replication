/* Change the working directory: This is the only change required to run this do-file on any computer */
cd ""


     *********************************************************************************
     *********************************************************************************
	 **************                                                     **************
	 **************           CREATION OF ALL REFINED DATASETS          **************
	 **************                                                     **************
	 *********************************************************************************
	 *********************************************************************************

	 
          ****************************************
	      ************* Gravity.dta **************
	      ****************************************
import delimited "Raw data\Gravity_V202211.csv", clear
keep if year >= 2012 & year <= 2019
keep year iso3_o iso3_d contig comlang_ethno col45 rta_type wto_o wto_d eu_o eu_d distcap
duplicates drop
drop if iso3_o == iso3_d

rename year Year
rename iso3_o Exporter
rename iso3_d Importer
rename contig Border
rename comlang_ethno Language
rename col45 Colonization
rename distcap Airdistance

gen byte Custom = (rta_type == 1 | rta_type == 2)
gen byte FTA = (Custom == 1 | rta_type == 4 | rta_type == 5)
drop rta_type

drop if Border == .
fillin Exporter Importer Year
drop if Exporter == Importer
drop _fillin

label variable Border "=1 if Common Border"
label variable Language "=1 if Common Language Spoken by >9% Population"
label variable Colonization "=1 if Former Colonization Relationship after 1945"
label variable wto_o "=1 if Exporting Country is a WTO Member"
label variable wto_d "=1 if Importing Country is a WTO Member"
label variable eu_o "=1 if Exporting Country is a EU Member"
label variable eu_d "=1 if Importing Country is a EU Member"
label variable Custom "=1 if Custom Union"
label variable FTA "=1 if Free Trade Agreement"
label variable Airdistance "Beeline Distance between Capital Cities (km)"

save "Refined data\Gravity Variables.dta", replace


          ****************************************
	      *********** Seadistance.dta ************
	      ****************************************
** We first need to create a new country "South Sudan" (SSD) defined with the geographic position of Uganda (UGA) because they share the same port of reference located in Kenya **
use "Raw data\CERDI-seadistance.dta", clear
preserve
replace iso1 = "SSD" if iso1 == "UGA"
replace iso2 = "SSD" if iso2 == "UGA"
keep if iso1 == "SSD" | iso2 == "SSD"
keep iso1 iso2 seadistance
save "Refined data\Seadistance.dta", replace
restore

** Now we create our final base by combining the original base with the sub-database for South Sudan **
append using "Refined data\Seadistance.dta"
rename iso1 Exporter
rename iso2 Importer
fillin Exporter Importer
drop if Exporter == Importer
drop _fillin

replace seadistance = 0 if Exporter == "SSD" & Importer == "UGA"
replace seadistance = 0 if Importer == "SSD" & Exporter == "UGA"
gen float Seadistance = seadistance

** For the few missing variables for the road distance between port and capital, we complete using data from Google **
replace capitalport1 = 1617 if Exporter == "SSD" /* We attribute the distance Djouba-Mombasa */
replace capitalport2 = 1617 if Importer == "SSD"
replace capitalport1 = 346 if Exporter == "COD" /* We attribute the distance Kinshasa-Matadi */
replace capitalport2 = 346 if Importer == "COD"
replace capitalport1 = 475 if Exporter == "UKR" /* We attribute the distance Kiev-Odessa */
replace capitalport2 = 475 if Importer == "UKR"
replace capitalport1 = 0 if capitalport1 == .
replace capitalport2 = 0 if capitalport2 == .
gen float Roaddistance = capitalport1 + capitalport2 //We create a new variable for the total road distance that products transported by sea must travel (from ports to capitals) at the country-pair level

drop seadistance roaddistance capitalport* short

sort Exporter Importer
label variable Seadistance "Distance by Sea Between Respective Ports of Reference"
label variable Roaddistance "Distance by Road Between Respective Capital Cities and Their Ports of Reference"
order Exporter Importer

save "Refined data\Seadistance.dta", replace //As we do not need the sub-database for South Sudan, we overwrite the dataset


          ****************************************
	      *********** Fuel Price.dta *************
	      ****************************************
import delimited "Raw data\Fuel Price.csv", clear

gen Month=monthly(v1, "YM")
format Month %tm
drop v1
sort Month
gen Year = 1960 + floor(Month/12)
recast int Year
rename v2 HFO
collapse (mean) HFO, by(Year) //We are only interested in annual data
label variable HFO "Rotterdam Price of Heavy Fuel < 1% Sulphur (USD/ton)"
tsset Year
save "Refined data\Fuel Price.dta", replace


          ****************************************
	      ********* TradeProd Ratios.dta *********
      	  ****************************************
use "Raw data\TPc_V202401.dta", clear

keep if year >= 2012 & year <= 2019

keep year industry iso3_tp_o iso3_tp_d trade_sq_yr

rename year Year
rename industry Industry
rename iso3_tp_o Exporter
rename iso3_tp_d Importer
rename trade_sq_yr Trade

recast str3 Exporter
recast str3 Importer

sort Year Industry Exporter Importer

gen Intra = (Exporter == Importer)

egen Total_Both = sum(Trade), by(Exporter Year Industry Intra)
gen Total_Inter = Total_Both if Intra == 0
egen Mean_Inter = mean(Total_Inter), by(Exporter Year Industry)
gen Total_Intra = Total_Both if Intra == 1
egen Mean_Intra = mean(Total_Intra), by(Exporter Year Industry)

gen Ratio = Mean_Intra / Mean_Inter
label variable Ratio "Ratio of Intranational Flows to International Exports (by Country of Exporter, Year and Industry)"
drop Total_Both Total_Inter Mean_Inter Total_Intra Mean_Intra

keep Year Industry Exporter Ratio
duplicates drop

fillin Exporter Year Industry
drop _fillin

replace Industry = "Chemicals" if Industry == "Chemicals (23t25)"
replace Industry = "Food" if Industry == "Food (15t16)"
replace Industry = "Machines" if Industry == "Machines (29t33)"
replace Industry = "Metals" if Industry == "Metals (27t28)"
replace Industry = "Minerals" if Industry == "Minerals (26)"
replace Industry = "Other" if Industry == "Other (36)"
replace Industry = "Textiles" if Industry == "Textiles (17t19)"
replace Industry = "Vehicles" if Industry == "Vehicles (34t35)"
replace Industry = "Wood" if Industry == "Wood-Paper (20t22)"
recast str9 Industry

gen float RoW_Ratio = . //We create the Ratio for the Rest of the World that will be used to complete missing observations
drop if Exporter == "MHL" //We drop Marshall Islands as it contains only missing values and is included in the rest of the World
replace RoW_Ratio = Ratio if Exporter == "ROW"
egen RoW = mean(RoW_Ratio), by(Year Industry)
label variable RoW "Ratio for Rest of the World"
drop RoW_Ratio
rename RoW RoW_Ratio

save "Refined data\TradeProd Ratios.dta", replace


          ****************************************
     	  *********** US+EU Trade.dta ************
	      ****************************************	  
** Product codes.dta **
import delimited "Raw data\product_codes_HS12_V202401b.csv", clear
rename code HS6
save "Refined data\HS6 Codes.dta", replace

** US Exports data **
import delimited "Raw data\State Exports by HS Commodities.csv", parselocale(en_US) case(preserve) clear
gen HS6=substr(Commodity, 1, 6)
destring HS6, replace
drop State Commodity
fillin HS6 Country Time
drop _fillin
rename TotalValueUS Exports_Total
rename VesselValueUS Exports_Sea
collapse (sum) Exports_Total Exports_Sea, by(HS6 Country)
replace Country="_World" if Country=="World Total"
reshape wide Exports_Total Exports_Sea, i(HS6) j(Country) string
gen double Exports_Total_Neighbors = Exports_TotalCanada + Exports_TotalMexico
gen double Exports_Total_ROW = Exports_Total_World - Exports_Total_Neighbors
gen double Exports_Sea_Neighbors = Exports_SeaCanada + Exports_SeaMexico
gen double Exports_Sea_ROW = Exports_Sea_World - Exports_Sea_Neighbors
keep HS6 Exports_Total_World Exports_Total_Neighbors Exports_Total_ROW Exports_Sea_World Exports_Sea_Neighbors Exports_Sea_ROW
save "Refined data\US+EU Trade.dta", replace

** US Imports data **
import delimited "Raw data\State Imports by HS Commodities.csv", parselocale(en_US) case(preserve) clear
gen HS6=substr(Commodity, 1, 6)
destring HS6, replace
drop State Commodity
fillin HS6 Country Time
drop _fillin
rename TotalValueUS Imports_Total
rename VesselValueUS Imports_Sea
collapse (sum) Imports_Total Imports_Sea, by(HS6 Country)
replace Country="_World" if Country=="World Total"
reshape wide Imports_Total Imports_Sea, i(HS6) j(Country) string
gen double Imports_Total_Neighbors = Imports_TotalCanada + Imports_TotalMexico
gen double Imports_Total_ROW = Imports_Total_World - Imports_Total_Neighbors
gen double Imports_Sea_Neighbors = Imports_SeaCanada + Imports_SeaMexico
gen double Imports_Sea_ROW = Imports_Sea_World - Imports_Sea_Neighbors
keep HS6 Imports_Total_World Imports_Total_Neighbors Imports_Total_ROW Imports_Sea_World Imports_Sea_Neighbors Imports_Sea_ROW

merge 1:1 HS6 using "Refined data\US+EU Trade.dta"
drop _merge
/* A few products have not been merged : the products that are either exported but not imported or imported but not exported. 
For these products, we will use only the export/import data and treat the other one as zero */
egen double US_Trade_Total_World = rowtotal(Exports_Total_World Imports_Total_World)
egen double US_Trade_Total_Neighbors = rowtotal(Exports_Total_Neighbors Imports_Total_Neighbors)
egen double US_Trade_Total_ROW = rowtotal(Exports_Total_ROW Imports_Total_ROW)
egen double US_Trade_Sea_World = rowtotal(Exports_Sea_World Imports_Sea_World)
egen double US_Trade_Sea_Neighbors = rowtotal(Exports_Sea_Neighbors Imports_Sea_Neighbors)
egen double US_Trade_Sea_ROW = rowtotal(Exports_Sea_ROW Imports_Sea_ROW)
keep HS6 US_*
save "Refined data\US+EU Trade.dta", replace

** Eurostat Data **
import excel "Raw data\Exchange_Rates_incl_Effective_Ex_Rat.xls", firstrow clear //We first need to save USD-Euro bilateral exchange rates data 
rename DomesticCurrencyperUSDolla NER
save "Refined data\NER.dta", replace

import excel "Raw data\Eurostat.xlsx", sheet("Feuil1") cellrange(A6:AJZ6650) firstrow clear
rename PRODUCTCodes HS6
drop PRODUCTLabels
quietly destring *, replace force

forvalues i=2012/2019 {
	egen double EU_Trade_Total_World`i' = rowtotal(*_World_`i')	
	egen double EU_Trade_Total_Neighbors`i' = rowtotal(*_AD_`i' *_AL_`i' *_BA_`i' *_BY_`i' *_CH_`i' *_LI_`i' *_MD_`i' *_ME_`i' *_MK_`i' *_NO_`i' *_RU_`i' *_TR_`i' *_UA_`i' *_XS_`i')
	gen double EU_Trade_Total_ROW`i' = EU_Trade_Total_World`i' - EU_Trade_Total_Neighbors`i'
	
	egen double EU_Trade_Sea_World`i' = rowtotal(*_Sea_World_`i' )
	egen double EU_Trade_Sea_Neighbors`i' = rowtotal(*_Sea_AD_`i' *_Sea_AL_`i' *_Sea_BA_`i' *_Sea_BY_`i' *_Sea_CH_`i' *_Sea_LI_`i' *_Sea_MD_`i' *_Sea_ME_`i' *_Sea_MK_`i' *_Sea_NO_`i' *_Sea_RU_`i' *_Sea_TR_`i' *_Sea_UA_`i' *_Sea_XS_`i') 
	gen double EU_Trade_Sea_ROW`i' = EU_Trade_Sea_World`i' - EU_Trade_Sea_Neighbors`i'
}
keep HS6 EU_*
reshape long EU_Trade_Total_World EU_Trade_Total_Neighbors EU_Trade_Total_ROW EU_Trade_Sea_World EU_Trade_Sea_Neighbors EU_Trade_Sea_ROW, i(HS6) j(Year)

merge n:1 Year using "Refined data\NER.dta"
drop _merge
sort HS6 Year
foreach x in EU_Trade_Total_World EU_Trade_Total_ROW EU_Trade_Sea_ROW {
	replace `x' = `x' / NER //We express our variables in USD instead of Euros
}
drop Year NER
collapse (sum) EU_*, by(HS6)
drop if EU_Trade_Total_World == 0
merge 1:1 HS6 using "Refined data\US+EU Trade.dta" //We merge US and EU data
drop _merge 
save "Refined data\US+EU Trade.dta", replace

merge 1:1 HS6 using "Refined data\HS6 Codes.dta"
preserve
drop if _merge == 1
drop _merge
save "Refined data\US+EU Trade.dta", replace
restore

/* In the US and EU original database, the revision 17 is used for years 2017, 2018, and 2019, while the revision 12 is used from year 2012 onwards.
Since we want only data define with the revision 12, we harmonize our data using equivalence tables from the World Customs Organization. We proceed as follows:
   - When a category changes in its HS6-digits value between rev12 and rev17, we change the HS6-digits value accordingly
   - When one category in rev12 becomes several categories in rev17, we simply sum them and merge them with the rev12 product
   - When several categories in rev12 becomes one category in rev17, we drop this category as we cannot know to which product we should attribute the value
*/
keep if _merge == 1
drop _merge
quietly replace HS6 = 30289 if HS6 == 30249
quietly replace HS6 = 30290 if HS6 == 30291
quietly replace HS6 = 30281 if HS6 == 30292
quietly drop if HS6 == 30299
quietly replace HS6 = 30389 if HS6 == 30359
quietly replace HS6 = 30390 if HS6 == 30391
quietly replace HS6 = 30381 if HS6 == 30392
quietly drop if HS6 == 30399
quietly replace HS6 = 30449 if (HS6 == 30447 | HS6 == 30448)
quietly replace HS6 = 30459 if (HS6 == 30456 | HS6 == 30457)
quietly replace HS6 = 30489 if HS6 == 30488
quietly replace HS6 = 30499 if (HS6 == 30496 | HS6 == 30497)
quietly replace HS6 = 30559 if (HS6 == 30552 | HS6 == 30553 | HS6 == 30554)
quietly replace HS6 = 30621 if (HS6 == 30631 | HS6 == 30691)
quietly replace HS6 = 30622 if (HS6 == 30632 | HS6 == 30692)
quietly replace HS6 = 30624 if (HS6 == 30633 | HS6 == 30693)
quietly replace HS6 = 30625 if (HS6 == 30634 | HS6 == 30694)
quietly replace HS6 = 30626 if HS6 == 30635
quietly replace HS6 = 30627 if HS6 == 30636
quietly replace HS6 = 30629 if (HS6 == 30639 | HS6 == 30699)
quietly drop if HS6 == 30695
quietly replace HS6 = 30719 if HS6 == 30712
quietly replace HS6 = 30729 if HS6 == 30722
quietly replace HS6 = 30739 if HS6 == 30732
quietly drop if HS6 == 30742
quietly drop if HS6 == 30743
quietly replace HS6 = 30759 if HS6 == 30752
quietly replace HS6 = 30779 if HS6 == 30772
quietly replace HS6 = 30791 if HS6 == 30782
quietly replace HS6 = 30789 if (HS6 == 30783 | HS6 == 30787)
quietly replace HS6 = 30799 if (HS6 == 30784 | HS6 == 30788 | HS6 == 30792)
quietly replace HS6 = 30819 if HS6 == 30812
quietly replace HS6 = 30829 if HS6 == 30822
quietly replace HS6 = 80520 if (HS6 == 80521 | HS6 == 80522 | HS6 == 80529)
quietly drop if HS6 == 121150
quietly replace HS6 = 130219 if HS6 == 130214
quietly replace HS6 = 160419 if HS6 == 160418
quietly replace HS6 = 220290 if (HS6 == 220291 | HS6 == 220299)
quietly replace HS6 = 220429 if HS6 == 220422
quietly replace HS6 = 271000 if (HS6 == 271012 | HS6 == 271019 | HS6 == 271020 | HS6 == 271091 | HS6 == 271099)
quietly replace HS6 = 281119 if HS6 == 281112
quietly replace HS6 = 281210 if (HS6 == 281211 | HS6 == 281212 | HS6 == 281213 | HS6 == 281214 | HS6 == 281215 | HS6 == 281216 | HS6 == 281217 | HS6 == 281219)
quietly replace HS6 = 285300 if (HS6 == 285310 | HS6 == 285390)
quietly replace HS6 = 290389 if HS6 == 290383
quietly replace HS6 = 290399 if (HS6 == 290393 | HS6 == 290394)
quietly replace HS6 = 290490 if (HS6 == 290431 | HS6 == 290432 | HS6 == 290433 | HS6 == 290434 | HS6 == 290435 | HS6 == 290436 | HS6 == 290491 | HS6 == 290499)
quietly replace HS6 = 291090 if HS6 == 291050
quietly replace HS6 = 291469 if HS6 == 291462
quietly replace HS6 = 291470 if (HS6 == 291471 | HS6 == 291479)
quietly drop if HS6 == 291800
quietly replace HS6 = 291819 if HS6 == 291817
quietly replace HS6 = 292090 if (HS6 == 292021 | HS6 == 292022 | HS6 == 292023 | HS6 == 292024 | HS6 == 292029 | HS6 == 292030)
quietly replace HS6 = 292119 if (HS6 == 292112 | HS6 == 292113 | HS6 == 292114)
quietly replace HS6 = 292213 if HS6 == 292215
quietly replace HS6 = 292219 if (HS6 == 292216 | HS6 == 292217 | HS6 == 292218)
quietly replace HS6 = 292390 if (HS6 == 292330 | HS6 == 292340)
quietly replace HS6 = 292429 if HS6 == 292425
quietly replace HS6 = 292690 if HS6 == 292640
quietly replace HS6 = 293090 if (HS6 == 293060 | HS6 == 293070)
quietly drop if HS6 == 293080
quietly replace HS6 = 293190 if (HS6 == 293131 | HS6 == 293132 | HS6 == 293133 | HS6 == 293134 | HS6 == 293135 | HS6 == 293136 | HS6 == 293137 | HS6 == 293138 | HS6 == 293139)
quietly replace HS6 = 293219 if HS6 == 293214
quietly replace HS6 = 293399 if HS6 == 293392
quietly replace HS6 = 293500 if (HS6 == 293510 | HS6 == 293520 | HS6 == 293530 | HS6 == 293540 | HS6 == 293550 | HS6 == 293590)
quietly replace HS6 = 293991 if HS6 == 293971
quietly replace HS6 = 293999 if HS6 == 293979
quietly drop if HS6 == 293980
quietly replace HS6 = 300210 if (HS6 == 300211 | HS6 == 300212 | HS6 == 300213 | HS6 == 300214 | HS6 == 300215 | HS6 == 300219)
quietly replace HS6 = 300390 if (HS6 == 300341 | HS6 == 300342 | HS6 == 300343 | HS6 == 300349) 
quietly replace HS6 = 300390 if HS6 == 300360
quietly replace HS6 = 300440 if (HS6 == 300441 | HS6 == 300442 | HS6 == 300443 | HS6 == 300449)
quietly replace HS6 = 300490 if HS6 == 300460
quietly replace HS6 = 310310 if (HS6 == 310311 | HS6 == 310319)
quietly drop if HS6 == 370291
quietly replace HS6 = 370296 if HS6 == 370293
quietly replace HS6 = 370297 if HS6 == 370294
quietly replace HS6 = 370298 if HS6 == 370295
quietly drop if HS6 == 370500
quietly replace HS6 = 380850 if HS6 == 380852
quietly drop if HS6 == 380859
quietly replace HS6 = 380891 if (HS6 == 380861 | HS6 == 380862 | HS6 == 380869)
quietly replace HS6 = 381230 if (HS6 == 381231 | HS6 == 381239)
quietly replace HS6 = 382490 if (HS6 == 382484 | HS6 == 382485 | HS6 == 382486 | HS6 == 382487 | HS6 == 382488 | HS6 == 382491 | HS6 == 382499)
quietly replace HS6 = 390190 if HS6 == 390140
quietly replace HS6 = 390760 if (HS6 == 390761 | HS6 == 390769)
quietly replace HS6 = 390930 if (HS6 == 390931 | HS6 == 390939)
quietly drop if (HS6 == 401170 | HS6 == 401180 | HS6 == 401190)
quietly replace HS6 = 440110 if (HS6 == 440111 | HS6 == 440112)
quietly replace HS6 = 440139 if HS6 == 440140
quietly replace HS6 = 440310 if (HS6 == 440311 | HS6 == 440312)
quietly replace HS6 = 440320 if (HS6 == 440321 | HS6 == 440322 | HS6 == 440323 | HS6 == 440324 | HS6 == 440325 | HS6 == 440326)
quietly replace HS6 = 440392 if (HS6 == 440393 | HS6 == 440394)
quietly replace HS6 = 440399 if (HS6 == 440395 | HS6 == 440396 | HS6 == 440397 | HS6 == 440398)
quietly replace HS6 = 440610 if (HS6 == 440611 | HS6 == 440612)
quietly replace HS6 = 440690 if (HS6 == 440691 | HS6 == 440692)
quietly replace HS6 = 440710 if (HS6 == 440711 | HS6 == 440712 | HS6 == 440719)
quietly replace HS6 = 440799 if (HS6 == 440796 | HS6 == 440797)
quietly replace HS6 = 440929 if HS6 == 440922
quietly replace HS6 = 441232 if (HS6 == 441233 | HS6 == 441234)
quietly drop if HS6 == 441873
quietly replace HS6 = 441871 if HS6 == 441874
quietly replace HS6 = 441872 if HS6 == 441875
quietly replace HS6 = 441890 if (HS6 == 441891 | HS6 == 441899)
quietly replace HS6 = 441900 if (HS6 == 441911 | HS6 == 441912 | HS6 == 441919 | HS6 == 441990)
quietly replace HS6 = 442190 if (HS6 == 442191 | HS6 == 442199)
quietly replace HS6 = 540259 if HS6 == 540253
quietly replace HS6 = 540269 if HS6 == 540263
quietly replace HS6 = 550200 if (HS6 == 550210 | HS6 == 550290)
quietly replace HS6 = 550690 if HS6 == 550640
quietly replace HS6 = 570490 if HS6 == 570420
quietly drop if HS6 == 600535
quietly replace HS6 = 600531 if HS6 == 600536
quietly replace HS6 = 600532 if HS6 == 600537
quietly replace HS6 = 600533 if HS6 == 600538
quietly replace HS6 = 600534 if HS6 == 600539
quietly replace HS6 = 630491 if HS6 == 630420
quietly drop if (HS6 == 690721 | HS6 == 690722 | HS6 == 690723 | HS6 == 690730 | HS6 == 690740)
quietly replace HS6 = 842481 if (HS6 == 842441 | HS6 == 842449 | HS6 == 842482)
quietly replace HS6 = 843230 if (HS6 == 843231 | HS6 == 843239)
quietly replace HS6 = 843240 if (HS6 == 843241 | HS6 == 843242)
quietly replace HS6 = 845610 if (HS6 == 845611 | HS6 == 845612)
quietly replace HS6 = 845690 if (HS6 == 845640 | HS6 == 845650)
quietly replace HS6 = 845940 if (HS6 == 845941 | HS6 == 845949)
quietly replace HS6 = 846011 if HS6 == 846012
quietly replace HS6 = 846021 if (HS6 == 846022 | HS6 == 846023 | HS6 ==	846024)
quietly drop if HS6 == 846520
quietly replace HS6 = 852841 if HS6 == 852842
quietly replace HS6 = 852851 if HS6 == 852852
quietly replace HS6 = 852861 if HS6 == 852862
quietly drop if HS6 == 853950
quietly replace HS6 = 870190 if (HS6 == 870191 | HS6 == 870192 | HS6 == 870193 | HS6 == 870194 | HS6 == 870195)
quietly drop if HS6 == 870220
quietly replace HS6 = 870290 if (HS6 == 870230 | HS6 == 870240)
quietly drop if (HS6 == 870340 | HS6 == 870350 | HS6 == 870360 | HS6 == 870370)
quietly replace HS6 = 870390 if HS6 == 870380
quietly replace HS6 = 871190 if HS6 == 871160
quietly drop if HS6 == 880000
quietly replace HS6 = 940151 if (HS6 == 940152 | HS6 == 940153)
quietly replace HS6 = 940381 if (HS6 == 940382 | HS6 == 940383)
quietly replace HS6 = 940600 if (HS6 == 940610 | HS6 == 940690)
quietly drop if (HS6 == 962000)
quietly drop if HS6 > 980000
append using "Refined data\US+EU Trade.dta"
drop description
collapse (sum) US_* EU_*, by(HS6)

foreach x in Trade_Total_World Trade_Total_Neighbors Trade_Total_ROW Trade_Sea_Neighbors Trade_Sea_ROW {
	gen double `x' = US_`x' + EU_`x'
}
drop US_* EU_*
gen Seashare = Trade_Sea_ROW / Trade_Total_ROW * 100
gen byte D50 = (Seashare > 50)
gen byte D60 = (Seashare > 60) 
gen byte D70 = (Seashare > 70)
save "Refined data\US+EU Trade.dta", replace


          ****************************************
     	  ************* HS6 Codes.dta ************
	      ****************************************
use "Refined data\HS6 Codes.dta", clear
tostring HS6, generate(commodity)
gen HS4 = substr(commodity, 1, 3) if HS6 < 100000 //We define the HS4-digits variable as the 4 first digits of the HS6-digits variable
replace HS4 = substr(commodity, 1, 4) if HS6 > 99999
destring HS4, replace
gen Product = substr(commodity, 1, 1) if HS6 < 100000 //We define the HS2-digits variale (called "Product" in the rest of the study) as the 2 first digits of the HS6-digits variable
replace Product = substr(commodity, 1, 2) if HS6 > 99999
destring Product, replace
drop commodity

/* We create the list of perishable products that will be used to define maritime products based on extended Hummels and Schaur (2013) approach 
This approach consists in defining as maritime the products in which definition we spot specific keywords.
Remark: we do not define as maritime the products in which the specific keyword is preceded by words such as "not", "excluding", or "other than" */
     * Parts *
generate byte Parts = ustrregexm(description,"\bParts\b")
replace Parts = 1 if ustrregexm(description,"\bparts\b") == 1
replace Parts = 0 if HS6 < 300000 //We want to exclude parts of plants and parts of animals from the sample

     * Components *
generate byte Components = ustrregexm(description,"\bcomponents\b")
replace Components = 1 if ustrregexm(description,"\bComponents\b") == 1

     * Fresh *
generate byte Fresh = ustrregexm(description,"\bFresh\b")
replace Fresh = 1 if ustrregexm(description,"\bfresh\b") == 1

     * Frozen *
generate byte Frozen = ustrregexm(description,"\bFrozen\b")
replace Frozen = 1 if ustrregexm(description,"\bfrozen\b") == 1
replace Frozen = 0 if ustrregexm(description,"\bnot frozen\b") == 1

     * Edible *
generate byte Edible = ustrregexm(description,"\bEdible\b")
replace Edible = 1 if ustrregexm(description,"\bedible\b") == 1
replace Edible = 0 if ustrregexm(description,"\bexcludes edible\b") == 1
replace Edible = 0 if ustrregexm(description,"\bother than edible\b") == 1
replace Edible = 0 if ustrregexm(description,"\bprepared or preserved\b") == 1
replace Edible = 0 if ustrregexm(description,"\bedible ice\b") == 1

     * Live *
generate byte Live = ustrregexm(description,"\bLive\b")
replace Live = 1 if ustrregexm(description,"\blive\b") == 1
replace Live = 0 if ustrregexm(description,"\bexcludes live\b") == 1
replace Live = 0 if ustrregexm(description,"\bother than live\b") == 1

     * Medical *
gen byte Medical = (HS6 > 300100 & HS6 < 300500) //We define "blood", "organs", "vaccines", and "medicaments" as maritime products

     * Artworks *
gen byte Artworks = (HS6 > 970000 & HS6 < 980000) //We define "Artworks and Antiques" (HS2 #97) as maritime products

gen byte D0 = (Parts == 0 & Components == 0 & Fresh == 0 & Frozen == 0 & Live == 0 & Edible == 0 & Medical == 0 & Artworks == 0)

merge 1:1 HS6 using "Refined data\US+EU Trade.dta"
keep HS6 HS4 Product D0 D50 D60 D70

label variable D0 "=1 if Non-Perishable and Non-Intermediate Product"
label variable D50 "=1 if US Trade by Sea > 50% Total US Trade"
label variable D60 "=1 if US Trade by Sea > 60% Total US Trade"
label variable D70 "=1 if US Trade by Sea > 70% Total US Trade"
order HS6 HS4 Product D0 D50 D60 D70
save "Refined data\HS6 Codes.dta", replace


          ****************************************
	      ********** Elasticities.dta ************
	      ****************************************
use "Refined data\HS6 Codes.dta", clear
merge 1:1 HS6 using "Raw data\elasticity_for_publication_2021_09_29.dta"
drop if _merge == 2
gen sigma = 1 - epsilon_pt
drop epsilon epsilon_pt zero positive missing positive_pt _merge

foreach x in 0 50 60 70 {
	gen sigma_`x'_sea = sigma if D`x' == 1
	replace sigma_`x'_sea = . if D`x' == 0
	egen sigma_`x' = mean(sigma_`x'_sea), by(Product)
	egen sigma_`x'_low = pctile(sigma_`x'_sea), by(Product) p(25)
	replace sigma_`x'_low = sigma_`x' if (sigma_`x'_low > sigma_`x')
	egen sigma_`x'_high = pctile(sigma_`x'_sea), by(Product) p(75)
	replace sigma_`x'_high = sigma_`x' if (sigma_`x'_high < sigma_`x')
	
	gen sigma_`x'_air = sigma if D`x' == 0
	replace sigma_`x'_air = . if D`x' == 1
	egen sigma_`x'_99 = mean(sigma_`x'_air)
	egen sigma_`x'_99_low = pctile(sigma_`x'_air), p(25)
	egen sigma_`x'_99_high = pctile(sigma_`x'_air), p(75)
	replace sigma_`x' = sigma_`x'_99 if Product == 99
	replace sigma_`x'_low = sigma_`x'_99_low if Product == 99
	replace sigma_`x'_high = sigma_`x'_99_high if Product == 99
	
	drop sigma_`x'_sea sigma_`x'_air sigma_`x'_99*
}
keep Product sigma_0* sigma_50* sigma_60* sigma_70*
duplicates drop

/* There are a two reasons why the value of sigma may be missing at the HS2-digits level. 
   (1) When the HS2-digits level product includes only maritime goods. 
This is the case for Product #97 for Y50, Y60, Y70, and Y0; Product #88 for Y70; and Products #1 and #8 for Y0
Here, we let the observation as missing (because no PPML will be regressed on these flows)
   (2) When all maritime goods within a HS2-digits product are associated with missing sigma (i.e., the available sigma within a HS2-digits product are all dropped when we exclude non-maritime flows).
In that case we attribute the "closest" sigma that is available:
     - For sigma_0 Product #6, we attribute the value of sigma_50
     - For sigma_60 and sigma_70 Product #43 we attribute the value of sigma_50
     - For sigma_50 and sigma_60 at Product #88 we attribute the value of sigma_0
*/
replace sigma_0 = sigma_50 if Product == 6
replace sigma_0_low = sigma_50_low if Product == 6
replace sigma_0_high = sigma_50_high if Product == 6

replace sigma_60 = sigma_50 if Product == 43
replace sigma_60_low = sigma_50_low if Product == 43
replace sigma_60_high = sigma_50_high if Product == 43

replace sigma_70 = sigma_50 if Product == 43
replace sigma_70_low = sigma_50_low if Product == 43
replace sigma_70_high = sigma_50_high if Product == 43

replace sigma_50 = sigma_0 if Product == 88
replace sigma_50_low = sigma_0_low if Product == 88
replace sigma_50_high = sigma_0_high if Product == 88

replace sigma_60 = sigma_0 if Product == 88
replace sigma_60_low = sigma_0_low if Product == 88
replace sigma_60_high = sigma_0_high if Product == 88

save "Refined data\Elasticities.dta", replace

          ****************************************
     	  ************* HS2 Codes.dta ************
	      ****************************************
import excel "Raw data\HS2-Level Products.xlsx", firstrow clear
rename HS2 Product
save "Refined data\HS2 Codes.dta", replace


          ****************************************
     	  ********** Country Codes.dta ***********
     	  ****************************************
import delimited "Raw data\UNSD Country Classification.csv", clear //We want to have a dataset containing the official names of each country, as well as their belonging to specific categories of countries (e.g. LDCs)
keep subregionname isoalpha3code leastdevelopedcountriesldc landlockeddevelopingcountrieslld smallislanddevelopingstatessids
rename subregionname Region
egen byte region = group(Region)
rename isoalpha3code Code
gen byte LDC = (leastdevelopedcountriesldc == "x")
drop leastdevelopedcountriesldc
label variable LDC "Least Developed Countries"
gen byte LLD = (landlockeddevelopingcountrieslld == "x")
drop landlockeddevelopingcountrieslld
label variable LLD "Landlocked Developing Countries"
gen byte SIDS = (smallislanddevelopingstatessids == "x")
drop smallislanddevelopingstatessids
label variable SIDS "Small Islands Developing States"
save "Refined data\Country Codes.dta", replace

import delimited "Raw data\country_codes_V202401b.csv", clear
rename country_code m49
label variable m49 "UN M49 Country Code"
rename country_name Country
label variable Country "Country"
rename country_iso3 Code
label variable Code "ISO-3 Country Code"
drop country_iso2
** We drop duplicates in the ISO code variable that correspond to former countries **
drop if m49 == 58 /* Belgium-Luxembourg */
drop if m49 == 280 /* Former Federal Republic of Germany */
drop if m49 == 711 /* South African Customs Union */
drop if m49 == 736 /* Former Sudan (before 2012) */
drop if Code == "N/A"
** We rename a few countries for consistency and readibility purposes **
replace Country = "Bolivia" if m49 == 68
replace Country = "Bosnia and Herzegovina" if m49 == 70
replace Country = "Rep. of the Congo" if m49 == 178
replace Country = "Dem. Rep. of the Congo" if m49 == 180
replace Country = "Cote d'Ivoire" if m49 == 384
replace Country = "Lao PDR" if m49 == 418
replace Country = "St Kitts and Nevis" if m49 == 659
replace Country = "St Lucia" if m49 == 662
replace Country = "St Vincent and the Gr." if m49 == 670
replace Country = "Eswatini" if m49 == 748
replace Country = "North Macedonia" if m49 == 807
replace Country = "Tanzania" if m49 == 834
replace Country = "United States" if m49 == 842
merge 1:1 Code using "Refined data\Country Codes.dta"
keep if _merge == 3
drop _merge
save "Refined data\Country Codes.dta", replace


          ****************************************
	      *************** GDPPC.dta **************
	      **************************************** 
import delimited "Raw data\World_Development_Indicators_GDPPC.csv", varnames(1) numericcols(3) case(preserve) clear
drop SeriesCode
drop in 222
drop in 221
drop if CountryCode==""
rename CountryCode Code
recast str3 Code
rename YR2019 GDPPC
label variable GDPPC "GDP per capita in 2019 (in PPP US$)"
sort Code
save "Refined data\GDPPC.dta", replace


          ****************************************
	      ************* REM Index.dta ************
	      **************************************** 
import excel "Raw data\2024-retrospective-review-official.xlsx", firstrow sheet("EVI index scores") clear
keep if Reviewyear == 2019
keep Iso REMIndex
rename Iso Code
rename REMIndex REM
label variable REM "UNDESA Remoteness Index"
sort Code
save "Refined data\REM.dta", replace


          ****************************************
	      ********** Map Countries.dta ***********
	      ****************************************
clear all
shp2dta using "Raw data\world-administrative-boundaries\world-administrative-boundaries", database(Refined data\Map Countries) coordinates(Refined data\Map Coordinates) genid(id) replace
use "Refined data\Map Countries.dta", clear
drop if iso3 == ""
drop if id == 188
drop if iso3 == "PSE"
rename iso3 Code
save "Refined data\Map Countries.dta", replace  


     *********************************************************************************
     *********************************************************************************
	 **************                                                     **************
	 **************       CREATION OF THE FINAL COMPLETE DATABASE       **************
	 **************                                                     **************
	 *********************************************************************************
	 *********************************************************************************
	  
	      ********************************************************************************
          ****** We reformat and append all annual datasets into our core database *******
		  ********************************************************************************
	
	     *** Year 2012 ***
import delimited "Raw data\BACI_HS12_Y2012_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2012

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

save "Database.dta", replace


     *** Year 2013 ***
import delimited "Raw data\BACI_HS12_Y2013_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2013

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace


     *** Year 2014 ***
import delimited "Raw data\BACI_HS12_Y2014_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2014

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace


     *** Year 2015 ***
import delimited "Raw data\BACI_HS12_Y2015_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2015

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace


     *** Year 2016 ***
import delimited "Raw data\BACI_HS12_Y2016_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2016

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace


     *** Year 2017 *** 
import delimited "Raw data\BACI_HS12_Y2017_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2017

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace


     *** Year 2018 ***  
import delimited "Raw data\BACI_HS12_Y2018_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2018

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace


     *** Year 2019 ***
import delimited "Raw data\BACI_HS12_Y2019_V202401b.csv", clear
drop t
rename k HS6
rename v Ytot
rename q Qtot
destring Qtot, replace force float

merge n:1 HS6 using "Refined data\HS6 Codes.dta"
keep if _merge == 3
drop _merge

foreach x in 0 50 60 70 {
	gen Y`x' = Ytot * D`x'
	gen Q`x' = Qtot * D`x'
}

collapse (sum) Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70, by(i j Product)
foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	recast float `x', force
}
destring Product, replace

rename i m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Exporter
rename region reg_exporter

rename j m49
merge n:1 m49 using "Refined data\Country Codes.dta"
keep if _merge == 3
drop Country m49 Region LDC LLD SIDS _merge
rename Code Importer
rename region reg_importer

fillin Exporter Importer Product
drop if Exporter == Importer
gen int Year = 2019

foreach x in Ytot Y0 Y50 Y60 Y70 Qtot Q0 Q50 Q60 Q70 {
	replace `x' = 0 if `x' == .
}
drop _fillin

append using "Database.dta"
save "Database.dta", replace

/* We drop the following territories as they are not independent countries and/or might lack observations in the next datasets */
drop if (Exporter == "ABW" | Importer == "ABW") /* Aruba */
drop if (Exporter == "AIA" | Importer == "AIA") /* Anguilla */
drop if (Exporter == "ASM" | Importer == "ASM") /* American Samoa */
drop if (Exporter == "ATF" | Importer == "ATF") /* French Southern Antarctic Territory */
drop if (Exporter == "BES" | Importer == "BES") /* Bonaire */
drop if (Exporter == "BLM" | Importer == "BLM") /* Saint Barthelemy */
drop if (Exporter == "BMU" | Importer == "BMU") /* Bermuda */
drop if (Exporter == "CCK" | Importer == "CCK") /* Cocos Islands */
drop if (Exporter == "CUW" | Importer == "CUW") /* Curacao */
drop if (Exporter == "CXR" | Importer == "CXR") /* Christmas Islands */
drop if (Exporter == "CYM" | Importer == "CYM") /* Cayman Islands */
drop if (Exporter == "FLK" | Importer == "FLK") /* Falkland Islands */
drop if (Exporter == "GIB" | Importer == "GIB") /* Gibraltar */
drop if (Exporter == "GRL" | Importer == "GRL") /* Greenland */
drop if (Exporter == "GUM" | Importer == "GUM") /* Guam */
drop if (Exporter == "HKG" | Importer == "HKG") /* Hong Kong */
drop if (Exporter == "IOT" | Importer == "IOT") /* British Indian Ocean Territory */
drop if (Exporter == "MAC" | Importer == "MAC") /* Macao */
drop if (Exporter == "MNP" | Importer == "MNP") /* Northern Mariana Islands */
drop if (Exporter == "MSR" | Importer == "MSR") /* Montserrat */
drop if (Exporter == "MYT" | Importer == "MYT") /* Mayotte */
drop if (Exporter == "NCL" | Importer == "NCL") /* New Caledonia */
drop if (Exporter == "NFK" | Importer == "NFK") /* Norfolk Islands */
drop if (Exporter == "PCN" | Importer == "PCN") /* Pitcairn */
drop if (Exporter == "PRK" | Importer == "PRK") /* Democratic People's Republic of Korea  */
drop if (Exporter == "PSE" | Importer == "PSE") /* State of Palestine */
drop if (Exporter == "PYF" | Importer == "PYF") /* French Polynesia */
drop if (Exporter == "SHN" | Importer == "SHN") /* Saint Helena */
drop if (Exporter == "SPM" | Importer == "SPM") /* Saint Pierre and Miquelon */
drop if (Exporter == "SXM" | Importer == "SXM") /* Saint Maarten */
drop if (Exporter == "TCA" | Importer == "TCA") /* Turks and Caicos Islands */
drop if (Exporter == "TKL" | Importer == "TKL") /* Tokelau */
drop if (Exporter == "VGB" | Importer == "VGB") /* British Virgin Islands */
drop if (Exporter == "WLF" | Importer == "WLF") /* Wallis and Futuna Islands */

sort Exporter Importer Year Product


          ********************************************************************************
          ****** We include our structural gravity model variables (BACI Database) *******
		  ********************************************************************************
merge n:1 Exporter Importer Year using "Refined data\Gravity Variables.dta"
keep if _merge == 3
drop _merge


          **********************************************************************************
          ****** We include our measure of sea distance (CERDI-SeaDistance Database) *******
		  **********************************************************************************
merge n:1 Exporter Importer using "Refined data\Seadistance.dta"
keep if _merge == 3
drop _merge


          ********************************************************************************
          ****** We include the intra/inter trade ratios (TradeProd Database) ************
		  ********************************************************************************
/* For this, we need first to square our dataset as it currently does not include domestic trade flows */
fillin Year Exporter Importer Product
drop _fillin
gen byte Home = (Exporter == Importer)
label variable Home "=1 if Intranational flow"

/* We attribute a null distance and a value 1 for every gravity variable to any country with itself to avoid having missing observations in the sample
Remark: Attributing 0 or 1 to these gravity variables does not affect PPML estimations as they will be captured by the "Home" binary variable */
replace Seadistance = 0 if Home == 1 
replace Roaddistance = 0 if Home == 1
replace Airdistance = 0 if Home == 1
replace Border = 1 if Home == 1
replace Language = 1 if Home == 1
replace Colonization = 1 if Home == 1
replace Custom = 1 if Home == 1
replace FTA = 1 if Home == 1

/* We fill the missing observations for the regional variables */
egen byte region_exporter = max(reg_exporter), by(Exporter)
egen byte region_importer = max(reg_importer), by(Importer)
drop reg_exporter reg_importer

/* We attribute to each HS2-digits sector its industry classification in the TradeProd Database */
gen str9 Industry = ""
replace Industry = "Food" if Product < 25
replace Industry = "Chemicals" if (Product == 27 | Product == 28 | Product == 29 | Product == 30 | Product == 31 | Product == 32 | Product == 33 | Product == 34 | Product == 35 | Product == 37 | Product == 38 | Product == 39 | Product == 40)
replace Industry = "Machines" if (Product == 84 | Product == 85 | Product == 90 | Product == 91 | Product == 93)
replace Industry = "Metals" if (Product == 26 | Product == 71 | Product == 72 | Product == 73 | Product == 74 | Product == 75 | Product == 76 | Product == 78 | Product == 79 | Product == 80 | Product == 81 | Product == 82 | Product == 83)
replace Industry = "Minerals" if (Product == 25 | Product == 68 | Product == 69 | Product == 70)
replace Industry = "Other" if (Product == 36 | Product == 66 | Product == 67 | Product == 92 | Product == 94 | Product == 95 | Product == 96 | Product == 97)
replace Industry = "Textiles" if (Product == 41 | Product == 42 | Product == 43 | Product == 50 | Product == 51 | Product == 52 | Product == 53 | Product == 54 | Product == 55 | Product == 56 | Product == 57 | Product == 58 | Product == 59 | Product == 60 | Product == 61 | Product == 62 | Product == 63 | Product == 64 | Product == 65)
replace Industry = "Vehicles" if (Product == 86 | Product == 87 | Product == 88 | Product == 89)
replace Industry = "Wood" if (Product == 44 | Product == 45 | Product == 46 | Product == 47 | Product == 48 | Product == 49)

/* Now, we can merge the two datasets and drop the countries for which data are missing in TradeProd */
merge n:1 Year Exporter Industry using "Refined data\TradeProd Ratios.dta"
drop if _merge == 2
gen byte RoW = (_merge == 1) //We create a binary variable for the 34 countries not included in the TradeProd database which will be attributed the "Rest of the World" Ratio

egen mean_RoW = mean(RoW_Ratio), by(Industry Year)
replace Ratio = mean_RoW if RoW == 1
drop RoW_Ratio mean_RoW _merge

egen byte industry = group(Industry)
label variable RoW "=1 if Ratio was missing and Replaced by Rest of the World Ratio"
drop Industry

foreach x in Ytot Y0 Y50 Y60 Y70 {
	egen `x'_Sum = sum(`x'), by(Exporter Year Product)
	replace `x' = `x'_Sum * Ratio if Home == 1
	drop `x'_Sum
}
foreach x in Qtot Q0 Q50 Q60 Q70 {
	egen `x'_Sum = sum(`x'), by(Exporter Year Product)
	replace `x' = `x'_Sum * Ratio if Home == 1
	drop `x'_Sum
}
drop Ratio
		  

          ********************************************************************************
          ****** We include the price of Heavy Fuel Oil (INSEE Data) *********************
		  ********************************************************************************	  
merge n:1 Year using "Refined data\Fuel Price.dta"
keep if _merge == 3
drop _merge	  
  
		  
          ********************************************************************************
          ****** We create and update some other important variables *********************
		  ********************************************************************************	  
/* As we are only interested in Xij variables (and not Xi or Xj), we create the binary variables WTO and EU equal to 1 if both countries are WTO or EU members respectively */
egen WTO_O = mean(wto_o), by(Exporter Year)
egen WTO_D = mean(wto_d), by(Importer Year)
egen EU_O = mean(eu_o), by(Exporter Year)
egen EU_D = mean(eu_d), by(Importer Year)

gen byte WTO = (WTO_O == 1 & WTO_D == 1)
label variable WTO "=1 if Both Countries are WTO Members"
gen byte EU = (EU_O == 1 & EU_D == 1)
label variable EU "=1 if Both Countries are EU Members"
drop WTO_O WTO_D EU_O EU_D wto_o wto_d eu_o eu_d
sort Exporter Importer Product
order Year Exporter Importer Product

/* We redefine "Border" and "Seadistance" so that neighboring countries are defined as having a null maritime distance and reciprocally */
replace Border = 1 if Seadistance == 0
replace Seadistance = 0 if Border == 1

/* We generate our main variable of interest, defined as: Cost_ijt = ln(1 + HeavyFuelOilPrice_t * SeaDistance_ij) */
gen cost = ln(1 + (Seadistance * HFO))

/* We label the main variables */
label variable Year "Year"
label variable Exporter "Exporting Country"
label variable Importer "Importing Country"
label variable Product "Product (HS 2-Digit)"
label variable Ytot "Value of Total Flow (1000 USD)"
label variable Y0 "Value of Flow for Perishable and/or Intermediate Goods (1000 USD)"
label variable Y50 "Value of Flow for Goods Traded by Sea at the 50% Threshold (1000 USD)"
label variable Y60 "Value of Flow for Goods Traded by Sea at the 60% Threshold (1000 USD)"
label variable Y70 "Value of Flow for Goods Traded by Sea at the 70% Threshold (1000 USD)"
label variable Qtot "Volume of Total Flows (1000 USD)"
label variable Q0 "Volume of Flow for Perishable and/or Intermediate Goods (tons)"
label variable Q50 "Volume of Flow for Goods Traded by Sea at the 50% Threshold (tons)"
label variable Q60 "Volume of Flow for Goods Traded by Sea at the 60% Threshold (tons)"
label variable Q70 "Volume of Flow for Goods Traded by Sea at the 70% Threshold (tons)"

save "Refined data\Flows.dta", replace


          ********************************************************************************
          ****** We create the New Product Which Includes All Non-Maritime Flows *********
		  ********************************************************************************
/* We define non-maritime flows at the exporter-importer-year level */
foreach x in 0 50 60 70 {
	gen Yair = Ytot - Y`x'
	egen Sum_Yair = sum(Yair), by(Exporter Importer Year)
	gen Qair = Qtot - Q`x'
	egen Sum_Qair = sum(Qair), by(Exporter Importer Year)
	replace Y`x' = Sum_Yair if Product == 97
	replace Q`x' = Sum_Qair if Product == 97
	drop Yair Qair Sum_Yair Sum_Qair
}
drop Ytot Qtot 	 
replace Product = 99 if Product == 97 


          ********************************************************************************
          ****** We re-order and save our database ***************************************
		  ********************************************************************************
egen int exporter = group(Exporter)
egen int importer = group(Importer)
sort Exporter Importer Year Product 
order Exporter Importer Year Product Y0 Y50 Y60 Y70 cost Border Language Colonization Custom FTA EU WTO Home Q0 Q50 Q60 Q70
save "Database.dta", replace