getresult <- function (ans, name, nc, nr){
  k<-1
  if(nc >= 2){k=2}
  
  var <- paste(name, " ", sep = "")
  resultvec <-unlist(strsplit(ans, "\n"))
  location <- grep("PD_Ship ", resultvec)
  value <- resultvec[(location+k):(location+6+k-1)]
  value <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", value, perl = TRUE)
  value <- paste(value,collapse=" ")
  mat<-matrix(unlist(strsplit(value, " ")), ncol = nc+1, nrow = nr, byrow= TRUE)  
  
  return(mat)
}# The function isolate a specific parameter from the solution response in NEOS

creatematrix <- function(ans)
	rown <- ans[,1]
	coln <- ans[,2]
	data <- ans[1,3:sqrt(length(ans))]
df<-data.frame(data, row.names(rown), col.names(coln))
return(df)
}
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
	   "EBU", "DUB", "DUB", "HAM", "BCN", "BRI") 
m <- matrix(a, nrow=(sqrt(length(a))), byrow=TRUE)
colnames(m)<-names
rownames(m)<-names

m <- as.data.frame(m)

load("result_ch2.Rda")
PD_Ship <- getresult(ans, "PD_Ship", nc = 1, nr = 6)

m["TPE",] <- c(0,PD_Ship[,2])

n <- network(m, ignore.eval = FALSE, names.eval="weights")

ggnet2(n, label = TRUE, arrow.size = 12, arrow.gap = 0.025, edge.label = "weights")

# weighted adjacency matrix
bip = data.frame(event1 = c(1, 2, 1),
                 event2 = c(0, 0, 3),
                 event3 = c(1, 1, 0),
                 row.names = letters[1:3])

# weighted bipartite network
bip = network(bip,
	      directed = TRUE,
              matrix.type = "bipartite",
              ignore.eval = FALSE,
	      names.eval = "weights")


