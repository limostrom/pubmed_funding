#------------------------------------------
# Pull Article Metadata from PubMed:      |
#   (1) publication date                  |
#   (2) MeSH Terms                        |
#   (3) Journal                           |
#   (4) Author Affiliations               |
#   (5) Publication Types                 |
#   (6) Grant Codes*                      |
#         * no longer using - WOS better  |
#------------------------------------------

# Load package for web scraping & cleaning strings
#install.packages("stringr")
#install.packages("rvest")
#install.packages("tidyverse")

library(tidyverse)
library(rvest)
library(stringr)

setwd("C:/Users/lmostrom/Documents")

################################### FUNCTIONS ###################################
# Pull list of PMIDs to query for individually
pull_pmids = function(query){
  
  search = URLencode(query)
  
  i = 0
  # Form URL using the term
  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=5000&retstart=',
                i,
		            '&term=',
		            search,
                '&tool=my_tool&email=my_email@example.com'
  )

  # Query PubMed and save result
  xml = read_xml(url)
  
  # Store total number of papers so you know when to stop looping
  N = xml %>%
    xml_node('Count') %>%
    xml_double()
print(N)
  # Return list of article IDs to scrape later
  pmid_list = xml %>% 
    xml_node('IdList')
  pmid_list = str_extract_all(pmid_list,"\\(?[0-9]+\\)?")[[1]]
	
  Sys.sleep(0.3)

  i = 5000
  while (i < N) {
    # Form URL using the term
    url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=5000&retstart=',
                i,
                '&term=',
                search,
                '&tool=my_tool&email=my_email@example.com')

    # Query PubMed and save result
    xml = read_xml(url)

    new_ids = xml %>%
      xml_node('IdList')
    new_ids = str_extract_all(new_ids,"\\(?[0-9]+\\)?")[[1]]


    i = i + 5000

    pmid_list = append(pmid_list, new_ids)

    Sys.sleep(runif(1,0.6,1))
  }

  

  return(pmid_list)
  
}

#--------------------------------------------------------------------------------
# Pull Publication Date, Journal, Publication Type, Journal, MeSH Terms, and Grants
pull_affs = function(id) {
  id_equals = paste0('id=', id)
  if (id_equals != "id=NA") {
	# Form URL using the term
	  url = paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=',
				id,
			   '&retmode=xml')
	#, '&api_key=ae06e6619c472ede6b6d4ac4b5eadecdb209')
	  # Query PubMed and save result
	  xml = read_xml(url)

	print(id)

		gr = xml %>%
		  xml_node('GrantList')
		  gr = as.character(gr)
	 	  gr = gsub("\n", "", gr)

		pt = xml %>%
		  xml_node('PublicationTypeList')
		  pt = as.character(pt)
		  pt = gsub("\n", "", pt)

		journal = xml %>%
		  xml_node('Journal')
		  journal = as.character(journal)
		  journal = gsub("\n", "", journal)

		date = xml %>%
		  xml_node('DateCompleted')
		  date = as.character(date)
		  date = gsub("\n", "", date)

		mesh = xml %>%
		  xml_node('MeshHeadingList')
		  mesh = as.character(mesh)
		  mesh = gsub("\n", "", mesh)
	
		affil = xml %>%
	  	  xml_node('AffiliationInfo')
	  	  affil = as.character(affil)
		  affil = gsub("\n", "", affil)
	

	output = c(date, mesh, journal, affil, pt, gr)

  Sys.sleep(runif(1,0.5,0.7))
  }
  else {
	output = c("NA", "NA", "NA", "NA", "NA", "NA")
  }
  return(output)
}

################### PULL ARTICLE METADATA ###################################

### TOP 7 JOURNALS, ALL JOURNAL ARTICLES
queries_sub = read_tsv(file = 'GitHub/pubmed_funding/search_terms_QA.txt')

queries = paste0(queries_sub$Query, ' AND (1980/01/01[PDAT] : 2019/12/31[PDAT])')
query_names = queries_sub$Query_Name

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries, FUN = pull_pmids) %>%
	unname()
PMIDs = as.numeric(PMIDs)

info = sapply(X = PMIDs[1:1000], FUN = pull_affs)
master = data.frame(pmid = PMIDs[1:5000], date = info[1,], mesh = info[2,],
				journal=info[3,], affil=info[4,], pt = info[5,], gr = info[6,])

write_csv(master, path = '../Dropbox/Amitabh/PubMed/QA_Metadata/raw_1_5000.csv')
write_csv(master, path = '../Dropbox/pubmed_funding/Data/PubMed/raw/QA_1_5000.csv')
write_csv(master, path = '../Dropbox/pubmed_geography/Data/PubMed/raw/QA_1_5000.csv')
