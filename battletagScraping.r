# Scrape player data from Overwtach
# https://overwatchtracker.com/leaderboards/pc/global
# Get battle tags from leaderboards

# Load libaries used
library(rvest)
library(data.table)
library(gdata)

# Read each page's table for battletags
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

# Read table on current page
battletags <- readTable(url)[,1]
# To approximately 950th page
for (i in 2:950) {
    # Adjust url to next page
    url<-'https://overwatchtracker.com/leaderboards/pc/global/CompetitiveRank?page='
    url<-paste(url,i, sep="")
    url<-paste(url,'&mode=1', sep="")
    print(paste('Visiting', url, sep=" "))
    table <- readTable(url)[,1]
    if(i%%100==0) {
        print(str(table))
    }
    battletags <- append(battletags, table)
}
# Create a list of just names
write.csv(battletags, '.\\data\\battletags.csv', row.names=FALSE)
