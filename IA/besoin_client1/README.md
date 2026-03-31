# Script de prédiction de cluster pour un navire (clustering AIS)
Ce script permet de prédire le cluster associé à un navire en fonction de trois caractéristiques de navigation :

* SOG : Speed Over Ground (vitesse réelle)

* COG : Course Over Ground (cap vrai)

* Heading : direction du navire (compas)

Il s'appuie sur un modèle de clustering MiniBatchKMeans entraîné en amont, et sur un scaler pour normaliser les données d'entrée.


## Fichiers nécessaires
Le script repose sur les fichiers suivants (générés à l’étape d'entraînement) :

* scaler.pkl : objet StandardScaler utilisé pour normaliser les données.

* model_kmeans.pkl : modèle KMeans (non utilisé ici mais chargé).

* model_minibatch.pkl : modèle MiniBatchKMeans utilisé pour la prédiction.

* model_birch.pkl : modèle Birch (non utilisé ici mais chargé).

Tous les fichiers .pkl doivent être présents dans le même répertoire que ce script.


## Utilisation
Lance le script et vous serez invité à entrer les caractéristiques du navire :

*exemple:*

**Entrez la vitesse de votre navire:** *12.4*

**Entrez la cap vrai de votre navire:** *78.3*

**Entrez le heading de votre navire:** *80*


Le script affichera ensuite le numéro de cluster prédit par le modèle MiniBatchKMeans :

**Cluster (MiniBatchKMeans):** *3*


## Personnalisation
Par défaut, la prédiction est effectuée avec le modèle MiniBatchKMeans. Vous pouvez facilement changer de modèle en modifiant la ligne suivante :

cluster = **model_minibatch**.predict(navire_scaled)[0]

Par exemple, pour utiliser KMeans :

cluster = **model_kmeans**.predict(navire_scaled)[0]


## Dépendances
Assurez-vous d'avoir installé les bibliothèques suivantes :

pip install **numpy pandas scikit-learn pyplot**


## Exemple d'intégration
Ce script peut être utilisé :

* Pour taguer automatiquement des trajectoires avec leur cluster,

* Dans un projet de visualisation interactive (type carte maritime),

* Comme outil d’interprétation rapide d’une observation individuelle.