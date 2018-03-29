getresult <- function (ans, name, nc, nr){
  k<-1
  if(nc >= 2){k=2}
  
  var <- paste(name, " ", sep = "")
  resultvec <-unlist(strsplit(ans, "\n"))
  location <- grep(var, resultvec)
  value <- resultvec[(location+k):(location+nr+k-1)]
  value <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", value, perl = TRUE)
  value <- paste(value,collapse=" ")
  mat<-matrix(unlist(strsplit(value, " ")), ncol = nc+1, nrow = nr, byrow= TRUE)  
  
  return(mat)
}# The function isolate a specific parameter from the solution response in NEOS

getresultBundle  <- function (ans,name,nc,nr){
k<-1 
  var <- paste(name, " ", sep = "")
  resultvec <-unlist(strsplit(ans, "\n"))
  location <- grep(var, resultvec)
  value <- resultvec[(location+k):(location+nr+k-1)]
  value <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", value, perl = TRUE)
  value <- paste(value,collapse=" ")
  value<- gsub(pattern="[.]", replacement="0", value)
  mat<-matrix(unlist(strsplit(value, " ")), ncol = nc+2, byrow= TRUE)  
 return(mat)
}

library("ggplot2")
library("maps")
library("network")
library("sna")
library("GGally")

load("result_ch2.Rda")

entities <- unlist(strsplit("TPE EBU DUB GOA HAM BCN BRI SPL BRU CGN FRA RIX HEL CPG NTE BIO MXP FCO NAP MRS LYS TLS SXF MUC STR SZG VIE DUS MAD AGP LIS SVQ OPO ATH VNO TLL LJU NOCO", split = " "))
type <- ifelse(entities %in% "TPE", "Producer", ifelse(entities %in% c("VNO","TLL","LJU","NOCO"),"Recycler", "Distributor"))

data <- matrix(0L, nrow = length(entities), ncol = length(entities))
df  <- data.frame(data)
colnames(df)<-entities
rownames(df)<-entities

PD_Ship <- cbind("TPE",getresult(ans, "PD_Ship", nc = 1, nr = 6))

DW_WW_WR_Ship <- getresultBundle(ans,"DW_Ship", nc = 3, nr = 171)
DW_Ship  <- DW_WW_WR_Ship[,c(1,2,3)]
WW_Ship  <- DW_WW_WR_Ship[,c(1,2,5)]
WR_Ship  <- DW_WW_WR_Ship[,c(1,2,4)]

RR_Ship <- cbind(getresult(ans, "RR_Ship", nc = 1, nr = 4)[,1],
		 "TPE",
		 getresult(ans, "RR_Ship", nc = 1, nr = 4)[,2])

merge <- rbind(PD_Ship,DW_Ship,WR_Ship,RR_Ship)
merge <- merge[(merge[,3] != 0),]
i<-1
for(i in 1:dim(merge)[1]){
	indexS <- merge[i,1]
	indexR <- merge[i,2]
	#Assign value
 	df[indexS,indexR] <- df[indexS,indexR] + log(as.numeric(merge[i,3]))
}

df <- df/25
n <- network(df, ignore.eval = FALSE, names.eval="weights")
n %v% "Function" = type

ggnet2(n,
       mode = "circle",
       size = 10,
       alpha = 0.7,
       color = "Function",
       label = TRUE,
       label.size = 3,
       arrow.size = 5,
       arrow.gap = 0.025,
       edge.size="weights",
       edge.label.size=2)

ggsave(filename="network.png")
