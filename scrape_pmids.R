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
#install.packages("xml2")


library(tidyverse)
library(rvest)
library(stringr)
library(xml2)


#setwd("C:/Users/lmostrom/Documents")
setwd("C:/Users/17036/OneDrive/Documents")


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

################### PULL ARTICLE PMID LISTS ###################################

### TOP 7 JOURNALS, ALL JOURNAL ARTICLES ========================================
queries_sub = read_tsv(file = 'GitHub/pubmed_funding/search_terms_QA.txt')

queries = paste0(queries_sub$Query, ' AND (1980/01/01[PDAT] : 2019/12/31[PDAT])')
query_names = queries_sub$Query_Name

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries, FUN = pull_pmids) %>%
	unname()
PMIDs = as.numeric(PMIDs)
PMIDdf = data.frame(pmid=PMIDs)
write_csv(PMIDdf, path = '../../Dropbox/pubmed_funding/Data/PubMed/raw/QA_pmids.csv')


### BASIC, TRANSLATIONAL, AND CLINICAL SCIENCE JOURNAL ARTICLES, ALL JOURNALS ===
years = as.character(1980:2019)
year_queries = paste0('(', years, '/01/01[PDAT] : ', years, '/12/31[PDAT])')

queries_sub = read_tsv(file = 'GitHub/pubmed_funding/search_terms_BTC_notQA.txt')

queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

queries = paste0(year_queries, ' AND ', queries)
query_names = paste0(query_names, '_', years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries[521:560], FUN = pull_pmids) %>%
	unname()
for (i in 1:40) {
	j = i + 520
	outfile = paste0('../../Dropbox/pubmed_funding/Data/PubMed/raw/BTC/BTC_',
				query_names[j],
				'.csv')
	subset = data.frame(unlist(PMIDs[i]), rep(query_names[j], length(unlist(PMIDs[i]))))
	write_csv(subset, outfile)
}


### DISEASES (GBD LEVEL 2) JOURNAL ARTICLES, ALL JOURNALS =======================
years = as.character(1980:2019)
year_queries = paste0('(', years, '/01/01[PDAT] : ', years, '/12/31[PDAT])')

queries_sub = read_tsv(file = 'GitHub/pubmed_funding/search_terms_GBDlev2_notQA.txt')

queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

queries = paste0(year_queries, ' AND ', queries)
query_names = paste0(query_names, '_', years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries[1441:1520], FUN = pull_pmids) %>%
	unname()
for (i in 1:80) {
	j = i + 1440
	outfile = paste0('../../Dropbox/pubmed_funding/Data/PubMed/raw/Diseases/JA_',
				query_names[j],
				'.csv')
	subset = data.frame(unlist(PMIDs[i]), rep(query_names[j], length(unlist(PMIDs[i]))))
	write_csv(subset, outfile)
}


### DISEASES (GBD LEVEL 2) CLINICAL TRIALS, ALL JOURNALS ========================
years = as.character(1980:2019)
year_queries = paste0('(', years, '/01/01[PDAT] : ', years, '/12/31[PDAT])')

queries_sub = read_tsv(file = 'GitHub/pubmed_funding/search_terms_GBDlev2_CT_notQA.txt')

queries = rep(queries_sub$Query, each=length(year_queries))
query_names = rep(queries_sub$Query_Name, each=length(year_queries))

queries = paste0(year_queries, ' AND ', queries)
query_names = paste0(query_names, '_', years)

#Run through scraping function to pull out PMIDs
PMIDs = sapply(X = queries[1201:1520], FUN = pull_pmids) %>%
	unname()
for (i in 1:320) {
	j = i + 1200
	outfile = paste0('../../Dropbox/pubmed_funding/Data/PubMed/raw/Diseases/CT_',
				query_names[j],
				'.csv')
	subset = data.frame(unlist(PMIDs[i]), rep(query_names[j], length(unlist(PMIDs[i]))))
	write_csv(subset, outfile)
}


