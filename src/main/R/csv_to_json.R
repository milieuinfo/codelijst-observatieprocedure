#!/usr/bin/Rscript
library(tidyr)
library(dplyr)
library(jsonlite)
library(stringr)
df <- read.csv(file = "../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.csv", sep=",", na.strings=c("","NA"))
# fix voor vctrs_error_incompatible in pubchem column
df <- df %>%
  mutate_all(list(~ str_c("", .)))
# verdubbel rijen met pipe separator
for(col in colnames(df)) {   # for-loop over columns
  df <- df %>%
    separate_rows(col, sep = "\\|")%>%
    distinct()
}
# members van collection uit "inverse" relatie
collections <- na.omit(distinct(df['collection']))
for (col in as.list(collections$collection)) {
  medium <- subset(df, collection == col ,
                   select=c(uri, collection))
  medium_members <- as.list(medium["uri"])
  df2 <- data.frame(col, medium_members)
  names(df2) <- c("uri","member")
  df <- bind_rows(df, df2)
}
# hasTopConcept relatie uit inverse relatie
schemes <- na.omit(distinct(df['topConceptOf']))
for (scheme in as.list(schemes$topConceptOf)) {
  topconceptof <- subset(df, topConceptOf == scheme ,
                         select=c(uri, topConceptOf))
  hastopconcept <- as.list(topconceptof["uri"])
  df2 <- data.frame(scheme, hastopconcept)
  names(df2) <- c("uri","hasTopConcept")
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

# serialiseer jsonld naar mooie turtle en mooie jsonld
# hiervoor dienen jena cli-tools geinstalleerd, zie README.md
system("riot --formatted=TURTLE /tmp/observatieprocedure.jsonld > ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.ttl")
system("riot --formatted=JSONLD ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.ttl > ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.jsonld")
