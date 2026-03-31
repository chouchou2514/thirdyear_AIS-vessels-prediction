import argparse       
import joblib          
import numpy as np                 
import sys            
import pandas as pd    

#fonction qui extrait les arguments en ligne de commande
def checkArguments():
    parser = argparse.ArgumentParser(description='Prédire la trajectoire d\'un navire')
    parser.add_argument('--sog', type=float, required=True,
                        help='Speed Over Ground (vitesse sur le fond)')
    parser.add_argument('--cog', type=float, required=True,
                        help='Course Over Ground (cap sur le fond)')
    parser.add_argument('--latitude', type=float, required=True,
                        help='Latitude actuelle')
    parser.add_argument('--longitude', type=float, required=True,
                        help='Longitude actuelle')
    parser.add_argument('--heading', type=float, required=True,
                        help='True heading angle (cap vrai)')
    parser.add_argument('--minutes', type=int, choices=[5, 10, 15], default=15,
                        help='Durée de prédiction en minutes (5, 10 ou 15)')
    
    return parser.parse_args()

#fonction qui charger le modèle correspondant au temps de prédiction demandé
def load_model(time):
    model_filename = f"random_forest_{time}.pkl" 
    
    if model_filename is None:
        print(f"Erreur: Aucun fichier de modèle trouvé pour {time} minutes!")
        print(f"Fichiers recherchés: {model_filename}")
        sys.exit(1)  #arrêt du script en cas d'erreur

    try:
        model = joblib.load(model_filename)  #chargement du modèle via joblib
        print(f"Modèle chargé: {model_filename}")
        model_type = "ranfor"  
        return model, model_type
    except Exception as e:
        print(f"Erreur lors du chargement du modèle {model_filename}: {e}")
        sys.exit(1)

#fonction qui créer les features à partir des données d'entrée
def features_preparation(sog, cog, heading):
    #conversion des angles en radians et calcul du sinus et cosinus
    cog_sin = np.sin(np.deg2rad(cog))
    cog_cos = np.cos(np.deg2rad(cog))
    heading_sin = np.sin(np.deg2rad(heading))
    heading_cos = np.cos(np.deg2rad(heading))
    
    #DataFrame avec les features nécessaires au modèle
    features = pd.DataFrame([{
        "SOG": sog,
        "COG_sin": cog_sin,
        "COG_cos": cog_cos,
        "Heading_sin": heading_sin,
        "Heading_cos": heading_cos
    }])
    
    return features

#fonction qui prédit la future position du navire
def predict_position(model, model_type, features, current_lat, current_lon):
    try:
        #prédiciton des deltas de latitude et longitude
        delta_pred = model.predict(features)
        
        #nouvelle position en ajoutant les deltas
        lat_pred = current_lat + delta_pred[0, 0]
        lon_pred = current_lon + delta_pred[0, 1]
        return lat_pred, lon_pred
    except Exception as e:
        print(f"Erreur lors de la prédiction: {e}")
        print(f"Type de modèle: {model_type}")
        print(f"Forme des features: {features.shape}")
        sys.exit(1)

if __name__ == "__main__":
    args = checkArguments()  
    model, model_type = load_model(args.minutes)
    features = features_preparation(args.sog, args.cog, args.heading)
    lat_pred, lon_pred = predict_position(model, model_type, features, args.latitude, args.longitude)
    
    #affichage du résultat
    print(f"Position prédite sur {args.minutes} minutes:")
    print(f"LAT: {lat_pred:.6f}")
    print(f"LON: {lon_pred:.6f}")
