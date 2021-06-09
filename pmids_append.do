/*
pmids_append.do

*/

cd Data/PubMed

local dis 0
local btc 0

*--- DISEASE PUBS ------------------------------------------------------------------
if `dis' == 1 {
	local filelist: dir "raw/Diseases" files "*.csv"

	local i = 1
	foreach file of local filelist {
		dis "`file'"
		import delimited pmid query_name using "raw/Diseases/`file'", rowr(2:) clear
		if _N > 0 {
			tostring pmid, replace
			drop if pmid == "NA"
			destring pmid, replace

			if `i' == 1 {
				tempfile full_pmids
				save `full_pmids', replace 
			}
			if `i' > 1 {
				append using `full_pmids'
				save `full_pmids', replace
			}
			local ++i
		}
	}

	use `full_pmids', clear

	split query_name, p("_")
	ren query_name1 dis_abbr
	gen nih = query_name2 == "NIH"
	ren query_name3 year
	destring year, replace
	drop query_name query_name2

	save Diseases_pmids.dta, replace // saving because takes ~7 hours to run
}

*--- BASIC, TRANSLATIONAL, AND CLINICAL SCIENCE PUBS ---------------------------
if `btc' == 1 {
	local filelist: dir "raw/BTC/" files "BTC_*.csv"

	local i = 1
	foreach file of local filelist {
		dis "`file'"
		import delimited pmid query_name using "raw/BTC/`file'", rowr(2:) clear
		if _N > 0 {
			tostring pmid, replace
			drop if pmid == "NA"
			destring pmid, replace

			if `i' == 1 {
				tempfile full_pmids
				save `full_pmids', replace 
			}
			if `i' > 1 {
				append using `full_pmids'
				save `full_pmids', replace
			}
			local ++i
		}
	}

	use `full_pmids', clear

	split query_name, p("_")
	ren query_name1 btc
	gen nih = query_name2 == "NIH"
	ren query_name3 year
	destring year, replace
	drop query_name query_name2

	replace pmid = pmid*10000 if inlist(btc, "total", "totalCTs")
	duplicates tag pmid, gen(dup)
	gen nothc = btc != "healthcare" if dup > 0
		bys pmid: egen tot_nothc = total(nothc)
		drop if dup & btc == "healthcare" & tot_nothc > 0
		drop dup
	duplicates tag pmid, gen(dup)
	gen clin = btc == "clinical" if dup > 0
		bys pmid: egen tot_clin = total(clin)
		drop if btc == "translational" & tot_clin > 0 & dup
		drop dup tot_clin clin tot_nothc nothc
	bys pmid btc: egen minyr = min(year)
		drop if year > minyr
	isid pmid
	replace pmid = pmid/10000 if inlist(btc, "total", "totalCTs")
	duplicates tag pmid, gen(dup)
	drop if dup & inlist(btc, "total", "totalCTs")
	replace btc = "other" if btc == "total"
	isid pmid
	drop dup minyr

	save "BTC_pmids.dta", replace
}

*===============================================================================

cd ../../
