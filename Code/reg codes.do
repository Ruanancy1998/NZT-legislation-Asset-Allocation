clear all
set more off

cd "/Users/xyz/Library/CloudStorage/Dropbox/NZT legislation/Data/Stata"

global temp "/Users/xyz/Library/CloudStorage/Dropbox/NZT legislation/Data/Stata/Temp"
global use "/Users/xyz/Library/CloudStorage/Dropbox/NZT legislation/Data/Stata/use"
global out "/Users/xyz/Library/CloudStorage/Dropbox/NZT legislation/Data/Stata/out"
global raw "/Users/xyz/Library/CloudStorage/Dropbox/NZT legislation/Data/Stata/raw"


use "$use/firm_financials_nzt",clear
merge 1:m isin year using "$use/firm_asset_capex_2"
keep if _merge==3
drop _merge
save "$use/firm_assets",replace


use "$use/eps_2025_clean.dta",clear
merge m:1 iso3 using "$use/country_leg.dta"
drop name actor_type equity
destring end_target_year interim_target_year inventory_year interim_target_baseline_year,replace
drop _merge
rename year_eps year

merge 1:m iso year using "$use/firm_assets"
drop if _merge==1
drop if _merge==2
sort iso3 year

save "$use/all_data_raw.dta",replace

use "$use/all_data_raw.dta",clear
drop _merge
merge m:1 iso3 year using "$raw/macro.dta"
drop if _merge==2
drop _merge
bysort iso3 (year):carryforward gdpp p en_use ren_e e_use oilp,replace
save "$use/all_data_raw1.dta",replace


use "$use/all_data_raw1.dta",clear
bysort iso3 (year):gen post=1 if year>status_year | year==status_year
bysort iso3 (year):replace post=0 if year<status_year

gen t1=1 if end_target_status=="In law" & end_target_year<2051
replace t1=0 if t1==.
gen t2=1 if end_target_status=="In law" & end_target_year<2050
replace t2=0 if t2==.

gen t3=1 if end_target_status=="In law" & end_target_year<2051 & has_plan=="Yes" & reporting_mechanism=="Less than annual reporting" 
replace t3=0 if t3==.
*has plan is not relevant*
gen t4=1 if end_target_status=="In law" & removals_targets=="Yes"
replace t4=0 if t4==.

gen tp1=t1*post
gen tp2=t2*post
gen tp3=t3*post
gen tp4=t4*post

drop if year<2014

gen pre=1 if post==0
bysort iso3 (post):egen spre=sum(pre)
bysort iso3 (post):egen spost=sum(post)
drop if spost==0
drop if spre==0
drop if status_year==2024

gen lmv=log(mv)
gen lcapex=log(CompanyCapex_r)
gen lcapex_hl=log(capex_hl)
gen lcapex_low=log(capex_low)
gen le_use=log(e_use)
gen len_use=log(en_use)
gen lgdp=log(gdpp)
gen lren=log(ren_e)
gen lp=log(p)
gen tcapex=log(capex)
drop if FuelType=="Nuclear"

****summary statistics table 3 *****
replace nzt_all=. if lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace nzt_tar=. if lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace nzt_fin=. if lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace nzt_gov=. if lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace nzt_pol=. if lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.

replace low_carbon=. if nzt_all==.|lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace eps=. if nzt_all==.|lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|low_carbon==.|gdpp==.
replace gdpp=. if nzt_all==.|lmv==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|low_carbon==.
replace lcapex=. if nzt_all==.|lmv==.|profitm==.|lev==.|gdpp==.|low_carbon==.|eps==.|low_carbon==.

replace lmv=. if nzt_all==.|profitm==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace profitm=. if nzt_all==.|lmv==.|lev==.|lcapex==.|low_carbon==.|eps==.|gdpp==.
replace lev=. if nzt_all==.|lmv==.|profitm==.|lcapex==.|low_carbon==.|eps==.|gdpp==.

save "$use/all_data_raw2.dta",replace
****summary statistics table 3 *****
use "$use/all_data_raw2.dta",clear
tabstat CompanyCapex_reps by FuelType,stat(mean sum n)

