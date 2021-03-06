#testing Can you see this change
library(tidyverse)
library(ggplot2)
library(dplyr)
library(class)
library(caret)

# Get raw data
Beers <- read.csv("//DS1513/AllData/Adam/SMU Data Science Courses/DS 6306 Doing Data Science/Unit 8 and 9_ Case Study 1/Beers.csv")
Breweries <- read.csv("//DS1513/AllData/Adam/SMU Data Science Courses/DS 6306 Doing Data Science/Unit 8 and 9_ Case Study 1/Breweries.csv")

# look for missing, duplicative, invalid data

# Fix duplicate Breweries, Just assign all Beers to one of the duplicates
#Breweries %>% filter(Breweries$Name=="Summit Brewing Company")
Beers[Beers$Brewery_id == 139,]$Brewery_id <- 59

#Breweries %>% filter(Breweries$Name=="Sly Fox Brewing Company")
Beers[Beers$Brewery_id == 164,]$Brewery_id <- 372

# Remove duplicate brewery
Breweries <- Breweries[!(Breweries$Brew_ID == 139 | Breweries$Brew_ID == 164),]

UniqueBeers <- Beers %>% group_by(Name,Brewery_id) %>% summarize(minBeer_ID = min(Beer_ID)) %>% select(minBeer_ID)

Beers <- inner_join(Beers, UniqueBeers, by = c("Beer_ID" = "minBeer_ID")) %>%
  select(Name = Name.x, Beer_ID, ABV, IBU, Brewery_id, Style, Ounces)

# Breweries
head(Breweries)
dim(Breweries)
summary(Breweries)
sum(as.numeric(is.na(Breweries$Name)))
sum(as.numeric(is.na(Breweries$City)))
sum(as.numeric(is.na(Breweries$State)))

#### AQ 1 ####
BreweriesByState <- Breweries %>% select(State) %>% group_by(State) %>% count()
BreweriesByStateDesc <- BreweriesByState %>% arrange(desc(n))

#BreweriesByCity
BreweriesByCity <- Breweries %>% select(State,City) %>% group_by(State,City) %>% count()
BreweriesByCityDesc <- BreweriesByCity %>% arrange(desc(n))

# Merge data display head and tail
#### AQ 2 ####
BeerAndBrewery <- Breweries %>% inner_join(Beers, by = c("Brew_ID" = "Brewery_id"))
head(BeerAndBrewery, 6)
tail(BeerAndBrewery, 6)

# Examine Beer data
head(Beers)
dim(Beers)
summary(Beers)
# ABV is missing 62 values and IBU is missing 990 values after removing duplicates

#### AQ 3 & AQ 4 #### With just removing NA data from ABV and IBU
BeerAndBreweryByState <- BeerAndBrewery %>% 
  dplyr::group_by(State) %>% 
  dplyr::summarize(StateABV = mean(ABV, na.rm = TRUE), StateIBU = mean(IBU, na.rm = TRUE)) %>% 
  select(State, StateABV, StateIBU) 

# Get tables of Mean ABV and IBU by Style. Use those values to replace NA data
ABVByStyle <- Beers %>% 
  dplyr::group_by(Style) %>% 
  dplyr::summarize(ABVStyle = mean(ABV, na.rm = TRUE)) %>% 
  select(Style, ABVStyle) 

IBUByStyle <- Beers %>% 
  dplyr::group_by(Style) %>% 
  dplyr::summarize(IBUStyle = as.integer(round(mean(IBU, na.rm = TRUE), 0))) %>% 
  select(Style, IBUStyle) 

BeerAndBreweryImproved <- BeerAndBrewery %>% 
  inner_join(ABVByStyle, by = "Style") %>% 
  inner_join(IBUByStyle, by = "Style") %>% 
  mutate(ABV = coalesce(ABV, ABVStyle)) %>%
  mutate(IBU = coalesce(IBU, IBUStyle))

# After replacing NA with averages based on style no beers are left without ABV and only 51 lack an IBU rating
summary(BeerAndBreweryImproved)  

