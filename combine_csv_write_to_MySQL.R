# load libraries
library(RMySQL)

# read in individual csv files
aapl <- read.csv("AAPL.csv", header=FALSE)
mu <- read.csv("MU.csv", header=FALSE)
pbr <- read.csv("PBR.csv", header=FALSE)
tt <- read.csv("T.csv", header=FALSE)

# add features if required
aapl <- data.frame(aapl, "aapl", 1:nrow(aapl))
mu <- data.frame(mu, "mu", 1:nrow(mu))
pbr <- data.frame(pbr, "pbr", 1:nrow(pbr))
tt <- data.frame(tt, "t", 1:nrow(tt))

# add column names to each dataframe
colnames(aapl) <- c("open", "high", "low", "close", "ticker", "order")
colnames(mu) <- c("open", "high", "low", "close", "ticker", "order")
colnames(pbr) <- c("open", "high", "low", "close", "ticker", "order")
colnames(tt) <- c("open", "high", "low", "close", "ticker", "order")

# combine individual data frames
dat <- data.frame(rbind(aapl, mu, pbr, tt))
str(dat)

# connect to mysql database
mydb <- dbConnect(MySQL(), 
		user = 'user', 
		password = 'pasword', 
		dbname = 'dbname', 
		host = 'host'
)

# write data to table
dbWriteTable(mydb, value = dat, name = "ohlc_1min_interval", append = TRUE, row.names = FALSE)

# disconnect from database
dbDisconnect(mydb)
