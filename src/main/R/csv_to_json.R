#!/usr/bin/Rscript
library(tidyr)
library(dplyr)
library(jsonlite)
setwd("/home/gehau/git/codelijst-observatieprocedure/src/main/R")

df <- read.csv(file = "../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.csv", sep=",", na.strings=c("","NA"))
for (col in list("https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/water","https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/lucht","https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/bodem")) {
  medium <- subset(df, collection == col ,
                   select=c(uri, collection)) 
  medium_members <- as.list(medium["uri"])
  df2 <- data.frame(col, medium_members)
  names(df2) <- c("uri","member")
  df <- bind_rows(df, df2)
}
df <- df %>%
  rename("@id" = uri,
         "@type" = type)
write.csv(df,"../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure_separate_rows.csv", row.names = FALSE)
context <- jsonlite::read_json("../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/context.json")
df_in_list <- list('@graph' = df, '@context' = context)
df_in_json <- toJSON(df_in_list, auto_unbox=TRUE)
write(df_in_json, "/tmp/observatieprocedure.jsonld")

