library(RMySQL)
library(ggplot2)
library(DBI)
library(tidyverse)

# Connect to Cloud SQL instance
connection = dbConnect(MySQL(),user="root", password="root", 
                       dbname="mydb", host="34.70.81.39")

# Alias dbGetQuery so I don't need to type it out each time
run <- function(query) {
  dbGetQuery(connection, query)
}

# Testing connection
run("show databases;")
run("use `mydb`;")
run("show tables;")
run("describe datetime")
run("describe trips")

# Pull together trips section of data from Cloud SQL
trips <- run("
              select 
                t.trip_id,
                d.`datetime`,
                d.`month`,
                d.`year`,
                d.`hour`,
                d.`day`,
                d.day_of_week,
                t.tripduration,
                n.name
              from
                trips t
                  left join
                `datetime` d on t.start_datetime_id = d.datetime_id
                  left join
                stations s on t.from_station_id = s.station_id
                  left join
                neighborhood n on s.neighborhood_id = n.neighborhood_id;")

# Group trips by datetime and neighborhood, so we have a count of trips per hour in each neighborhood
tripsAgg <- trips %>%
  group_by(datetime, name, year, month, day, hour) %>%
  summarize(trips = n(), avg_tripduration = mean(tripduration))

# Pull traffic data (only to realize Cloud SQL version is missing data)
traffic <- run("
                select
                  n.`name`,
                  d.`datetime`,
                  d.`month`,
                  d.`year`,
                  d.`hour`,
                  d.`day`,
                  r.speed
                from
                  records r
                    left join
                  `datetime` d on r.datetime_id = d.datetime_id
                    left join
                  segments s on r.segment_id = s.segment_id
                    left join
                  neighborhood n on s.start_neighborhood_id = n.neighborhood_id;")

# Read traffic data in from local file
segmentsDat <- read_csv('data/segments.csv', col_names = c('segment_id','street','start_lat','end_lat',
                                                           'start_long','end_long','direction',
                                                           'start_neighborhood_id','end_neighborhood_id',
                                                           'neighborhood_id'))
recordsDat <- read_csv('data/records.csv', col_names = c('record_id','speed','bus_count','message_count',
                                                         'segment_id','datetime_id'))

# Create neighborhood_id for segments data
segmentsDat2 <- segmentsDat %>%
  mutate(neighborhood_id = case_when(start_neighborhood_id == end_neighborhood_id ~ start_neighborhood_id,
                                     is.na(start_neighborhood_id) & is.na(end_neighborhood_id) ~ NA_real_,
                                     !is.na(start_neighborhood_id) & is.na(end_neighborhood_id) ~ start_neighborhood_id,
                                     is.na(start_neighborhood_id) & !is.na(end_neighborhood_id) ~ end_neighborhood_id,
                                     start_neighborhood_id != end_neighborhood_id ~ start_neighborhood_id))

# Load other data necessary for traffic data join
datetimeDat <- run("select * from datetime;")
neighborhood <- run("select * from neighborhood;")

# Traffic data joins
traffic2 <- recordsDat %>%
  left_join(datetimeDat, by = c('datetime_id' = 'datetime_id')) %>%
  left_join(segmentsDat2, by = c('segment_id' = 'segment_id')) %>%
  left_join(neighborhood, by = c('neighborhood_id' = 'neighborhood_id')) %>%
  select(name, datetime, speed, month, year, hour, day)

# Pull crashes data from Cloud SQL
crashes <- run("
                select
                  c.crash_id,
                  c.first_crash_type,
                  d.`datetime`,
                  d.`month`,
                  d.`year`,
                  d.`hour`,
                  d.`day`,
                  n.`name`
                from
                  crash c
                    left join
                  `datetime` d on c.datetime_id = d.datetime_id
                    left join
                  neighborhood n on c.neighborhood_id = n.neighborhood_id;")

# Join the three datasets to form final regression dataset
regDat <- traffic2 %>%
  full_join(tripsAgg, by = c('datetime' = 'datetime', 'name' = 'name', 'month' = 'month',
                             'year' = 'year', 'hour' = 'hour', 'day' = 'day'))

regDat <- regDat %>%
  full_join(crashes, by = c('datetime' = 'datetime', 'name' = 'name', 'month' = 'month',
                            'year' = 'year', 'hour' = 'hour', 'day' = 'day'))

# Saving objects and regression data
save(tripsAgg, traffic2, crashes, file = "regressionEnv.RData")
load('regressionEnv.RData')

#reading regression data
regDat <- read_csv('regression_data.csv', col_types = cols(
  datetime = col_date(),
  name = col_factor(),
  month = col_integer(),
  year = col_integer(),
  hour = col_integer(),
  day = col_integer(),
  trips = col_integer(),
  speed = col_double(),
  avg_tripduration = col_double(),
  first_crash_type = col_character(),
  crash_id = col_integer()
))

regDat <- regDat %>%
  mutate(crash = ifelse(is.na(crash_id),0,1))

regDat$name <- fct_explicit_na(regDat$name)

write_csv(regDat, 'regression_data.csv')

