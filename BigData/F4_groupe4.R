
# Chargement des packages
library(ggplot2)
library(dplyr)
library(MASS)
library(readr)
library(corrplot)
library(RColorBrewer)

#Chargement des données
#file.exists("C:/Users/BEAUSSIER/Downloads/vessel_data_clean.csv")
vessel_total_clean_v2 <- read_csv("C:/Users/BEAUSSIER/Downloads/vessel_data_clean_v2.csv")

#fonctionnalité 4 - Etude des corrélation entre variable 

#1) Variable Quantitative & Variable Quantitative

#Etude des liens entre 2 variables quantitatives 
  #Etape à suivre : 
    #1) Représentation graphique : le nuage de point{(x,y)}
    #2)Calcul de la corrélation de Pearson et en déduire le type de la liaison
#il faut faire le calcul de la corrélation et en déduire s'il y a un lien 
#faire toute les quantitatives ensembles 
#matrice de corrélation ?

# Sélection des variables quantitatives
vars_quanti <- vessel_total_clean_v2[, c("LAT", "LON", "SOG", "COG", "Heading", "Length", "Width", "Draft")]

# Matrice de corrélation de Pearson
mat_corr <- cor(vars_quanti, use = "complete.obs", method = "pearson")
print(mat_corr)

# Matrice graphique de corrélation
corrplot(mat_corr, method = "color", type = "upper", 
         tl.col = "black", tl.srt = 45, addCoef.col = "black")

# LAT vs LON
#ggplot(vessel_total_clean, aes(x = LON, y = LAT)) +
 # geom_point(alpha = 0.3, color = "steelblue") +
  #geom_smooth(method = "lm", color = "red", se = FALSE) +
  #labs(title = "Nuage de points : Latitude vs Longitude",
   #    x = "Longitude",
    #   y = "Latitude") +
  #theme_minimal()
#################################################################
#Droite de régression Width et Length

# Échantillonnage : 1 ligne sur 1000
vessel_sample <- vessel_total_clean_v2[seq(1, nrow(vessel_total_clean_v2), by = 1000), ]

# Nuage de points avec droite de régression entre Draft et heading
lm_Width_length <- lm(Length ~ Width, data = vessel_sample)
summary(lm_Width_length )  #Affichage du résumé statistique du modèle de regression

#affichage de la droite de régression
ggplot(vessel_sample, aes(x = Width, y = Length)) +
  geom_point(alpha = 0.5, color = "black") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Régression linéaire : Length en fonction de Width",
    x = "Width",
    y = "Length"
  ) +
  theme_minimal()


# les point qui sont autour se rassemble pour former un point
# Prends une valeur sur 500 pour que ça aille plus vite 

#################################################################
#Droite de régression Draft et LAT

# Échantillonnage : 1 ligne sur 1000
vessel_sample <- vessel_total_clean_v2[seq(1, nrow(vessel_total_clean_v2), by = 1000), ]

# Nuage de points avec droite de régression entre Draft et heading
lm_Draft_LAT <- lm(LAT ~ Draft, data = vessel_sample)
summary(lm_Draft_LAT )  #Affichage du résumé statistique du modèle de regression

#affichage de la droite de régression
ggplot(vessel_sample, aes(x = Draft, y = LAT)) +
  geom_point(alpha = 0.5, color = "black") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Régression linéaire : LAT en fonction de Draft",
    x = "Draft",
    y = "LAT"
  ) +
  theme_minimal()

#################################################################
#Droite de régression Draft et Width

# Échantillonnage : 1 ligne sur 1000
vessel_sample <- vessel_total_clean_v2[seq(1, nrow(vessel_total_clean_v2), by = 1000), ]

# Nuage de points avec droite de régression entre Draft et heading
lm_Width_Draft <- lm(Width ~ Draft , data = vessel_sample)
summary(lm_Width_Draft)  #Affichage du résumé statistique du modèle de regression

#affichage de la droite de régression
ggplot(vessel_sample, aes(x = Width, y = Draft)) +
  geom_point(alpha = 0.5, color = "black") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Régression linéaire : Width en fonction de Draft",
    x = "Draft",
    y = "Width"
  ) +
  theme_minimal()

#################################################################
#Droite de régression Length et Heading

# Échantillonnage : 1 ligne sur 1000
vessel_sample <- vessel_total_clean_v2[seq(1, nrow(vessel_total_clean_v2), by = 1000), ]

