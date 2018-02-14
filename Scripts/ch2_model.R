
pricesimulation<-function (pzero, sigma, l){
  initialPrice = pzero
  dailyDeviation = sigma

  n = 15 #number of days
  
  prices<-vector(mode = "numeric", length = l) 
  
  i <- 1
  for(i in 1:l){  
    prices[i] = initialPrice + cumsum(rnorm(n = n,mean = 0, sd = dailyDeviation))
  }
  return(prices)
  }

#Main script chapter 2 model
#Using NEOS server for solving it
library("rneos")
library("fPortfolio")
library("telegram")
library("here")
library("ggplot2")
set.seed(200)

# Create the bot object
bot <- TGBot$new(token = bot_token('RBot'))
bot$set_default_chat_id(423034192)
# Start routine
setwd(here())
# Turn off warnings (for XML package)
options(warn = -1)
# Ping the neos server
Nping()

# Setting the number of simulations
n <- 100

# Commodity data
Price <- c(15,8,11,6) #price at time zero
Volatility <-c(0.5,1,2,0.7) #volatility of the commodity on the reference market

# Initialize the matrix with the random prices and the result matrix
symmat <- matrix(nrow = 4, ncol = n)
symmat <- t(mapply(pricesimulation, Price, Volatility, ncol(symmat)))
mainmat <- matrix(nrow = 4, ncol = n)

# Data File DECLARATION of unchanged variables
K<-2660
ProcAct <- c(49, 52, 50, 55) #Variable cost based on the production activities
demand <- c(1900, 1200, 1600, 600)
cost = matrix(
  c(0, 14, 11, 14,
    27, 0, 12, 22,
    24, 14, 0, 12,
    10, 13, 3, 0),
  nrow=4,
  ncol=4,
  byrow = TRUE)


# Get the template for the solver
template<-NgetSolverTemplate(category = "lp", solvername = "MOSEK", inputMethod = "AMPL")

# Model File:
  modf <- c(
    "set ORIG := 1..4;",
    "set DEST := 1..4;",
    "param demand {DEST} >= 0;",
    "param K;",
    "param cost {ORIG,DEST} >= 0;",
    "param ProcV {ORIG} >= 0;",
    "check: K <= sum {j in DEST} demand[j];",
    "var supply {ORIG} >= 0 integer;",
    "var Trans {ORIG,DEST} >= 0 integer;",
    "var Dev >= 0;",
    "var Devp >= 0;",
    "var supply2{ORIG} >= 0 integer;",
    "minimize Total_Deviation: Devp + Dev;",
    "s.t. Inbound: sum {i in ORIG} ProcV[i] * supply[i] - Devp = 0;",
    "s.t. Transport: sum {i in ORIG, j in DEST} cost[i,j] * Trans[i,j] - Dev = 0;",
    "s.t. Supply {i in ORIG}: sum {j in DEST} Trans[i,j] = supply[i];",
    "s.t. Demand {j in DEST}: sum {i in ORIG} Trans[i,j] <= demand[j];",
    "s.t. Allocation: sum {i in ORIG} supply[i]= K;",
    "s.t. Allocation2{i in ORIG}: sum {j in DEST} Trans[j,i] = supply2[i];"
  )

# Run File:
  comf <- c(
    "solve;",
    "display supply;"
    #"option display_1col 0;",
    #"display Trans;"
  )

i <- 1
for (i in 1:n){
  ProcV <- ProcAct + symmat[,i] #add the price forcast to the other costs
  
  # Data File:
  amplDataOpen("ampl") #clear the dat file
  amplDataAddValue("K", K, "ampl")
  amplDataAddVector("ProcV", ProcV, "ampl")
  amplDataAddVector("demand", demand, "ampl")
  amplDataAddMatrix("cost",cost ,"ampl")
  # Write in the variable 
  datf <- paste(paste(readLines("ampl.dat"), collapse = "\n"), "\n")

  #Pass the AMPL files to the server
  argslist <- list(model = modf, data = datf, commands = comf, comments = "")
  xmls <- CreateXmlString(neosxml = template, cdatalist = argslist)
  (test <- NsubmitJob(xmlstring = xmls, user = "mrepetto94", interface = "", id = 0))

  #cleaning the result
  Sys.sleep(2)
  result <- NgetFinalResults(obj = test)
  string <- sub(".*:=\n", "", result@ans)
  string <- sub("\n;\n\n", "", string)
  string <- gsub("\n", " ", string)
  string <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", string, perl = TRUE)
  string <- strsplit(string, " ")
  string <- unlist(string)

  mainmat[,i] <- as.numeric(matrix(string, ncol = 2, nrow = 4, byrow = TRUE)[,2])

  if ( (i%%1) == 0){
  bot$sendMessage(paste("Now processing number ", i))
  }

}
bot$sendMessage(paste("The process is complete, the files are in: ", here()))
write.csv(mainmat, file = "mainmat.csv")
storage.mode(mainmat) <- "numeric"

png("test.png")
loc1 <- data.frame(length = mainmat[1,])
loc2 <- data.frame(length = mainmat[2,])
loc3 <- data.frame(length = mainmat[3,])
loc4 <- data.frame(length = mainmat[4,])

loc1$name <- 'Location1'
loc2$name <- 'Location2'
loc3$name <- 'Location3'
loc4$name <- 'Location4'

locations <- rbind(loc1, loc2, loc3, loc4)

ggplot(locations, aes(x=length, fill = name)) +
  #geom_histogram( alpha=0.6, position="identity")
  

dev.off()
bot$sendPhoto("test.png", caption = "Resulting histogram")
