### LOC Chronicallying America API

library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)

setwd("H:\\Private\\Ryan book\\LOC data")

baseurl <- "https://chroniclingamerica.loc.gov/search/pages/results/"

searchterms <- "comet"

rowsperpg <- 20
startyr <- 1850
endyr <- 1900

#searchyr <- 1850 #from testing

##multi-year loop
for(searchyr in startyr:endyr){
  #reset these every loop
  page <- 1
  maxPages <- 1
  hits <-0
  
  ### pages loop
  while(page <= maxPages) {
    query <- paste0(baseurl,
                    "?",
                    "dateFilterType=yearRange&date1=",searchyr,"&date2=",searchyr,
                    "&proxtext=",searchterms,"+",searchterms,"&proxdistance=100",
                    #"andtext=",searchterms,
                    "&rows=",rowsperpg,
                    "&searchType=advanced",
                    "&format=json",
                    "&page=",page)
    
    htmlresp <- GET(query) #send query to API and get returned html
    #View(content(htmlresp, "text")) #for debugging
    jsonresp <- fromJSON(content(htmlresp, "text")) #extract just the page content, format should be json
    
    #update maxpages
    if(page==1){
      hits <- jsonresp$totalItems #total hits from query
      maxPages <- round(hits / rowsperpg) #calculating last page - starts at 1 not 0
      pages_lst <- list() #empty list to concatenate results
    }
  
    #to debug skipping pages
    message(sprintf("For %s, Retrieving page %d of %d", searchyr, page, maxPages))
    
    #saving everything to a list for later processing
    pages_lst[[page]]<- jsonresp$items
    
    #increment page
    page <- page + 1
    
  }#end pages loop
  
    #once you have all the pages, try jsonlite rbind trick
    pages_df <- rbind_pages(pages_lst)
    
    #then clean up nested lists & write to file:
      ## this bit does the following
      ### line 1 - pastes list entries down into one string seperated by ||
      ### line 2 - removes line breaks from ocr text
      ### Line 3 - removes original ocr column from results
      ### Line 4 - saves file to hd
      pages_df %>% mutate(across(where(is.list), ~ sapply(.x, paste, collapse="||"))) %>% 
        mutate(text_clean = gsub("\n"," ", ocr_eng)) %>% 
        select(!starts_with("ocr")) %>%
        write.table(paste0("CHRONAM_",searchterms,"_",searchyr,".txt"), sep="\t", row.names=F, quote=F, qmethod="double")
} #end multi-year loop
