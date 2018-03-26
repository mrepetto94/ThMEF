getresult <- function (result, name, nc, nr){
  k<-1
  if(nc >= 2){k=2}
  
  var <- paste(name, " ", sep = "")
  resultvec <-unlist(strsplit(result, "\n"))
  location <- grep(var, resultvec)
  value <- resultvec[(location+k):(location+nr+k-1)]
  value <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", value, perl = TRUE)
  value <- paste(value,collapse=" ")
  mat<-matrix(scan(text= value), nrow = nr, ncol = nc+1, byrow = TRUE)
  mat<-mat[,-1]
  
  return(mat)
}# The function isolate a specific parameter from the solution response in NEOS


library("ggplot2")
library("maps")
library("network")
library("sna")
library("GGally")

a <- c(0,1,1,1,1,1,1,
       0,0,0,0,0,0,0,
       0,0,0,0,0,0,0,
       0,0,0,0,0,0,0,
       0,0,0,0,0,0,0,
       0,0,0,0,0,0,0,
       0,0,0,0,0,0,0)

names <- c("TPE",
	   "EBU", "DUB", "GOA", "HAM", "BCN", "BRI") 
colnames(m)<-names
rownames(m)<-names

load("result_ch2.Rda")

m <- matrix(a, nrow=(length(a)/2), byrow=TRUE)
n <- network(m, directed = TRUE)

ggnet2(n, label = TRUE, arrow.size = 12, arrow.gap = 0.025)


