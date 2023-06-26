#!/usr/bin/Rscript
library(xml2)
library(tidyr)
library(dplyr)
library(jsonlite)
library(data.table)
library(stringr)
library(yaml)
library(R.utils)

setwd('/home/gehau/git/codelijst-observatieprocedure/src/main/R')
#setwd('/Users/pieter/work/git/codelijst-observatieprocedure/src/main/R')

##### FUNCTIES

# functie om dataframe om te zetten naar jsonld
to_jsonld <- function(dataframe) {
  # lees context
  context <- jsonlite::read_json(jsonld_source_pad)
  # jsonld constructie
  df_in_list <- list('@graph' = dataframe, '@context' = context)
  df_in_json <- toJSON(df_in_list, auto_unbox=TRUE)
  return(df_in_json)
}

### functie om de volgende release versie juist te zetten
prompt_versie <- function(version_next_release) {
  cat(paste("Is de volgende release versie : ",version_next_release,'?\n'))
  cat(" (y/n)  : ")
  yes_or_no <- readLines("stdin",n=1);
  if ( yes_or_no == 'y') {
    return(version_next_release)
  } else if ( yes_or_no == 'n') {
    cat(" Wat is de volgende release versie?  : ")
    version_next_release <- readLines("stdin",n=1)
    prompt_versie(version_next_release)
  } else {
    cat("enter y or n\n")
    prompt_versie(version_next_release)
  }
}

prompt_update_catalog <- function(version_next_release) {
  cat(paste("Update het catalog bron bestand met (nieuwe) dataset versie records (versie ",version_next_release,')?\n'))
  cat(" (y/n)  : ")
  yes_or_no <- readLines("stdin",n=1);
  return(yes_or_no)
}

prompt_genereer_catalog <- function() {
  cat(paste("Genereer catalog metadata bestand(en)?\n"))
  cat(" (y/n)  : ")
  yes_or_no <- readLines("stdin",n=1)
  return(yes_or_no)
}

rename_columns <- function(df) {
  # rename columns
  df <- df %>%
    rename(  "@id" = id,
             "@type" = type)
  
  return(df)
}

expand_df_on_pipe <- function(df) {
  # verdubbel rijen met pipe separator
  for(col in colnames(df)) {   # for-loop over columns
    df <- df %>%
      separate_rows(col, sep = "\\|")%>%
      distinct()
  }
  return(df)
}

collapse_df_on_pipe <- function(df) {
  # group by
  if(nrow(df) == 0){
    return(df)
  }
  df3 <- df %>% select(id) %>% distinct()
  for(col in colnames(df)) {   # for-loop over columns
    if ( col != 'id') {
      df4 <- df %>% select(id, col)
      names(df4)[2] <- 'naam' # hack, geef de tweede kolom een vaste naam, summarize werkt niet met variabele namen
      df2 <- df4 %>% group_by(id) %>%
        summarize(naam = paste(sort(unique(naam)),collapse="|"))
      names(df2)[2] <- col # wijzig kolom met naam 'naam' terug naar variabele naam
      df3 <- merge(df3, df2, by = "id")
    }
  }
  df3 <- df3 %>%
    mutate_all(~na_if(., ''))
  return(df3)
}

add_package_as_distribution <- function(df) {
  #ds <- df[df$type == 'spdx:Package', ]['id']
  ds <- subset(df, type == 'spdx:Package')$id
  setDT(df)[type == "dcat:Dataset", distribution := paste(distribution,ds, sep = "|")]
  setDT(df)[type == "spdx:Package", type := paste(type,'dcat:Distribution', sep = "|")]
  
  df <- as.data.frame(df)
  return(df)
}

hasVersion_from_isVersionOf  <- function(df) {
  # hasVersion relatie uit inverse relatie
  
  datasets <- na.omit(distinct(df['isVersionOf'])) 
  for (dataset in as.list(datasets$isVersionOf)) {
    isversionof <- subset(df, isVersionOf == dataset[1] ,
                          select=c(id, isVersionOf))
    hasversion <- as.list(isversionof["id"])
    df2 <- data.frame(dataset, hasversion)
    names(df2) <- c("id","hasVersion")
    df <- bind_rows(df, df2)
  }
  return(df)
}


