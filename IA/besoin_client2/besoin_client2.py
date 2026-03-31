import joblib
import numpy as np
import pandas as pd
import seaborn as sns
from joblib import dump
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, ConfusionMatrixDisplay
from imblearn.over_sampling import SMOTE


#1)Préparation des données
# Chargement du fichier 
df = pd.read_csv("C:/Users/BEAUSSIER/Downloads/vessel_data_clean_v2.csv")
#print(df.head())
# --- AFFICHAGE INITIAL ---
print("=== Informations sur les identifiants des bateaux (MMSI) ===")
print(f"Nombre total d'enregistrements : {len(df)}")
print(f"Nombre de MMSI uniques : {df['MMSI'].nunique()}")
print(f"Exemples de MMSI : {df['MMSI'].unique()[:10]}\n")

# --- GRAPHIQUE DE TOUS LES MMSI ---
mmsi_counts = df['MMSI'].value_counts()

plt.figure(figsize=(max(12, len(mmsi_counts) // 4), 6))  # Largeur ajustée dynamiquement

sns.barplot(x=mmsi_counts.index.astype(str), y=mmsi_counts.values, palette="viridis")

# plt.title("Nombre d'occurrences pour chaque MMSI (bateau)")
# plt.xlabel("MMSI (Identifiant unique du bateau)")
# plt.ylabel("Nombre d'occurrences")
# plt.xticks(rotation=90, fontsize=6)  # Rotation et petite taille de police
# plt.tight_layout()
# plt.show()

# --- SUPPRESSION DES DOUBLONS (UN SEUL MMSI PAR BATEAU) ---
unique_mmsi = df['MMSI'].unique()  # facultatif mais illustratif
df = df[df['MMSI'].isin(unique_mmsi)].drop_duplicates(subset='MMSI', keep='first')


# --- AFFICHAGE APRÈS FILTRAGE ---
print("=== Après suppression des doublons (1 ligne par bateau) ===")
print(f"Nombre d'enregistrements restants : {len(df)}")
print(f"Nombre de MMSI uniques : {df['MMSI'].nunique()}")
print(f"Exemples de MMSI restants : {df['MMSI'].unique()[:10]}\n")

    #1.a) Test pour savoir quel est le meilleur modèle IA  
# df = df.sample(frac=0.1, random_state=42) # Prendre 10% des données aléatoirement car sinon il y a trop de données

# Supprimer les colonnes pour qu'elles ne soient pas incluent dans l'encodage
df_var_explicative = df.drop(columns=['id', 'MMSI', 'BaseDateTime', 'VesselName', 'VesselType', 'IMO', 'CallSign'])

df_var_explicative = df_var_explicative.dropna() # Suppression des lignes avec des valeurs manquantes

df = df.dropna()

# Encoder les colonnes catégorielles, sauf 'VesselType'
for col in df_var_explicative.select_dtypes(include='object').columns:
    if col != 'VesselType':
        df_var_explicative[col] = LabelEncoder().fit_transform(df_var_explicative[col].astype(str))

# Encoder la variable cible séparément si elle est de type objet
if df['VesselType'].dtype == 'object':
    df['VesselType'] = LabelEncoder().fit_transform(df['VesselType'].astype(str))

print(f"Liste des colonnes après encodage :\n{df_var_explicative.columns}\n")

# rajouter Length + .unique
# Faire des affichage des mmsi qui correspondent à l'identification des bateaux pour expliquer pourquoi on utilise le .unique afin de ne pas avoir deux fois la meme identifictaion du bateaux donc deux fois le meme bateaux 

# Extraction des données d'intérets
features = ['Heading', 'Draft', 'Length', 'Width', 'Status', 'SOG', 'LAT', 'LON', 'COG', 'Cargo'] # Colonnes à utiliser (en entrée)
target = 'VesselType' # Colonnes que l'on souhaite prédire (en sortie)

# Séparation X/Y
X = df[['Heading', 'Draft', 'Length', 'Width', 'Status', 'SOG', 'LAT', 'LON', 'COG', 'Cargo']]#toutes les colonnes pour determiner target (=VesselType) 
y = df[target]      #juste la colonne target


# Normalisation (transformation des données afin d'améliorer la qualité, la performance et l'interprétabilité des analyses statistiques)
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Séparer en train (80%) /test (20%)
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)

# 9. Équilibrage des données avec SMOTE
# smote = SMOTE(random_state=42)
# X_train_bal, y_train_bal = smote.fit_resample(X_train, y_train)


# Grille d'hyperparamètres avec class_weight
param_grid = {
    'n_estimators': [100, 200],
    'max_depth': [None, 10, 20],
    'min_samples_split': [2, 5],
    'min_samples_leaf': [1, 2],
    #'class_weight': ['balanced']    
}

# Modèle de base
rf = RandomForestClassifier(random_state=42)

# GridSearchCV
grid_search = GridSearchCV(
    estimator=rf,
    param_grid=param_grid,
    cv=5,   #normalement c'est 5 mais on peut essayer avec 3
    scoring='accuracy',
    n_jobs=-1,      #vitesse à laquelle le modele s'entraine
)

# Entraînement sur les données équilibrées
grid_search.fit(X_train, y_train)

# Meilleur modèle et paramètres
print("\n Meilleur score (cross-validation) :", grid_search.best_score_)
print(" Meilleurs paramètres :", grid_search.best_params_)


# Liste des modèles à tester afin de savoir lequel choisir 
models = {
    "RandomForest": RandomForestClassifier(),
    "LogisticRegression": LogisticRegression(max_iter=400000),
    "SVM": SVC(),  # Support Vector Machine
    "KNN": KNeighborsClassifier(),
}
#prendre un model de chaque catégorie:distance probabilité


# Entraîner les modèles et comparer
best_model = None
best_score = 0

for name, model in models.items():
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    score = accuracy_score(y_test, y_pred)
    if score > best_score:
        best_score = score
        best_model = model
        best_model_name = name

# Sauvegarde du meilleur modèle
joblib.dump(best_model, f"{best_model_name}model.pkl")
print(f" Meilleur modèle : {best_model_name} à sauvegardé.")
###### Résultat ###### -> best_model = RandomForest
 
    #1.b) Test pour savoir quelles sont les meilleurs variables à utilisé pour déterminer VesselType
# Afficher les importances des variables en utilisant le modèle Random Forest (celui qui a été selectionné précédemment)
importances = best_model.feature_importances_
#feature_names = X.columns

# Création d’un dataframe pour trier et visualiser
feat_imp = pd.DataFrame({'Variable': features, 'Importance':importances})
feat_imp = feat_imp.sort_values(by='Importance', ascending=False)

# Affichage texte des variables les plus importantes
#print("Importance des variables pour la prédiction de 'VesselType' :\n")
#print(feat_imp)
#colonnes que l'on à garder : 'Length', 'Width', 'Heading', 'Draft'
#On ne garde pas Cargo car il est trop corréler avec VesselType donc ça serait trop facile (il faut savoir expliquer ++)


# Affichage graphique
plt.figure(figsize=(10, 6))
sns.barplot(x='Importance', y='Variable', hue='Variable', data=feat_imp, palette='viridis', legend=False)
plt.title("Importance des variables pour la prédiction du type de navire (VesselType)")
plt.tight_layout()
plt.show() 

#Méthode de preprocessing à utiliser pour randomForest
#Ne garder que les variables qui sont interessant pour la prédiction  : Length, Width, Draft, Heading
#entrainement du modèle avec ses 4 valeurs pour la prédiction de VesselType
#savoir comment les variables sont encoder pour savoir à quoi cooresponds les chiffre dans la matrice de corrélation

# Métriques pour la classification : évalue les performances d'un modèle de classification
# Prédiction finale (avec le meilleur modèle déjà entraîné)
y_pred = best_model.predict(X_test)

# Métrique 1 : Accuracy (Score de classification de précision)
print(f"\nAccuracy : {accuracy_score(y_test, y_pred):.4f}")     #accurancy = exactitude

#  Classification report (=rapport global) donne la précision (parmi les prédits positifs, combien sont corrects ?), rappel(Parmis les vrais positifs combien sont détectés ?) 
# et F1-score (moyenne harmonique entre précision et rappel) et support : nombre d’exemples réels de la classe dans le jeu de test.
print("\nRapport de classification :")
print(classification_report(y_test, y_pred))

# Metrique 2 : Matrice de confusion pour évaluer la précision d'une classification
cm = confusion_matrix(y_test, y_pred)
disp = ConfusionMatrixDisplay(confusion_matrix=cm)
disp.plot(cmap='viridis')
plt.title("Matrice de confusion")
plt.show()

#Corrélations des colonnes avec VesselType 
print("\nCorrélation avec VesselType :")
print(df.corr(numeric_only=True)['VesselType'].sort_values(ascending=False))

# matrice de corrélation entre les entrée et la sortie
# tester avec les autres modèles 
# Si tout les résultats sont 1 c'est que la base de donnée est trop simple 
#expliquer pour chaque modèle pk c'est plus simple ou non, expliquer pour RandomForest, RegressionLogistique et DecisionTree
#équiilibrer les variable : SMOTE pour que chque variable ait soit composé du meme nombre 

# #Matrice de corrélation 
# # Calcul de la matrice de corrélation
# correlation_matrix = df.corr(numeric_only=True)

# # Extraire la corrélation avec la variable cible VesselType
# corr_with_target = correlation_matrix['VesselType'].drop('VesselType').sort_values(ascending=False)

# # Affichage graphique
# plt.figure(figsize=(10, 6))
# sns.barplot(x=corr_with_target.values, y=corr_with_target.index, palette="coolwarm")
# plt.title("Corrélation des variables avec VesselType")
# plt.xlabel("Coefficient de corrélation")
# plt.ylabel("Variables")
# plt.grid(True)
# plt.tight_layout()
# plt.show()

# print("Count :")
# print(y.value_counts(normalize=True))

#après avoir étudier la qualité du model on observe que la qualité est de 100% entre les données prédites et les vrais données ce qui signifie soit que le moèdele est parfait, soit que la base de données est trop simple, en essayant avec RegressionLogistique on a eu un tout autre résultat : Plus on avait de valeur, plus c'était précis

#Utilisation de GriSearchCV pour tester toutes les combinaisons possibles d'hyperparamètres et trouver automatiquement la meilleure configuration


dump(best_model, "model.pkl")
dump(scaler, "scaler.pkl")