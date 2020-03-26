library('maps')
library('geosphere')
library('ggmap')
library('ggplot2')
library('readr')
library('sf')
library('dplyr')
library('ggthemes')

# Read Node and Edge tables
EdgeTable <- read_csv('EdgeTable2.csv')
NodeTable <- read_csv('NodeTable.csv')

EdgeTable2 <- EdgeTable %>%
  filter(Weight >= 20)

# create utilization metric
graphData <- NetworkMeasures %>%
  mutate(UtilizationFactor = case_when(activedocks != 0 ~(`weighted outdegree`/`weighted indegree`) * (`Weighted Degree`/activedocks ),
                                       activedocks == 0 ~ 4000))

# plot to confirm
ggplot(graphData) + geom_histogram(aes(x = UtilizationFactor))

# let's make the node color a function of its utilization factor score
UtilizationFactorGradient <- colorRampPalette(c('red','yellow'))

graphData <- graphData %>% arrange(UtilizationFactor)
graphData$Color <- UtilizationFactorGradient(10)[as.numeric(cut(graphData$UtilizationFactor,
                                                              breaks = 10))]
# load in map to plot our network on
NeighborhoodMap <- st_read('neighborhoods/geo_export_c0182ca0-1f35-4cb2-b1bd-75b05d26853c.shp')
NeighborhoodMap <- as(NeighborhoodMap, "Spatial")

ChicagoMap2 <- SpatialPolygons2map(NeighborhoodMap, namefield=NULL)
maps::map(ChicagoMap2, col="grey", fill=TRUE, bg="grey96", lwd=0.1)

# add the nodes to the map
points(x=graphData$longitude, y=graphData$latitude, pch=19, 
       cex=0.1 * (graphData$UtilizationFactor/max(graphData$UtilizationFactor))
       , col=graphData$Color)

(graphData$UtilizationFactor/max(graphData$UtilizationFactor))

# finessing color on the graph
col.1 <- adjustcolor("orange red", alpha=0.2)
col.2 <- adjustcolor("orange", alpha=0.2)
edge.pal <- colorRampPalette(c(col.1, col.2), alpha = TRUE)
edge.col <- edge.pal(100)

# adding edges to the network graph
for(i in 1:nrow(EdgeTable2))  {
  node1 <- graphData[graphData$Id == EdgeTable2[i,]$Source,]
  node2 <- graphData[graphData$Id == EdgeTable2[i,]$Target,]
  
  arc <- gcIntermediate( c(node1[1,]$longitude, node1[1,]$latitude), 
                         c(node2[1,]$longitude, node2[1,]$latitude), 
                         n=10, addStartEnd=TRUE )
  edge.ind <- round(100*EdgeTable2[i,]$Weight / max(EdgeTable2$Weight))
  
  lines(arc, col=edge.col[edge.ind], lwd=edge.ind/30)
}

# read in network measures data (computed in Gephi)
NetworkMeasures <- read_csv('NetworkMeasures.csv')

betweenness <- graphData %>%
  select(Id, Label, neighborhood, betweenesscentrality) %>%
  arrange(desc(betweenesscentrality))

# create a plot to examine distribution of betweenness centrality scores
ggplot(betweenness) +
  geom_histogram(aes(betweenesscentrality, ..count..))+ theme_bw() +
  theme(text = element_text(size = 20))
  
  
  theme_tufte(base_size = 11, base_family = "serif", ticks = FALSE)