update_id_with_version <- function(id, version_next_release) {
  subst <- paste("\\1",".",version_next_release, sep = "")
  new_id <- gsub("(codelijst-[^.]+)", subst, id, perl=TRUE)
  return(new_id)
}

update_uri_with_version <- function(uri, version_next_release) {
  subst <- paste("\\1",".",version_next_release, sep = "")
  new_uri <- gsub("(codelijst-[^.]+)", subst, uri, perl=TRUE)
  return(new_uri)
}


update_version <- function(df) {
  setDT(df)[recordtype == RCTYPE_DSVERSIE, owl.versionInfo := version_next_release]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, issued := issued_]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, label := paste(label," (",version_next_release,")", sep = "")]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, id := update_uri_with_version(id, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, dc.identifier := update_id_with_version(dc.identifier, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, identifier := update_uri_with_version(identifier, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, distribution := update_uri_with_version(distribution, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSVERSIE, page := update_uri_with_version(page, version_next_release)]
  #setDT(df)[recordtype == RCTYPE_DSDVERSIE, owl.versionInfo := version_next_release]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, id := update_uri_with_version(id, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, dc.identifier := update_id_with_version(dc.identifier, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, identifier := update_uri_with_version(identifier, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, downloadURL := update_id_with_version(downloadURL, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, page := update_uri_with_version(page, version_next_release)]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, issued := issued_]
  #setDT(df)[recordtype == RCTYPE_DSPVERSIE, owl.versionInfo := version_next_release]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, issued := issued_]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, id := package_id]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, identifier := package_id]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, dc.identifier := paste(packageName_,version_next_release, sep = ".")]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, downloadLocation := downloadLocation_]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, downloadURL := downloadLocation_]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, packageFileName := packageFileName_]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, packageName := packageName_]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, versionInfo := version_next_release]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, label := paste("Package", artifactId, sep = " ")]
  
  
  setDT(df)[recordtype == RCTYPE_DSVERSIE, recordtype := DS_VERSIE]
  setDT(df)[recordtype == RCTYPE_DSDVERSIE, recordtype := DSD_VERSIE]
  setDT(df)[recordtype == RCTYPE_DSPVERSIE, recordtype := DSP_VERSIE]
  
  df <- df %>%
    distinct()
  df <- as.data.frame(df)
  return(df)
}

write_rdf_distributies  <- function(df, distributie_pad, distributie_naam) {
  ### Prepare RDF distributie:
  df <- subset(df, select = -c(recordtype))
  # Wat doet dit?
  df <- df %>%
    mutate_all(list(~ str_c("", .)))%>% 
    mutate_all(~na_if(., ''))

  df <- expand_df_on_pipe(df)%>%
      hasVersion_from_isVersionOf()

  ### JSONLD RDF UIT DATAFRAME
  df_in_json <- to_jsonld(df)

  tmp_file <- tempfile(fileext = ".jsonld")

  write(df_in_json, tmp_file)

  ### CLEAN RDF

  ttl_distributie <- paste(distributie_pad, distributie_naam, ".ttl", sep="")
  jsonld_distributie <- paste(distributie_pad, distributie_naam, ".jsonld", sep="")

  riot_cmd <- paste("riot --formatted=TURTLE ", tmp_file, " > ", ttl_distributie)
  system(riot_cmd)

  riot_cmd <- paste("riot --formatted=JSONLD ", ttl_distributie, " > ", jsonld_distributie)
  system(riot_cmd)
}

## READ CSV and remove spaces
f_read_csv <- function(file) {
  df <- read.csv(file, sep=",", na.strings=c("", "NA"))
  df <- df %>% mutate_if(is.character, ~str_trim(., side="both"))
  return(df)
}

## Load dataset source CSV and update with the appropriate dataset version metadata
f_load_dataset_template <- function() {
  dataset_df <- f_read_csv(file = dataset_source_pad)
  
  catalogus <- subset(dataset_df, recordtype == RCTYPE_CAT, select=c(recordtype, id, type, dataset))
  dataset_df <- subset(dataset_df, recordtype != RCTYPE_CAT)
  dataset_df <- bind_rows(dataset_df, catalogus)
  
  dataset_df <- expand_df_on_pipe(dataset_df) ## !!! else error in update_version 
  dataset_df <- update_version(dataset_df)
  #dataset_df <- collapse_df_on_pipe(dataset_df)
  return(dataset_df)
}

## Prepare and genereer datasetversie m=etadata bestanden
f_genereer_datasetversie <- function(dataset_template) {
  dataset <- subset(dataset_template, recordtype == RCTYPE_DS, select=c(recordtype, id, type))
  df <- subset(dataset_template, recordtype != RCTYPE_DS)
  df <- bind_rows(df, dataset)
  
  df <- collapse_df_on_pipe(df)
  df <- df %>% relocate(recordtype, .before = id)
  df <- df %>% arrange(recordtype, id)
  
  csv_distributie <- paste(dataset_distributie_pad, ds_distributie_naam, ".csv", sep="")
  write.csv(df, csv_distributie, row.names = FALSE, na='', fileEncoding='UTF-8')
  ## TODO hasversion
  write_rdf_distributies(df, dataset_distributie_pad, ds_distributie_naam)
}

## Update het catalog source bestand met de (nieuwe) dataset versie en de eventuele dataset wijzigingen gedaan in het dataset source bestand
f_update_catalog <- function(dataset_template) {
  catalog_df <- f_read_csv(file = catalog_source_pad)
  
  # Delete huidige records van de dataset versie die (opnieuw) gemaakt wordt als ook van de dataset zelf
  catalog_df <- subset(catalog_df,  !recordtype %in% c(RCTYPE_DS, DS_VERSIE, DSD_VERSIE, DSP_VERSIE))
  #catalog_df <- collapse_df_on_pipe(catalog_df)
  
  # Voeg dataset en nieuwe versie records uit dataset bestand toe
  if(nrow(catalog_df) == 0){
    catalog_df <- dataset_template
  }
  else {
    catalog_df <- bind_rows(catalog_df, dataset_template) %>%
      distinct()
  }
  
  # Schrijf geupdate catalog terug naar het catalog bron bestand.
  catalog_df <- collapse_df_on_pipe(catalog_df)
  catalog_df <- catalog_df %>% relocate(recordtype, .before = id)
  catalog_df <- catalog_df %>% arrange(recordtype, id)
  write.csv(catalog_df, catalog_source_pad, row.names = FALSE, na='', fileEncoding='UTF-8')
}

f_genereer_catalog <- function() {
  catalog_df <- f_read_csv(file = catalog_source_pad)
  
  catalog_df <- collapse_df_on_pipe(catalog_df)
  catalog_df <- catalog_df %>% relocate(recordtype, .before = id)
  catalog_df <- catalog_df %>% arrange(recordtype, id)
  
  csv_distributie <- paste(catalog_distributie_pad, cat_distributie_naam, ".csv", sep="")
  write.csv(catalog_df, csv_distributie, row.names = FALSE, na='', fileEncoding='UTF-8')

  ## TODO hasversion
  write_rdf_distributies(catalog_df, catalog_distributie_pad, cat_distributie_naam)
}

# START SCRIPT

## SET VARIABLES

### PARSE YML CONFIG, CMD LINE ARGS AND SET COMMON VARIABLES

config = yaml.load_file("config.yml")

catalog_distributie_pad = config$dcat$distributie_pad_catalog
dataset_distributie_pad = config$dcat$distributie_pad_dataset
jsonld_source_pad = config$dcat$jsonld_source
dataset_source_pad = config$dcat$dataset_source
catalog_source_pad = config$dcat$catalog_source
cat_distributie_naam = "catalog"
ds_distributie_naam = "dataset"

#### TODO support operations: all (create dataset bestand, update catalog source en generate catalog bestand), update catalog source, generate_catalog
operatie <- cmdArg("operatie")

cat("Config params: \n")
cat("operatie=", operatie,"\n")
cat("jsonld_source=", jsonld_source_pad,"\n")
cat("dataset_source=", dataset_source_pad,"\n")
cat("catalog_source=", catalog_source_pad,"\n")
cat("distributie_pad_catalog=", catalog_distributie_pad,"\n")
cat("distributie_pad_dataset=", dataset_distributie_pad,"\n")

artifactory = "https://repo.omgeving.vlaanderen.be/artifactory/release"

### PARSE POM.XML AND SET VARIABLES

# read pom.xml
x <- read_xml("../../../pom.xml")
xml_ns_strip( x )
groupId <- xml_text( xml_find_first(x, "/project/groupId") )
artifactId <- xml_text( xml_find_first(x, "/project/artifactId") )
version <- xml_text( xml_find_first(x, "/project/version") )
name <- xml_text( xml_find_first(x, "/project/name") )
class_path  <- gsub("\\.","/", groupId)
version_next_release <- strsplit(version, '-')[[1]][1]
version_next_release <- prompt_versie(version_next_release)
packageFileName_ <- paste(name,'-',version_next_release,'.jar', sep = "")
packageName_ <- paste(groupId, name, sep = ".")
package_id <- paste(paste("omg_package", packageName_, sep = ":"),version_next_release, sep = ".")
downloadLocation_ <- paste(artifactory, class_path, name, version_next_release, packageFileName_, sep = "/")

issued_ <- format(Sys.Date())

RCTYPE_CAT <- "CATALOG"
RCTYPE_DS <- "DATASET"
RCTYPE_DSVERSIE <- "VERSIE-DATASET"
RCTYPE_DSDVERSIE <- "VERSIE-DISTRIB"
RCTYPE_DSPVERSIE <- "VERSIE-PACKAGE"

DS_VERSIE <- str_replace(RCTYPE_DSVERSIE,"VERSIE",paste("V",version_next_release,sep = ""))
DSD_VERSIE <- str_replace(RCTYPE_DSDVERSIE,"VERSIE",paste("V",version_next_release,sep = ""))
DSP_VERSIE <- str_replace(RCTYPE_DSPVERSIE,"VERSIE",paste("V",version_next_release,sep = ""))

OP_GEN_DATASET <- "genereer_dataset"
OP_UPD_CATALOG <- "opdate_catalog_source"
OP_GEN_CATALOG <- "genereer_catalog"

## START LOGICA 

if (is.null(operatie)) {
  operatie <- "do_all"
}

### Het dataset source bestand bevat metadata op basis waarvan catalog, dataset en concrete dataset versie gemaakt worden.
print("Load dataset source csv bestand and process")
dataset_template <- f_load_dataset_template()

print("Genereer dataset metadata bestanden")
f_genereer_datasetversie(dataset_template)

if (operatie != OP_GEN_CATALOG && operatie != OP_GEN_DATASET) {
  ### Het catalog source bestand is ons admin bestand waar we de metadata bijhouden van al de versies die gepubliceerd moeten worden. Het bevat zowel de dataset metadata als metadata van de dataset versies 
  flow <- prompt_update_catalog(version_next_release)
  if (flow != 'n') {
    print("update catalog source csv bestand met dataset record en (nieuwe) versie records uit dataset source bestand..")
    f_update_catalog(dataset_template)
  }
}

if (operatie != OP_UPD_CATALOG && operatie != OP_GEN_DATASET) {
  ### Genereer catalog metadata bestanden
  flow <- prompt_genereer_catalog()
  if (flow != 'n') {
    print("genereer catalog metadata bestanden...")
    f_genereer_catalog()
  }
}

print("End")

