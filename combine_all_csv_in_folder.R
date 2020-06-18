# load libraries
library(RMySQL)
library(stringr)

# load all csv files in directory
filenames = list.files(pattern="*.csv")
files = lapply(filenames, read.csv, header=FALSE)
dfNames = str_sub(filenames, start=1, end=-5)
names(files) <- dfNames

# add features if required
filesEdit <- lapply(seq_along(files), function(y, n, i) data.frame(y[[i]], n[[i]], 1:nrow(y[[i]])), y = files, n = names(files))
filesEdit <- lapply(filesEdit, setNames, c("open", "high", "low", "close", "ticker", "order"))
names(filesEdit) <- dfNames

# combine list of data frames
filesCombined <- do.call(rbind, filesEdit)

# connect to mysql database
mydb <- dbConnect(MySQL(), 
		user = 'user', 
		password = 'password', 
		dbname = 'dbname', 
		host = 'host'
)

# write data to table
dbWriteTable(mydb, value = filesCombined, name = "ohlc_5min_interval", append = TRUE, row.names = FALSE)

# disconnect from database
dbDisconnect(mydb)
