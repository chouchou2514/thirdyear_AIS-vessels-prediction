  vessel_total_clean <- read_csv("C:/Users/c_pre/OneDrive - yncréa/S6/Projets/Projets Outils Numériques/Semaine 2 - Big Data/vessel_data_clean_v2.csv")
  
  
  # On trie les données d'abord par identifiant de bateau (Vessel_ID),
  # puis par date-heure croissante (BaseDateTime) pour reconstruire la trajectoire dans le bon ordre.
  donnees <- vessel_total_clean[order(vessel_total_clean$MMSI, vessel_total_clean$BaseDateTime), ]
  
  # Charger les bibliothèques nécessaires
  library(leaflet)       # Pour créer des cartes interactives
  library(dplyr)         # Pour manipuler les données facilement

  
  # Extraire tous les identifiants de bateaux uniques dans les données
  bateaux <- unique(donnees$MMSI)
  # Limiter à seulement 5 bateaux (pour alléger l'affichage)
  bateaux_limites <- bateaux[1:150]
  #bateaux_limites <- setdiff(bateaux[1:150], bateaux[101])
  
  # Créer une carte leaflet de base avec les tuiles OpenStreetMap
  map <- leaflet() %>% addTiles()
  
  #tableau de correspondance pour les types de bateaux
  vessel_type_dict <- c(
    "60" = "Passenger, all ships of this type",
    "61" = "Passenger, hazardous category A",
    "69" = "Passenger, no additional information",
    "70" = "Cargo, all ships of this type",
    "71" = "Cargo, hazardous category A",
    "74" = "Cargo, hazardous category D",
    "79" = "Cargo, no additional information",
    "80" = "Tanker, all ships of this type",
    "82" = "Tanker, hazardous category B",
    "84" = "Tanker, hazardous category D",
    "89" = "Tanker, no additional information"
  )
  
  
  
  # Boucle sur chaque bateau pour dessiner sa trajectoire et placer des marqueurs
  for (id_vessel in bateaux_limites) {
    
    # Filtrer les données pour ne garder que les points correspondant au bateau courant (id)
    trajet <- donnees %>% filter(id_vessel == MMSI)
    
    #on fait gaffe à l'affichage de notre type de bateau
    # Récupérer le type de navire en clair
    type_bateau <- vessel_type_dict[as.character(trajet$VesselType[1])]
    

  
    # Ajouter la ligne représentant la trajectoire du bateau (liaison des points GPS)
    map <- map %>%
      addPolylines(
        lng = trajet$LON,         # Longitude des points
        lat = trajet$LAT,          # Latitude des points
        color = "red",               # Couleur du bateau
        weight = 10,                     # Épaisseur de la ligne
        opacity = 0.1,
        group = as.character(id_vessel),       # Nom du groupe (utilisé pour organiser la carte), en gros ca regroupe les lignes qui concernent un même bateau, je le mets pour essayer d'afficher un seul bateau à la fois après
        label = htmltools::HTML(paste(
                      "Bateau:", trajet$VesselName[1],
                      "<br>MMSI:", trajet$MMSI[1],
                      "<br>Type de bateau:", type_bateau)    # Info bulle affichée quand on clique sur la ligne
      )
      )
      
  }
  
  map

  
  
