# import the species list from a csv to the sqliteDB

library(RSQLite)
library(here)

pathSppList <- ("F:/_Howard/Projects/NatureServe_MOBI/TrackingDatabase")

dat <- read.csv(paste(pathSppList, "FINAL_SpeciesListforMoBI-Sept_5_2018.csv", sep = "/"))

dat <- dat[,c("ELEMENT_GLOBAL_ID","Broad.Group","Taxonomic.Group","Scientific.Name",
              "Common.Name","G_RANK","Rounded.G.Rank","ESA.Status","MAJOR_HAB")]

names(dat) <- c("EGT_ID","broad_group","tax_group","scientific_name","common_name",
                "g_rank","rounded_g_rank","esa_status","major_hab")

head(dat)

# special cases accounted for: hybrids (x in between names)
#     hyphenated specific epithet

dat$spCode <- sub("(^[a-z]{2,4})[a-z]* x? ?([a-z]{2,4})[a-z-]*", "\\1\\2", tolower(dat$scientific_name))
  
table(nchar(dat$spCode))

# longOnes <- spCode[nchar(spCode)>8]
# shortOnes <- spCode[nchar(spCode)<8]
length(dat$spCode)
length(unique(dat$spCode))

# this adds trailing numbers to only the second (and additional) dups, not the first. 
# I think we want the first to get a value too
#spCode.u <- make.unique(spCode, sep = ".")

# try doing it with duplicated
dat$dups <- duplicated(dat$spCode)
dupCodes <- dat$spCode[dat$dups == TRUE]

# are there any triplets? (no)
length(dupCodes)
length(unique(dupCodes))

dat[dat$dups,"dupsvals"] <- 1
#now include the un-nunbered (first set) dups
dat$dups <- dat$spCode %in% dupCodes
# replace NA with zero where needed
dat[dat$dups & is.na(dat$dupsvals), "dupsvals"] <- 0
# add one to all dups values
dat[dat$dups,"dupsvals"] <- dat$dupsvals[dat$dups] + 1
# set remaining NAs to empty before paste call
dat[is.na(dat$dupsvals), "dupsvals"] <- ""
# concatenate to spp names
dat$spCode <- paste(dat$spCode, dat$dupsvals, sep = "")

length(unique(dat$spCode))

# get rid of extra cols
dat <- within(dat, rm(dups, dupsvals))

dbLoc <- here("_data","databases")
dbName <- "SDM_lookupAndTracking.sqlite"

db <- dbConnect(SQLite(),dbname=paste(dbLoc, dbName, sep = "/"))

for(i in 14:nrow(dat)){
  SQLquery <- paste('INSERT INTO lkpSpecies ("EGT_ID","sp_code","broad_group","tax_group",
                    "scientific_name","common_name","g_rank","rounded_g_rank","esa_status",
                    "major_hab") 
                    VALUES (',
                    dat$EGT_ID[i], ', "', dat$spCode[i], '", "', dat$broad_group[i], '", "', 
                    dat$tax_group[i], '", "', 
                    dat$scientific_name[i], '", "', dat$common_name[i], '", "', dat$g_rank[i], '", "', 
                    dat$rounded_g_rank[i], '", "', dat$esa_status[i], '", "', dat$major_hab[i],
                    '");', sep = '')  
  dbSendQuery(db, SQLquery)
}

# clean up

dbDisconnect(db)









