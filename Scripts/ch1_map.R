library("ggplot2")
library("stringr")
library("ggmap")
library("readxl")
library("rgeos")
library("rworldmap")

dt <- readLines("Data/GP.lgr")
country <- read_excel("Data/ExLingo.xlsx", range = "Lingo!C1:C143")
type <- read_excel("Data/ExLingo.xlsx", range = "Lingo!F1:F143")
 

#clean them
dt <- dt[37:320]
dt <- gsub("\\s+", " ", str_trim(dt))

#get rid of the parentheses space
dt <- gsub("\\(\\s", "(", dt)

dt <- matrix(unlist(strsplit(paste(dt), split = " ")), ncol = 3, byrow= TRUE)

dt <- dt[,1:2]

Cost <- as.numeric(dt[1:142,2])

Revenue <-as.numeric(dt[143:284,2])

df <- data.frame(country, type, Revenue, Cost)

#get world centroids
wmap <- getMap()
ISO3 <- as.character(dati$ISO3)
LAT <- as.numeric(dati$LAT)
LON <- as.numeric(dati$LON)
centroids <- data.frame(ISO3,LAT,LON)

df <- merge(x=df, y=centroids, by="ISO3")

result <- df[(df$Revenue > 0 & df$Cost > 0),]
RevCost <- "Revenue"
rev  <- data.frame(result[,-4], RevCost)
colnames(rev)[3] <- "Amount"
RevCost  <- "Cost"
cost <- data.frame(result[,-3], RevCost)
colnames(cost)[3] <- "Amount"

result <- rbind(rev, cost)
rownames(result) <- 1:dim(result)[1]
result$Type <- as.factor(result$Type)

europe <- c(left = -12, bottom = 20, right = 85, top = 58)
map <- get_stamenmap(europe, zoom = 5, maptype = "toner-lite")

ggmap(map) +
geom_point(aes(x=LON, y=LAT, shape = Type, size= Amount), data = result, alpha = 0.5) +
scale_size(range=c(3,20), name = "Amount") +
scale_shape(name = "Function performed")

ggsave(filename="ch1map.png")
