##########################
# The script creates 3 parts of the model in chapter 2, namely the .dat the .mod and the .run files
# Then wrap it in an XML object and send it to neos server
##########################

getresult <- function (result, name, nc, nr){
  k<-1
  if(nc >= 2){k=2}
  
  var <- paste(name, " ", sep = "")
  resultvec <-unlist(strsplit(result@ans, "\n"))
  location <- grep(var, resultvec)
  value <- resultvec[(location+k):(location+nr+k-1)]
  value <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", value, perl = TRUE)
  value <- paste(value,collapse=" ")
  mat<-matrix(scan(text= value), nrow = nr, ncol = nc+1, byrow = TRUE)
  mat<-mat[,-1]
  
  return(mat)
}# The function isolate a specific parameter from the solution response in NEOS

library("rneos")
library("fPortfolio")
library("telegram")
library("here")
library("ggplot2")
library("googlesheets")

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
n <- 1

# Read the data from the Gsheet EARLY IMPLEMENTATION
Sheet <- gs_url("https://docs.google.com/spreadsheets/d/1naneKBCuCWOJfBOnacVWGmNWvkRTb4oK2znkebMDPLo/edit?usp=sharing") 
PocAct <- as.numeric(gs_read(ss = Sheet, ws = 1, range = "B3:E3", col_names = FALSE))	


# Commodity data
Price <- c(11,12,13,12) #price at time zero
Volatility <-c(3,2,1.5,2.5) #volatility of the commodity on the reference market

# Data File DECLARATION of unchanged variables
D <- 3100  #number of components
# ProcAct <- c(40, 43, 46, 49) #Variable cost based on the procurement activities
ProdAct <- c(49, 46, 43, 40) #Variable cost based on the production activities
capacity <- c(1000, 1500, 1500, 1000)
cost = matrix(
  c(0,	6,	8,	12,
    6,	0,	3,	6,
    8,	3,	0,	3,
    12,	6,	3,	0),
  nrow=4,
  ncol=4,
  byrow = TRUE)

# Get the template for the solver
template<-NgetSolverTemplate(category = "go", solvername = "BARON", inputMethod = "AMPL")

# Model File:
  modf <- c(
    "set ORIG := 1..4;",
    "set DEST := 1..4;",
    "param capacity {DEST} >= 0;",
    "param K;",
    "param cost {ORIG,DEST} >= 0;",
    "param ProcV {ORIG} >= 0;",
    "param ProdV {ORIG} >= 0;",
    "check: K <= sum {j in DEST} capacity[j];",
    "var supply {ORIG} >= 0;",
    "var supply2{ORIG} >= 0;",
    "var Trans {ORIG,DEST} >= 0;",
    "var DevT >= 0;",
    "var DevProc >= 0;",
    "var DevProd >= 0;",
    "",
    "minimize Total_Deviation: DevProc + DevT + DevProd;",
    "",
    "s.t. Inbound: sum {i in ORIG} ProcV[i] * supply[i] - DevProc = 0;",
    "s.t. Transport: sum {i in ORIG, j in DEST} cost[i,j] * Trans[i,j] - DevT = 0;",
    "s.t. Operations: sum {i in ORIG} ProdV[i] * supply2[i] - DevProd = 0;",
    "",
    "s.t. Supply {i in ORIG}: sum {j in DEST} Trans[i,j] = supply[i];",
    "s.t. Capacity {j in DEST}: sum {i in ORIG} Trans[i,j] <= capacity[j];",
    "s.t. Allocation: sum {i in ORIG} supply[i]= K;",
    "s.t. Allocation2{i in ORIG}: sum {j in DEST} Trans[j,i] = supply2[i];"
  )

# Run File:
  comf <- c(
    "solve;",
    "display DevProc, DevProd, DevT;",
    "display supply;", 
    "display supply2;",
    "option display_1col 0;",
    "display Trans;"
  )

  ProcV <- ProcAct
  
  # Data File:
  amplDataOpen("ampl") #clear the dat file
  amplDataAddValue("K", K, "ampl")
  amplDataAddVector("ProcV", ProcV, "ampl")
  amplDataAddVector("ProdV", ProcAct, "ampl")
  amplDataAddVector("capacity", capacity, "ampl")
  amplDataAddMatrix("cost",cost ,"ampl")
  # Write in the variable 
  datf <- paste(paste(readLines("ampl.dat"), collapse = "\n"), "\n")

  #Pass the AMPL files to the server
  argslist <- list(model = modf, data = datf, commands = comf, comments = "")
  xmls <- CreateXmlString(neosxml = template, cdatalist = argslist)
  (test <- NsubmitJob(xmlstring = xmls, user = "mrepetto94@me.com", interface = "", id = 0))
  result <- NgetFinalResults(test)
  #cleaning the result
  objective[[i]] <- 
  as.numeric(sub("Objective ", "", unlist(strsplit(result@ans, "\n"))[grep("Objective", unlist(strsplit(result@ans, "\n")))]))
  
  supply <- getresult(result, "supply", 1, 4)
  supply2 <- getresult(result, "supply2", 1, 4)
  trans <- getresult(result, "Trans", 4, 4)

bot$sendMessage(paste("The process is complete, the files are in: ", here()))