#### AQ 4 Improved #### 
BeerAndBreweryImprovedByState <- BeerAndBreweryImproved %>% 
  dplyr::group_by(State) %>% 
  dplyr::summarize(StateABVMean = mean(ABV, na.rm = TRUE), StateABVMedian = median(ABV, na.rm = TRUE), 
                   StateIBUMean = mean(IBU, na.rm = TRUE), StateIBUMedian = median(IBU, na.rm = TRUE),
                   StateBeerCount = n()) %>% 
  select(State, StateABVMean, StateABVMedian, StateIBUMean, StateIBUMedian, StateBeerCount) 

BeerAndBreweryImprovedByState$StateABVMeanPercent <- BeerAndBreweryImprovedByState$StateABVMean * 100.0
BeerAndBreweryImprovedByState$StateABVMedianPercent <- BeerAndBreweryImprovedByState$StateABVMedian * 100.0

#### AQ 4 chart  #### use box plots######

# more convienient to use this scale factor as now the same tick marks worl for both scales
#scaleFactor <- max(BeerAndBreweryImprovedByState$StateABVMedianPercent) / max(BeerAndBreweryImprovedByState$StateIBUMedian)

scaleFactor = 0.1

ggplot(data = BeerAndBreweryImprovedByState, aes(x=State,  width=.4)) +
  geom_col(aes(y=StateABVMedianPercent), fill="blue") +
  geom_col(aes(y=StateIBUMedian * scaleFactor), fill="red", position = position_nudge(x = -.4)) +
  scale_y_continuous(name="Medain percent ABV by State", sec.axis=sec_axis(~./scaleFactor, name="Median IBU by State")) +
  theme(
    axis.title.x.top=element_text(color="red"),
    axis.text.x.top=element_text(color="red"),
    axis.title.x.bottom=element_text(color="blue"),
    axis.text.x.bottom=element_text(color="blue")
  ) +
  coord_flip() +
  labs(title = "Food Security in Venezuela, Cereals Production and Food Gap", x = element_blank()) +
  scale_x_discrete(limits = rev(levels(BeerAndBreweryImprovedByState$State)))

#### AQ 5
# Max ABV
BeerAndBreweryImprovedByState[which.max(BeerAndBreweryImprovedByState$StateABVMedian),]

# Max IBU
BeerAndBreweryImprovedByState[which.max(BeerAndBreweryImprovedByState$StateIBUMedian),]

# or for single beer

BeerAndBreweryImproved[which.max(BeerAndBreweryImproved$ABV),] %>% select(State, Name.x, Name.y, ABV)
BeerAndBreweryImproved[which.max(BeerAndBreweryImproved$IBU),] %>% select(State, Name.x, Name.y, IBU)

# Get states with most and least median alcoholic beer offerings
BeerAndBreweryImprovedByState %>% arrange(desc(StateABVMedian)) %>% head(10)
BeerAndBreweryImprovedByState %>% arrange(StateABVMedian) %>% head(10)

# most states have a median ABV for beers brewed of between five and six percent. Two states fall bellow that range UT and NJ, 
# however NJ has only eight different flavors of beer being brewed in that state.
# Five states have a median ABV for beers brewed above six percent KY, DC, WV, NM, MI, however, DC and WV have less than 
# ten different flavors of beer brewed in them.

#### AQ 7 ####
ggplot(data = BeerAndBreweryImproved, mapping = aes(x = ABV * 100, y = IBU)) +
  geom_point(position = "dodge") + geom_smooth(se = FALSE) +
  xlim(2.5, 10) + xlab("Percent ABV") + ylab("IBU Rating")

#### AQ 8 ####
IsAleBool <- str_detect(BeerAndBreweryImproved$Name.y, regex("\\bAle\\b", ignore_case = TRUE)) & #Ale is a word
            str_detect(BeerAndBreweryImproved$Name.y, regex("\\bIPA\\b|India Pale Ale", ignore_case = TRUE), negate = TRUE) #But does not include IPA

IsIPABool <- str_detect(BeerAndBreweryImproved$Name.y, regex("\\bIPA\\b|India Pale Ale", ignore_case = TRUE))

BeerAndBreweryImproved$Classify <- "Other"
BeerAndBreweryImproved[IsAleBool,]$Classify <- "Ale"
BeerAndBreweryImproved[IsIPABool,]$Classify <- "IPA"

# now add it for Style
IsAleBool <- str_detect(BeerAndBreweryImproved$Style, regex("\\bAle\\b", ignore_case = TRUE)) & #Ale is a word
  str_detect(BeerAndBreweryImproved$Style, regex("\\bIPA\\b|India Pale Ale", ignore_case = TRUE), negate = TRUE) #But does not include IPA

