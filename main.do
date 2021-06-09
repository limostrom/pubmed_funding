/*
main.do


*/
set scheme s1color
pause on


local wd: pwd
if substr("`wd'",10,8) == "lmostrom" {
	global repo "C:\Users\lmostrom\Documents\GitHub\pubmed_funding"
	global drop "C:\Users\lmostrom\Dropbox\pubmed_funding\"
}
if substr("`wd'",10,5) == "17036" {
	global repo "C:\Users\17036\OneDrive\Documents\GitHub\pubmed_funding"
	global drop "C:\Users\17036\Dropbox\pubmed_funding"
}

cd $drop

*=== Web Of Science Data ===*
/*--- (i) turns list of PMIDs into a set of queries to plug into WOS,
	  (ii) appends CSVs exported from WOS and saves as a Stata dataset
	  (iii) uses funding text from WOS to code funder ------------------------*/
*include $repo/prep_wos_exports.do

*=== Publication Data ===*
include $repo/pmids_append.do // appends list of PMIDs by disease area
include $repo/pub_gbd_data_prep.do // merges PubMed, WOS, and GBD data

*=== Figures ===*
include $repo/figures_1-2.do // scatter plots of publications weighted by disease burden
include $repo/figures_3-4.do // scatter plots split by GBD High SDI/Low SDI Ratio
