#!/usr/bin/Rscript
library(tidyr)
library(dplyr)
library(jsonlite)

df <- read.csv(file = "../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.csv", sep=",", na.strings=c("","NA"))
df <- df %>%
  separate_rows(definitions, sep = "\\|")%>%
  separate_rows(themes, sep = "\\|")%>%
  separate_rows(collections, sep = "\\|")%>%
  rename(
    definition = definitions,
    theme = themes,
    collection = collections,
    "@type" = type
  )
for (col in list("https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/water","https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/lucht","https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/bodem")) {
  medium <- subset(df, collection == col ,
                   select=c(uri, collection)) 
  medium_members <- as.list(medium["uri"])
  df2 <- data.frame(col, medium_members)
  names(df2) <- c("uri","member")
  df <- bind_rows(df, df2)
}
tco <- subset(df, topConceptOf == 'https://data.omgeving.vlaanderen.be/id/conceptscheme/observatieprocedure' ,
              select=c(uri, topConceptOf))
htc <- as.list(tco["uri"])
df2 <- data.frame('https://data.omgeving.vlaanderen.be/id/conceptscheme/observatieprocedure', htc)
names(df2) <- c("uri","hasTopConcept")
df <- bind_rows(df, df2)
df <- df %>%
  rename("@id" = uri)
write.csv(df,"../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure_separate_rows.csv", row.names = FALSE)
context <- jsonlite::read_json("../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/context.json")
df_in_list <- list('@graph' = df, '@context' = context)
df_in_json <- toJSON(df_in_list, auto_unbox=TRUE)
write(df_in_json, "/tmp/observatieprocedure.jsonld")

