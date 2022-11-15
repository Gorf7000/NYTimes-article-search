#Sample NYTimes Article Search Script
#### Simplified httr-only version
library(httr)
library(jsonlite)
library(tidyverse)

##### INPUTS #####
##### Change this string to change your search term 
# Need to use + to string together separate words
searchstr <- "space"
searchyr <- 1880 #limit year to get < 1000 hits
yourAPIkey <- "" #goes here

setwd("C://Users//spark//OneDrive//Documents//Rwork") #change for local machine

NYT_Search_URL <- "https://api.nytimes.com/svc/search/v2/articlesearch.json"

page <- 0
hits <- 0
maxPages <- 0

while(page <= maxPages){
  basequery <- paste0(NYT_Search_URL,"?",
                  "q=",searchstr,"&",
                  "fq=pub_year:(",searchyr,")","&",
                  "facet_filter=","true","&",
                  "facet_fields=", "pub_month", "&",
                  "facet=true","&",
                  "api-key=",yourAPIkey)
  initialQuery <- fromJSON(paste0(basequery,"&page=",page))
  
  #start pasting results into df
  if(page == 0){ #if first time through, create pages list and check max hits / pages
    hits <- initialQuery$response$meta$hits
    pages_lst <- list()
    maxPages <- round((hits / 10)-1)
    #save the facet results
    facettbl <- initialQuery$response$facets[[1]][[1]]
    names(facettbl)[1] <- names(initialQuery$response$facets) #rename term to actual facet var name
    if(hits>1000){ #only need to check hits the 1st time through
      sprintf("Too many results, hits=%d", hits)
      break
    }
  } 
    
  #to debug skipping pages
  message("Retrieving page ", page)
    
  #saving everything to a list for later processing
  pages_lst[[page+1]]<- initialQuery$response$docs
  
  #increment page
  page <- page + 1
  
  #pause so we don't make NYTimes mad
  #API documentation says 10 requests per minute limit (4000 per day)
  Sys.sleep(6)
}

#save files for later

#unlist full results
pages_df <- rbind_pages(pages_lst)
pages_df <- pages_df %>% mutate(searchstr=searchstr, searchyr=searchyr)
#need to deal with multimedia and keywords lists at some point
pages_df %>% select(!where(is.list)) %>% 
write.table(paste0("NYTimes_",searchstr,"_",searchyr,".txt"), sep="\t")
