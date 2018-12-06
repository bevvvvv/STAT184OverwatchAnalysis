# Scrape player data from Overwtach
# https://overwatchtracker.com/leaderboards/pc/global
# Get battle tags from leaderboards then lookup profile data

# Import Overwatch tags into a list

library(rvest)
library(data.table)
library(gdata)

# Read each page's table
readTable <- function(url) {
    table <- url %>%
        read_html() %>%
        html_nodes(xpath='/html/body/div[1]/div[1]/div[3]/div[2]/div[2]/div[3]/table') %>%
        html_table()
    table <- table[[1]]
    colnames(table) <- c('Rank', 'Battletag', 'Elo', 'Games')
    table$Battletag<-trim(table$Battletag)
    table$pos <- regexpr('\\n', table$Battletag)
    table$Battletag<-substring(table$Battletag, 0,table$pos-1)
    table$pos <-NULL
    table$Rank <-NULL
    table$Elo<-NULL
    table$Games<-NULL
    return(table)
}

url <- "https://overwatchtracker.com/leaderboards/pc/global"

# See if reading proper html
html <- url %>% read_html() %>% html_nodes(xpath='/html/body/div[1]/div[1]/div[3]/div[2]/div[2]/div[3]/table')
fileConn<-file("elementHTML.txt")
writeLines(as.character(html), con=fileConn, sep="")
close(fileConn)

# Read table on current page
battletags <- readTable(url)[,1]
# Get an element
# To 950?
for (i in 2:950) {
    url<-'https://overwatchtracker.com/leaderboards/pc/global/CompetitiveRank?page='
    url<-paste(url,i, sep="")
    url<-paste(url,'&mode=1', sep="")
    print(paste('Visiting', url, sep=" "))
    table <- readTable(url)[,1]
    print(str(table))
    battletags <- append(battletags, table)
}

write.csv(battletags, 'battletags.csv', row.names=FALSE)
# Create a list of just names

# Two list - name and value are css classes
# Variables - names
# Case - battletag followed by values


#empty nodes = skip
