library(RSocrata)
library(tidyverse)

# either-or here
load("traffic-round.RData")

df <- read.csv("traffic.csv")

# remove observations out of scope
df <- df[df$TIME < as.POSIXct(as.Date("2019-07-01")),]
df <- df[df$TIME > as.POSIXct(as.Date("2018-03-01")),]

df$TIME <- as.POSIXct(trunc(df$TIME, "hour")) # truncate datetimes to hour

# create datetime sequence
test <- seq.POSIXt(as.POSIXct("2018-03-01 00:00:00"), as.POSIXct("2019-07-01"), by="hour")
test <- data.frame(time=test)
test$month <- as.numeric((as.POSIXlt(test$time))$mon) + 1
test$day <- as.numeric((as.POSIXlt(test$time))$mday)
test$year <- as.numeric((as.POSIXlt(test$time))$year) + 1900
test$hour <- as.numeric((as.POSIXlt(test$time))$hour)
test$day_of_week <- as.numeric((as.POSIXlt(test$time))$wday)
test$datetime_id <- 1:(dim(test)[1])
test <- test[-(dim(test)[1]),]
datetime <- test
remove(test)
write.csv(datetime,'datetime.csv',row.names=F)

# replace times with datetime ids
records <- df[, (names(df) %in% c("SPEED",
                                  "BUS_COUNT","MESSAGE_COUNT","SEGMENT_ID",'TIME'))]
records <- records[-(dim(records)[1]),]
records$RECORD_ID <- 1:(dim(records)[1])
records$DATETIME_ID <- datetime$datetime_id[match(as.numeric(records$TIME),as.numeric(datetime$time))]
records <- records[, !(names(records) %in% c("TIME"))]
write.csv(records, 'records.csv', row.names=F)

# group segments for write
segments <- df %>%
  group_by(SEGMENT_ID, STREET, DIRECTION, START_LATITUDE, START_LONGITUDE, END_LATITUDE, END_LONGITUDE) %>%
  summarise(SPEED = sum(SPEED))
segments <- segments[, !(names(segments) %in% c("SPEED"))]
segments <- segments[-(dim(segments)[1]),]
write.csv(segments, 'segments.csv', row.names=F)

df = df[!df$SPEED==-1,] # remove invalid speed observations

# group segments by hour (avg speed)
df <- df %>%
  group_by(SEGMENT_ID, TIME, STREET, DIRECTION, START_LATITUDE, START_LONGITUDE, END_LATITUDE, END_LONGITUDE) %>% 
  summarise(SPEED = mean(SPEED), 
            BUS_COUNT = sum(BUS_COUNT),
            MESSAGE_COUNT = sum(MESSAGE_COUNT))

# read function for API get
df <- read.socrata(
  "https://data.cityofchicago.org/resource/sxs8-h27x.json?$select=time,segment_id,speed,street,bus_count,message_count,start_location,end_location&$where=speed>-1&$limit=1000",
  app_token = "xpMfkQQaY3GV3m5eWLBVPuQrG",
  email     = "andrewmorse@uchicago.edu",
  password  = "if you think this is OVER"
)

# convert time to posixt
df$TIME <- as.POSIXct(df$TIME, format="%m/%d/%Y %I:%M:%S %p", tz="CST6CDT")

# select columns
df <- df[ , !(names(df) %in% c("STREET_HEADING","HOUR",
                               "DAY_OF_WEEK","MONTH","START_LOCATION","END_LOCATION"))]

write.csv(df, "clean.csv")

# convert types of numbers
df$segment_id = as.integer(df$segment_id)
df$speed = as.integer(df$speed)
df$bus_count = as.integer(df$bus_count)
df$message_count = as.integer(df$message_count)

# extract location information
df$start_long = apply(df, 1, FUN = function(x) x$start_location.coordinates[[1]])
df$start_lat = apply(df, 1, FUN = function(x) x$start_location.coordinates[[2]])
df$end_long = apply(df, 1, FUN = function(x) x$end_location.coordinates[[1]])
df$end_lat = apply(df, 1, FUN = function(x) x$end_location.coordinates[[2]])

# drop unmodified location information
df <- df[ , !(names(df) %in% c("start_location.type","start_location.coordinates",
                               "end_location.type","end_location.coordinates"))]