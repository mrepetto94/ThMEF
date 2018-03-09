############
# The script creates 3 parts of the model in chapter 2, namely the .dat the .mod and the .run files
# Then wrap it in an XML object and send it to neos server
############

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
library("ggplot2")
library("here")
library("googlesheets")

# Start routine
setwd(here())

# Ping the neos server
Nping()

# Read the data from the Gsheet EARLY IMPLEMENTATION
sheet<- gs_url("https://docs.google.com/spreadsheets/d/1naneKBCuCWOJfBOnacVWGmNWvkRTb4oK2znkebMDPLo/edit?usp=sharing") 

data  <- gs_read(ss = sheet, ws = 1, range = "A1:AB11", col_names = TRUE)	

n <- length(data$N_entity)

q <- (length(data) - n + 1) : (length(data)) #index of the transportation matrix

demand  <- 2540000  #number of components

# Get the template for the solver
template<-NgetSolverTemplate(category = "go", solvername = "BARON", inputMethod = "AMPL")

# Model File:
  modf <- c(
    paste("set ORIG := 1..",n,";"),
    paste("set DEST := 1..",n,";"),
    "",
    "param operation_capacity {DEST} >= 0;",
    "param demand;",
    "param transportation_cost {ORIG,DEST} >= 0;",
    "param inbound_cost{ORIG} >= 0;",
    "param operation_cost{ORIG} >= 0;",
    "",
    "check: demand <= sum {j in DEST} operation_capacity[j];",
    "",
    "var inbound_supply {ORIG} >= 0;",
    "var operation_supply {ORIG} >= 0;",
    "",
    "var trans_inbound_operation {ORIG,DEST} >= 0;",
    #"var DevT >= 0;",
    "var dev_inbound >= 0;",
    "var dev_transportation_inb_opt >= 0;",
    "var dev_operation >= 0;",
    "",
    "minimize Total_Deviation: dev_inbound + dev_operation  + dev_transportation_inb_opt;",
    "",
    "s.t. Inbound: sum {i in ORIG} inbound_cost[i] * inbound_supply[i] - dev_inbound = 0;",
    "s.t. Operation: sum {i in ORIG} operation_cost[i] * operation_supply[i] - dev_operation = 0;",
    "s.t. TransportInbound2Operation: sum {i in ORIG, j in DEST} transportation_cost[i,j] * trans_inbound_operation[i,j] - dev_transportation_inb_opt = 0;",
        "",
    #"s.t. Supply {i in ORIG}: sum {j in DEST} Trans[i,j] = supply[i];",
    "s.t. Capacity {j in DEST}: sum {i in ORIG} trans_inbound_operation[i,j] <= operation_capacity[j];",
    "s.t. Allocation1: sum {i in ORIG} inbound_supply[i]= demand;",
    "s.t. Allocation2: sum {i in ORIG} operation_supply[i]= demand;"
    #"s.t. Allocation2{i in ORIG}: sum {j in DEST} Trans[j,i] = supply2[i];"
  )

# Run File:
  comf <- c(
    "solve;",
    "display dev_inbound;",
    "display inbound_supply;",
    "display operation_supply;",
    "display trans_inbound_operation;"
  )
  
  # Data File:
  amplDataOpen("ampl") #clear the dat file 
  amplDataAddValue("demand", demand, "ampl")
  amplDataAddVector("inbound_cost", data$Inbound_cost, "ampl")
  amplDataAddVector("operation_cost", data$Operation_cost, "ampl")
  amplDataAddVector("operation_capacity", data$Operation_capacity, "ampl")
 amplDataAddMatrix("transportation_cost",as.matrix(data[q]),"ampl")
  
  # Write in the variable 
  datf <- paste(paste(readLines("ampl.dat"), collapse = "\n"), "\n")

  #Pass the AMPL files to the server
  argslist <- list(model = modf, data = datf, commands = comf, comments = "")
  xmls <- CreateXmlString(neosxml = template, cdatalist = argslist)
  (test <- NsubmitJob(xmlstring = xmls, user = "mrepetto94@me.com", interface = "", id = 0))
  
  result <- NgetFinalResults(test)
 
  #cleaning the result
  #supply <- getresult(result, "supply", 1, 4)
  #supply2 <- getresult(result, "supply2", 1, 4)
  #trans <- getresult(result, "Trans", 4, 4)

