# Use battletags scraped from leaderboards to get stats from profiles

# Two list - name and value are css classes
# Variables - names
# Case - battletag followed by values


#empty nodes = skip
# Load Libraries
library(rvest)
library(data.table)

names <-c('Level','Rating','K/D','KDA','Win Pct','Kills/Game','Elim/Game','Damage/Game','Healing/Game',
            'Elim/Min','Healing/Min','Damage/Min','Solo Kills','Obj kills','Final Blows','Damage Done','Elims','Environment Kills','MultiKills','Deaths')
xpathValues<-c('/html/body/div[2]/div[1]/div[3]/div/div[2]/div[1]/div[2]/div/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[2]/div[2]/div/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[3]/div[2]/div[1]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[3]/div[2]/div[2]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[3]/div[2]/div[3]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[3]/div[2]/div[4]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[5]/div[2]/div[1]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[5]/div[2]/div[2]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[5]/div[2]/div[3]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[5]/div[2]/div[4]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[5]/div[2]/div[5]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[5]/div[2]/div[6]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[1]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[2]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[3]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[4]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[5]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[6]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[6]/div[2]/div[7]/div[2]',
                '/html/body/div[2]/div[1]/div[3]/div/div[2]/div[7]/div[2]/div[1]/div[2]')

# Function that reads profile, returns default value if no profile found
addProfile <- function(battletag, table, rowNum) {
    #url <- 'https://overwatchtracker.com/profile/pc/global/OGE-31607'
    url <- paste('https://overwatchtracker.com/profile/pc/global/',battletag,sep='')
    print(rowNum)
    print(paste('Visiting ', url, sep=' '))
    result <- tryCatch({
        download.file(url, destfile = "scrapedpage.html", quiet=TRUE)
        webpage <- read_html("scrapedpage.html")
        for(i in 1:length(xpathValues)){
            table[rowNum, names[i]] <- gsub('\\r|\\n','', webpage %>%
            html_nodes(xpath=xpathValues[i]) %>%
            html_text())
        }
    }, error = function(cond){
        table <- table[-rowNum]
        message(cond)
    }, warning = function(cond){
        table <- table[-rowNum]
        message(cond)
    })
    
    return(table)
    
}

profileData <- fread('battletags.csv')

profileData$Battletags <- gsub('#','-',profileData$Battletags)
end<-length(profileData$Battletags)
i<-1
while (i < end) {
    profileData<-addProfile(profileData[i,1], profileData, i)
    if(i%%1000==0) {
        print(str(profileData))
    }
    i<-i+9
}
profileData<-profileData[complete.cases(profileData),]
fwrite(profileData,'profileData.csv')