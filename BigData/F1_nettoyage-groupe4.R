# Nettoyage des données
#   • Valeurs manquantes, valeurs aberrantes
#   • Doublons

library(questionr)
vessel_total_clean <- read_csv("Dossier de données-20250610/vessel-total-clean.csv") #importation des données csv
head(vessel_total_clean) #affiche le début des données 
cat("nb de ligne:",nrow(vessel_total_clean), "\n")

#######################################################################################################################

###Fonctions###

#fonction pour détecter les outliers (selon la méthode IQR)
is_outlier <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR_val <- Q3 - Q1
  lower <- Q1 - 1.5 * IQR_val
  upper <- Q3 + 1.5 * IQR_val
  (x < (Q1 - 1.5 * IQR_val)) | (x > (Q3 + 1.5 * IQR_val))
}

#fonction qui converti les colonne en numérique
conversion_numeric <- function(data, col_name) {
  data[[col_name]] <- as.numeric(data[[col_name]])
  return(data) 
}

#######################################################################################################################

###Valeurs manquantes###
#remplacer les valeurs manquantes par la moyenne si il n'y a peu de valeur abérente 
#sinon par la mediane 
#ou si les valeurs manquantes sont inf a 5% supprimer 

#remplacer "\N" par NA
for (col in names(vessel_total_clean)) { 
  if (is.character(vessel_total_clean[[col]])) {
    vessel_total_clean[[col]][vessel_total_clean[[col]] == "\\N"] <- NA
  }
  else if (is.numeric(vessel_total_clean[[col]]) || is.integer(vessel_total_clean[[col]])) {
    col_as_char <- as.character(vessel_total_clean[[col]]) # Convertir en character pour tester les valeurs
    non_numeric <- !grepl("^[-+]?[0-9]*\\.?[0-9]+$", col_as_char) & !is.na(col_as_char) 
    #renvoir TRUE si c'est une chaine de carractaire en ne prenant pas en compte 'NA'
    vessel_total_clean[[col]][non_numeric] <- NA
  }
}

head(vessel_total_clean) #vérifie on a bien remplacer par NA
questionr::freq.na(vessel_total_clean) #affiche le nb et le pourcentage 

#créer une copie du dataframe pour les modifications
vessel_clean_final <- vessel_total_clean

#conversion de Length, Width, Draft
vessel_clean_final <- conversion_numeric(vessel_clean_final, "Length")
vessel_clean_final <- conversion_numeric(vessel_clean_final, "Width")
vessel_clean_final <- conversion_numeric(vessel_clean_final, "Draft")

#résumé des changements de NA
resumer_na <- data.frame()

#remplacer NA 
for (col in names(vessel_clean_final)) {
  #initialisation des variables par defautl du resumer pour chaque colonne
  nb_na <- sum(is.na(vessel_clean_final[[col]]))
  na_rate <- nb_na / nrow(vessel_clean_final)
  nb_lignes_avant <- nrow(vessel_clean_final)
  outlier_rate <- 0
  traitement <- "Aucun"
  
  #colonnes numériques
  if (is.numeric(vessel_clean_final[[col]])) {
    #calcul des outliers sans les valeurs NA
    non_na_values <- vessel_clean_final[[col]][!is.na(vessel_clean_final[[col]])]
    if (length(non_na_values) > 0) {
      outliers <- sum(is_outlier(non_na_values))
      outlier_rate <- outliers / length(non_na_values)
    }
    
    #traitement des NA
    if (na_rate > 0 & na_rate < 0.05) {
      #supprime si <5% de NA
      vessel_clean_final <- vessel_clean_final[!is.na(vessel_clean_final[[col]]), ]
      traitement <- "Lignes supprimées"
    } 
    else if (na_rate >= 0.05) {
      #remplace par la moyenne si peu d'abérence
      if (outlier_rate < 0.05) {
        mean_val <- mean(vessel_clean_final[[col]], na.rm = TRUE)
        vessel_clean_final[[col]][is.na(vessel_clean_final[[col]])] <- mean_val
        traitement <- paste("Remplacé par moyenne:", round(mean_val, 2))
      } 
      else {
        #sinon remplace par la médiane
        med_val <- median(vessel_clean_final[[col]], na.rm = TRUE)
        vessel_clean_final[[col]][is.na(vessel_clean_final[[col]])] <- med_val
        traitement <- paste("Remplacé par médiane:", round(med_val, 2))
      }
    }
  }
  
  #colonnes qualitatives
  if (is.character(vessel_clean_final[[col]])) {
    if (na_rate > 0 & na_rate < 0.05) {
      #supprime si <5% de NA
      vessel_clean_final <- vessel_clean_final[!is.na(vessel_clean_final[[col]]), ]
      traitement <- "Lignes supprimées"
    } else if (any(is.na(vessel_clean_final[[col]]))) {
      vessel_clean_final[[col]][is.na(vessel_clean_final[[col]])] <- "INCONNUE"
      traitement <- "Remplacé par 'INCONNUE'"
    }
  }
  
  #mise à jour du résumé
  resumer_na <- rbind(resumer_na, data.frame(Colonne = col,
  Type = class(vessel_clean_final[[col]])[1],
  nb_NA = nb_na,
  pourcentage_NA = round(na_rate*100, 2),
  Outlier_percent = round(outlier_rate*100, 2),
  Lignes_avant = nb_lignes_avant,
  Lignes_apres = nrow(vessel_clean_final),
  Traitement = traitement))

}

