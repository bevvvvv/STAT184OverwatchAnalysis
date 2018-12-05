# Scrape player data from Overwtach
# https://overwatchtracker.com/leaderboards/pc/global
# Get battle tags from leaderboards then lookup profile data

# Import Overwatch tags into a list

library(rvest)
library(data.table)
library(XML)
# Required to load data in table loaded through JS
library(RSelenium)

#setwd("./")
system('java -Dwebdriver.chrome.driver=chromedriver.exe -jar selenium-server-standalone-3.9.0.jar', wait=FALSE)

Sys.sleep(1)

url <- "https://overwatchtracker.com/leaderboards/pc/global"
# adblockPath <- '.\\3.34.0_0'

# Driver
remDr <- remoteDriver(remoteServerAddr = "localhost"
                      , port = 4444
                      , browserName = "chrome"
                      )
remDr$open()
#remDr$getStatus()
# Go to Fortnite site
remDr$navigate(url)


# Wait
Sys.sleep(1)
results <- ''
tables <- list()
# Get an element
for (i in 2:1201) {
    Sys.sleep(0.3)
    
    # webElem<-remDr$findElement(using = "class", value = "card-table-material")
    # # Get data from table
    # results <- paste(results, webElem$getElementText(), sep = " ")
    
    # webElem <- remDr$findElement("xpath", "/html/body/div[1]/div[1]/div[3]/div[2]/div[2]/div[2]/a[3]")
    # webElem$clickElement()
    doc <- htmlParse(remDr$getPageSource()[[1]])
    tables[i-1] <- readHTMLTable(doc)
    Sys.sleep(0.5)

    url<-'https://overwatchtracker.com/leaderboards/pc/global/CompetitiveRank?page='
    url<-paste(c(url,i), sep="")
    url<-paste(c(url,'&mode=1'), sep="")
    remDr$navigate(url)
}





# Get an element
# Click on element (onclick function)

remDr$close()

# Write results to text file so don't have to scrape again
str(results)
fileConn<-file("fortniteTableData.txt")
writeLines(as.character(results), con=fileConn, sep="")
close(fileConn)
