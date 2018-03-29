#
# The script sends 3 part of the model in chapter 2, namely the .dat the .mod and the .run files
# Then wrap it in an XML object and send it to neos server
#

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

NauthenticatedSubmitJob <- function (xmlstring, user, password, interface = "", id = 0, nc = CreateNeosComm()){
    if (requireNamespace("XMLRPC", quietly = TRUE)) {
        if (!(class(nc) == "NeosComm")) {
            stop("Object provided for 'nc' must be of class 'NeosComm'")
        }
        call <- match.call()
        ans <- XMLRPC::xml.rpc(url = nc@url, method = "authenticatedSubmitJob", .args = list(xmlstring = xmlstring, user = user, password = password, interface = interface), .convert = TRUE, .opts = nc@curlopts, .curl = nc@curlhandle)
        res <- new("NeosJob", jobnumber = ans[[1]], password = ans[[2]], method = "authenticatedSubmitJob", call = call, nc = nc)
        return(res)
    }
    else {
        stop("Package 'XMLRPC' not available, please install first from
Omegahat.")
    }
} #function to get call authenticatedJobsubmit provided by Bernhard Pfaff 

NgetSolverTemplateCPLEX<- function (category = "lp", solvername = "CPLEX", inputMethod = "AMPL"){
	nc  <- CreateNeosComm()
	call <- match.call()
	ans <- XMLRPC::xml.rpc(url = nc@url, method = "getSolverTemplate",
            .args = list(category = "lp", solvername = "CPLEX",
                inputMethod = "AMPL"), .convert = TRUE,
            .opts = nc@curlopts, .curl = nc@curlhandle)
	ans <-paste(substr(ans, 1, nchar(ans)-13),
		     "\n<email><![CDATA[\n...Insert Value Here...\n]]></email>\n",
		     "\n</document>\n", sep ="")
        xml <- xmlRoot(xmlTreeParse(ans, asText = TRUE))
        res <- new("NeosXml", xml = xml, method = "getSolverTemplate",
            call = call, nc = nc)
	return(res)
}

library("rneos")

library("ggplot2")

# Ping the neos server
Nping()

# Get the template for the solver
template<-NgetSolverTemplateCPLEX(category = "lp", solvername = "CPLEX", inputMethod = "AMPL")

# Model File:
modf <- paste(paste(readLines("AMPLmodel/ampl.mod"), collapse = "\n"), "\n")
  
# Run File
comf <- paste(paste(readLines("AMPLmodel/ampl.run"), collapse = "\n"), "\n")

# Data File and weights 
we <-c(0.11,0.08,0.04,0.57,0.20)

datf <- paste(paste(readLines("AMPLmodel/ampl.dat"), collapse = "\n"), "\n")
weight <- paste(sep="","param we :=\n","\t1\t",we[1],",\t2\t",we[2],",\t3\t",we[3],",\t4\t",we[4],",\t5\t",we[5],";")
datf <- paste(datf, weight)

#Pass the AMPL files to the server
argslist <- list(model = modf, data = datf, commands = comf, email = Sys.getenv("NeosMail") ,comments = "")
xmls <- CreateXmlString(neosxml = template, cdatalist = argslist)
#(test <- NsubmitJob(xmlstring = xmls, user = "mrepetto94@me.com", interface = "", id = 0))

(test <- NauthenticatedSubmitJob(xmlstring = xmls, user = Sys.getenv("NeosName"), password = Sys.getenv("NeosPW")))

result <- NgetFinalResults(test)
ans <- result@ans
save(ans,file = "result_ch2.Rda") 
#ratio  <- getresult(result,"obj", 1,5)

