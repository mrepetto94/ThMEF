#Main script chapter 2 model
#Using NEOS server for solving it

library("rneos")

setwd("~/Documents/Git/ThMEF/R_script")

Nping()

oldw <- getOption("warn")
options(warn = -1)

NlistSolversInCategory(category = "go")

template<-NgetSolverTemplate(category = "go", solvername = "BARON", inputMethod = "AMPL")

modf <- paste(paste(readLines("modelch2.mod"), collapse = "\n"), "\n")
datf <- paste(paste(readLines("modelch2.dat"), collapse = "\n"), "\n")
comf <- paste(paste(readLines("modelch2.run"), collapse = "\n"), "\n")

argslist <- list(model = modf, data = datf, commands = comf, comments = "")
xmls <- CreateXmlString(neosxml = template, cdatalist = argslist)

(test <- NsubmitJob(xmlstring = xmls, user = "mrepetto94@me.com", interface = "", id = 0))

Sys.sleep(20)

NgetJobStatus(obj = test)

NgetFinalResults(obj = test)

options(warn = oldw)
