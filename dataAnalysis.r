# Cast data to proper format
# Analyze that data

# load packages
library(data.table)
library(ggplot2)
library(xgboost)
library(caret)
library(reshape2)
library(dplyr)


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

# Create histogram of rank distribution
ratingDistData<- profileData[Rating>0]
ggplot(ratingDistData, aes(x=Rating)) + geom_histogram()
ggsave('.\\plots\\ratingDistribution.pdf')

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
