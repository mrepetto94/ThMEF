library("ggplot2")

data  <- read.csv("GSCocc/out.csv")

p <- ggplot(data, aes(x=year, y=results)) +
	geom_bar(stat="identity") +
	xlab("Year") + ylab("Occurrence")

ggsave("occurence.png")
