library(randomForest)
library(caret)
library(sperrorest)
library(reshape)

### Here we want to show how subsampling from two classes of a population
### can influence model performance

### Create a data set with two distinct classes
set.seed(1)
sample.size <- 100  # size of data set
ratio <- 0.1  # ratio of minority to majority class
n.maj <- (1-ratio) * sample.size
n.min <- ratio * sample.size

# Create majority data with two informative and one uninformative predictor
df.maj <- data.frame(Y=runif(n.maj, 0, 100))
df.maj$X1 <- 20 + df.maj$Y * 4 + rnorm(n.maj, 0, 60)
df.maj$X2 <- 60 + df.maj$Y *-2 + rnorm(n.maj, 0, 60)
df.maj$X3 <- runif(n.maj, 0, 100)
df.maj$class <- 'majority'

# Create the data for the minority class
df.min <- data.frame(Y=runif(n.min, 80, 100))
df.min$X1 <- 400 + df.min$Y * -3 + rnorm(n.min, 0, 15)
df.min$X2 <- -20 + df.min$Y * 1 + rnorm(n.min, 0, 15)
df.min$X3 <- runif(n.min, 80, 100)
df.min$class <- 'minority'

df <- rbind(df.maj, df.min)
ggplot(df, aes(X1, Y, color=class))+geom_point()
ggplot(df, aes(X2, Y, color=class))+geom_point()


# Prepare folds for cross validation
nfold=5
nrep=100
partitions <- partition_cv(df, nfold = nfold, repetition = nrep)

# Data frame to hold RMSE values
rmse <- data.frame(full=rep(NA, nfold * nrep), majority=rep(NA, nfold * nrep), minority=rep(NA, nfold * nrep), set='Original data')

# CV procedure
i <- 1
for(rep in 1:nrep){
  for(fold in 1:nfold){
    xtrain <- df[partitions[[rep]][[fold]]$train, 2:4]
    ytrain <- df[partitions[[rep]][[fold]]$train, 1]
    xtest <- df[partitions[[rep]][[fold]]$test, 2:4]
    ytest <- df[partitions[[rep]][[fold]]$test, 1]
    
    rf <- randomForest(xtrain, ytrain, mtry = 2)
    ypred <- predict(rf, xtest)
    predicted <- data.frame(ytest=ytest, ypred=ypred, class=df[partitions[[rep]][[fold]]$test, 5])
    rmse$full[i] <- RMSE(predicted$ytest, predicted$ypred)
    rmse$majority[i] <- RMSE(predicted$ytest[predicted$class=='majority'], predicted$ypred[predicted$class=='majority'])
    rmse$minority[i] <- RMSE(predicted$ytest[predicted$class=='minority'], predicted$ypred[predicted$class=='minority'])
    i <- i + 1
  }
}

# ratio of minority to majority samples
sample.ratio <- 0.3

rmse_resamp <- data.frame(full=rep(NA, nfold * nrep), majority=rep(NA, nfold * nrep), minority=rep(NA, nfold * nrep), set='Resampling')

i <- 1; rep <- 1; fold <- 1
for(rep in 1:nrep){
  for(fold in 1:nfold){
    n.maj.sample <- (1 - sample.ratio) * ((nfold-1) * sample.size / nfold)
    n.min.sample <- sample.ratio * ((nfold-1) * sample.size / nfold)
    
    train <- df[partitions[[rep]][[fold]]$train, ]
    train.maj <- train[train$class == 'majority', ][,-5]
    train.min <- train[train$class == 'minority', ][,-5]
    
    train.maj.sample <- train.maj[sample(1:nrow(train.maj), n.maj.sample), ]
    train.min.sample <- train.min[sample(1:nrow(train.min), n.min.sample, replace = T), ]
    
    train.df <- rbind(train.maj.sample, train.min.sample)
    
    xtrain <- train.df[, 2:4]
    ytrain <- train.df[, 1]
    
    xtest <- df[partitions[[rep]][[fold]]$test, 2:4]
    ytest <- df[partitions[[rep]][[fold]]$test, 1]
    
    rf <- randomForest(xtrain, ytrain, mtry = 2)
    ypred <- predict(rf, xtest)
    predicted <- data.frame(ytest=ytest, ypred=ypred, class=df[partitions[[rep]][[fold]]$test, 5])
    rmse_resamp$full[i] <- RMSE(predicted$ytest, predicted$ypred)
    rmse_resamp$majority[i] <- RMSE(predicted$ytest[predicted$class=='majority'], predicted$ypred[predicted$class=='majority'])
    rmse_resamp$minority[i] <- RMSE(predicted$ytest[predicted$class=='minority'], predicted$ypred[predicted$class=='minority'])
    i <- i + 1
  }
}

# as the sample ratio increases in favor of the minority class, the error of that class decreases
res <- rbind(rmse, rmse_resamp)
l.res <- melt(res, id='set')
ggplot(l.res, aes(variable, value, fill=set))+geom_boxplot()+labs(x='Data class', y='RMSE', fill='Data set')

colMeans(rmse, na.rm = T)
colMeans(rmse_resamp, na.rm = T)
