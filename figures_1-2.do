/*
figures_1-2.do
Scatter plots of all disease groups, corporate publications and NIH publications
	weighted by disease burden (US and Global)
*/


drop if decade < 2000 | dis_abbr == "Dementia"
keep if measure == "DALYs"

replace pubsNIH = 0 if pubsNIH == .
replace pubsCorp = 0 if pubsCorp == .

reshape wide pubs* val*, i(dis_abbr cause_name ct) j(decade)

gen disease = "Cardiovascular" if cause_name == "Cardiovascular diseases"
	replace disease = "Chronic Respiratory" if cause_name == "Chronic respiratory diseases"
	replace disease = "Digestive" if cause_name == "Digestive diseases"
	replace disease = "Diabetes & Kidney" if cause_name == "Diabetes and kidney diseases"
	replace disease = "Musculoskeletal" if cause_name == "Musculoskeletal disorders"
	replace disease = "Neurological" if cause_name == "Neurological disorders"
	replace disease = "Infectious Diseases" if cause_name == "Other infectious diseases"
	replace disease = "Maternal & Neonatal" if cause_name == "Maternal and neonatal disorders"
	replace disease = "Tuberculosis & Respiratory Infections" ///
				if cause_name == "Respiratory infections and tuberculosis"
	replace disease = "HIV/AIDS & STIs" ///
				if cause_name == "HIV/AIDS and sexually transmitted infections"
	replace disease = "Skin & Subcutaneous" if cause_name == "Skin and subcutaneous diseases"
	replace disease = "Substance Use" if cause_name == "Substance use disorders"
	replace disease = "Malaria & Tropical Diseases" ///
				if cause_name == "Neglected tropical diseases and malaria"
	replace disease = proper(cause_name) ///
		if inlist(cause_name, "Enteric infections", "Mental disorders", "Neoplasms", ///
				"Nutritional deficiencies", "Sense organ diseases")

*--- FIGURE 1 ---*
foreach xy in "Y" "X" {
	egen diagonal`xy' = max(pubsNIH2010)
	replace diagonal`xy' = . if _n > 2
	replace diagonal`xy' = 0 if _n == 1
}

corr pubsCorp2010 pubsNIH2010 [w=valUSA2010] if !ct
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)
corr pubsCorp2010 pubsNIH2010 [w=valUSA2010] if !ct & dis_abbr != "Neoplasms"
	local r_exNeo = r(C)[2,1]
	local r_exNeo = substr("`r_exNeo'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2010 if !ct, mc(white) mlab(disease) mlabp(12) mlabc(black))
   (line diagonalY diagonalX, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2010 if !ct [w=valUSA2010], msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2010-2019)") yti("Corporate-Funded (2010-2019)")
 ti("Publications in All Disease Groups" "Weighted by US Disease Burden")
 subti("r=`r'")
 note("Correlation excluding Neoplasms: `r_exNeo'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig1-pubs_corr_wUSA.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

drop diagonal?	

*--- FIGURE 2 ---*
foreach xy in "Y" "X" {
	egen diagonal`xy' = max(pubsNIH2010) if !ct
	ereplace diagonal`xy' = max(diagonal`xy')
	replace diagonal`xy' = . if _n > 2
	replace diagonal`xy' = 0 if _n == 1
	egen diagonal`xy'ct = max(pubsCorp2010) if ct
	ereplace diagonal`xy'ct = max(diagonal`xy'ct)
	replace diagonal`xy'ct = . if _n > 2
	replace diagonal`xy'ct = 0 if _n == 1
}

corr pubsCorp2010 pubsNIH2010 [w=valGlobal2010] if !ct
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)
corr pubsCorp2010 pubsNIH2010 [w=valGlobal2010] if !ct & dis_abbr != "Neoplasms"
	local r_exNeo = r(C)[2,1]
	local r_exNeo = substr("`r_exNeo'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2010 if !ct, mc(white) mlab(disease) mlabp(12) mlabc(black))
   (line diagonalY diagonalX, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2010 if !ct [w=valGlobal2010], msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2010-2019)") yti("Corporate-Funded (2010-2019)")
 ti("Publications in All Disease Groups" "Weighted by Global Disease Burden")
 subti("r=`r'")
 note("Correlation excluding Neoplasms: `r_exNeo'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig2a-pubs_corr_wGlobal.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

corr pubsCorp2010 pubsNIH2010 [w=valGlobal2010] if ct
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)
corr pubsCorp2010 pubsNIH2010 [w=valGlobal2010] if ct & dis_abbr != "Neoplasms"
	local r_exNeo = r(C)[2,1]
	local r_exNeo = substr("`r_exNeo'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2010 if ct, mc(white) mlab(disease) mlabp(3) mlabc(black))
   (line diagonalYct diagonalXct, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2010 if ct [w=valGlobal2010], msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2010-2019)") yti("Corporate-Funded (2010-2019)")
 ti("Clinical Trials in All Disease Groups" "Weighted by Global Disease Burden")
 subti("r=`r'")
 note("Correlation excluding Neoplasms: `r_exNeo'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig2b-cts_corr_wGlobal.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

drop diagonal*	
		