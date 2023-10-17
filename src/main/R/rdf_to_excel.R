#!/usr/bin/Rscript
library(tidyr)
library(dplyr)
library(stringr)
library(xlsx)



setwd('/home/gehau/git/codelijst-observatieprocedure/src/main/R')


collapse_df_on_pipe <- function(df, id_col) {
  ## https://dplyr.tidyverse.org/articles/programming.html
  df3 <-  df %>%
    select(all_of(id_col)) %>%
    distinct()
  for(col in colnames(df)) {   # for-loop over columns
    if ( col != id_col) {
      df4 <- df %>% select(all_of(c(id_col, col)))
      names(df4)[2] <- 'naam' # hack, geef de tweede kolom een vaste naam, summarize werkt niet met variabele namen
      df2 <- df4 %>% group_by(across(all_of(id_col))) %>%
        summarize(naam = paste(sort(unique(naam)),collapse="|"))
      names(df2)[2] <- col # wijzig kolom met naam 'naam' terug naar variabele naam
      df3 <- merge(df3, df2, by = id_col)
    }
  }
  df3 <- df3 %>%
    mutate_all(~na_if(., ''))
  return(df3)
}


# sparql ttl to csv
ttl_file <- tempfile(fileext = ".ttl")
csv_file <- tempfile(fileext = ".csv")
excel_file <- "../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.xlsx"
riot_cmd <- paste("riot --formatted=TURTLE ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/*.ttl > ", ttl_file, sep="")
system(riot_cmd)
sparql_cmd <- paste("sparql --results=CSV --query ../sparql/rdf_to_excel.rq --data=", ttl_file, " > ", csv_file, sep="")
system(sparql_cmd)  
# lees csv
df <- read.csv(file = csv_file, sep=",")

df <- collapse_df_on_pipe(df, 'uri') 
df[is.na(df)] = ""
write.xlsx(df, excel_file, sheetName = 'codelijst observatieprocedure', row.names=FALSE)



