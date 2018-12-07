# Overwatch Player Data Analysis Project
# Stat 184 Final Project
# Author: Joseph Sepich
#####################################################################################################################################
# load options parser
library(optparse)
library(rvest)
library(gdata)
library(data.table)
library(ggplot2)
library(xgboost)
library(caret)
library(reshape2)
library(dplyr)
#####################################################################################################################################
# Install requirements
installReqs<-function(){
    cranRepo<-"http://cran.rstudio.com/"
    install.packages("optparse", repos=cranRepo)
    install.packages("rvest", repos=cranRepo)
    install.packages("gdata", repos=cranRepo)
    install.packages("ggplot2", repos=cranRepo)
    install.packages("xgboost", repos=cranRepo)
    install.packages("caret", repos=cranRepo)
    install.packages("reshape2", repos=cranRepo)
    install.packages("dplyr", repos=cranRepo)
    install.packages("data.table", repos=cranRepo)
}
#####################################################################################################################################
# Scrape Battletags
scrapeTags<-function(){
    # Scrape player data from Overwtach
    # https://overwatchtracker.com/leaderboards/pc/global
    # Get battle tags from leaderboards

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

}
#####################################################################################################################################
# Scrape player profiles
scrapeProfiles<-function(){
    # Use battletags scraped from leaderboards to get stats from profiles
    names <-c('Level','Rating','K/D','KDA','Win Pct','Kills/Game','Elim/Game','Damage/Game','Healing/Game',
                'Elim/Min','Healing/Min','Damage/Min','Solo Kills','Obj kills','Final Blows','Damage Done','Elims','Environment Kills','MultiKills','Deaths')
    # Path to each stat value
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

    # Function that reads profile
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

    # Read battletags in from leaderboards
    profileData <- fread('.\\data\\battletags.csv')

    # Change battletag character to use with url param
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
    # Get rid of profiles that do not exist or names were corrupted
    profileData<-profileData[complete.cases(profileData),]
    fwrite(profileData,'.\\data\\profileData.csv')
}
#####################################################################################################################################
# Anaylyze Scraped Data
dataAnalysis<-function(){
    # Cast column to numeric data type
    toNumeric <- function(column) {
        column <- gsub('\\n|\\r|\"|,|%','',column)
        column <- as.numeric(column)
    }

    profileData<-fread('.\\data\\profileData.csv')

    # Convert data, except battletags, to numeric values
    print('Converting profile data to numeric values')
    names<-names(profileData)
    for (i in 2:length(names)) {
        profileData[[names[i]]]<-toNumeric(profileData[[names[i]]])
    }

    # Sort by rank
    profileData<-data.table(profileData)
    setkey(profileData, Rating)

    # Number of games, in game time, 
    profileData$Games <- profileData$'Damage Done' / profileData$'Damage/Game'
    profileData$GameTimeMin<- profileData$'Damage Done' / profileData$'Damage/Min'
    # Add group name based off elo range
    ranks<-c('Bronze','Silver','Gold','Platinum','Diamond','Master','Grandmaster')
    
    profileData$Rank[profileData$Rating>0 & profileData$Rating<1000] <- ranks[1]
    profileData$Rank[profileData$Rating>=1000 & profileData$Rating<2000] <- ranks[2]
    profileData$Rank[profileData$Rating>=2000 & profileData$Rating<2500] <- ranks[3]
    profileData$Rank[profileData$Rating>=2500 & profileData$Rating<3000] <- ranks[4]
    profileData$Rank[profileData$Rating>=3000 & profileData$Rating<3500] <- ranks[5]
    profileData$Rank[profileData$Rating>=3500 & profileData$Rating<4000] <- ranks[6]
    profileData$Rank[profileData$Rating>=4000 & profileData$Rating<=5000] <- ranks[7]
    # Sort ranks in ascending order (written in vector ranks)
    profileData$Rank <- factor(profileData$Rank, levels = ranks)

    # Create histogram of rank distribution
    ratingDistData<- profileData[Rating>0]
    ggplot(ratingDistData, aes(x=Rating)) + geom_histogram()+ labs(title='Player Skill Distribution',x='Player SR (Skill Rating)',y='Number of players',caption='Distribution of Overwatch player ranks.\n Should be in the shape of a bell curve with common spikes at 3000 and 4000.')
    ggsave('.\\plots\\ratingDistribution.pdf')

    ggplot(ratingDistData, aes(y=GameTimeMin, fill=Rank)) + geom_boxplot() +labs(title='Play time by Rank',x='Player Rank',y='Play time in minutes',caption='This compares the play time of players to their rank. \nPlay time appears correlated to higher ranks.')
    ggsave('.\\plots\\gameTimeMin.pdf')

    # Silver Damage vs Masters Damage
    # Silvers<-ratingDistData[Rating>1000 & Rating<2000]
    # Masters<-ratingDistData[Rating>3500 & Rating<4000]
    # silverDamage<-ggplot(ratingDistData, aes(x='Damage/Min')) + geom_bar(aes(fill='Healing/Game'))
    # mastersDamage<-ggplot(ratingDistData, aes(x='Damage/Min')) + geom_histogram()


    # Create predicting tree
    # Build Testing data
    # Random sample indexes
    train_index <- sample(1:nrow(ratingDistData), 0.99 * nrow(ratingDistData))
    test_index <- setdiff(1:nrow(ratingDistData), train_index)

    # Build X_train, y_train, X_test, y_test
    X_train <- ratingDistData[train_index, -3]
    y_train <- ratingDistData[train_index, "Rating"]

    X_test <- ratingDistData[test_index, -3]
    y_test <- ratingDistData[test_index, "Rating"]

    print('Training prediction tree')
    # Train data
    for (i in 1:5) {
        xgb <- xgboost(data = data.matrix(X_train[,-1]),
            label = y_train$Rating, 
            eta = 0.5,
            max_depth = 5, 
            nround=80, 
            subsample = 0.5,
            colsample_bytree = 0.5,
            seed = 1,
            nthread = 3,
            verbose=0
        )

        # predict values in test set
        y_pred <- predict(xgb, data.matrix(X_test[,-1]))

        y_diff <- abs(y_pred - y_test$Rating)


        print(paste('Trial Number: ',i,sep=''))
        print(paste('Mean difference in prediction-value: ',mean(y_diff),sep=''))
    }

    X_train$Rating<-y_train
    X_test$Rating<-y_test
    predicts<-merge(y_pred,y_diff)

    write.csv(X_train,".\\data\\train.csv",row.names=F)
    write.csv(X_test,".\\data\\test.csv",row.names=F)
    fwrite(predicts,'.\\data\\predictions.csv',row.names=FALSE)

    print('Predicition infromation saved')
}
#####################################################################################################################################
# Options for running from cmd
option_list = list(
    make_option('--install', type='logical', default=FALSE, help='Install_Requirements', metavar="boolean"),
    make_option('--tags', type='logical', default=FALSE, help='Scrape_Battletags', metavar="boolean"),
    make_option('--pro', type='logical', default=FALSE, help='Scrape_Profiles:warning_long_process', metavar="boolean"),
    make_option('--a', type='logical', default=TRUE, help='Analyze_data', metavar="boolean")
)

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

reqs<-opt$install
btags<-opt$tags
profiles<-opt$pro
analyze<-opt$a

#####################################################################################################################################
######
#Main#
######

if(reqs == TRUE) {
    installReqs()
}


if(btags == TRUE) {
    scrapeTags()
}


if(profiles == TRUE) {
    scrapeProfiles()
}


if(analyze == TRUE) {
    dataAnalysis()
}

