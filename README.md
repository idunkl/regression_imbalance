## Class imbalance in regression

Resampling from an imbalanced data set is a well known procedure to improve the accuracy of the minority class in a data classification application. This script shows, how resampling from a mixed population can alter the performance of a regression model.

A data set is created in which the target variable `Y` is explained by two informative and one uninformative predictor. The population exists of two subgroups with different relationships between response and predictors.

![data](data.png)
Format: ![Alt Text](url)

Oversampling from the minority class can lead to a decreased RMSE in that class.

![boxplot](boxplot.png)
Format: ![Alt Text](url)
