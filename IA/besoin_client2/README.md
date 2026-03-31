# Projet IA - Client 2 : Prédiction du Type de Navire

Ce projet vise à prédire le type de navire à partir de ses caractéristiques : longueur, largeur, tirant d’eau, cap, vitesse, statut, etc.

---

## Fichiers

- `script.py` : Script principal de prédiction
- `model.pkl` : Modèle IA pré-entraîné (apprentissage supervisé)
- `README.md` : Documentation du projet

---

## Installation des packages nécessaires

Ouvre un terminal et exécute la commande suivante :

```bash
pip install numpy pandas seaborn matplotlib scikit-learn imbalanced-learn joblib argparse

## Variables en entrée

| Variable | Description                   |
|----------|-------------------------------|
| heading  | Cap du navire (en degrés)     |
| draft    | Tirant d'eau (en mètres)      |
| length   | Longueur du navire (en m)     |
| width    | Largeur du navire (en m)      |
| sog      | Speed Over Ground (en nœuds)  |
| status   | Statut du navire (catégoriel) |

---

## Exécution:

exemple 1:
python .\script.py  --heading 180 --draft 5.2 --length 120 --width 15 --sog 1 --status 2 

Doit renvoyer :
Catégorie prédit : Cargo
Type prédit : 70
Détail exact : Cargo, all ships of this type


exemple 2:
python .\script.py  --heading 90 --draft 3.5 --length 80 --width 12 --sog 5 --status 1    

Doit renvoyer :
Catégorie prédit : Passenger
Type prédit : 60
Détail exact : Passenger, all ships of this type