tabstat CompanyCapex_r low_carbon eps en_use gdpp nzt_all nzt_tar nzt_fin nzt_pol nzt_gov mv profitm lev,by(t1) stat(mean sd n)  columns(statistics)
tabstat lcapex nzt_all nzt_tar nzt_fin nzt_pol nzt_gov low_carbon eps gdpp lmv profitm lev,by(t1) stat(mean sd n)  columns(statistics)
tabstat lcapex nzt_all nzt_tar nzt_fin nzt_pol nzt_gov low_carbon eps gdpp lmv profitm lev if t1==1,by(t2) stat(mean sd n)  columns(statistics)


****************************************************************************************************************************************************
*** baseline regression 1 effect on capital flow**

* Table 5 use log(companyCapex_r)
eststo clear
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T5", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*use absolute capex*
eststo clear
eststo:reghdfe CompanyCapex_r c.tp1#c.low_carbon tp1 low_carbon eps gdpp mv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r c.tp1#c.low_carbon tp1 low_carbon eps gdpp mv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r c.tp1#c.low_carbon tp1 low_carbon eps gdpp mv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe CompanyCapex_r c.tp2#c.low_carbon tp2 low_carbon eps gdpp mv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r c.tp2#c.low_carbon tp2 low_carbon eps gdpp mv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r c.tp2#c.low_carbon tp2 low_carbon eps gdpp mv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T5", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap


**************************************************************************************************************************************
***Table 6 regression for low_carbon projects

*use log(companyCapex_r)
eststo clear
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year isin) vce(cluster iso3)

eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year isin) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T6", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*Table 6 use log(companyCapex_r) and add specific policies
eststo clear
eststo:reghdfe lcapex tp1 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp1 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp1 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex tp2 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp2 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp2 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T6", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap



eststo clear

eststo:reghdfe lcapex tp1 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe lcapex tp2 ren_ts gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T5", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap


*use absolute capex*
eststo clear
eststo:reghdfe CompanyCapex_r tp1 eps gdpp mv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp1 eps gdpp mv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp1 eps gdpp mv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe CompanyCapex_r tp2 eps gdpp mv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp2 eps gdpp mv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp2 eps gdpp mv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T6", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

******************************************************************************************************************
***Table 6s regression only for solar and wind
*use absolute capex*
eststo clear
eststo:reghdfe CompanyCapex_r tp1 eps e_use gdpp mv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp1 eps e_use gdpp mv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp1 eps e_use gdpp mv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year isin) vce(cluster iso3)

eststo:reghdfe CompanyCapex_r tp2 eps e_use gdpp mv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp2 eps e_use gdpp mv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe CompanyCapex_r tp2 eps e_use gdpp mv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year isin) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T6s", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*use log(companyCapex_r)
eststo clear
eststo:reghdfe lcapex tp1 wind gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp1 wind gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp1 wind gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex tp2 wind gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp2 wind gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp2 wind gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T6s", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap


*******************************************************************************************************************************
**************************** Channels or mechanisms**
*******************************************************************************************************************************
* Table 8 and 9 baseline regression 2 effect on corporate NZT
use "$use/all_data_raw2.dta",clear
eststo clear

eststo:reghdfe nzt_all tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_tar tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_fin tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_pol tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_gov tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)

eststo:reghdfe nzt_all tp2 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_tar tp2 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_fin tp2 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_pol tp2 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_gov tp2 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T8_1", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap


eststo clear
eststo:reghdfe lcapex c.tp1#c.nzt_all nzt_all tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.nzt_tar nzt_tar tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.nzt_fin nzt_fin tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.nzt_pol nzt_pol tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.nzt_gov nzt_gov tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)

eststo:reghdfe lcapex c.tp2#c.nzt_all nzt_all tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.nzt_tar nzt_tar tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.nzt_fin nzt_fin tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.nzt_pol nzt_pol tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.nzt_gov nzt_gov tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T8_2", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*Table 10,
gen reporting_mechanism_d=1 if reporting_mechanism=="Less than annual reporting" 
replace reporting_mechanism_d=0 if reporting_mechanism_d==.
gen has_plan_d=1 if has_plan=="Yes"
replace has_plan_d=0 if has_plan_d==.
gen interim_tyd=1 if interim_target_year==2030
replace interim_tyd=0 if interim_tyd==.
gen tp2r=tp2*reporting_mechanism_d
gen tp2it=tp2*interim_tyd