IsIPABool <- str_detect(BeerAndBreweryImproved$Style, regex("\\bIPA\\b|India Pale Ale", ignore_case = TRUE))

BeerAndBreweryImproved[IsAleBool,]$Classify <- "Ale"
BeerAndBreweryImproved[IsIPABool,]$Classify <- "IPA"

# may need to explore using Style as well as Name NOT APPLICABLE
#scatter plot
ggplot(data = BeerAndBreweryImproved, mapping = aes(x = ABV * 100, y = IBU)) +
  geom_point(position = "dodge", mapping = aes(color = Classify)) + 
  geom_smooth(se = FALSE, mapping = aes(color = Classify)) +
  xlim(2.5, 10) + xlab("Percent ABV") + ylab("IBU Rating")

splitPerc = .7

# scale responses since we have 1 to 3 in one case and age is the other
#Remove the few that do not have IBU
BeerAndBreweryImproved <- BeerAndBreweryImproved %>% filter(!is.na(IBU))

BeerAndBreweryImproved$zABV = scale(BeerAndBreweryImproved$ABV)
BeerAndBreweryImproved$zIBU = scale(BeerAndBreweryImproved$IBU)
# measured against itself       
trainIndices = sample(1:dim(BeerAndBreweryImproved)[1],round(splitPerc * dim(BeerAndBreweryImproved)[1]))
BeerAndBreweryImprovedTrain = BeerAndBreweryImproved[trainIndices,]
BeerAndBreweryImprovedTest = BeerAndBreweryImproved[-trainIndices,]
BeerClassify <- knn(BeerAndBreweryImprovedTrain[,c('zABV','zIBU')], BeerAndBreweryImprovedTrain[,c('zABV','zIBU')], BeerAndBreweryImprovedTrain$Classify, k = 49, prob = TRUE)
table(BeerClassify,BeerAndBreweryImprovedTrain$Classify)
confusionMatrix(table(BeerClassify,BeerAndBreweryImprovedTrain$Classify))

summary(BeerAndBreweryImproved)

#Hyperparameter Tunning--------------------
BeerAndBreweryImproved2 = BeerAndBreweryImproved%>%
  filter(Classify != 'Other')

set.seed(1)
iterations = 500
numks = 60
splitPerc = .7

masterAcc = matrix(nrow = iterations, ncol = numks)

for(j in 1:iterations)
{
  trainIndices = sample(1:dim(BeerAndBreweryImproved2)[1],round(splitPerc * dim(BeerAndBreweryImproved2)[1]))
  train = BeerAndBreweryImproved2[trainIndices,]
  test = BeerAndBreweryImproved2[-trainIndices,]
  for(i in 1:numks)
  {
    classifications = knn(train[,c('zABV','zIBU')], test[,c('zABV','zIBU')], train$Classify, k = i)
    table(classifications,test$Classify)
    CM = confusionMatrix(table(classifications,test$Classify))
    masterAcc[j,i] = CM$overall[1]
  }
  
}

MeanAcc = colMeans(masterAcc)

plot(seq(1,numks,1),MeanAcc, type = "l", main = "Hyperparameter Optimization", xlab = "Number of k's", ylab = "Mean Accuracy")

which.max(MeanAcc)
max(MeanAcc)

#New Model using hyperparamter tunning
trainIndices = sample(1:dim(BeerAndBreweryImproved2)[1],round(splitPerc * dim(BeerAndBreweryImproved2)[1]))
BeerAndBreweryImprovedTrain2 = BeerAndBreweryImproved2[trainIndices,]
BeerAndBreweryImprovedTest2 = BeerAndBreweryImproved2[-trainIndices,]
<<<<<<< HEAD
BeerClassify <- knn(BeerAndBreweryImprovedTrain2[,c('zABV','zIBU')], BeerAndBreweryImprovedTest2[,c('zABV','zIBU')], BeerAndBreweryImprovedTrain2$Classify, k = 11, prob = TRUE)
=======
BeerClassify <- knn(BeerAndBreweryImprovedTrain2[,c('zABV','zIBU')], BeerAndBreweryImprovedTest2[,c('zABV','zIBU')], BeerAndBreweryImprovedTrain2$Classify, k = 26, prob = TRUE)
>>>>>>> f4c8331fc84d723d0e436019ca18bca1d2ac18bf
table(BeerClassify,BeerAndBreweryImprovedTest2$Classify)
confusionMatrix(table(BeerClassify,BeerAndBreweryImprovedTest2$Classify))





