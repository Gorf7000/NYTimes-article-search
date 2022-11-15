#Sample NYTimes Article Search Script

#library(httr2)

#initialize the basic request - prob need to modify everything after the ?
#req <- request("https://api.nytimes.com/svc/search/v2/articlesearch.json") %>%
#        #add search terms & filters
#        req_headers(q = "space", #search string
#                    #pub_year = 2022, #filter on this year
#                    #facet_filter="true", #restrict facet results to filter range
#                    #facet_fields="pub_date", #return counts by day
#                    'api-key'=Sys.getenv("NYTIMES_KEY")) #mykey
                    
#test_response <- req %>% req_perform()

#teststr=paste0("https://api.nytimes.com/svc/search/v2/articlesearch.json","?",
#               "q=","space","&","api-key=",Sys.getenv("NYTIMES_KEY"))
#### httr2 didn't work for me - reverting to httr
library(httr)
library(jsonlite)
library(tidyverse)

##### Change this string to change your search term 
# Need to use + to string together separate words
searchstr <- "space"
searchyr <- 1880 #limit year to get < 1000 hits

setwd("C://Users//spark//OneDrive//Documents//Rwork")

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
                  "api-key=uY4GMg9yuDZUZDxq5xdhAhh5BGREoT8E")
  initialQuery <- fromJSON(paste0(basequery,"&page=",page))
  
  #for testing
  #facettbl <- initialQuery$response$facets[[1]][[1]]
  #url_lst <- initialQuery$response$docs$web_url
  
  #start pasting results into df
  if(page == 0){ #if first time through, create new df
    hits <- initialQuery$response$meta$hits
    result_df <- data.frame(index=c(1:hits), headline=c(""), url=c(""), pubdate=c(""))
    pages_lst <- list()
    maxPages <- round((hits / 10)-1)
    #save the facet results
    facettbl <- initialQuery$response$facets[[1]][[1]]
    names(facettbl)[1] <- names(initialQuery$response$facets) #rename term to actual facet var naem
    if(hits>1000){ #only need to check hits the 1st time through
      sprintf("Too many results, hits=%d", hits)
      break
    }
  } 
  
  
  #to debug skipping pages
  message("Retrieving page ", page)
  
  #page indexing - page = 0 returns results 1-10
  ## page=1 returns results 11-20
  ## page=10 returns results 101-110?
  ## see offset in metareults
  index <- initialQuery$response$meta$offset
  result_df[(index+1):(index+10),"headline"] <- initialQuery$response$docs$headline$main
  result_df[(index+1):(index+10),"url"] <- initialQuery$response$docs$web_url
  result_df[(index+1):(index+10),"pubdate"] <- initialQuery$response$docs$pub_date
  
  #also saving everything to a list for later processing
  pages_lst[[page+1]]<- initialQuery$response$docs
  
  #increment page
  page <- page + 1
  
  #pause so we don't make NYTimes mad
  #API documentation says 10 requests per minute limit (4000 per day)
  Sys.sleep(6)
}

#save files for later

#unlist full results - too easy, remove results_df stuff
pages_df <- rbind_pages(pages_lst)
pages_df <- pages_df %>% mutate(searchstr=searchstr, searchyr=searchyr)
#need to deal with multimedia and keywords lists at some point
pages_df %>% select(!where(is.list)) %>% 
write.table(paste0("NYTimes_",searchstr,"_",searchyr,".txt"), sep="\t")
