#!/usr/bin/Rscript
library(tidyr)
library(dplyr)
library(jsonlite)

df <- read.csv(file = "../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.csv", sep=",", na.strings=c("","NA"))
df <- df %>%
  separate_rows(casNumbers, sep = "\\|")%>%
  separate_rows(notations, sep = "\\|")%>%
  separate_rows(altLabels, sep = "\\|")%>%
  separate_rows(exactMatches, sep = "\\|")%>%
  separate_rows(isSubjectOfs, sep = "\\|")%>%
  separate_rows(collections, sep = "\\|")%>%
  separate_rows(vmmParameterIds, sep = "\\|")%>% 
  separate_rows(types, sep = "\\|")%>% 
  rename(
    casNumber = casNumbers,
    notation = notations,
    altLabel = altLabels,
    exactMatch = exactMatches,
    isSubjectOf = isSubjectOfs,
    collection = collections,
    vmmParameterId = vmmParameterIds,
    "@type" = types
  )
for (col in list("https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/water","https://data.omgeving.vlaanderen.be/id/collection/observatieprocedure/lucht")) {
  medium <- subset(df, collection == col ,
                   select=c(uri, collection)) 
  medium_members <- as.list(medium["uri"])
  df2 <- data.frame(col, medium_members)
  names(df2) <- c("uri","member")
  df <- bind_rows(df, df2)
}
df <- df %>%
  rename("@id" = uri)
write.csv(df,"../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure_separate_rows.csv", row.names = FALSE)
context <- jsonlite::read_json("../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/context.json")
df_in_list <- list('@graph' = df, '@context' = context)
df_in_json <- toJSON(df_in_list, auto_unbox=TRUE)
write(df_in_json, "/tmp/observatieprocedure.jsonld")