eststo clear
eststo:reghdfe lcapex c.tp1#c.reporting_mechanism_d tp1 reporting_mechanism_d  eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3 FuelType) vce(cluster iso3)

eststo:reghdfe lcapex c.tp2#c.reporting_mechanism_d tp2 reporting_mechanism_d  eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3 FuelType) vce(cluster iso3)
esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T9", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap



reghdfe lcapex c.tp1#c.eps tp1  eps gdpp lmv profitm lev if low_carbon==1, absorb(year iso3 FuelType) vce(cluster iso3)
reghdfe lcapex c.tp1#c.eps tp1  eps gdpp lmv profitm lev, absorb(year iso3 FuelType) vce(cluster iso3)

*******************************************************************************************************************************
**************************************Endogeneity tests Table 7 **************************************************
*******************************************************************************************************************************
use "$use/all_data_raw1.dta",clear
bysort iso3 (year):gen post=1 if year>status_year | year==status_year
bysort iso3 (year):replace post=0 if year<status_year

gen t1=1 if end_target_status=="In law" & end_target_year<2051
replace t1=0 if t1==.
gen t2=1 if end_target_status=="In law" & end_target_year<2050
replace t2=0 if t2==.

gen t3=1 if end_target_status=="In law" & end_target_year<2051 & has_plan=="Yes" & reporting_mechanism=="Annual reporting" & memberships!="" & removals_targets=="Yes"
replace t3=0 if t3==.
gen t4=1 if end_target_status=="In law" & removals_targets=="Yes"
replace t4=0 if t4==.

drop if year<2014

gen pre=1 if post==0
bysort iso3 (post):egen spre=sum(pre)
bysort iso3 (post):egen spost=sum(post)
drop if spost==0
drop if spre==0
drop if status_year==2024

gen lmv=log(mv)
gen lcapex=log(CompanyCapex_r)
gen lcapex_hl=log(capex_hl)
gen lcapex_low=log(capex_low)
gen le_use=log(e_use)
gen len_use=log(en_use)
gen lgdp=log(gdpp)
gen lren=log(ren_e)
gen lp=log(p)
gen tcapex=log(capex)
drop if FuelType=="Nuclear"

*Table 7**
gen before2=1 if year-status_year==-2 | year-status_year==-1
replace before2=0 if before2==.
gen current=1 if year-status_year==0
replace current=0 if current==.
gen after1=1 if year-status_year==1
replace after1=0 if after1==.
gen after2=1 if year-status_year>1
replace after2=0 if after2==.

gen before2t=t2*before2
gen currentt=t2*current
gen after1t=t2*after1
gen after2t=t2*after2

gen before2t1=t1*before2
gen currentt1=t1*current
gen after1t1=t1*after1
gen after2t1=t1*after2

eststo clear
eststo:reghdfe lcapex before2t currentt after1t after2t eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe lcapex before2t1 currentt1 after1t1 after2t1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T7", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap



*******************************************************************************************************************************
**************************************Robustness tests**************************************************
*******************************************************************************************************************************
use "$use/all_data_raw2.dta",clear

* Table AI1  using different dependent variables, the absolute value of Capex and the number of projects**
eststo clear
eststo:reghdfe capex_hlc c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe capex_hlc c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)
esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA1_1", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

eststo clear
eststo:reghdfe capex_hlc c.tp1 tp1 low_carbon eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe capex_hlc c.tp2 tp2 low_carbon eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)
esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA1_2", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

******************************************************************************************************************
***Table IA 3 regression only for solar and wind
*use log(companyCapex_r)
eststo clear
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if FuelType=="SolarPV" | FuelType=="Solarthermal" | FuelType=="Onshorewind" | FuelType=="Offshorewind", absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA3", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

******************************************************************************************************************
* Table IA 4 :adding more variables and isin fixed effect


gen len_use=log(en_use)
gen lren_e=log(ren_e)
gen le_use=log(e_use)

*all sample*
eststo clear
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev le_use , absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev le_use oilp, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev le_use, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev le_use oilp , absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA4_1", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*low carbon*
eststo clear
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev len_use if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev len_use oilp if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev len_use if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev len_use oilp if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA4_2", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap


*******************************************************************************************************************************
*****Table IA 2: Two-year window test ****
use "$use/all_data_raw1.dta",clear
bysort iso3 (year):gen post=1 if year>status_year | year==status_year
bysort iso3 (year):replace post=0 if year<status_year

gen t1=1 if end_target_status=="In law" & end_target_year<2051
replace t1=0 if t1==.
gen t2=1 if end_target_status=="In law" & end_target_year<2050
replace t2=0 if t2==.
gen t3=1 if end_target_status=="In law" & end_target_year<2051 & has_plan=="Yes" & reporting_mechanism=="Annual reporting" & memberships!="" & removals_targets=="Yes"
replace t3=0 if t3==.

gen tp1=t1*post
gen tp2=t2*post
gen tp3=t3*post

drop if year<2014

gen pre=1 if post==0
bysort iso3 (post):egen spre=sum(pre)
bysort iso3 (post):egen spost=sum(post)
drop if spost==0
drop if spre==0

gen pre2024=1 if status_year==2024 & status_year-year>1
drop if pre2024==1
gen pre2022=1 if status_year==2022 & status_year-year>3
drop if pre2022==1
gen pre2021=1 if status_year==2021 & status_year-year>4
drop if pre2021==1
gen pre2020=1 if status_year==2020 & status_year-year>5
drop if pre2020==1
gen pre2019=1 if status_year==2019 & status_year-year>6
drop if pre2019==1

drop if status_year==2024
drop if FuelType=="Nuclear"

gen lmv=log(mv)
gen lcapex=log(CompanyCapex_r)
gen lcapex_hl=log(capex_hl)
gen lcapex_low=log(capex_low)
gen le_use=log(e_use)
gen len_use=log(en_use)
gen lgdp=log(gdpp)
gen lren=log(ren_e)
gen lp=log(p)
gen tcapex=log(capex)
*** baseline regression 1 effect on capital flow**
eststo clear
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA2_1", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

eststo clear
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp1 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lcapex tp2 eps gdpp lmv profitm lev if low_carbon==1, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "TIA2_2", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*********************************************************************************************************
****Impact on NZT disclosure: two-year window
eststo clear

eststo:reghdfe nzt_all tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_tar tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_fin tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_pol tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_gov tp1 eps gdpp lmv profitm lev, absorb(year iso3) vce(cluster iso3)

eststo:reghdfe nzt_all tp2 eps gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_tar tp2 eps gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_fin tp2 eps gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_pol tp2 eps gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_gov tp2 eps gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T10", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap

*
eststo clear

eststo:reghdfe nzt_all tp1 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_tar tp1 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_fin tp1 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_pol tp1 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_gov tp1 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)

eststo:reghdfe nzt_all tp2 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_tar tp2 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_fin tp2 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_pol tp2 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)
eststo:reghdfe nzt_gov tp2 eps le_use gdpp lmv profitm lev capexrate roe, absorb(year iso3) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T10", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap


































*********************************************************************************************************
*****Parallel Figure 

use "$use/all_data_raw1.dta",clear
bysort iso3 (year):gen post=1 if year>status_year | year==status_year
bysort iso3 (year):replace post=0 if year<status_year

gen t1=1 if end_target_status=="In law" & end_target_year<2051
replace t1=0 if t1==.
gen t2=1 if end_target_status=="In law" & end_target_year<2050
replace t2=0 if t2==.

gen t3=1 if end_target_status=="In law" & end_target_year<2051 & has_plan=="Yes" & reporting_mechanism=="Annual reporting" & memberships!="" & removals_targets=="Yes"
replace t3=0 if t3==.
gen t4=1 if end_target_status=="In law" & removals_targets=="Yes"
replace t4=0 if t4==.

gen tp1=t1*post
gen tp2=t2*post
gen tp3=t3*post
gen tp4=t4*post

drop if year<2014

gen pre=1 if post==0
bysort iso3 (post):egen spre=sum(pre)
bysort iso3 (post):egen spost=sum(post)
drop if spost==0
drop if spre==0
drop if status_year==2024