#Deep Dive----
skimr::skim(BeerAndBreweryImproved)
averageABV = BeerAndBreweryImproved %>% 
  group_by(State) %>% 
  summarize(ABV = mean(ABV), IBU = mean(IBU))

#CODE FOR HEAT MAP HERE
#Perform ANOVA by region for ABV and IBU here

west = BeerAndBreweryImproved %>% 
  filter(str_trim(State, side = c("both")) %in% c('WA','OR','CA','NV','ID','MT','WY','CO','NM','AZ','UT')) %>%
  mutate(region = 'W')

midwest = BeerAndBreweryImproved %>% 
  filter(str_trim(State, side = c("both")) %in% c('ND','SD', 'NE', 'KS','MN','IA','MO','WI','IL','IN','MI','OH')) %>%
  mutate(region = 'MW')

southwest = BeerAndBreweryImproved %>% 
  filter(str_trim(State, side = c("both")) %in% c('AZ','NM','OK','TX')) %>%
  mutate(region = 'SW')

southeast = BeerAndBreweryImproved %>% 
  filter(str_trim(State, side = c("both")) %in% c('AK','LA','MA','AL','TN','KY','GA','WV','VA','NC','SC','FL')) %>%
  mutate(region = 'SE')

northeast = BeerAndBreweryImproved %>% 
  filter(str_trim(State, side = c("both")) %in% c('ME','NH','VT','MA','CT','RI','NJ','NY','PA')) %>%
  mutate(region = 'NE')

pacific = BeerAndBreweryImproved %>% 
  filter(str_trim(State, side = c("both")) %in% c('AL','HI')) %>%
  mutate(region = 'PA')
USregions = rbind(west,midwest,southwest,southeast,northeast,pacific)
USregions$region = as.factor(USregions$region)

#ANOVA for IBU and ABV with Tukey HSD Post Hoc------------------------
library(ggpubr)
ggboxplot(USregions, x = "region", y = "ABV", 
          ylab = "ABV", xlab = "region")
abvModel = aov(ABV~region, data = USregions)
summary(lm(ABV~region, data = USregions))  
summary(abvModel)
abvTukey = TukeyHSD(abvModel)

abvpvals <- abvTukey$region[,4]
sort(abvpvals)


ggboxplot(USregions, x = "region", y = "IBU", 
          ylab = "IBU", xlab = "region")
IBUModel = aov(IBU~region, data = USregions)
summary(IBUModel)
TukeyHSD(IBUModel)

# Start my analysis of 9
# work with more styles "Lager","Pilsner","Stout","Porter","Weissbier","Bock","Cider","Bitter","Hefeweizen","Oktoberfest","Quad","Tripel","Witbier"

styles = c("Lager","Pilsner","Stout","Porter","Weissbier","Bock","Bitter","Hefeweizen","Oktoberfest","Tripel","Witbier")

for(i in 1:length(styles)){
  style = str_trim(styles[i], side = c("both"))
  styleRegex = paste("\\b", style, "\\b", sep="")
  IsStyleBoolName <- str_detect(BeerAndBreweryImproved$Name.y, regex(styleRegex, ignore_case = TRUE))
  IsStyleBoolStyle <- str_detect(BeerAndBreweryImproved$Style, regex(styleRegex, ignore_case = TRUE))
  BeerAndBreweryImproved[IsStyleBoolName|IsStyleBoolStyle,]$Classify <- style
}

#scatter plot
BeerAndBreweryImproved %>% filter(Classify != "Other" & Classify != "Ale" & Classify != "IPA") %>% 
ggplot(mapping = aes(x = ABV * 100, y = IBU))  + theme(legend.position = "none") +
  geom_point(position = "dodge", mapping = aes(color = Classify)) + facet_wrap(vars(Classify), ncol = 3) +
  ggtitle("IBU rating versus ABV percent by style") +
  xlim(2.5, 10) + xlab("Percent ABV") + ylab("IBU Rating")

=======
>>>>>>> f4c8331fc84d723d0e436019ca18bca1d2ac18bf

