# Scrape player data from Overwtach
# https://overwatchtracker.com/leaderboards/pc/global
# Get battle tags from leaderboards then lookup profile data

# Import Overwatch tags into a list

library(rvest)
library(data.table)

# Read each page's table
readTable <- function(url) {
    table <- url %>%
        read_html() %>%
        html_nodes(xpath='/html/body/div[1]/div[1]/div[3]/div[2]/div[2]/div[3]/table') %>%
        html_table()
    table <- table[[1]]
    colnames(table) <- c('Rank', 'Battletag', 'Elo', 'Games')
    table$Battletag <- unlist(strsplit(table$Battletag,split="\\n"))
    table$Rank <-NULL
    table$Elo<-NULL
    table$Games<-NULL
    return(table)
}

url <- "https://overwatchtracker.com/leaderboards/pc/global"

# Read table on current page
tables <- list(readTable(url))
# Get an element
# To 1200
for (i in 2:10) {
    url<-'https://overwatchtracker.com/leaderboards/pc/global/CompetitiveRank?page='
    url<-paste(url,i, sep="")
    url<-paste(url,'&mode=1', sep="")
    print(paste('Visiting', url, sep=" "))
    tables[i] <- readTable(url)   
}

# Create a list of just names






# # Get an element
# # Click on element (onclick function)

# remDr$close()

# # Write results to text file so don't have to scrape again
# str(results)
# fileConn<-file("fortniteTableData.txt")
# writeLines(as.character(results), con=fileConn, sep="")
# close(fileConn)
