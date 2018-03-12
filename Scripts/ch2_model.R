###########
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
demand  <- 1000  #number of components
s <- 3 #number of steps

# Get the template for the solver
template<-NgetSolverTemplate(category = "go", solvername = "BARON", inputMethod = "AMPL")

# Model File:
  modf <- c(
	    paste("set ORIG := 1..",n,";"),
	    paste("set DEST := 1..",n,";"),
	    paste("set STEP := 1..",s,";"),
	    #Declare the parameters
	    "param operation_capacity {DEST} >= 0;",
	    "param demand;",
	    "param transportation_cost {ORIG,DEST} >= 0;",
	   # "param inbound_cost{ORIG} >= 0;",
	    "param operation_cost{ORIG,STEP} >= 0;",
	    #Check that the demand do not overflow the capacities of each step
	    "check: demand <= sum {j in DEST} operation_capacity[j];",
	    #Decision variables
	   # "var inbound_supply {ORIG} >= 0;",
	    "var operation_supply {ORIG,STEP} >= 0;",
	    "var trans_inbound_operation {ORIG,DEST} >= 0;",
	    #Deviational variables
	    "var dev_operation{STEP} >= 0;", 
	    "var dev_transportation{STEP} >= 0;",
	    #Minimize the deviations
	    "minimize Total_Deviation: sum {i in STEP} dev_operation[i] + sum {i in STEP} dev_transportation[i];",
	    #Soft constraints operative part
	    #"s.t. Inbound: sum {i in ORIG} inbound_cost[i] * inbound_supply[i] - dev_operation[1] = 0;",
	    "s.t. Operation{j in STEP}: sum {i in ORIG} operation_cost[i,j] * operation_supply[i,j] - dev_operation[j] = 0;",
	    #"s.t. Outbound: sum {i in ORIG} outbound_cost[i] * outbound_supply[i] - dev_operation[3] = 0;",
	    #Soft constraints transportational part
	    "s.t. TransportInbound2Operation: sum {i in ORIG, j in DEST} transportation_cost[i,j] * trans_inbound_operation[i,j] - dev_transportation[1] = 0;",
	    #Hard constraints, the positivity if the deviation was already stated in the preamble
	    "s.t. Flowconservation_inbound {i in ORIG}: sum {j in DEST} trans_inbound_operation[i,j] = operation_supply[i,1];",
	    "s.t. Flowconservation_operation {i in ORIG}: sum {j in DEST} trans_inbound_operation[i,j] = operation_supply[i,2];",
	    "s.t. Capacity {j in DEST}: sum {i in ORIG} trans_inbound_operation[i,j] <= operation_capacity[j];",
	    #"s.t. Allocation_inbound: sum {i in ORIG} inbound_supply[i]= demand;",
	    "s.t. Allocation_operation{j in STEP}: sum {i in ORIG} operation_supply[i,j]= demand;"
	    
  )

# Run File:
  comf <- c(
	    "solve;",
	    "display dev_operation;",
	    "display dev_transportation;"
  )
  
#Data File:
  amplDataOpen("ampl") #clear the dat file 
  amplDataAddValue("demand", demand, "ampl")
  #amplDataAddVector("inbound_cost", data$Inbound_cost, "ampl")
  amplDataAddMatrix("operation_cost",as.matrix(data[7:9]),"ampl")
  amplDataAddVector("operation_capacity", data$Operation_capacity, "ampl")
  amplDataAddMatrix("transportation_cost",as.matrix(data[q]),"ampl")
  
#Write in the variable 
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

