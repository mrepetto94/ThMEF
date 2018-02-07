library("eurostat")
library("rvest")
library("knitr")
library("tidyr")
library("data.table")
library("ggplot2")

dat <- get_eurostat("env_waselee", time_format = "num")
dat <- as.data.table(dat)
dat <- dat[(dat$wst_oper == "COL_HH") & (dat$unit == "KG_HAB") & (dat$wst_oper == "COL_HH") & (dat$waste == "TOTAL")]
dat<-dat[order(dat$geo),]
dat <- as.data.table(dat)[, sum(values), by = .(geo, time)]
dat <- dat[dat$geo != "EU28"]

p <- ggplot(dat, aes(time, geo)) + geom_tile(aes(fill = V1), colour = "white") + scale_fill_gradient(low = "white", high = "indianred4")

base_size <- 9

p + 
  theme_grey(base_size = base_size) + 
  labs(x = "", y = "", fill = "Collection rate%") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
