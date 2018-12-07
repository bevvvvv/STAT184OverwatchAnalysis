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

# Install requirements
installReqs<-function(){
    return('Install')
}
# Scrape Battletags
scrapeTags<-function(){
    return('Scrape Tags')
}
# Scrape player profiles
scrapeProfiles<-function(){
    return('Scrape Profiles')
}
# Anaylyze Scraped Data
dataAnalysis<-function(){
    return('Analyze')
}

option_list = list(
    make_option('--install', type='logical', default=FALSE, help='Install_Requirements', metavar="boolean"),
    make_option('--tags', type='logical', default=FALSE, help='Scrape_Battletags', metavar="boolean"),
    make_option('--pro', type='logical', default=FALSE, help='Scrape_Profiles', metavar="boolean"),
    make_option('--a', type='logical', default=TRUE, help='Analyze_data', metavar="boolean")
)

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

reqs<-opt$install
btags<-opt$tags
profiles<-opt$pro
analyze<-opt$a

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