# Nuage de points avec droite de régression entre Draft et heading
lm_Length_Heading <- lm(Length ~ Heading , data = vessel_sample)
summary(lm_Length_Heading)  #Affichage du résumé statistique du modèle de regression

#affichage de la droite de régression
ggplot(vessel_sample, aes(x = Heading, y = Length)) +
  geom_point(alpha = 0.5, color = "black") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Régression linéaire : Length en fonction de Heading",
    x = "Heading",
    y = "Length"
  ) +
  theme_minimal()

#################################################################
#Droite de régression heading et Width

# Échantillonnage : 1 ligne sur 1000
vessel_sample <- vessel_total_clean_v2[seq(1, nrow(vessel_total_clean_v2), by = 1000), ]

# Nuage de points avec droite de régression entre Draft et heading
lm_Width_Heading <- lm(Width ~ Heading , data = vessel_sample)
summary(lm_Width_Heading)  #Affichage du résumé statistique du modèle de regression

#affichage de la droite de régression
ggplot(vessel_sample, aes(x = Heading, y = Width)) +
  geom_point(alpha = 0.5, color = "black") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Régression linéaire : Width en fonction de Heading",
    x = "Heading",
    y = "Width"
  ) +
  theme_minimal()

#################################################################
#Droite de régression Length et SOG

# Échantillonnage : 1 ligne sur 1000
vessel_sample <- vessel_total_clean_v2[seq(1, nrow(vessel_total_clean_v2), by = 1000), ]

# Nuage de points avec droite de régression entre Draft et heading
lm_Length_SOG <- lm(Length ~ SOG , data = vessel_sample)
summary(lm_Length_SOG)  #Affichage du résumé statistique du modèle de regression

#affichage de la droite de régression
ggplot(vessel_sample, aes(x = SOG, y = Length)) +
  geom_point(alpha = 0.5, color = "black") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Régression linéaire : Length en fonction de SOG",
    x = "SOG",
    y = "Length"
  ) +
  theme_minimal()

# les point qui sont autour se rassemble pour former un point
# Prends une valeur sur 500 pour que ça aille plus vite 
########################################################################################
#1) Variable Qualitative & Variable Qualitative

          # TransceiverClass & VesselType
# Étape 1 : Nettoyage de la colonne TransceiverClass
vessel_total_clean_v2$TransceiverClass <- gsub(";", "", vessel_total_clean_v2$TransceiverClass)  # Enlève le point-virgule

# Étape 2 : Création du tableau croisé
tab_croise_transceiverclass <- table(vessel_total_clean_v2$VesselType, vessel_total_clean_v2$TransceiverClass)
print(tab_croise_transceiverclass)

# Étape 3 : Test du chi²
test_chi2 <- chisq.test(tab_croise_transceiverclass)
print(test_chi2)

# Étape 4 : Visualisation avec un mosaicplot
mosaicplot(tab_croise_transceiverclass,
           main = "Mosaicplot : VesselType vs TransceiverClass",
           xlab = "Vessel Type",
           ylab = "Transceiver Class",
           color = TRUE,
           las = 2,
           cex.axis = 0.7)
ggsave("mosaique_TransceiverClass_VS_VesselType.png", width = 8, height = 6)

unique(vessel_total_clean_v2$TransceiverClass)


###################################################################################"
            
            #  Status & VesselType 

# Création du tableau croisé
tab_vtype_status <- table(vessel_total_clean_v2$VesselType, vessel_total_clean_v2$Status)
print(tab_vtype_status)

# Test du chi² d’indépendance
test_chi2_vtype_status <- chisq.test(tab_vtype_status)
print(test_chi2_vtype_status)

# Visualisation avec un mosaicplot
mosaicplot(tab_vtype_status,
           main = "Mosaicplot : VesselType vs Status",
           xlab = "Vessel Type",
           ylab = "Status",
           color = TRUE,
           las = 2,
           cex.axis = 0.7)
# Légende
legend("topright", legend = "status",
       title = "Status", cex = 0.8)



#################################################################################
#VARIABLE QUANTITATIF ET QUALITATIF

#anova + boite à moustache

vessel_total_clean_v2$VesselType <- as.factor(vessel_total_clean_v2$VesselType)

anova_length_vtype <- aov(Length ~ VesselType, data = vessel_total_clean_v2)
summary(anova_length_vtype)

ggplot(vessel_total_clean_v2, aes(x = VesselType, y = Length)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Longueur par type de navire",
       x = "Type de navire", y = "Longueur") +
  theme_minimal()




