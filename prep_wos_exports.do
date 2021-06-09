/*
prep_wos_exports.do

Form PMIDs list for QA and NotQA random sample into strings of
	"PMID=(X OR Y OR ...)", of 500 PMIDs each to put into the query window in
	Web of Science
*/
clear all
pause on


local qa_prep 0
local notqa_prep 0
local qa_append 0
local notqa_append 0
local tab_funders 1

cd Data/PubMed

*-------------------------------------------------------------------------------
*First, QA list
if `qa_prep' == 1 {
*-------------------------------------------------------------------------------
import delimited "raw/QA_pmids.csv", clear varn(1)

gen group = int((_n-1)/500)
tostring pmid, replace
bys group: gen top = _n == 1

forval ii = 1/499 {
    replace pmid = pmid + " OR " + pmid[_n+`ii'] if top & group == group[_n+`ii']
}
gen peak = substr(pmid, -15, .) // to look at last pmid on the list and verify
								// it's the same as the 500th pmid in the group
*br
*pause
drop if !top
replace pmid = "PMID=(" + pmid
replace pmid = pmid + ")"
ren pmid query
drop top peak

export excel using "../WoS_Queries_QA.xlsx", replace
}
*-------------------------------------------------------------------------------
*Next, Not QA list
if `notqa_prep' == 1 {
*-------------------------------------------------------------------------------
import delimited pmid using "raw/PMIDs_master_2019.csv", clear rowr(2:)
tempfile pmids2019
save `pmids2019', replace

import delimited pmid using "raw/PMIDs_master_samp5pct.csv", clear rowr(2:)
* This file is a random 5% sample by year of journal articles in PubMed published
*	in any journal between 1980-2018
append using `pmids2019' // Adding a random 5% of journal articles published in 2019
duplicates drop
export delimited "raw/notQA_pmids.csv", replace

* We need to assemble query terms for the Web of Science database, of the form
*	"PMID=(XXXXX OR XXXXX OR ...)", to copy and paste into the advanced search field.
*	These lines transform the PMID list into this series of queries and saves it
gen group = int((_n-1)/500)
tostring pmid, replace
bys group: gen top = _n == 1

forval ii = 1/499 {
    replace pmid = pmid + " OR " + pmid[_n+`ii'] if top & group == group[_n+`ii']
}
gen peak = substr(pmid, -15, .) // to look at last pmid on the list and verify
								// it's the same as the 500th pmid in the group
*br
*pause
drop if !top
replace pmid = "PMID=(" + pmid
replace pmid = pmid + ")"
ren pmid query
drop top peak

export excel using "../WoS_Queries_notQA.xlsx", replace
}
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd ../WebOfScience
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*Append QA List
if `qa_append' == 1 {
*--------------------------------------------------------------------------------
local start 1
forval i=0/10 {
	local filelist`i': dir "QA`i'00" files "*.txt"
	foreach file of local filelist`i' {
		dis "QA`i'00/`file'"
		import delimited "QA`i'00/`file'", ///
			clear varn(1) bindquote(strict) maxquotedrows(unlimited)
		
		*https://images.webofknowledge.com/images/help/WOS/hs_wos_fieldtags.html
		keep pm c1 fu fx
			ren pm pmid
			ren c1 address
			ren fu funding_agency
			ren fx funding_text
			
		tostring pmid, replace
			drop if inlist(pmid, "NA", "")
			drop if substr(pmid, 1, 3) == "WOS"
		destring pmid, replace force
		drop if pmid == .
		tostring address funding_agency funding_text, replace
		
		if `start' {
			tempfile qa_exports
			save `qa_exports', replace
		}
		else {
			append using `qa_exports'
			save `qa_exports', replace
		}
		local start 0
	}
}

replace funding_text = "" if funding_text == "."
replace funding_agency = "" if funding_agency == "."
gen no_funding_info = funding_agency == "" & funding_text == ""

save "wos_funding_QA.dta", replace
}
*--------------------------------------------------------------------------------
*Append Not QA List
if `notqa_append' == 1 {
*--------------------------------------------------------------------------------
local start 1
forval i=0/24 {
	local filelist`i': dir "notQA`i'00" files "*.txt"
	foreach file of local filelist`i' {
		dis "notQA`i'00/`file'"
		import delimited "notQA`i'00/`file'", ///
			clear varn(1) bindquote(strict) maxquotedrows(unlimited)
		
		*https://images.webofknowledge.com/images/help/WOS/hs_wos_fieldtags.html
		keep pm c1 fu fx
			ren pm pmid
			ren c1 address
			ren fu funding_agency
			ren fx funding_text
			
		tostring pmid, replace
			drop if inlist(pmid, "NA", "")
			drop if substr(pmid, 1, 3) == "WOS"
		destring pmid, replace force
		drop if pmid == .
		tostring address funding_agency funding_text, replace
		
		if `start' {
			tempfile notqa_exports
			save `notqa_exports', replace
		}
		else {
			append using `notqa_exports'
			save `notqa_exports', replace
		}
		local start 0
	}
}

replace funding_text = "" if funding_text == "."
replace funding_agency = "" if funding_agency == "."
gen no_funding_info = funding_agency == "" & funding_text == ""

