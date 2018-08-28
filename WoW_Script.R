### Importing library
library(dplyr) ## Used for data.frame analysis
library(lubridate) ## Used for data/time manipulation
library(ggplot2)

### Importing Data
originalWoW <- read.csv("~/WoW Dataset/wowah_data.csv", header = TRUE, sep = ",")
originalDataWoW <- tbl_df(originalWoW)

### Converting from factor to time for $timestamp
originalDataWoW$timestamp <-mdy_hms(originalDataWoW$timestamp)

## First level 61
over60 <- filter(originalDataWoW, level > 60) ## Makes a subset of characters over lvl 60
over70 <- filter(originalDataWoW, level > 70) ## Makes a subset of characters over lvl 70
arrange(over70, timestamp) ## Ascending order from timestamp for the over70 dataframe

########### Checks to see which dates are missing from dataset #####################
## Changes format of date/time to only date (in string/char format), then changes it to date format
originalDataWoW$timestamp <- format(originalDataWoW$timestamp, '%m/%d/%Y' ) 
originalDataWoW$timestamp <- mdy(originalDataWoW$timestamp) 
datesWoW <- distinct(originalDataWoW, timestamp) ## Find the unique dates

dayToBeChecked <- as.Date(datesWoW$timestamp) 
dayCheck <- seq(as.Date("2008-01-01"), as.Date("2008-12-31"), by = "days") ## Creates an array of days from two points

## Checks to see which dates are missing in distinct($timestamp) 
for(datez in dayCheck){
  if((datez %in% dayToBeChecked) == FALSE){
    class(datez) <- class(dayCheck)
    missingDays2 <- c(missingDays2, datez) ## Appending to vector is slow (only do for small sets)
  }
}

################ Find average entries per char ####################
allCharacters <- distinct(originalDataWoW, char) # Gets all unique avatars
allCharacters <- arrange(allCharacters, char) # arranges them in ascending
allCharacters <- mutate(allCharacters, entryCount = 0) # Initializes new column in dataframe


## For Loop to populate the entry count for each avatar in the new dataframe
## DO NOT RUN AGAIN UNLESSS NESSCARY - 10minutes+
i <- 1
for(eachChar in allCharacters$char){
    allCharacters$entryCount[i] <-nrow(filter(originalDataWoW, char == eachChar))
    i <- i + 1
}

summary(allCharacters$entryCount) # Tells you min, max, mean, median
## Min = 1 | Max = 42801 | Mean = 289.8 | Median = 6


################ Number of people who reach max level per week ################
dataBeforeWrath <- filter(originalDataWoW, timestamp < "2008-11-13")
dataBeforeWrath <- select(dataBeforeWrath, char, level, charclass, timestamp) ## This should be done first
weeks <- seq(as.Date("2008-01-01"), as.Date("2008-11-12"), by = "weeks")
weeksFrame <- data.frame(weeks)
weeksFrame <- tbl_df(weeksFrame)
weeksFrame <- mutate(weeksFrame, newMaxLevel = 0)

## Starts the loop 
## First a subset is made for each week with lvl 69 and lvl 70.  Then, I found the unique char values 
## for the lvl 69 subset.  Then, I made a forward loop look for each one in the subset for lvl 70s.  
## If the value for the lvl 69 was found in the subset for 70, then you know the player achieved max
## level in that week.  
##
## Note: weekLevel69 has a -1 for date because if a player leveled to 70 on the first day of the new week
## then it would not count the person.

i <- 1
for(p in weeksFrame$weeks){
    weekLevel69 <- filter(dataBeforeWrath, timestamp >= (weeks[i] - 1) & timestamp <= weeks[i] & level == 69)
    weekLevel70 <- filter(dataBeforeWrath, timestamp >= (weeks[i]) & timestamp <= weeks[i] & level == 70)
    unique69 <- distinct(weekLevel69, char)
    ii <- 0
    for(j in unique69$char){
      tempData <- nrow(filter(weekLevel70, char == j)) 
      if(tempData > 0){ii <- ii + 1}
    }
    weeksFrame$newMaxLevel[i] <- ii
    i <- i + 1
}

graphWeeks <- ggplot(weeksFrame, aes(weeks, newMaxLevel))
graphWeeks + stat_summary(fun.y = mean, geom = "point", colour = "Blue") + 
              stat_summary(fun.y = mean,geom = "line", colour = "Blue") +
              labs(x = "Weeks", y = "Number of New Max Levels", 
                   title = "New Max Level Players Per Week")
################## end of Number of people who reach max level per week ################

################## Combinations of races / class ###########################

raceClassData <- select(originalDataWoW, char, level, race, charclass)
distRaceClass <- distinct(raceClassData) ## Removes duplicate rows (good for reducing table to only seee level ups)

aescDRClass <- arrange(distRaceClass, char) # Main working set
aescDRClass <- select(aescDRClass, char, race, charclass)
uniqueRaceClass <- distinct(aescDRClass)

## Test count() function
countClassRace <- count(uniqueRaceClass, race, charclass) ## EPIC FUNCTION | Counted all combinations of race/class
testClassRace <- countClassRace

