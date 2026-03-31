#import du fichier
vessel_total_clean <- read_csv("C:/Users/c_pre/OneDrive - yncréa/S6/Projets/Projets Outils Numériques/Semaine 2 - Big Data/vessel_data_clean_v2.csv")

#Description par R des colonnes du tableau (à corriger bien sur)
summary(vessel_total_clean)

#VARIABLES QUANTITATIVES
# Variance pour des colonnes spécifiques 
variance_values <- sapply(vessel_total_clean[, c("LAT", "LON", "SOG", "COG", "Heading", "Length", "Width", "Draft")], var, na.rm = TRUE)
print(variance_values)


#VARIABLES QUALITATIVES
# Variables qualitatives après recherches
qual_vars <- c("id", "MMSI", "VesselName", "IMO", "CallSign", 
               "VesselType", "Status", "Cargo", "TransceiverClass")

# Nombre de modalités uniques
sapply(vessel_total_clean[ , qual_vars], function(x) length(unique(x)))
#--> je vois que ca vaut le coup d'afficher celles de VesselType, Status, Cargo et TransceiverClass

#Maintenant je vais convertir en facteur pour les 4 catégories
vessel_total_clean[ , qual_vars] <- lapply(vessel_total_clean[ , qual_vars], function(x) {
  if (length(unique(x)) < 30) {
    return(as.factor(x))
  } else {
    return(x)
  }
})

# Voir les modalités pour les colonnes qui sont maintenant des facteurs
lapply(vessel_total_clean[ , qual_vars], function(x) {
  if (is.factor(x)) {
    return(levels(x))
  } else {
    return(NULL)
  }
})


# Pour chaque variable qualitative (factor) dans le dataframe , afficher le nombre d'occurrences par modalité
lapply(vessel_total_clean[, qual_vars], function(x) {
  if (is.factor(x)) {
    # Table de fréquence des modalités
    freq_table <- table(x)
    return(freq_table)
  } else {
    return(NULL)
  }
})