gen lmv=log(mv)
gen lcapex=log(CompanyCapex_r)
gen lcapex_hl=log(capex_hl)
gen lcapex_low=log(capex_low)
gen le_use=log(e_use)
gen len_use=log(en_use)
gen lgdp=log(gdpp)
gen lren=log(ren_e)
gen lp=log(p)
gen tcapex=log(capex)
drop if FuelType=="Nuclear"


bysort iso3 year: egen capex_y=sum(CompanyCapex_r)
bysort iso3 year: gen x=1 if year!=year[_n-1]
keep if x==1
drop x

bysort iso3 (year): gen year_r=1 if status_year-year==0
bysort iso3 (year): replace year_r=2 if status_year-year==-1
bysort iso3 (year): replace year_r=3 if status_year-year==-2
bysort iso3 (year): replace year_r=4 if status_year-year==-3

bysort iso3 (year): replace year_r=-1 if status_year-year==1
bysort iso3 (year): replace year_r=-2 if status_year-year==2
bysort iso3 (year): replace year_r=-3 if status_year-year==3
bysort iso3 (year): replace year_r=-4 if status_year-year==4


bysort t2 year_r: egen t_capex=mean(capex_y) if t2==1 
bysort t2 year_r: egen c_capex=mean(capex_y) if t2==0

bysort t2 year_r: gen x=1 if year_r!=year_r[_n-1]
keep if x==1
drop x


gen lt_capex=log(t_capex)
gen lc_capex=log(c_capex)

drop if year_r==5
drop if year_r==4
drop if year_r==-5
drop if year_r==-4

*Panel A: VaR mean comparison**
twoway line lt_capex lc_capex year_r , xlabel(-24(2)-1) ylabel(2(0.5)4.5) ytitle("VaR") xtitle("Event Time") lpattern(dash) legend(label(1 "Target") label(2 "Control"))




******************************************************************************************************************************************************
*******************************************************************************************************************************************************
**Firm level data analysis

use "$use/all_data_raw1.dta",clear

bysort iso3 isin FuelType year:egen fcapex=sum(CompanyCapex_r)
bysort iso3 isin FuelType  year:gen x=1 if isin==isin[_n-1]
drop if x==1
drop x

bysort iso3 (year):gen post=1 if year>status_year | year==status_year
bysort iso3 (year):replace post=0 if year<status_year

gen t1=1 if end_target_status=="In law" & end_target_year<2051
replace t1=0 if t1==.
gen t2=1 if end_target_status=="In law" & end_target_year<2050
replace t2=0 if t2==.

gen t3=1 if end_target_status=="In law" & end_target_year<2051 & has_plan=="Yes" & reporting_mechanism=="Annual reporting" & memberships!="" & removals_targets=="Yes"
replace t3=0 if t3==.
gen t4=1 if end_target_status=="In law" & removals_targets=="Yes"
replace t4=0 if t4==.

gen tp1=t1*post
gen tp2=t2*post
gen tp3=t3*post
gen tp4=t4*post

drop if year<2014
drop if status_year==2024

gen pre=1 if post==0
bysort iso3 (post):egen spre=sum(pre)
bysort iso3 (post):egen spost=sum(post)
drop if spost==0
drop if spre==0

gen lmv=log(mv)
gen lcapex=log(CompanyCapex_r)
gen lcapex_hl=log(capex_hl)
gen lcapex_low=log(capex_low)
gen le_use=log(e_use)
gen len_use=log(en_use)
gen lgdp=log(gdpp)
gen lren=log(ren_e)
gen lp=log(p)
gen tcapex=log(capex)
gen lfcapex=log(fcapex)
drop if FuelType=="Nuclear"

eststo clear
eststo:reghdfe lfcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lfcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lfcapex c.tp1#c.low_carbon tp1 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

eststo:reghdfe lfcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3) vce(cluster iso3)
eststo:reghdfe lfcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year) vce(cluster iso3)
eststo:reghdfe lfcapex c.tp2#c.low_carbon tp2 low_carbon eps gdpp lmv profitm lev, absorb(iso3 year FuelType) vce(cluster iso3)

esttab, b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  order()  label
esttab using  "T1", replace scsv b(3) t(2) ar2 star(* 0.1 ** 0.05 *** 0.01)  nogap






















