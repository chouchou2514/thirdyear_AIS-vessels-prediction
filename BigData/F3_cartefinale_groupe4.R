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

values_legende <- intersect(as.character(donnees$VesselType), names(vessel_type_dict))


# Palette de couleurs avec les codes VesselType
codes_uniques <- unique(as.character(donnees$VesselType))

# Exemple de palette personnalisée (au format hexadécimal)
ma_palette <- c("#FF0000", "#FF9A00", "#FFF700", "#5EA430", "#B0FA7F", "#00FFFF", "#2EC1FF", "#1100FF", "#AB00FF", "#FF66B2", "#DE00FF")

couleur <- colorFactor(ma_palette[1:length(codes_uniques)], domain = codes_uniques)




# Boucle sur chaque bateau pour dessiner sa trajectoire et placer des marqueurs
for (id_vessel in bateaux_limites) {
  
  # Filtrer les données pour ne garder que les points correspondant au bateau courant (id)
  trajet <- donnees %>% filter(id_vessel == MMSI)
  
  #utile pour le lien entre couleur et type de bateau
  code_type <- as.character(trajet$VesselType[1])
  
  #on fait gaffe à l'affichage de notre type de bateau
  # Récupérer le type de navire en clair
  type_bateau <- vessel_type_dict[as.character(trajet$VesselType[1])]
  
  
  nom_type_bateau <- as.character(vessel_type_dict[code_type])
  
  # Ajouter la ligne représentant la trajectoire du bateau (liaison des points GPS)
  map <- map %>%
    addPolylines(
      lng = trajet$LON,         # Longitude des points
      lat = trajet$LAT,          # Latitude des points
      color = couleur(code_type),               # Couleur du bateau
      weight = 2,                     # Épaisseur de la ligne
      group = nom_type_bateau,       # Nom du groupe (utilisé pour organiser la carte), en gros ca regroupe les lignes qui concernent un même bateau, je le mets pour essayer d'afficher un seul bateau à la fois après
      label = htmltools::HTML(paste(
        "Bateau:", trajet$VesselName[1],
        "<br>MMSI:", trajet$MMSI[1],
        "<br>Type de bateau:", type_bateau)    # Info bulle affichée quand on clique sur la ligne
      )
    ) 
  # Ajouter un cercle pour le point de départ
  map <- map %>% addCircleMarkers(
    lng = trajet$LON[1],
    lat = trajet$LAT[1],
    radius = 4,
    color = "green",
    fillColor = "green",
    fillOpacity = 0.9,
    stroke = FALSE,
    label = paste("Départ -", trajet$VesselName[1]),
    group = "Départs"
  )
  
  # Ajouter un cercle pour le point de fin
  map <- map %>% addCircleMarkers(
    lng = trajet$LON[nrow(trajet)],
    lat = trajet$LAT[nrow(trajet)],
    radius = 4,
    color = "red",
    fillColor = "red",
    fillOpacity = 0.9,
    stroke = FALSE,
    label = paste("Fin -", trajet$VesselName[1]),
    group = "Fins"
  )
}

codes_present <- names(vessel_type_dict)

# Obtenir les labels textes correspondants
labels_legende <- vessel_type_dict[codes_present]

# Obtenir les couleurs correspondantes à ces codes
colors_legende <- couleur(codes_present)

# Ajouter la légende à la carte
map <- map %>%
  addLegend(
    position = "bottomright",
    colors = colors_legende,
    labels = labels_legende,
    title = "Type de bateau",
    opacity = 1
  )

# Ajouter le contrôle des couches pour types de bateau + points spéciaux
map <- map %>% addLayersControl(
  overlayGroups = c(unname(vessel_type_dict[codes_uniques]), "Départs", "Fins"),
  options = layersControlOptions(collapsed = FALSE)
)


#Legende pour les petits points de départ et fin
map <- map %>%
  addControl(
    html = "<div style='background:white; padding:6px; border-radius:5px; box-shadow: 1px 1px 3px rgba(0,0,0,0.3);'>
              <b>Points spéciaux</b><br>
              <span style='color:green;'>&#9679;</span> Départ<br>
              <span style='color:red;'>&#9679;</span> Fin
            </div>",
    position = "bottomleft"
  )

map


