import pickle
import numpy as np
import pandas as pd

# Charger le scaler
with open("scaler.pkl", "rb") as f:
    scaler = pickle.load(f)

# Charger les modèles
with open("model_kmeans.pkl", "rb") as f:
    model_kmeans = pickle.load(f)

with open("model_minibatch.pkl", "rb") as f:
    model_minibatch = pickle.load(f)

with open("model_birch.pkl", "rb") as f:
    model_birch = pickle.load(f)


sog = float(input('Entrez la vitesse de votre navire:'))
cog= float(input('Entrez la cap vrai de votre navire:'))
heading = float(input('Entrez le heading de votre navire:'))

# Fonction pour prédire le cluster

cluster_navire = pd.DataFrame([[sog, cog, heading]], columns=['SOG', 'COG', 'Heading'])
navire_scaled = scaler.transform(cluster_navire)
cluster = model_minibatch.predict(navire_scaled)[0]

print(f"Cluster (MiniBatchKMeans): {cluster}")


