library(tidyverse)
library(RMySQL)
library(ggplot2)
library(DBI)


# Connect to Cloud SQL instance
connection = dbConnect(MySQL(),user="root", password="root", 
                       dbname="mydb", host="34.70.81.39")

# 'alias' dbGetQuery(); "dbGetQuery" is too long, I'd rather type "run"
run <- function(query) {
  dbGetQuery(connection, query)
}

# Testing connection
run("show databases;")
run("use `mydb`;")
run("show tables;")
run("describe datetime")
run("describe trips")

TotalDocksColumn <- run('select station_name, total_docks from stations;')

graphData <- graphData %>%
  left_join(TotalDocksColumn, by = c('Label' = 'station_name'))

NodeTable <- run("
  select
    s.station_id as Id,
    s.station_name as Label,
    s.lat as Latitude,
    s.long as Longitude,
    s.docks_in_service as ActiveDocks,
    n.name as Neighborhood
  from
    stations s
      inner join
    neighborhood n on s.neighborhood_id = n.neighborhood_id;
  ")

EdgeTable <- run("
  select
    s1.station_id as Source,
    s2.station_id as Target,
    t.tripduration as Duration,
    d1.datetime as StartDate,
    d1.hour as StartHour,
    d2.datetime as EndDate,
    d2.hour as EndHour
  from
    trips t
      inner join
    stations s1 on t.from_station_id = s1.station_id
      inner join
    stations s2 on t.to_station_id = s2.station_id
      inner join
    datetime d1 on t.start_datetime_id = d1.datetime_id
      inner join
    datetime d2 on t.end_datetime_id = d2.datetime_id;
  ")

EdgeTable2 <- EdgeTable %>%
  group_by(Source, Target) %>%
  summarize(Weight = n(), AvgDuration = mean(Duration))

EdgeTable <- EdgeTable %>%
  mutate(Type = "Directed")

write_csv(EdgeTable, 'EdgeTable.csv')
write_csv(EdgeTable2, 'EdgeTable2.csv')
write_csv(NodeTable, 'NodeTable.csv')  