save "wos_funding_notQA.dta", replace
}
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*Look at Funders & Tag NIH, Private, etc.
if `tab_funders' == 1 {
*--------------------------------------------------------------------------------
foreach QA_not in "QA" "notQA" {
	use "wos_funding_`QA_not'.dta", clear

	gen nih = strpos(funding_agency, "National Institutes of Health") > 0 ///
				| strpos(funding_agency, "NIH") > 0

	#delimit ;		
	gen gov = strpos(funding_agency, "HHS") > 0
		| strpos(funding_agency, "United States Public Health Service") > 0
		| strpos(funding_agency, "USAID") > 0
		| strpos(funding_agency, "Office of Naval Research") > 0
		| strpos(funding_agency, "Naval Research Laboratory") > 0
		| strpos(funding_agency, "Air Force Office") > 0
		| strpos(funding_agency, "Army Research Office") > 0
		| strpos(funding_agency, "US Army") > 0
		| strpos(funding_agency, "United States Department") > 0
		| strpos(funding_agency, "US Department") > 0
		| strpos(funding_agency, "U.S. Department") > 0
		| strpos(funding_agency, "NOAA") > 0
		| strpos(funding_agency, "National Science Foundation") > 0
		| strpos(funding_agency, "National Cancer Institute") > 0
		| strpos(funding_agency, "National Institute") > 0
		| strpos(funding_agency, "NASA") > 0
		| strpos(funding_agency, "BLRD VA") > 0
		| strpos(funding_agency, "CSRD VA") > 0
		| strpos(funding_agency, "Food and Drug Administration") > 0
		/* Austria */
		| strpos(funding_agency, "Austrian Science Fund") > 0
		| strpos(funding_agency, "Austrian Federal Chancellery") > 0
		/* Australia */
		| strpos(funding_agency, "Australian Research Council") > 0
		| strpos(funding_agency, "Australian Reserch Council") > 0
		/* Belgium */
		| strpos(funding_agency, "FNRS") > 0
		/* Brazil */
		| strpos(funding_agency, "CNPq") > 0
		/* Canada */
		| strpos(funding_agency, "Alberta Innovates") > 0
		| strpos(funding_agency, "CANARIE") > 0
		| strpos(funding_agency, "Natural Sciences and Engineering Research Council of Canada") > 0
		/* China */
		| strpos(lower(funding_agency), "973 program") > 0
		| strpos(lower(funding_agency), "973 project") > 0
		| strpos(funding_agency, "Beijing Municipal Science and Technology Commission") > 0
		| strpos(funding_agency, "Beijing Scientific Commission") > 0
		| strpos(funding_agency, "China Scholarship Council") > 0
		| strpos(funding_agency, "Natural Science Foundation of China") > 0
		| strpos(funding_agency, "Shanghai Science and Technology Committee") > 0
		/* Denmark */
		| strpos(funding_agency, "Danish Cancer Society") > 0
		/* Germany */
		| strpos(funding_agency, "Alexander von Humboldt Foundation") > 0
		/* Israel */
		| strpos(funding_agency, "Israel Science Foundation") > 0
		/* Italy */
		| strpos(funding_agency, "Italian Space Agency") > 0
		| strpos(funding_agency, "Italian National Health Service") > 0
		| strpos(funding_agency, "Agenzia Italiana del Farmaco") > 0
		/* India */
		| strpos(funding_agency, "CSIR") > 0
		/* Japan */
		| strpos(funding_agency, "MEXT") > 0
		| (strpos(funding_agency, "MAFF") > 0 & strpos(funding_agency, "Japan") > 0)
		| strpos(funding_agency, "Japan Ministry") > 0
		/* Korea */
		| strpos(funding_agency, "Korea Science and Engineering Foundation") > 0
		| strpos(funding_agency, "Korea Ministry") > 0
		| (strpos(funding_agency, "KIST") > 0 & strpos(funding_agency, "Korea") > 0)
		/* Luxembourg */
		| strpos(funding_agency, "Luxembourg National Research Fund") > 0
		/* Netherlands */
		| (strpos(funding_agency, "NWO") > 0 & strpos(funding_agency, "Netherlands") > 0)
		| strpos(funding_agency, "Dutch Ministry") > 0
		/* Norway */
		| strpos(funding_agency, "Research Council of Norway") > 0
		/* Poland */
		| strpos(funding_agency, "Polish Science Foundation") > 0
		/* Portugal */
		| strpos(funding_agency, "Portugese Foundation for Science and Technology") > 0
		/* Singapore */
		| strpos(funding_agency, "A*STAR") > 0
		| strpos(funding_agency, "ASTAR") > 0
		| strpos(funding_agency, "A<SUP>star</SUP>STAR") > 0
		| strpos(funding_agency, "Singapore Ministry") > 0
		/* Spain */
		| strpos(funding_agency, "ICREA") > 0
		| strpos(funding_agency, "Spanish Government") > 0
		/* Sweden */
		| strpos(funding_agency, "Swedish Research Council") > 0
		/* Taiwan */
		| strpos(funding_agency, "Taiwan Ministry") > 0
		/* UK */
		| strpos(funding_agency, "Natural Environment Research Council") > 0
		| strpos(funding_agency, "Engineering and Physical Sciences Research Council") > 0
		| strpos(funding_agency, "National Institute for Health Research") > 0
		| strpos(funding_agency, "Science and Technology Facilities Council") > 0
		| strpos(funding_agency, "Economic and Social Research Council") > 0
		
		| strpos(funding_agency, "Centers for Disease Control") > 0
		| strpos(funding_agency, "European Commission") > 0
		| strpos(funding_agency, "European Union") > 0
		| strpos(funding_agency, "EMBO") > 0
		| strpos(funding_agency, "International Agency for Research on Cancer") > 0
		| strpos(funding_agency, "World Bank") > 0
		
		| strpos(funding_agency, "Ministry") > 0
		| strpos(lower(funding_agency), "government") > 0;

	gen foundation = strpos(funding_agency, "Alzheimer's Association") > 0
		| strpos(funding_agency, "American Epilepsy Society") > 0
		| strpos(funding_agency, "American Heart Association") > 0
		| strpos(funding_agency, "American Red Cross") > 0
		| strpos(funding_agency, "American Stroke Association") > 0
		| strpos(funding_agency, "Autism Science Foundation") > 0
		| strpos(funding_agency, "Autism Speaks") > 0
		| strpos(funding_agency, "Cancer Research Institute") > 0
		| strpos(funding_agency, "Curie") > 0
		| strpos(funding_agency, "Damon Runyon Cancer Research Foundation") > 0
		| strpos(funding_agency, "Donaghue Foundation") > 0
		| strpos(funding_agency, "Doris Duke Charitable Foundation") > 0
		| strpos(funding_agency, "Foundation Fighting Blindness") > 0
		| strpos(funding_agency, "Howard Hughes Medical Institute") > 0
		| strpos(funding_agency, "JDRF") > 0
		| strpos(funding_agency, "Leenaards") > 0
		| strpos(funding_agency, "LUNGevity Foundation") > 0
		| strpos(funding_agency, "Lymphoma Research Foundation") > 0
		| strpos(funding_agency, "National Psoriasis Foundation") > 0
		| strpos(funding_agency, "Pancreatic Cancer Action Network") > 0
		| strpos(funding_agency, "Parkinson’s Disease Foundation") > 0
		| strpos(funding_agency, "PCORI") > 0
		| strpos(funding_agency, "PEPFAR") > 0
		| strpos(funding_agency, "Susan G. Komen") > 0
		| strpos(funding_agency, "Thome Foundation") > 0
		| strpos(funding_agency, "Tuberous Sclerosis Alliance") > 0
		| strpos(funding_agency, "The V Foundation for Cancer Research") > 0
		| strpos(funding_agency, "Academy of Medical Sciences") > 0
		| strpos(funding_agency, "Action on Hearing Loss") > 0
		| strpos(funding_agency, "Alzheimer's Society") > 0
		| strpos(funding_agency, "Arthritis Research UK") > 0
		| strpos(funding_agency, "Austrian Science Research Fund") > 0
		| strpos(funding_agency, "Biotechnology and Biological Sciences Research Council") > 0
		| strpos(funding_agency, "Breast Cancer Now") > 0
		| strpos(funding_agency, "Bloodwise") > 0
		| strpos(funding_agency, "British Heart Foundation") > 0
		| strpos(funding_agency, "Canadian Institutes of Health Research") > 0
		| strpos(funding_agency, "Cancer Research UK") > 0
		| strpos(funding_agency, "Charles A. Dana Foundation") > 0
		| strpos(funding_agency, "Chief Scientist Office") > 0
		| strpos(funding_agency, "China Medical Board") > 0
		| strpos(funding_agency, "Department of Health") > 0
		| strpos(funding_agency, "Diabetes UK") > 0
		| strpos(funding_agency, "The Dunhill Medical Trust") > 0
		| strpos(funding_agency, "European Research Council") > 0
		| strpos(funding_agency, "Health Research Board") > 0
		| strpos(funding_agency, "Marie Curie") > 0
		| strpos(funding_agency, "Medical Research Council") > 0
		| strpos(funding_agency, "Motor Neurone Disease Association") > 0
		| strpos(funding_agency, "Multiple Sclerosis Society") > 0
		| strpos(funding_agency, "Myrovlytis Trust") > 0
		| strpos(funding_agency,
			"National Centre for the Replacement, Refinement and Reduction of Animals in Research") > 0
		| strpos(funding_agency, "Parkinson's UK") > 0
		| strpos(funding_agency, "Prostate Cancer UK") > 0
		| strpos(funding_agency, "Science Foundation Ireland") > 0
		| strpos(funding_agency, "Swiss National Science Foundation") > 0
		| strpos(funding_agency, "Telethon") > 0
		| strpos(funding_agency, "UNICEF") > 0
		| strpos(funding_agency, "Versus Arthritis") > 0
		| strpos(funding_agency, "Wellcome Trust") > 0
		| strpos(funding_agency, "Wellcome Trust-DBT India Alliance") > 0
		| strpos(funding_agency, "World Health Organization") > 0
		| strpos(funding_agency, "Worldwide Cancer Research") > 0
		| strpos(funding_agency, "Yorkshire Cancer Research") > 0;
		
		/* Added; not in PubMed Foundation List*/
		replace foundation = 1 if !foundation &
		  strpos(funding_agency, "AASLD") > 0
		| strpos(funding_agency, "ABFM Foundation") > 0
		| strpos(funding_agency, "AHRC") > 0
		| strpos(funding_agency, "AIRC") > 0
		| strpos(funding_agency, "American Asthma Foundation") > 0
		| strpos(funding_agency, "American Board of Internal Medicine") > 0
		| strpos(funding_agency, "American Cancer Society") > 0
		| strpos(funding_agency, "American Chemistry Council") > 0
		| strpos(funding_agency, "American Epilepsy Society") > 0
		| strpos(funding_agency, "American Society of Clinical Oncology") > 0
		| strpos(funding_agency, "American Society of Hematology") > 0
		| strpos(funding_agency, "American Thyroid Association") > 0
		| strpos(funding_agency, "AO Foundation") > 0
		| strpos(funding_agency, "Arthur Flaming Foundation") > 0
		| strpos(funding_agency, "Association Francaise Contre les Myopathies") > 0
		| strpos(funding_agency, "Avon Foundation") > 0
		| strpos(funding_agency, "Bloomberg Philanthropies") > 0
		| strpos(funding_agency, "Bernard Osher Foundation") > 0
		| strpos(funding_agency, "Canadian Cancer Society") > 0
		| strpos(funding_agency, "Canadian Diabetes Association") > 0
		| strpos(funding_agency, "Carlsberg Foundation") > 0
		| strpos(funding_agency, "CIFAR") > 0
		| strpos(funding_agency, "Diabetes Canada") > 0
		| strpos(funding_agency, "Dutch Cancer Society") > 0
		| strpos(funding_agency, "Gates Foundation") > 0
		| strpos(funding_agency, "Gates Malaria Partnership") > 0
		| strpos(funding_agency, "Human Frontier Science Program") > 0
		| strpos(funding_agency, "KNAW") > 0
		| strpos(funding_agency, "Leukemia and Lymphoma Society") > 0
		| strpos(funding_agency, "Ludwig Institute for Cancer Research") > 0
		| strpos(funding_agency, "Max Planck Society") > 0
		| strpos(funding_agency, "Moore Foundation") > 0
		| strpos(funding_agency, "PhRMA Foundation") > 0
		| strpos(funding_agency, "Robert Wood Johnson Foundation") > 0
		| strpos(funding_agency, "Sloan Foundation") > 0
		| strpos(funding_agency, "Terry Fox") > 0
		| strpos(funding_agency, "Wallenberg Foundation") > 0
		| strpos(funding_agency, "Welch Foundation") > 0
		
		| strpos(funding_agency, "Research Foundation") > 0
		| strpos(funding_agency, "Family Foundation") > 0;

	gen educ = strpos(funding_agency, "University") > 0
		| strpos(funding_agency, "School of") > 0
		
		| strpos(funding_agency, "Austrian Academy of Sciences") > 0
		| strpos(funding_agency, "Academia Sinica") > 0
		| strpos(funding_agency, "Academic Sinica") > 0
		| strpos(funding_agency, "CNRS") > 0
		| (strpos(funding_agency, "Academy") > 0 & !gov)
		| (strpos(funding_agency, "Institute") > 0 & !gov);
		
	gen hosp = (strpos(funding_agency, "Hospital") > 0
					& strpos(funding_agency, "Hospital Foundation") > 0)
		| strpos(funding_agency, "Hopitaux") > 0;
		
	gen corp = strpos(funding_agency, "Company") > 0
		| strpos(funding_agency, "Corporation") > 0
		| strpos(funding_agency, "Inc") > 0
		/* Public */
		| strpos(funding_agency, "Abbott Laboratories") > 0
		| strpos(funding_agency, "Alpharma") > 0
		| strpos(funding_agency, "Amgen") > 0
		| strpos(funding_agency, "AstraZeneca") > 0
		| strpos(funding_agency, "Astra Zeneca") > 0
		| strpos(funding_agency, "Bausch Lomb") > 0
		| strpos(funding_agency, "Baxter") > 0
		| strpos(funding_agency, "Bayer") > 0
		| strpos(funding_agency, "Bristol-Myers Squibb") > 0
		| strpos(funding_agency, "Caraco") > 0
		| strpos(funding_agency, "Eli Lilly") > 0
		| strpos(funding_agency, "Genzyme") > 0
		| strpos(funding_agency, "Gilead") > 0
		| strpos(funding_agency, "GlaxoSmithKline") > 0
		| strpos(funding_agency, "Medtronic") > 0
		| strpos(funding_agency, "Merck") > 0
		| strpos(funding_agency, "Novartis") > 0
		| strpos(funding_agency, "Novo Nordisk") > 0
		| strpos(funding_agency, "Pfizer") > 0
		| strpos(funding_agency, "Roche") > 0
		| strpos(funding_agency, "Theravance") > 0
		| strpos(funding_agency, "Valeant") > 0
		| strpos(funding_agency, "Wyeth") > 0;
		
		/*Private */
	replace corp = 1 if !corp &
		  strpos(funding_agency, "14M Genomics") > 0
		| strpos(funding_agency, "AAI") > 0
		| strpos(funding_agency, "Ablynx") > 0
		| strpos(funding_agency, "Accredo") > 0
		| strpos(funding_agency, "Acerta Pharma") > 0
		| strpos(funding_agency, "Acetylon Pharma") > 0
		| strpos(funding_agency, "Actavis") > 0
		| strpos(funding_agency, "Actelion") > 0
		| strpos(funding_agency, "Addrenex") > 0
		| strpos(funding_agency, "Adeona") > 0
		| strpos(funding_agency, "Afaxys") > 0
		| strpos(funding_agency, "Affymetrix") > 0
		| strpos(funding_agency, "Aimdyn") > 0
		| strpos(funding_agency, "Ajanta") > 0
		| strpos(funding_agency, "Akrimax") > 0
		| strpos(funding_agency, "Alcresta") > 0
		| strpos(funding_agency, "Alfacell") > 0
		| strpos(funding_agency, "Alfasigma") > 0
		| strpos(funding_agency, "Alimera") > 0
		| strpos(funding_agency, "ALK-Abello") > 0
		| strpos(funding_agency, "Allegiant") > 0
		| strpos(funding_agency, "Almatica") > 0
		| strpos(funding_agency, "Alvogen") > 0
		| strpos(funding_agency, "AM-Pharma") > 0
		| strpos(funding_agency, "American Regent") > 0
		| strpos(funding_agency, "Amerigen") > 0
		| strpos(funding_agency, "AMRI Global") > 0
		| strpos(funding_agency, "Amryt") > 0
		| strpos(funding_agency, "Antigenics") > 0
		| strpos(funding_agency, "Angelini") > 0
		| strpos(funding_agency, "Apobiologix") > 0
		| strpos(funding_agency, "Apotex") > 0
		| strpos(funding_agency, "Apple") > 0
		| strpos(funding_agency, "Apicore") > 0
		| strpos(funding_agency, "Apollo") > 0
		| strpos(funding_agency, "ApoPharma") > 0
		| strpos(funding_agency, "Apotex") > 0
		| strpos(funding_agency, "Apothecus") > 0
		| strpos(funding_agency, "Aprecia") > 0
		| strpos(funding_agency, "Aptiv Solutions") > 0
		| strpos(funding_agency, "Aqua Pharma") > 0
		| strpos(funding_agency, "Arbor Pharma") > 0
		| strpos(funding_agency, "ARCA") > 0
		| strpos(funding_agency, "Argentum") > 0
		| strpos(funding_agency, "Ark Therapeutics") > 0
		| strpos(funding_agency, "Armas") > 0
		| strpos(funding_agency, "Artesa") > 0
		| strpos(funding_agency, "Ascend") > 0
		| strpos(funding_agency, "Ascent") > 0
		| strpos(funding_agency, "Asegua") > 0
		| strpos(funding_agency, "Astellas") > 0
		| strpos(funding_agency, "Atritech") > 0
		| strpos(funding_agency, "Aucta Pharma") > 0
		| strpos(funding_agency, "Aurobindo") > 0
		| strpos(funding_agency, "Austar Pharma") > 0
		| strpos(funding_agency, "Autonomic Technologies") > 0
		| strpos(funding_agency, "Avidas") > 0
		| strpos(funding_agency, "Avion") > 0
		| strpos(funding_agency, "AXA Insurance") > 0
		| strpos(funding_agency, "AXON Neuroscience") > 0
		| strpos(funding_agency, "Axolotl Biologix") > 0
		| strpos(funding_agency, "Azurity") > 0;
		
	replace corp = 1 if !corp & 
		  strpos(funding_agency, "BASF") > 0
		| strpos(funding_agency, "Beach Pharma") > 0
		| strpos(funding_agency, "Bedford Lab") > 0
		| strpos(funding_agency, "Beiersdorf") > 0
		| strpos(funding_agency, "Beijing Biostar Technologies") > 0
		| strpos(funding_agency, "Belcher") > 0
		| strpos(funding_agency, "Bell Pharma") > 0
		| strpos(funding_agency, "Beloteca") > 0
		| strpos(funding_agency, "Betta Pharma") > 0
		| strpos(funding_agency, "Braun") > 0
		| strpos(funding_agency, "Biocodex") > 0
		| strpos(funding_agency, "Biofilm") > 0
		| strpos(funding_agency, "Bionpharma") > 0
		| strpos(funding_agency, "Biotest") > 0
		| strpos(funding_agency, "Biotronik") > 0
		| strpos(funding_agency, "Bioventus") > 0
		| strpos(funding_agency, "Biovista") > 0
		| strpos(funding_agency, "Birchwood Lab") > 0
		| strpos(funding_agency, "Blaine") > 0
		| strpos(funding_agency, "Blairex") > 0
		| strpos(funding_agency, "Boehringer Ingelheim") > 0
		| strpos(funding_agency, "Boiron") > 0
		| strpos(funding_agency, "Boston Oncology") > 0
		| strpos(funding_agency, "BPL") > 0
		| strpos(funding_agency, "Braeburn") > 0
		| strpos(funding_agency, "Braintree Lab") > 0
		| strpos(funding_agency, "Britannia Pharma") > 0
		| strpos(funding_agency, "Breckenridge") > 0
		| strpos(funding_agency, "BTG International") > 0
		| strpos(funding_agency, "Calpis") > 0
		| strpos(funding_agency, "CanSino Bio") > 0
		| strpos(funding_agency, "Cera") > 0
		| strpos(funding_agency, "Charles River Analytics") > 0
		| strpos(funding_agency, "Chiesi") > 0
		| strpos(funding_agency, "Chugai") > 0
		| strpos(funding_agency, "Cipla") > 0
		| strpos(funding_agency, "Circassia") > 0
		| strpos(funding_agency, "CMP Pharma") > 0
		| strpos(funding_agency, "Cogentus Pharma") > 0
		| strpos(funding_agency, "Combe") > 0
		| strpos(funding_agency, "Concert Pharma") > 0
		| strpos(funding_agency, "Concordia") > 0
		| strpos(funding_agency, "Consegna") > 0
		| strpos(funding_agency, "Coria") > 0
		| strpos(funding_agency, "Corthera") > 0
		| strpos(funding_agency, "Cosette") > 0
		| strpos(funding_agency, "CoStim") > 0
		| strpos(funding_agency, "Covis") > 0
		| strpos(funding_agency, "Cronus") > 0
		| strpos(funding_agency, "CSL Behring") > 0
		| strpos(funding_agency, "Currax") > 0
		| strpos(funding_agency, "Cutanea") > 0
		| strpos(funding_agency, "Cytyc") > 0
		| strpos(funding_agency, "Daiichi Sankyo") > 0
		| strpos(funding_agency, "Danco Lab") > 0
		| strpos(funding_agency, "DAVA") > 0
		| strpos(funding_agency, "Depomed") > 0
		| strpos(funding_agency, "Dey LP") > 0
		| strpos(funding_agency, "Digestive Care") > 0
		| strpos(funding_agency, "Dipharma") > 0
		| strpos(funding_agency, "Discovery Lab") > 0
		| strpos(funding_agency, "DOR BioPharma") > 0
		| strpos(funding_agency, "Duchesnay") > 0;
		
	replace corp = 1 if !corp & 
		  strpos(funding_agency, "Eckson") > 0
		| strpos(funding_agency, "Edenbridge") > 0
		| strpos(funding_agency, "Egalet") > 0
		| strpos(funding_agency, "Eisai") > 0
		| strpos(funding_agency, "Elorac") > 0
		| strpos(funding_agency, "Elusys") > 0
		| strpos(funding_agency, "EMD Serono") > 0
		| strpos(funding_agency, "Emmaus Life Science") > 0
		| strpos(funding_agency, "Encore Dermatology") > 0
		| strpos(funding_agency, "Entera") > 0
		| strpos(funding_agency, "Epic ") > 0
		| strpos(funding_agency, "Espero") > 0
		| strpos(funding_agency, "Ethex") > 0
		| strpos(funding_agency, "Ethicon") > 0
		| strpos(funding_agency, "Ethypharm") > 0
		| strpos(funding_agency, "EUSA Pharma") > 0
		| strpos(funding_agency, "Everidis") > 0
		| strpos(funding_agency, "Exela") > 0
		| strpos(funding_agency, "Exeltis") > 0
		| strpos(funding_agency, "Ezra") > 0
		| strpos(funding_agency, "Fabre-Kramer") > 0
		| strpos(funding_agency, "Female Health") > 0
		| strpos(funding_agency, "FemCap") > 0
		| strpos(funding_agency, "Ferndale Lab") > 0
		| strpos(funding_agency, "Ferring") > 0
		| strpos(funding_agency, "Fleet") > 0
		| strpos(funding_agency, "FOCUS") > 0
		| strpos(funding_agency, "Forest Pharma") > 0
		| strpos(funding_agency, "Fougera") > 0
		| strpos(funding_agency, "Freeline") > 0
		| strpos(funding_agency, "Galderma") > 0
		| strpos(funding_agency, "Galen") > 0
		| strpos(funding_agency, "Ganeden") > 0
		| strpos(funding_agency, "Gemini") > 0
		| strpos(funding_agency, "Genervon") > 0
		| strpos(funding_agency, "Gensco") > 0
		| strpos(funding_agency, "Greenstone") > 0
		| strpos(funding_agency, "Global Pharma") > 0
		| strpos(funding_agency, "Greenstone") > 0
		| strpos(funding_agency, "Greenwich Bio") > 0
		| strpos(funding_agency, "GTC") > 0
		| strpos(funding_agency, "H3") > 0
		| strpos(funding_agency, "Handa") > 0
		| strpos(funding_agency, "Harris Pharma") > 0
		| strpos(funding_agency, "Harvest Moon") > 0
		| strpos(funding_agency, "Health Pharma") > 0
		| strpos(funding_agency, "Helsinn") > 0
		| strpos(funding_agency, "Hemispherx") > 0
		| strpos(funding_agency, "Hercon") > 0
		| strpos(funding_agency, "Heritage") > 0
		| strpos(funding_agency, "Hikma") > 0
		| strpos(funding_agency, "Hill Dermaceuticals") > 0
		| strpos(funding_agency, "Hisun") > 0
		| strpos(funding_agency, "HLS ") > 0
		| strpos(funding_agency, "Hobart Lab") > 0
		| strpos(funding_agency, "Hope Pharma") > 0
		| strpos(funding_agency, "Horizon Pharma") > 0
		| strpos(funding_agency, "HRA ") > 0
		| strpos(funding_agency, "Iksuda") > 0
		| strpos(funding_agency, "Imprimis") > 0
		| strpos(funding_agency, "Imugen") > 0
		| strpos(funding_agency, "Iksuda") > 0
		| strpos(funding_agency, "Indivior") > 0
		| strpos(funding_agency, "Ingenus") > 0
		| strpos(funding_agency, "Innogenix") > 0
		| strpos(funding_agency, "Innovus") > 0
		| strpos(funding_agency, "International Vitamin") > 0
		| strpos(funding_agency, "Ipsen") > 0
		| strpos(funding_agency, "Iroko") > 0
		| strpos(funding_agency, "Isis") > 0
		| strpos(funding_agency, "ITF ") > 0
		| strpos(funding_agency, "IVP ") > 0;
		
	replace corp = 1 if !corp & 
		  strpos(funding_agency, "Janssen") > 0
		| strpos(funding_agency, "JHP ") > 0
		| strpos(funding_agency, "Jubilant Cadista") > 0
		| strpos(funding_agency, "Jubilant Hollister") > 0
		| strpos(funding_agency, "Juniper") > 0
		| strpos(funding_agency, "Kaleo") > 0
		| strpos(funding_agency, "Kedrion") > 0
		| strpos(funding_agency, "Klus") > 0
		| strpos(funding_agency, "Konsyl") > 0
		| strpos(funding_agency, "Kowa") > 0
		| strpos(funding_agency, "KVK Tech") > 0
		| strpos(funding_agency, "Kyowa") > 0
		| strpos(funding_agency, "Leadiant") > 0
		| strpos(funding_agency, "Leading Pharma") > 0
		| strpos(funding_agency, "LEO ") > 0
		| strpos(funding_agency, "Leucadia") > 0
		| strpos(funding_agency, "LGM ") > 0
		| strpos(funding_agency, "Luitpold") > 0
		| strpos(funding_agency, "Lundbeck") > 0
		| strpos(funding_agency, "Lupin") > 0
		| strpos(funding_agency, "Magna") > 0
		| strpos(funding_agency, "Major Pharma") > 0
		| strpos(funding_agency, "Mapp Bio") > 0
		| strpos(funding_agency, "Mayer") > 0
		| strpos(funding_agency, "Mayne Pharma") > 0
		| strpos(funding_agency, "McGuff Pharma") > 0
		| strpos(funding_agency, "Meda;") > 0
		| strpos(funding_agency, "Medac Pharma") > 0
		| strpos(funding_agency, "Medimetriks") > 0
		| strpos(funding_agency, "MediQuest") > 0
		| strpos(funding_agency, "Meitheal") > 0
		| strpos(funding_agency, "Methapharm") > 0
		| strpos(funding_agency, "Mission Pharmacal") > 0
		| strpos(funding_agency, "Mist Pharma") > 0
		| strpos(funding_agency, "Morphotek") > 0
		| strpos(funding_agency, "Morton Grove") > 0
		| strpos(funding_agency, "Myoderm") > 0
		| strpos(funding_agency, "Nagase") > 0
		| strpos(funding_agency, "Nalpropion") > 0
		| strpos(funding_agency, "NanoTech") > 0
		| strpos(funding_agency, "Napo Pharma") > 0
		| strpos(funding_agency, "Navigate BioPharma") > 0
		| strpos(funding_agency, "Navinta") > 0
		| strpos(funding_agency, "Nephroceuticals") > 0
		| strpos(funding_agency, "Nephron Pharma") > 0
		| strpos(funding_agency, "Nesher") > 0
		| strpos(funding_agency, "Neurolixis") > 0
		| strpos(funding_agency, "NexMed") > 0
		| strpos(funding_agency, "NextSource") > 0
		| strpos(funding_agency, "Nexus") > 0
		| strpos(funding_agency, "Noden") > 0
		| strpos(funding_agency, "Nomax") > 0
		| strpos(funding_agency, "Norwich Pharma") > 0
		| strpos(funding_agency, "Nostrum Pharma") > 0
		| strpos(funding_agency, "NovaBiotics") > 0
		| strpos(funding_agency, "Novitium") > 0
		| strpos(funding_agency, "NovoBiotic") > 0
		| strpos(funding_agency, "Nuvora") > 0
		| strpos(funding_agency, "Nymox") > 0
		| strpos(funding_agency, "Oakrum") > 0
		| strpos(funding_agency, "Octapharma") > 0
		| strpos(funding_agency, "ONY ") > 0
		| strpos(funding_agency, "Orexo") > 0
		| strpos(funding_agency, "Ortho Biotech") > 0
		| strpos(funding_agency, "Orth-McNeil") > 0
		| strpos(funding_agency, "Othera") > 0
		| strpos(funding_agency, "Otsuka America") > 0;
		
	replace corp = 1 if !corp & 
		  strpos(funding_agency, "Paddock") > 0
		| strpos(funding_agency, "Pain Therapeutics") > 0
		| strpos(funding_agency, "ParaPRO") > 0
		| strpos(funding_agency, "Partner Therapeutics") > 0
		| strpos(funding_agency, "PharmaDerm") > 0
		| strpos(funding_agency, "Pharmalucence") > 0
		| strpos(funding_agency, "Pharmics") > 0
		| strpos(funding_agency, "Photocure") > 0
		| strpos(funding_agency, "Pinnacle Bio") > 0
		| strpos(funding_agency, "PL Developments") > 0
		| strpos(funding_agency, "Plexxikon") > 0
		| strpos(funding_agency, "Poly Pharma") > 0
		| strpos(funding_agency, "Pozen") > 0
		| strpos(funding_agency, "Prasco Lab") > 0
		| strpos(funding_agency, "Primus Pharma") > 0
		| strpos(funding_agency, "Prinston Pharma") > 0
		| strpos(funding_agency, "Procter & Gamble") > 0
		| strpos(funding_agency, "Procter Gamble") > 0
		| strpos(funding_agency, "Profounda") > 0
		| strpos(funding_agency, "Prosetta") > 0
		| strpos(funding_agency, "PruGen") > 0
		| strpos(funding_agency, "Qualitest") > 0
		| strpos(funding_agency, "Quark") > 0
		| strpos(funding_agency, "Radius Health") > 0
		| strpos(funding_agency, "Ranbaxy") > 0
		| strpos(funding_agency, "Rare Disease Therapeutics") > 0
		| strpos(funding_agency, "RDD Pharma") > 0
		| strpos(funding_agency, "Recipharm") > 0
		| strpos(funding_agency, "Recordati Rare Diseases") > 0
		| strpos(funding_agency, "Retrotrope") > 0
		| strpos(funding_agency, "Rhodes Pharma") > 0
		| strpos(funding_agency, "Rising Pharma") > 0
		| strpos(funding_agency, "Romark Pharma") > 0
		| strpos(funding_agency, "Rowell Lab") > 0
		| strpos(funding_agency, "Roxane") > 0
		| strpos(funding_agency, "Roxro") > 0
		| strpos(funding_agency, "Rutherford Medical") > 0
		| strpos(funding_agency, "Sage Pharma") > 0
		| strpos(funding_agency, "Sandoz") > 0
		| strpos(funding_agency, "Saptalis") > 0
		| strpos(funding_agency, "SCA ") > 0
		| strpos(funding_agency, "Sciecure Pharma") > 0
		| strpos(funding_agency, "ScieGen") > 0
		| strpos(funding_agency, "Semma") > 0
		| strpos(funding_agency, "Sentynl") > 0
		| strpos(funding_agency, "Seqirus") > 0
		| strpos(funding_agency, "Seragon Pharma") > 0
		| strpos(funding_agency, "Servier") > 0
		| strpos(funding_agency, "Shionogi") > 0
		| strpos(funding_agency, "Silvergate Pharma") > 0
		| strpos(funding_agency, "Sirion") > 0
		| strpos(funding_agency, "Slayback") > 0
		| strpos(funding_agency, "Sobi ") > 0
		| strpos(funding_agency, "Solvay") > 0
		| strpos(funding_agency, "STI Pharma") > 0
		| strpos(funding_agency, "Summers Lab") > 0
		| strpos(funding_agency, "Sun Pharma") > 0
		| strpos(funding_agency, "SunGen Pharma") > 0
		| strpos(funding_agency, "Sunovion") > 0
		| strpos(funding_agency, "Supergen") > 0
		| strpos(funding_agency, "Symbiomix") > 0;
		
	replace corp = 1 if !corp & 
		  strpos(funding_agency, "Taiho Oncology") > 0
		| strpos(funding_agency, "Takeda") > 0
		| strpos(funding_agency, "Targanta") > 0
		| strpos(funding_agency, "Taro") > 0
		| strpos(funding_agency, "TerSera") > 0
		| strpos(funding_agency, "Three Rivers") > 0
		| strpos(funding_agency, "ThromboGenics") > 0
		| strpos(funding_agency, "Tolmar") > 0
		| strpos(funding_agency, "Torrent Pharma") > 0
		| strpos(funding_agency, "Trigen Lab") > 0
		| strpos(funding_agency, "Trigg Lab") > 0
		| strpos(funding_agency, "Tris Pharma") > 0
		| strpos(funding_agency, "UCB;") > 0
		| strpos(funding_agency, "Upsher-Smith") > 0
		| strpos(funding_agency, "URL") > 0
		| strpos(funding_agency, "Validus") > 0
		| strpos(funding_agency, "Veloxis") > 0
		| strpos(funding_agency, "Vensun") > 0
		| strpos(funding_agency, "VeroScience") > 0
		| strpos(funding_agency, "Verseon") > 0
		| strpos(funding_agency, "Vertex") > 0
		| strpos(funding_agency, "Vertical") > 0
		| strpos(funding_agency, "Vertice") > 0
		| strpos(funding_agency, "Vetter") > 0
		| strpos(funding_agency, "ViiV") > 0
		| strpos(funding_agency, "Virtus") > 0
		| strpos(funding_agency, "Watson Pharma") > 0
		| strpos(funding_agency, "WellSpring") > 0
		| strpos(funding_agency, "Wellstat") > 0
		| strpos(funding_agency, "West Pharma") > 0
		| strpos(funding_agency, "WG Critical Care") > 0
		| strpos(funding_agency, "Wilshire") > 0
		| strpos(funding_agency, "Windtree") > 0
		| strpos(funding_agency, "Wockhardt") > 0
		| strpos(funding_agency, "WraSer") > 0
		| strpos(funding_agency, "Xanodyne") > 0
		| strpos(funding_agency, "Xspire") > 0
		| strpos(funding_agency, "Zydus") > 0;
		
	#delimit cr

	preserve
		use conm sic using "../../../Compustat-CRSP_Merged_Annual.dta", clear
			duplicates drop
			ffind sic, newvar(ff48) type(48)
			keep if inlist(ff48, 11 /*Healthcare*/, 12 /*Medical Equipment*/, ///
									13 /*Pharmaceutical Products*/)
		sort conm
		stnd_specialchar conm
		foreach stub in " OLD" " CL A" " CL B" " LAB" " NV" " REDH" "" {
			replace conm = subinstr(conm, "`stub'", "", .)
		}
		stnd_compname conm, gen(stnd_conm)
		foreach stub in " INTL" " CP" " SVC" " HLDGS" " HLDG" " ENGR" " AG" " & CO" " IND" " AS" ///
						" LAB" " PHRMCUTCLS" " PHRMCUTCL" " PHRMCEUTCLS" " PHRMCEUTCL" ///
						" PHRMCEUTICLS" " PHRMCEUTICL" " ENT" " SYS" " HLD" " USA" " CO" {
			replace stnd_conm = subinstr(stnd_conm, "`stub'", "", .)
		}
		replace stnd_conm = subinstr(stnd_conm, " SA", "", .) ///
				if substr(stnd_conm, -3, .) == " SA"
		levelsof stnd_conm, local(compufirms)
	restore
	gen compustat = 0
	foreach firm of local compufirms {
		replace compustat = 1 if strpos(upper(funding_agency), upper("`firm'")) > 0
	}
		
	keep pmid nih gov foundation corp compustat educ hosp no_funding_info funding_agency funding_text
	duplicates drop
	duplicates tag pmid, gen(dup)
		drop if dup & no_funding_info
		drop dup
		duplicates tag pmid, gen(dup)
		egen tot_fund_cats = rowtotal(nih gov foundation corp compustat)
		bys pmid: egen max_info = max(tot_fund_cats)
		drop if dup & tot_fund_cats < max_info
		drop if dup & tot_fund_cats == max_info & funding_text == ""
		drop dup tot_fund_cats max_info
		duplicates drop pmid, force
	isid pmid
	save "../pmids_`QA_not'_wos_funding.dta", replace
}


	
}
cd ../../