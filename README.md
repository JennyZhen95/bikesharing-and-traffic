# Bike-sharing in Chicago and its impact on traffic

This was a group project put together by [Andrew Morse](https://github.com/andrewjmorse "Andrew's GitHub profile"), [Jenni Ni Zhen](https://github.com/JennyZhen95 "Jenny's GitHub profile"), [Michael Setyawan](https://github.com/MichaelSetyawan "Michael's GitHub profile"), and [Yannik Kumar](https://github.com/yannikkumar "Yannik's GitHub profile") for the data engineering course taught at the University of Chicago.

#### Motivation
There are many studies out there that show that introducing bike-sharing to a city can help reduce motor vehicle congestion (examples [here](https://www.sciencedirect.com/science/article/abs/pii/S0095069616300420 "Bicycle infrastructure and traffic congestion: Evidence from DC's Capital Bikeshare"), [here](https://arxiv.org/pdf/1808.06606.pdf "Impact Of Bike Sharing In New York City"), and [here](https://www.sciencedirect.com/science/article/abs/pii/S0966692317302715 "Bike-sharing systems and congestion: Evidence from US cities")). We were interested to see whether the same held true for our city of Chicago, where the Divvy bike-sharing system is quite popular. Moreover, designing and implementing a database and pipeline for the different public datasets seemed like a good opportunity to practice our data engineering skills.

![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/research-questions.png)

## Data pipeline
Our workflow looked like.
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/data-pipeline.png)
1. We first pulled traffic and crash records from the City of Chicago's data portal, and bike-sharing data from Divvy's website (future iterations of this project could look to automate this). 
2. We then wrangled the data into formats that worked with the database schema we designed and the types of analyses we wanted to run.

   * `wrangle01-dates.R` Performs handling of bad data, date transformation, and formatting.
   * `wrangle02-geocode-neighborhoods.ipynb` Geocodes neighborhoods with latitude and longitude. Since our level of analysis was at the neighborhood level, this was necessary to identify which neighborhoods each bike-sharing station fell into.
   * `wrangle03-cleaning-crash-data.ipynb` Includes steps to clean up the crash dataset.
   * `wrangle04-formatting-and-ids.R` Primarily serves to match date/time values to IDs and format the data for server loading.
   * `wrangle05-node-and-edge-tables.R` Pulls data from our CloudSQL instance and creates edge and node tables that are used to create a graph representation of the bike-sharing system.
   * `wrangle06-data-for-modeling.R` Pulls data from our CloudSQL instance and creates a dataset that is ready for data modeling techniques, such as regression.
3. Next we designed a relational database. And using a CloudSQL instance on Google Cloud Platform, we loaded the data.
   * `database-schema-definition.sql` is the script used to create database schema in GCP.
4. Finally we created a dashboard with some visualizations in Tableau, and used R and Gephi to explore the data from a network perspective.
   * `visualize-network.R` is the code used to generate the network visualization.

## Database design
Here's the enhanced entity relationship model for our database.
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/EER-model.png)
Designing the schema proved to be challenging and full of tradeoffs! We initially wanted a dimensional model for our dataset, but realized that reconciling the datasets for our fact table would require either:
* taking the cartesian product of three datasets (which was a magnitude of a trillion rows - clearly intractable).
* or aggregrating/grouping data, which meant losing information.
Hence, we opted for a relational database model, since it reduced data redundancy, preserved all data attributes, and maximized user and application flexibility.

## Exploring the data
### Are bike-sharing stations optimized for the need of Divvy users?
Short answer: mostly yes, with some trouble spots.

So what's the current usage pattern like?
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/daily-trips.gif)
It appears that:
1. Divvy users bike to downtown area during 5a-11a.
2. Divvy users bike to areas surrounding loop during 4-8p.
3. Divvy usage is not heavy in south of Chicago.

To answer the question if the current system of stations is meeting user demand, we decided to generate a graph model of the bike-sharing data. Nodes represented stations, edges were >20 trips between stations, and the color of a node was determined by utilization metric we created that represented overloaded stations.
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/creating-graph-model.png)

And here's what the network looked like.
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/network-viz.png)
The darker the node the greater its utilization score. From the visualization, we can see that for the most part the system is doing a good job of meeting user demand; however, there are some trouble spots downtown that could benefit from additional bike docks. 

We also calculated the betweenness centrality for each station (which is how many times the station is on the shortest path from each node in the network to every other node). Stations with high betweenness centrality function as bridges in the network, connecting different sections of the network together.
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/stations-betweenness.png)
Looking at the distribution of betweenness centrality scores we see there are a number of outlier stations with very high betweenness centrality scores. The areas surrounding these stations could benefit from new Divvy bike stations to help reduce the risk of potential overloading of other parts of the network if these outlier stations were rendered out of service.

What are unsafe areas for new stations?
With crash records we could identify areas that might be unsafe for bike traffic.
![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/daily-crashes.gif)
We see that the trend overlaps with arriving-trip visualization. It might be interesting to investigate the causes of the crashes in these areas. 

### Does bike sharing reduce traffic congestion in Chicago?
Short answer: no - at least it’s not supported by the data we have.

![alt text](https://github.com/yannikkumar/bikesharing-and-traffic/blob/master/imgs/trips-and-traffic-bubbleplot.png)
1. For most neighborhoods, there are more trips in the evening compared to all other times of day.
2. A high number of trips does not relate to a higher average speed of traffic.
3. People use Divvy bikes a lot in the Far North Side District.

We also explored some regression models of traffic with a few different bike-sharing related predictor variables and other covariates, but were unsatisfied with their explanatory value. 

## Conclusion
As an answer to our second RQ: we think the current bike-sharing system is doing a good job given current demand, but there is room for improvement. Areas surrounding stations with abnormally high betweenness centrality are candidates for new stations. Stations with high utilization (concentrated in the loop downtown) are overburdened, and could benefit from additional bikes. Stations in the North side could also benefit from additional bike docks.

Regarding our first RQ: on the whole it looks like with our data we aren't able to give a compelling case for the Divvy bike-sharing system reducing traffic congestion in Chicago. Nonetheless, the lakeshore paths of Chicago have some great scenic bike paths that we recommend everyone ride along at least once!
