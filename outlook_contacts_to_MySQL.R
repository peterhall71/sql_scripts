# start by exporting outlook contacts as csv, no additional preprocessing necessary
# the cleaner the fields are in outlook the easier the next steps will be

# workspace prep
library(RMySQL)
library(stringr)

# load data and review
oc <- read.csv("ahccontacts.csv", na.strings=c("","NA"))
str(oc)
summary(oc)

# review attributes for data issues
levels(oc$First.Name)
levels(oc$Middle.Name)
levels(oc$Company) # check for duplicates
levels(oc$Department) # check for duplicatescol
levels(oc$Notes)
levels(oc$Business.Street) # addresses will most likely need cleaning if not structured properly in outlook

# select columns to be imported to sql
ocFinal <- oc[ , c(
		"First.Name", 
		"Middle.Name", 
		"Last.Name", 
		"Company", 
		"Department", 
		"Job.Title", 
		"Business.Phone", 
		"Mobile.Phone", 
		"Home.Phone", 
		"E.mail.Address", 
		"E.mail.2.Address", 
		"Business.Street", 
		"Business.City",
		"Business.State", 
		"Business.Postal.Code", 
		"Business.Country.Region", 
		"Business.Fax"
)]

# remove any records you do not want to be imported
ocFinal <- ocFinal[order(ocFinal$Last.Name), ]
rownames(ocFinal) <- seq(length=nrow(ocFinal))
ocFinal[ , c(1, 3, 4)]
ocFinalTrim <- ocFinal[-c(2:3, 6, 9, 12:13, 19, 25:27, 31, 33:38, 40:42, 45, 48, 51, 56:57, 62, 64, 66, 68:69, 72:73, 75, 77, 80:82, 84, 88:90, 94, 97, 99, 104, 109, 112, 115, 118, 120:124, 132:136, 148, 149, 152, 158, 161, 164, 166:167, 171:175), ]
rownames(ocFinalTrim) <- seq(length=nrow(ocFinalTrim))

# separate out peoples companies for separate table that links with foreign key
# company phone and address is being listed as NA for now
companies <- data.frame(
		companyname = levels(ocFinalTrim$Company), 
		"phone" = NA, 
		"streetphysical" = NA, 
		"cityphysical" = NA, 
		"statephysical" = NA, 
		"zipcodephysical" = NA, 
		"countryphysical" = NA
)
rownames(companies) <- NULL

# connect to mysql database and write data
mydb = dbConnect(MySQL(), 
		user = 'user', 
		password = 'password', 
		dbname = 'dbname', 
		host = 'host'
)
dbWriteTable(mydb, value = companies, name = "ahc_company", append = TRUE, row.names = FALSE)

# retrieve auto generated company ids and rename column
compids <- dbReadTable(mydb, name = "ahc_company")
compids <- compids[ , 1:2]
colnames(compids) <- c("companyid", "Company")

# merge customer df and compids df
# this way in the MySQL database the company and customer tables are linked by foreign key companyid
ocMerge <- merge(ocFinalTrim, compids, by = "Company")

# remove special characters and white space from phone numbers
ocMerge[ , c(7:9, 17)] <- sapply(ocMerge[ , c(7:9, 17)], str_replace_all, pattern = c("\\-|\\(|\\)|\\+| "), replacement = "")

# prep dataframe for writing to MySQL
ocMerge <- ocMerge[ , -1]
colnames(ocMerge) <- c(
		"firstname", 
		"middlename", 
		"lastname", 
		"department", 
		"title", 
		"phonework", 
		"phonealt", 
		"phonepersonal", 
		"emailwork", 
		"emailalt", 
		"streetmailing", 
		"citymailing", 
		"statemailing", 
		"zipcodemailing", 
		"countrymailing", 
		"faxwork", 
		"companyid"
)

# write contact data to MySQL and close connection
dbWriteTable(mydb, value = ocMerge, name = "ahc_customer", append = TRUE, row.names = FALSE)
dbDisconnect(mydb)

