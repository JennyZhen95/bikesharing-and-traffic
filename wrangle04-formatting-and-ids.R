# segments
seg <- read.csv("segments.csv")
neigh_id <- seg$start_neigh_id == seg$end_neigh_id
neigh_id[is.na(neigh_id)] <- F
neigh_id[neigh_id] <- seg$start_neigh_id[neigh_id]
neigh_id[neigh_id == 0] <- NA
seg$neigh_id <- neigh_id
seg <- seg[,!names(seg) %in% c("X")]
names(seg) <- c("segment_id","street","direction","start_lat","start_long","end_lat","end_long",
                "start_neighborhood_id","end_neighborhood_id","neighborhood_id")
seg[,1:10] <- seg[,c(1,2,4,6,5,7,3,8,9,10)]
names(seg)[1:10] <- names(seg)[c(1,2,4,6,5,7,3,8,9,10)]
write.csv(seg, "segments.csv", row.names=F)

# get date/time from trips
trip <- read.csv("trips.csv")
s <- as.POSIXct(trip$start_time, format="%Y-%m-%dT%H:%M:%SZ")
e <- as.POSIXct(trip$end_time, format="%Y-%m-%dT%H:%M:%SZ")
datetime <- unique(c(s,e))
datetime <- data.frame(time=datetime)
datetime$month <- as.numeric((as.POSIXlt(datetime$time))$mon) + 1
datetime$day <- as.numeric((as.POSIXlt(datetime$time))$mday)
datetime$year <- as.numeric((as.POSIXlt(datetime$time))$year) + 1900
datetime$hour <- as.numeric((as.POSIXlt(datetime$time))$hour)
datetime$day_of_week <- as.numeric((as.POSIXlt(datetime$time))$wday)
datetime.old <- read.csv("datetime.csv")
datetime.old <- datetime.old[,!names(datetime.old) %in% c("datetime_id")]
datetime.old$time <- as.POSIXct(datetime.old$time, format="%Y-%m-%d %H:%M:%S")
datetime <- as.data.frame(rbind(datetime.old, datetime))
write.csv(datetime, "datetime.csv", row.names=F)

# get date/time from crashes
crash <- read.csv("crash.csv")
datetime <- unique(as.POSIXct(crash$CRASH_DATE, format="%Y-%m-%d %H:%M:%S"))
datetime <- data.frame(time=datetime)
datetime$month <- as.numeric((as.POSIXlt(datetime$time))$mon) + 1
datetime$day <- as.numeric((as.POSIXlt(datetime$time))$mday)
datetime$year <- as.numeric((as.POSIXlt(datetime$time))$year) + 1900
datetime$hour <- as.numeric((as.POSIXlt(datetime$time))$hour)
datetime$day_of_week <- as.numeric((as.POSIXlt(datetime$time))$wday)
datetime.old <- read.csv("datetime.csv")
datetime.old$time <- as.POSIXct(datetime.old$time, format="%Y-%m-%d %H:%M:%S")
datetime.old <- datetime.old[,!names(datetime.old) %in% c("X")]
datetime <- as.data.frame(rbind(datetime.old, datetime))

# shrink date/time table
datetime <- datetime[!duplicated(datetime$time),]
datetime$datetime_id <- 1:(dim(datetime)[1])
write.csv(datetime, "datetime.csv", row.names=F)

# convert date/time in other tables
trip$start_time <- as.POSIXct(trip$start_time, format="%Y-%m-%dT%H:%M:%SZ")
trip$end_time <- as.POSIXct(trip$end_time, format="%Y-%m-%dT%H:%M:%SZ")
crash$CRASH_DATE <- as.POSIXct(crash$CRASH_DATE, format="%Y-%m-%d %H:%M:%S")
trip$start_datetime_id <- datetime$datetime_id[match(as.numeric(trip$start_time),as.numeric(datetime$time))]
trip$end_datetime_id <- datetime$datetime_id[match(as.numeric(trip$end_time),as.numeric(datetime$time))]
crash$datetime_id <- datetime$datetime_id[match(as.numeric(crash$CRASH_DATE),as.numeric(datetime$time))]
trip <- trip[,!names(trip) %in% c("start_time","end_time")]
crash <- crash[,!names(crash) %in% c("CRASH_DATE")]
write.csv(trip, "trips.csv", row.names=F)
write.csv(crash, "crash.csv", row.names=F)

# modify crashes for load
crash <- crash[,!names(crash) %in% c("RD_NO","STREET_NO","STREET_DIRECTION","CRASH_HOUR","CRASH_DAY_OF_WEEK",
                                     "CRASH_MONTH","LOCATION","CRASH_YEAR")]
names(crash) <- c("first_crash_type","type","damage","street_name","num_units","lat","long","neighborhood_id",
                  "datetime_id")
crash[,1:9] <- crash[,c(9,1,2,3,4,5,6,7,8)]
names(crash)[1:9] <- names(crash)[c(9,1,2,3,4,5,6,7,8)]
crash$crash_id <- 1:dim(crash)[1]
levels(crash$damage)[levels(crash$damage)=="$501 - $1,500"] <- "$501 - $1500"
levels(crash$damage)[levels(crash$damage)=="OVER $1,500"] <- "OVER $1500"
write.csv(crash, "crash.csv", row.names=F)

# modify trips for load
trip <- trip[,!names(trip) %in% c("from_station_name","to_station_name","usertype")]
trip[,1:9] <- trip[,c(1,8,9,3,4,5,2,6,7)]
names(trip)[1:9] <- names(trip)[c(1,8,9,3,4,5,2,6,7)]
write.csv(trip, "trips.csv", row.names=F)

# modify records for load
rec <- read.csv("records.csv")
names(rec) <- c("segment_id","speed","bus_count","message_count","record_id","datetime_id")
rec[,1:6] <- rec[,c(5,2,3,4,1,6)]
names(rec)[1:6] <- names(rec)[c(5,2,3,4,1,6)]
write.csv(rec, "records.csv", row.names=F)

# modify datetime for load
datetime <- read.csv("datetime.csv")
names(datetime) <- c("datetime","month","day","year","hour","day_of_week","datetime_id")
datetime$datetime <- as.POSIXct(datetime$datetime, format="%Y-%m-%d %H:%M:%S")
datetime[,1:7] <- datetime[,c(7,1,2,4,5,6,3)]
names(datetime)[1:7] <- names(datetime)[c(7,1,2,4,5,6,3)]
write.csv(datetime, "datetime.csv", row.names=F)

# modify stations for load
stations <- read.csv("stations.csv")
stations <- stations[,!names(stations) %in% c("location")]
write.csv(stations, "stations.csv", row.names=F)

# Fix neighborhood indices
seg <- read.csv("segments.csv", header=F)
stations <- read.csv("stations.csv", header=F)
crash <- read.csv("crash.csv", header=F)
neigh <- read.csv("neighborhood.csv", header=F)
neigh$V1 <- neigh$V1 + 1
crash$V9 <- crash$V9 + 1
seg$V8 <- seg$V8 + 1
seg$V9 <- seg$V9 + 1
seg$V10 <- seg$V10 + 1
stations$V9 <- stations$V9 + 1
crash <- crash[!is.na(crash$V8),]
crash <- crash[!(crash$V8 == 0),]
write.csv(crash, "crash.csv", row.names=F)
write.csv(neigh, "neighborhood.csv", row.names=F)
write.csv(seg, "segments.csv", row.names=F)
write.csv(stations, "stations.csv", row.names=F)
