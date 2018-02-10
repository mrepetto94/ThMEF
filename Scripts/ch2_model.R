#Main script chapter 2 model
#Using NEOS server for solving it

library("rneos")
library("fPortfolio")

options(warn = -1)

Nping()

#NlistSolversInCategory(category = "lp")

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

# Data File:
amplDataOpen("ampl") #clear the dat file

  K<-2660
  amplDataAddValue("K", K, "ampl")

  ProcV <- c(40, 60, 90, 80)
  demand <- c(1900, 1200, 1600, 600)
  amplDataAddVector("ProcV", ProcV, "ampl")
  amplDataAddVector("demand", demand, "ampl")

  cost = matrix( 
    c(0, 14, 11, 14,
      27, 0, 12, 22,
      24, 14, 0, 12,
      10, 13, 3, 0),  
      nrow=4,               
      ncol=4,               
      byrow = TRUE)
  amplDataAddMatrix("cost",cost ,"ampl")

datf <- paste(paste(readLines("ampl.dat"), collapse = "\n"), "\n")

# Run File:
comf <- c(
  "solve;",
  "display supply, supply2;",
  "option display_1col 0;",
  "display Trans;"
  )

argslist <- list(model = modf, data = datf, commands = comf, comments = "")
xmls <- CreateXmlString(neosxml = template, cdatalist = argslist)

(test <- NsubmitJob(xmlstring = xmls, user = "mrepetto94", interface = "", id = 0))

#NgetJobStatus(obj = test)

NgetFinalResults(obj = test)


