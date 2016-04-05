library(choroplethr)

#only need to do this the first time
#firsttime: library(devtools)
#firsttime: install_github('arilamstein/choroplethrZip@v1.3.0')

library(choroplethrZip)

setwd("c:/finalproject") 

#get nyc zip codes
#---------------------------------------------------------------------------------
#use the zip.regions dataset to get the full list of zip codes in NYC which is made up of 5 counties
data(zip.regions)
data("df_pop_zip")

#only need to do this the first time
##subset with just the counties in NYC
#nyc_counties<-c("new york","queens","bronx","brooklyn","richmond")
#nyc_zip_full<-zip.regions[(zip.regions$county.name %in% nyc_counties)&(zip.regions$state.name == "new york"),]
#nyc_zip<-data.frame(nyc_zip_full[,1]) #convert to data frame
#names(nyc_zip)<-"zip"
#nyc_zip$zip<-as.character(nyc_zip$zip)
#write.csv(nyc_zip,"./data/nyc_zip.csv") #save this file for future use

#after first time just do this
nyc_zip<-read.csv("./data/nyc_zip.csv")
nyc_zip$zip<-as.character(nyc_zip$zip)

#get 311 data via SQL query
#------------------------------------------------------------------------------------

#Now run a sql query to pull all of the counts of 311 incidents in the zip codes from nyc_zip file
library(sqldf)
db <- dbConnect(SQLite(), dbname="./data/SelectedColumnsAllRowsThe311.db")
dbListTables(db)
dbListFields(db, "The311")
zip_counts <- dbGetQuery(db, "SELECT substr(trim(incidentzip), 1, 5) as zip, COUNT(*) as TotalIncidentCount FROM The311 GROUP BY substr(trim(incidentzip), 1, 5)")
dbDisconnect(db)            # Close connection

#save that file in zip_counts.csv file in the working directory
write.csv(zip_counts,"./data/zip_query.csv") #save this file for future use

#if you want to test with same query as last time, comment out query and read the file so it runs faster
#zip_counts<-read.csv("./data/zip_query.csv", header = T)
#zip_counts$X <- NULL

zip_counts$zip<-as.character(zip_counts$zip)

#remove any zips != 5 chars
zip_counts<-zip_counts[nchar(zip_counts$zip)==5,]

#remove any zips that are 0's
zip_counts<-zip_counts[substr(zip_counts$zip,1,4)!='0000',]

#Use this merged dataframe below for the actualplot (we can't miss any zipcodes if it wasnt in the database so we merge)
IncidentCount311<-merge(nyc_zip,zip_counts,all.x = TRUE)

#remove NAs
IncidentCount311[is.na(IncidentCount311)]<-0

#remove duplicate regions(duplicate Zipcodes - there were 2)
names(IncidentCount311)<-c("region","value")
IncidentCount311 <- IncidentCount311[!duplicated(IncidentCount311$region),]

#plot
#-------------------------------------------------------------------------------

zip_choropleth(IncidentCount311, 
               zip_zoom=IncidentCount311$region, 
               title="NYC 311 Incident Counts",
               legend="Total 311 Counts")

#now we want to weight these by the population in these zip codes
data("df_pop_zip")
names(df_pop_zip)<-c("region", "pop")
weighted_df<-merge(IncidentCount311,df_pop_zip,all.x = T)
weighted_df$value <- weighted_df$value/weighted_df$pop
#make this ready for plotting
weighted_df <- weighted_df[,-3]
zip_choropleth(weighted_df,
               zip_zoom=weighted_df$region,
               title="Total 311 Counts Weighted by Population in the Zip Codes",
               legend="Weighted Total 311 Counts")
