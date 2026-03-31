# Chargement des packages
library(ggplot2)
library(dplyr)
library(MASS)
library(readr)

#Chargement des données
vessel_total_clean_v2 <- read_csv("C:/Users/BEAUSSIER/Downloads/vessel_data_clean_v2.csv")

# test
#file.exists("C:/Users/BEAUSSIER/Downloads/vessel_data_clean_v2.csv")
#head(vessel_total_clean_v2)
#colnames(vessel_total_clean)
#summary(vessel_total_clean)


######## fonctionnalité 2 - visualisation des données des graphiques ##############

  #1)Répartition des bateaux selon leur type

ggplot(vessel_total_clean_v2, aes(x = as.factor(VesselType))) + #ggplot initialise le graphique
  geom_bar(fill = "steelblue") +  # geom_bar créer un diagramme à barre 
  labs(title = "Répartition des navires par type", x = "Type de navire", y = "Nombre de navire") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))  # Centre le titre
#Sauvegarde du graphique
ggsave("repartition_par_type.png", width = 8, height = 6)


  #2)Répartition des bateaux selon leur catégorie

#Création d'une nouvelle colonne "categorie" selon VesselType dans le dataframe
#Donne un noms à chaque catégorie à partir de VesselType
vessel_total_clean_v2$categorie <- with(vessel_total_clean_v2, ifelse(VesselType >= 60 & VesselType <= 69, "Passenger",
                                                                ifelse(VesselType >= 70 & VesselType <= 79, "Cargo",
                                                                     ifelse(VesselType >= 80 & VesselType <= 89, "Tanker", "Autre"))))
#graphique barpplot
ggplot(vessel_total_clean_v2, aes(x = as.factor(categorie))) +
  geom_bar(fill = "darkgreen") +
  labs(title = "Répartition des navires par catégorie",
       x = "Catégorie du navire",
       y = "Nombre de navires") +
  theme_minimal()+ #applique un thème graphique simple et épuré
  theme(plot.title = element_text(hjust = 0.5))  # Centre le titre   

# Sauvegarde du graphique en png
ggsave("repartition_par_categorie.png", width = 8, height = 6)

# Création d'un dataframe avec les fréquences pour le camembert
categorie_freq <- as.data.frame(table(vessel_total_clean_v2$categorie)) #compte le nombre d'occurence et les stocks dans un dataframe
colnames(categorie_freq) <- c("Categorie", "Frequence") #créer un tableau avec deux colonnes sa catégorie et sa fréquence

# Calcul du pourcentage
categorie_freq$Pourcentage <- round(categorie_freq$Frequence / sum(categorie_freq$Frequence) * 100, 1)

# Création de la position pour les étiquettes
categorie_freq$Label <- paste0(categorie_freq$Categorie, "\n", categorie_freq$Pourcentage, "%")

# Affichage Camembert 
ggplot(categorie_freq, aes(x = "", y = Frequence, fill = Categorie)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  geom_text(aes(label = Label), 
            position = position_stack(vjust = 0.5), 
            size = 4, color = "black") +
  labs(title = "Répartition des navires par catégorie") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5),
        legend.title = element_blank())

#table(vessel_total_clean_v2$categorie)

  #3)Ports les plus utilisés
# Regrouper par arrondi de coordonnées (à 1 décimale ~ environ 10 km)
# Définir les ports avec leurs coordonnées (latitude et longitude) et noms
ports <- data.frame(
  Latitude = c(29.3, 29.1, 29.7, 29.9, 26.1, 29.8, 29.7, 27.8, 30.0, 29.6),
  Longitude = c(-89.4, -90.2, -91.1, -90.1, -80.1, -93.3, -95.3, -97.1, -90.1, -89.9),
  Nom = c("Port of Venice", "Port of Fourchon", "Port of Morgan City", "Port of Marrero/New Orleans",
          "Port Everglades", "Port of Cameron", "Port of Houston", "Port Aransas/Corpus Christi",
          "Port of New Orleans", "Zone Delta Mississippi")
)

# Fonction pour compter les points proches d’un port (dans un rayon donné)
count_nearby_points <- function(lat, lon, data, radius = 0.1) {
  sum(abs(data$LAT - lat) <= radius & abs(data$LON - lon) <= radius)
}

# Appliquer la fonction à tous les ports
ports$Frequentation <- mapply(count_nearby_points, ports$Latitude, ports$Longitude,
                              MoreArgs = list(data = vessel_total_clean_v2, radius = 0.1))

# Trier les ports par ordre décroissant de fréquentation
ports <- ports[order(-ports$Frequentation), ]
ports$Nom <- factor(ports$Nom, levels = ports$Nom)  # garder l'ordre dans le plot

# Barplot
ggplot(ports, aes(x = Nom, y = Frequentation)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Ports par ordre de fréquentation",
       x = "Port",
       y = "Nombre de positions AIS détectées (densité)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + theme(plot.title = element_text(hjust = 0.5))  # Centre le titre 

# Sauvegarde du graphique
ggsave("frequentation_ports.png", width = 10, height = 6)



    # Histogramme des longueurs des navires
ggplot(vessel_total_clean_v2, aes(x = Length)) +
  geom_histogram(bins = 10, fill = "salmon", color="black") +
  labs(title = "Longueurs des navires", x = "Longueur", y = "Nombre de navires") +
  theme_minimal()+
  theme(plot.title = element_text(hjust = 0.5))  # Centre le titre
# Sauvegarde du graphique
ggsave("longueur_navire.png", width = 10, height = 6)


    #Histogramme des largeurs des navires
ggplot(vessel_total_clean_v2, aes(x = Width)) +
  geom_histogram(bins = 10, fill = "brown", color="black") +
  labs(title = "Largeurs des navires", x = "Largeur", y = "Nombre de navires") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))  # Centre le titre
# Sauvegarde du graphique
ggsave("largeur_navire.png", width = 10, height = 6)


# Barplot de la vitesse des bateaux 
ggplot(vessel_total_clean_v2, aes(y = SOG)) +
  geom_histogram(bins = 20, fill = "darkblue",color="white") +
  coord_flip() +  # Inverser les axes
  labs(title = "Distribution de la vitesse au sol des navires (SOG)",
       y = "Vitesse (noeuds)",
       x = "Nombre de navires") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))  # Centre le titre
# Sauvegarde du graphique
ggsave("vitesse_global.png", width = 8, height = 6)