testClassUngroupRace <- ungroup(countClassRace)

allClasses.data <- distinct(select(testClassUngroupRace, charclass), charclass)
allRaces.data <- distinct(select(testClassUngroupRace, race), race)

for(raceWoW in allRaces.data$race){
    tempClassRace <- filter(testClassUngroupRace, race == raceWoW)
    missingClass <- allClasses.data$charclass[!allClasses.data$charclass %in% tempClassRace$charclass]
    for(addClass in missingClass)
      testClassUngroupRace2 <- testClassUngroupRace2 %>%
                               rbind(list(raceWoW, addClass, 0)) ## Use list() to rbind different types
}

finalRaceClass.data <- arrange(testClassUngroupRace2, race)

ggplot(testFRC1, aes(charclass, newn)) +   
  geom_bar(aes(fill = race), position = "dodge", stat="identity", width = 0.8) +
  scale_fill_manual(values = c("red", "grey", "grey", "grey", "grey")) +
  coord_flip()

## Used to figure out why there were duplicates of certain avatars
## Answer: They rerolled the character to a different race/class with the same name
## testCount <- count(uniqueRaceClass, char) # Makes another dataFrame with the count as a column
## filter(testCount, n > 1)
## filter(uniqueRaceClass, char == 870)


######################## Top 10 Guilds with most max levels ############### 

dataBeforeWrath <-  originalDataWoW %>%
                      filter(level == 70 & guild > 0 & timestamp < "2008-11-13") %>%                    
                        select(char, charclass, guild, timestamp) %>%
                          distinct() %>%
                            arrange(timestamp)

weeks <- seq(as.Date("2008-01-01"), as.Date("2008-11-18"), by = "weeks")

## Changes the individual dates to weeks dateVec is a vector
dateVec <- dataBeforeWrath %>% select(timestamp) %>% .$timestamp

for(i in 1:length(weeks)){
  cond <- (dateVec >= weeks[i] & dateVec < weeks[i + 1])
  dateVec[cond] <- weeks[i]
}

dataBeforeWrath$timestamp <- dateVec

## Summarises the top 10 guilds 
top10Guilds <-  dataBeforeWrath %>%
                  distinct() %>%
                    group_by(timestamp,guild) %>%
                      summarise(count = n()) %>%
                        group_by(guild) %>%
                          summarise(finalavg = mean(count)) %>%
                            arrange(desc(finalavg)) %>%
                              slice(1:10)

top10Guilds$guild <- factor(top10Guilds$guild)                              
ggplot(top10Guilds, aes(x = reorder(guild, finalavg), y = finalavg)) + 
  geom_bar(stat = "identity") +
    labs(x = "Guilds", y = "# of Max Level Characters", title = "Average # of Max Level Characters") +
      coord_flip()

################################# Done Average Max Level Characters ###############

################################# Top 10 Guild Max Level Class Distribution #################
top10GuildsClass <-  dataBeforeWrath %>%
  distinct() %>%
  group_by(timestamp,guild,charclass) %>%
  summarise(count = n()) %>%
  group_by(guild, charclass) %>%
  summarise(finalavg = mean(count)) %>%
  arrange(desc(finalavg)) %>%
  filter(guild == top10Guilds$guild[1] | guild == top10Guilds$guild[2] | guild == top10Guilds$guild[3] | 
           guild == top10Guilds$guild[4] | guild == top10Guilds$guild[5] | guild == top10Guilds$guild[6] |
           guild == top10Guilds$guild[7] | guild == top10Guilds$guild[8] | guild == top10Guilds$guild[9] |
           guild == top10Guilds$guild[10])

top10GuildsClass$guild <- factor(top10GuildsClass$guild) 
top10GuildsClass <- arrange(top10GuildsClass, guild, charclass)
ggplot(top10GuildsClass, aes(x = reorder(guild, finalavg), y = finalavg, fill = charclass)) + 
  geom_bar(stat = "identity") +
  labs(x = "Guilds", y = "# of Max Level Characters", 
       title = "Top 10 Guilds\n # of Max Level Characters (Pre-WOTLK)") +
  coord_flip() + theme() +
  scale_fill_manual(name = "Classes" ,values = c("#FF7D0A", "#ABD473", "#69CCF0", "#F58CBA", "#D3D3D3",
                                              "#FFF569","#0070DE", "#9482C9", "#C79C6E")) 


################################# Done Top 10 Guild Max Level Class Distribution #################

######################## Most popular zone by level 70######################

dataZones <- originalDataWoW %>%
              filter(timestamp < "2008-11-13") ## Pre-wotlk

## Block of code used if you want to see between a bracket range
levelBracket <- seq(1, 70, 1) ## Vector of level brackets
level.Vec <- dataZones %>% select(level) %>% .$level
for(i in 1:length(levelBracket)){
  cond <- (level.Vec > levelBracket[i] & level.Vec <= levelBracket[i + 1])
  level.Vec[cond] <- levelBracket[i + 1]
}
dataZones$level <- level.Vec 
## End block

