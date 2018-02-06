library("eurostat")
library("rvest")
library("knitr")
library("tidyr")
library("data.table")

dat <- get_eurostat("env_waselee", time_format = "num")
dat <- as.data.table(dat)
dat <- dat[(dat$wst_oper == "COL_HH") & (dat$unit == "KG_HAB") & (dat$wst_oper == "COL_HH") & (dat$waste == "TOTAL")]

dat <- as.data.table(dat)[, sum(values), by = .(geo, time)]

FR <- (dat[dat$geo == "FR"])
plot(x = FR$time, y = FR$V1)
