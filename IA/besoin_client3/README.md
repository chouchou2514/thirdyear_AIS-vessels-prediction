# 🚢 Prédiction de la Trajectoire d'un Navire (AIS)

Ce projet permet de prédire la position future d’un navire (**latitude** et **longitude**) à partir de ses paramètres de navigation actuels, en utilisant un modèle **Random Forest** préalablement entraîné.

## 🧠 Modèle et Fonctionnement

Le modèle utilisé est une **Random Forest** entraînée pour prédire les variations de coordonnées (**delta_LAT** et **delta_LON**). Pour optimiser la précision, le script utilise les caractéristiques suivantes:

* **Vitesse sur le fond** (`SOG`).
* **Cap sur le fond** (`COG`) — transformé en composantes `sin` et `cos`.
* **Cap vrai** (`Heading`) — transformé en composantes `sin` et `cos`.

## 📂 Fichiers de modèles nécessaires

Le dépôt doit contenir les fichiers de modèles pré-entraînés correspondant aux différents délais de prédiction:
* `random_forest_5.pkl` : Modèle pour une prédiction à **5 minutes**.
* `random_forest_10.pkl` : Modèle pour une prédiction à **10 minutes**.
* `random_forest_15.pkl` : Modèle pour une prédiction à **15 minutes**.

## 🛠️ Bibliothèques requises

Avant de lancer le script, assurez-vous d’avoir installé les modules Python suivants :
* **numpy**
* **joblib**
* **scikit-learn**

```bash
pip install numpy joblib scikit-learn


##Exécution

```bash
#L'exécution se fait via le terminal en passant les paramètres du navire en arguments.
python script.py --sog <SOG> --cog <COG> --latitude <LAT> --longitude <LON> --heading <HEADING> --minutes <DELAI>

#Exemple: Pour obtenir une prédiction à 15 minutes avec une vitesse de 13.4 nœuds :
python script.py --sog 13.4 --cog 131 --latitude 29.19717 --longitude -94.4992 --heading 131 --minutes 15

