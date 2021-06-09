/*
figures_3-4.do
Scatter plots of corporate publications and NIH publications weighted by global
	disease burden, for diseases that disproportionately impact High and Low SDI
	countries
*/


gen hl_ratio = valHigh2010/valLow2010

local split = 0.75

*--- FIGURE 3 ---*
foreach xy in "Y" "X" {
	egen diagonal`xy' = max(pubsNIH2000) if !ct & hl_ratio >= `split'
	ereplace diagonal`xy' = max(diagonal`xy')
	replace diagonal`xy' = . if _n > 2
	replace diagonal`xy' = 0 if _n == 1
	egen diagonal`xy'ct = max(pubsCorp2010) if ct & hl_ratio >= `split'
	ereplace diagonal`xy'ct = max(diagonal`xy'ct)
	replace diagonal`xy'ct = . if _n > 2
	replace diagonal`xy'ct = 0 if _n == 1
}

// Panel A //
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if !ct & hl_ratio >= `split'
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if !ct ///
		& dis_abbr != "Neoplasms" & hl_ratio >= `split'
	local r_exNeo = r(C)[2,1]
	local r_exNeo = substr("`r_exNeo'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2000 if !ct & hl_ratio >= `split',
		mc(white) mlab(disease) mlabp(12) mlabc(black))
   (line diagonalY diagonalX, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2000 if !ct & hl_ratio >= `split' [w=valGlobal2000],
		msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2000-2009)") yti("Corporate-Funded (2010-2019)")
 ti("Publications About Diseases that Disproportionately"
	"Impact High SDI Countries or are SDI-Neutral")
 subti("r=`r'")
 note("Cutoff for Ratio of High SDI/Low SDI Disease Burden: `split'"
		"Correlation excluding Neoplasms: `r_exNeo'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig3a-pubs_corr_HighSDI_wGlobal.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

// Panel B //
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if ct & hl_ratio >= `split'
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if ct ///
		& dis_abbr != "Neoplasms" & hl_ratio >= `split'
	local r_exNeo = r(C)[2,1]
	local r_exNeo = substr("`r_exNeo'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2000 if ct & hl_ratio >= `split',
		mc(white) mlab(disease) mlabp(3) mlabc(black))
   (line diagonalYct diagonalXct, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2000 if ct & hl_ratio >= `split' [w=valGlobal2000],
		msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2000-2009)") yti("Corporate-Funded (2010-2019)")
 ti("Clinical Trials About Diseases that Disproportionately"
	"Impact High SDI Countries or are SDI-Neutral")
 subti("r=`r'")
 note("Cutoff for Ratio of High SDI/Low SDI Disease Burden: `split'"
		"Correlation excluding Neoplasms: `r_exNeo'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig3b-cts_corr_HighSDI_wGlobal.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

drop diagonal*	
		
		
*--- FIGURE 4 ---*
foreach xy in "Y" "X" {
	egen diagonal`xy' = max(pubsNIH2000) if !ct & hl_ratio < `split'
	ereplace diagonal`xy' = max(diagonal`xy')
	replace diagonal`xy' = . if _n > 2
	replace diagonal`xy' = 0 if _n == 1
	egen diagonal`xy'ct = max(pubsCorp2010) if ct & hl_ratio < `split'
	ereplace diagonal`xy'ct = max(diagonal`xy'ct)
	replace diagonal`xy'ct = . if _n > 2
	replace diagonal`xy'ct = 0 if _n == 1
}

// Panel A //
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if !ct & hl_ratio < `split'
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if !ct ///
		& dis_abbr != "Neoplasms" & hl_ratio < `split'
	local r_exNeo = r(C)[2,1]
	local r_exNeo = substr("`r_exNeo'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2000 if !ct & hl_ratio < `split',
		mc(white) mlab(disease) mlabp(12) mlabc(black))
   (line diagonalY diagonalX, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2000 if !ct & hl_ratio < `split' [w=valGlobal2000],
		msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2000-2009)") yti("Corporate-Funded (2010-2019)")
 ti("Publications About Diseases that"
	"Disproportionately Impact Low SDI Countries")
 subti("r=`r'")
 note("Cutoff for Ratio of High SDI/Low SDI Disease Burden: `split'"
		"Correlation excluding Neoplasms: `r_exNeo'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig4a-pubs_corr_LowSDI_wGlobal.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

// Panel B //
corr pubsCorp2010 pubsNIH2000 [w=valGlobal2000] if ct & hl_ratio < `split'
	local r = r(C)[2,1]
	local r = substr("`r'", 1, 4)

	
#delimit ;
tw (scatter pubsCorp2010 pubsNIH2000 if ct & hl_ratio < `split',
		mc(white) mlab(disease) mlabp(3) mlabc(black))
   (line diagonalYct diagonalXct, lp(_) lc(gs12))
   (scatter pubsCorp2010 pubsNIH2000 if ct & hl_ratio < `split' [w=valGlobal2000],
		msym("Oh") mc(black)),
 legend(off) xti("NIH-Funded (2000-2009)") yti("Corporate-Funded (2010-2019)")
 ti("Clinical Trials About Diseases that"
	"Disproportionately Impact Low SDI Countries")
 subti("r=`r'")
 note("Cutoff for Ratio of High SDI/Low SDI Disease Burden: `split'"
		"Circle size weighted by disease burden in the US (in DALYs)");
	
graph export "Output/fig4b-cts_corr_LowSDI_wGlobal.png", replace
		as(png) wid(1200) hei(700);
#delimit cr

drop diagonal*	
		