/*
pub_gbd_data_prep.do
Merges PubMed publication data, Web of Science funding data, and IHME diseases
	burden data
*/

import delimited "Data/GBD/IHME-GBD_2019_DATA-bd6680ff-1.csv", varn(1) clear
drop measure_id location_id sex_id sex_name age_id age_name metric_id upper lower
split measure_name, p(" ") l(1)
ren measure_name1 measure
drop measure_name
keep if metric_name == "Number"

gen dis_abbr = "Cardio" if cause_name == "Cardiovascular diseases"
	replace dis_abbr = "ChronicResp" if cause_name == "Chronic respiratory diseases"
	replace dis_abbr = "Kidney" if cause_name == "Diabetes and kidney diseases"
	replace dis_abbr = "Digestive" if cause_name == "Digestive diseases"
	replace dis_abbr = "Enteritis" if cause_name == "Enteric infections"
	replace dis_abbr = "STIs" if cause_name == "HIV/AIDS and sexually transmitted infections"
	replace dis_abbr = "Pregnancy" if cause_name == "Maternal and neonatal disorders"
	replace dis_abbr = "Mental" if cause_name == "Mental disorders"
	replace dis_abbr = "Muscle" if cause_name == "Musculoskeletal disorders"
	replace dis_abbr = "Tropic" if cause_name == "Neglected tropical diseases and malaria"
	replace dis_abbr = "Neoplasms" if cause_name == "Neoplasms"
	replace dis_abbr = "Neurologic" if cause_name == "Neurological disorders"
	replace dis_abbr = "Nutrition" if cause_name == "Nutritional deficiencies"
	replace dis_abbr = "OthInfectious" if cause_name == "Other infectious diseases"
	replace dis_abbr = "RespInf" if cause_name == "Respiratory infections and tuberculosis"
	replace dis_abbr = "Senses" if cause_name == "Sense organ diseases"
	replace dis_abbr = "Skin" if cause_name == "Skin and subcutaneous diseases"
	replace dis_abbr = "Substance" if cause_name == "Substance use disorders"
	drop if dis_abbr == ""
	
gen loc_abbr = subinstr(location_name, " SDI", "", .)
	replace loc_abbr = subinstr(loc_abbr, "-", "", .)
	replace loc_abbr = "USA" if loc_abbr == "United States of America"
	
keep dis_abbr cause_name year measure val loc_abbr
reshape wide val, i(dis_abbr cause_name year measure) j(loc_abbr) string
	
gen decade = int(year/10)*10
collapse (mean) valHigh valHighmiddle valMiddle valLowmiddle valLow valUSA, ///
	by(dis_abbr cause_name decade measure)
	
tempfile gbd
save `gbd', replace


import delimited "Data/PubMed/raw/QA_pmids.csv", clear varn(1)
drop if pmid == "NA"
destring pmid, replace
tempfile qa
save `qa', replace

use "Data/PubMed/Diseases_pmids.dta", clear
merge m:1 pmid using `qa', keep(3) nogen
merge m:1 pmid using "Data/PubMed/BTC_pmids.dta", keep(1 3)
keep if inlist(btc, "translational", "clinical", "trial")
ren nih pm_nih
drop _merge
merge m:1 pmid using "Data/pmids_QA_wos_funding.dta", keep(1 3) gen(m_wos) ///
	keepus(no_funding_info nih gov foundation educ hosp corp compustat)
	
gen funding = "NIH" if nih == 1 | (pm_nih == 1 & btc == "trial" & nih == .)
	replace funding = "Corp" if (corp | compustat) ///
		& !nih & !gov & !foundation

gen ct = btc == "trial"
drop btc // TESTING
collapse (count) pubs = pmid, by(dis_abbr year funding ct)
drop if funding == ""
reshape wide pubs, i(dis_abbr year ct) j(funding) string
replace pubsCorp = 0 if pubsCorp == .
replace pubsNIH = 0 if pubsNIH == .
gen decade = int(year/10)*10
collapse (sum) pubsNIH pubsCorp, by(dis_abbr decade ct)

joinby dis_abbr decade using `gbd'
		
gen valGlobal = valHigh + valHighmiddle + valMiddle + valLowmiddle + valLow		

/*
foreach var of varlist val* {
    local grp = substr("`var'", 4, .)
	replace `var' = `var'/1000000
	lab var `var' "Disease burden in millions (`grp')"
}
*/