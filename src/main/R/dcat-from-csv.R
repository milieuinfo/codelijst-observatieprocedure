library(xml2)
library(tidyr)
library(dplyr)
library(jsonlite)
library(data.table)
library(stringr)


artifactory <- "https://repo.omgeving.vlaanderen.be/artifactory/release"

# read pom.xml 
x <- read_xml("../../../pom.xml")
xml_ns_strip( x )
groupId <- xml_text( xml_find_first(x, "/project/groupId") )
artifactId <- xml_text( xml_find_first(x, "/project/artifactId") )
version <- xml_text( xml_find_first(x, "/project/version") )
name <- xml_text( xml_find_first(x, "/project/name") )

class_path  <- gsub("\\.","/", groupId) 
version_next_release <- strsplit(version, '-')[[1]][1]
version_former_release <- paste(strsplit(version_next_release, '\\.')[[1]][1],strsplit(version_next_release, '\\.')[[1]][2],as.character(as.integer(strsplit(version_next_release, '\\.')[[1]][3])-1) , sep = "."  )
packageFileName_ <- paste(name,'-',version_former_release,'.jar', sep = "")
packageName_ <- paste(groupId, name, sep = ".")
package_id <- paste("omg_package", packageName_, sep = ":")
downloadLocation_ <- paste(artifactory, class_path, name, version_former_release, packageFileName_, sep = "/")


df <- read.csv(file = "../resources/be/vlaanderen/omgeving/data/id/catalog/catalog.csv", sep=",", na.strings=c("","NA"))
setDT(df)[id == package_id, downloadLocation := downloadLocation_]
setDT(df)[id == package_id, packageFileName := packageFileName_]
setDT(df)[id == package_id, packageName := packageName_]
setDT(df)[id == package_id, versionInfo := version_former_release]
write.csv(df,"../resources/be/vlaanderen/omgeving/data/id/catalog/catalog.csv", row.names = FALSE)
df <- df %>%
  mutate_all(list(~ str_c("", .)))
for(col in 1:ncol(df)) {   # for-loop over columns
  df <- df %>%
    separate_rows(col, sep = "\\|")
}
df <- df %>% rename(
  "@id" = id,
  "@type" = type
)
context <- jsonlite::read_json("../resources/be/vlaanderen/omgeving/data/id/catalog/context.json")
df_in_list <- list('@graph' = df, '@context' = context)
df_in_json <- toJSON(df_in_list, auto_unbox=TRUE)
write(df_in_json, "/tmp/catalog.jsonld")
system("riot --formatted=TURTLE /tmp/catalog.jsonld > ../resources/be/vlaanderen/omgeving/data/id/catalog/catalog.ttl")
system("riot --formatted=JSONLD ../resources/be/vlaanderen/omgeving/data/id/catalog/catalog.ttl > ../resources/be/vlaanderen/omgeving/data/id/catalog/catalog.jsonld")