#affichage des résultats
print(resumer_na)
cat("\nNombre final de lignes:", nrow(vessel_clean_final), "\n")

#vérification des NA restants
cat("\nValeurs manquantes après traitement:\n")
print(questionr::freq.na(vessel_clean_final))
head(vessel_clean_final)
cat("nb de ligne:",nrow(vessel_clean_final), "\n")

#calcul du pourcentage de lignes supprimées
pourcentage_supprime <- (1 - nrow(vessel_clean_final)/nrow(vessel_total_clean)) * 100
cat("Pourcentage supprimé:", round(pourcentage_supprime, 2), "%\n")

#######################################################################################################################

###Valeurs aberrantes - mehtodes des IQR (interquartile)###
#remplacer valeurs aberentes

#il faut exclure du traitement les données LAT,LON,MMSI car il ne peuvent pas avoir de valeur abérentes
exclu <- c("MMSI", "LAT", "LON")


#résumé des changements des abérations
resumer_aberation <- data.frame()

for (col in names(vessel_clean_final)) {
  #initialisation des variables par defautl du resumer pour chaque colonne
  nb_outliers <- 0
  outlier_rate <- 0
  traitement <- "Aucun"
  valeur_remplacement <- NA
  
  #exclure les colonnes spécifiques
  if (col %in% exclu) {
    traitement <- "exclu"
    resumer_aberation <- rbind(resumer_aberation,
    data.frame(
    Colonne = col,
    Type = class(vessel_clean_final[[col]])[1],
    Outliers_count = 0,
    Outlier_percent = 0,
    Valeur_remplacement = "N/A",
    Traitement = traitement
 )
    )
    next
  }
  
  #colonnes numériques
  if (is.numeric(vessel_clean_final[[col]])) {
    # Extraction des valeurs non-NA
    values <- vessel_clean_final[[col]]
    non_na_values <- values[!is.na(values)]
    
    if (length(non_na_values) > 0) {
      outliers <- is_outlier(non_na_values)
      nb_outliers <- sum(outliers)
      outlier_rate <- nb_outliers / length(non_na_values)
      
      # Traitement des aberations
      if (nb_outliers > 0) {
        # Valeurs non-outliers pour calcul
        clean_values <- non_na_values[!outliers]
        
        if (outlier_rate < 0.05) {
          #remplacer par la moyenne si peu d'outliers
          mean_val <- mean(clean_values, na.rm = TRUE)
          vessel_clean_final[[col]][outliers] <- mean_val
          traitement <- "Remplacé par moyenne"
          valeur_remplacement <- mean_val
        } else {
          #remplacer par la médiane si beaucoup d'outliers
          med_val <- median(clean_values, na.rm = TRUE)
          vessel_clean_final[[col]][outliers] <- med_val
          traitement <- "Remplacé par médiane"
          valeur_remplacement <- med_val
        }
      }
    }
  }
  
  #mise à jour du résumé
  resumer_aberation <- rbind(resumer_aberation,
  data.frame(Colonne = col,
  Type = class(vessel_clean_final[[col]])[1],
  Outliers_count = nb_outliers,
  Outlier_percent = round(outlier_rate*100, 2),
  Valeur_remplacement = ifelse(is.na(valeur_remplacement), 
  "N/A", 
  round(valeur_remplacement, 2)),
  Traitement = traitement))
}

#affichage des résultats
cat("\nTraitement des valeurs aberrantes:\n")
print(resumer_aberation)

#vérifier s'il ne reste plus aucun valeurs abérentes
cat("version sans valeurs aberantes : \n")
head(vessel_clean_final)
cat("nb de ligne:",nrow(vessel_clean_final), "\n")

#calcul du pourcentage de lignes supprimées
pourcentage_supprime <- (1 - nrow(vessel_clean_final)/nrow(vessel_total_clean)) * 100
cat("Pourcentage supprimé:", round(pourcentage_supprime, 2), "%\n")


#######################################################################################################################

###Doublons###

vessel_clean_final <- unique(vessel_clean_final)
cat("version final : \n")
head(vessel_clean_final)
cat("nb de ligne:",nrow(vessel_clean_final), "\n")

#calcul du pourcentage de lignes supprimées
pourcentage_supprime <- (1 - nrow(vessel_clean_final)/nrow(vessel_total_clean)) * 100
cat("Pourcentage supprimé:", round(pourcentage_supprime, 2), "%\n")

#######################################################################################################################

###Exportation###

write_csv(vessel_clean_final, "vessel_data_clean_v2.csv")