dataZones.Sum <- dataZones %>%
                  group_by(level, zone) %>%
                    summarise(count = n()) %>%
                        filter(count == max(count))


ggplot(dataZones.Sum, aes(level, reorder(zone, level))) + geom_point(size = 1.8) +
      scale_x_continuous(breaks = seq(0,70,5)) + labs(x = "Level", y = "Zone", title = "Most Popular Zone by Level")

######################## Most popular zone by level 80######################

dataZones <- originalDataWoW

dataZones.Sum <- dataZones %>%
  group_by(level, zone) %>%
  summarise(count = n()) %>%
  filter(count == max(count))


ggplot(dataZones.Sum, aes(level, reorder(zone, level))) + geom_point(size = 1.8) +
  scale_x_continuous(breaks = seq(0,80,5)) + labs(x = "Level", y = "Zone", title = "Most Popular Zone by Level")

######################## END Most popular zone by level ######################


####################### # of max level per class lvl 70 #########################


dataMaxTBC <- originalDataWoW %>% filter(timestamp < "2008-11-13") ## Pre-wotlk

dataMaxTBC <- dataMaxTBC %>%
                select(char, level, charclass) %>%
                  filter(level == 70) %>%
                    distinct() %>%
                      group_by(charclass) %>%
                        summarise(count = n())

ggplot(dataMaxTBC, aes(reorder(charclass, -count), count)) + geom_bar(stat = "identity") +
      labs(x = "Classes", y = "# of Max Level Characters", title = "Number of Max level Character per Class")

####################### # of max level per class lvl 80 #########################

dataMaxWOTLK <- originalDataWoW

dataMaxWOTLK <- dataMaxWOTLK %>%
  select(char, level, charclass) %>%
  filter(level == 80) %>%
  distinct() %>%
  group_by(charclass) %>%
  summarise(count = n())

ggplot(dataMaxWOTLK, aes(reorder(charclass, -count), count)) + geom_bar(stat = "identity") +
  labs(x = "Classes", y = "# of Max Level Characters", title = "Number of Max level Character per Class")


####################### DONE # of max level per class #########################

####################### Finding possible raid zones #########################

## Logic behind finding raid zone
## Step 1: Filter TBC / Level 70 and in a guild
## Step 2: Turn all times into hours
## Step 3: Count the amount of times 20 or more characters (max level) are in the same zone per hour

# Step 1
raidZones <- originalDataWoW %>% filter(timestamp < "2008-11-13",level == 70 & guild > 0) ## Pre-wotlk

# Step 2
raidZones.test <- raidZones
hours <- seq(as.POSIXct("2008-01-01 0:00", tz = "UTC"), as.POSIXct("2008-11-14 0:00", tz = "UTC"), by = "hour")

hourVec <- raidZones.test %>% select(timestamp) %>% .$timestamp

## Careful running this portion.  Takes upwards of 15 minutes
for(i in 1:length(hours)){
  print(i)
  cond <- (hourVec >= hours[i] & hourVec < hours[i + 1])
  hourVec[cond] <- hours[i]
}

raidZones.test$timestamp <- hourVec

## Step 3
raidZones.test3 <- raidZones.test %>%
                    group_by(timestamp, guild, zone) %>%
                      summarise(count = n()) %>%
                        ungroup() %>%
                          filter(count > 20) %>%
                            group_by(zone) %>%
                              summarise(count = n()) %>%
                                arrange(desc(count)) %>%
                                  slice(1:10)

####################### Done Finding possible raid zones #########################            

#################### Average time to to max level ##################

classLevel <- originalDataWoW %>% filter(timestamp < "2008-11-13" & level <= 70) ## Pre-wotlk

char.Vec <- classLevel %>% select(char) %>% .$char
uniquePlayers70.Vec <- classLevel %>%
                          filter(level == 70 & timestamp < "2008-01-02") %>%
                            distinct(char) %>%
                              .$char

## Changes all characters already lvl 70 on the first day to (-1).  Will delete
cond <- (char.Vec %in% uniquePlayers70.Vec)
char.Vec[cond] <- -1
classLevel$char <- char.Vec

startLevel <- filter(classLevel, char != -1 & level > 1) %>%
                select(char, level, charclass, timestamp)

## Real Block

perLevel.test <- startLevel %>%
  group_by(char, level) %>%
  arrange(char) %>%
  ungroup()

perLevel.test$diff <-  unlist(tapply(perLevel.test$timestamp, INDEX = perLevel.test$char,
                                 FUN = function(x) c(`units<-`(diff(x), "hours"), 0)))

perLevel.test2 <- perLevel.test %>% 
                  filter(diff < 1 & level != 70 & diff != 0) %>%
                    group_by(char, level,charclass) %>%
                      summarise(sumOfLevel = sum(diff)) %>%
                        ungroup() %>%
                          group_by(charclass, level) %>%
                            summarise(averageTimeLevel = mean(sumOfLevel))

totalTimePerClass <- perLevel.test2 %>%
                      group_by(charclass) %>%
                        summarise(total = sum(averageTimeLevel))
                    


