import pandas as pd
import plotly.graph_objects as go
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import PolynomialFeatures
from sklearn.pipeline import Pipeline
from haversine import haversine, Unit
import numpy as np
import joblib

import warnings
warnings.filterwarnings('ignore')

#modèle de prédiction a utiliser 
#   - regression lineaire
#   - random forest
#   - regression polynomiale

def load_data(filepath):
    try:
        df = pd.read_csv(filepath) #chargement des données
        print(f"Données chargées: {df.shape[0]} lignes, {df.shape[1]} colonnes")
        return df
    except Exception as e:
        print(f"Erreur lors du chargement: {e}")
        return None


def clean_data(df):
    cleaned = df.copy()

    #converti la colonne Basedatetime en format date et transforme les valeur manquante en NoTime
    cleaned['BaseDateTime'] = pd.to_datetime(cleaned['BaseDateTime'], errors='coerce')
    
    #filtre les bateaux qui sont a l'arret
    if 'SOG' in cleaned.columns:
        sog_mask = (cleaned['SOG'] > 0) & (cleaned['SOG'] != 0)
        cleaned = cleaned[sog_mask]
    
    cleaned = cleaned.sort_values('BaseDateTime').reset_index(drop=True) #ordonne par date

    return cleaned


def futur_target(df):
    colonnes_utiles = ['MMSI', 'BaseDateTime', 'LAT', 'LON', 'SOG', 'COG', 'Heading']
    copy = df[colonnes_utiles].copy()

    copy['BaseDateTime'] = pd.to_datetime(copy['BaseDateTime'])
    copy = copy.sort_values(['MMSI', 'BaseDateTime'])

    copy['LAT_future'] = copy.groupby('MMSI')['LAT'].shift(-1) #latitude au temps suivant
    copy['LON_future'] = copy.groupby('MMSI')['LON'].shift(-1) #longitude au temps suivant

    copy['delta_LAT'] = copy['LAT_future'] - copy['LAT'] #différence de latitude
    copy['delta_LON'] = copy['LON_future'] - copy['LON'] #différence de longitude
    copy = copy.dropna(subset=['delta_LAT', 'delta_LON', 'SOG', 'COG', 'Heading'])
    #calcule des cos et sin 
    copy['COG_sin'] = np.sin(np.deg2rad(copy['COG']))
    copy['COG_cos'] = np.cos(np.deg2rad(copy['COG']))
    copy['Heading_sin'] = np.sin(np.deg2rad(copy['Heading']))
    copy['Heading_cos'] = np.cos(np.deg2rad(copy['Heading']))

    return copy


def past_data(groupe, delai):
    dernier_temps = groupe['BaseDateTime'].max()
    borne_de_coupure = dernier_temps - pd.Timedelta(minutes=delai)
    
    return groupe[groupe['BaseDateTime'] <= borne_de_coupure]


def last_sample(groupe, delai):
    dernier_temps = groupe['BaseDateTime'].max()
    borne = dernier_temps - pd.Timedelta(minutes=delai)
    
    return groupe[groupe['BaseDateTime'] > borne]


def data_train(groupe, delai):
    dernier_temps = groupe['BaseDateTime'].max()
    borne = dernier_temps - pd.Timedelta(minutes=delai)
    
    return groupe[groupe['BaseDateTime'] <= borne]


def data_test(groupe, delai):
    dernier_temps = groupe['BaseDateTime'].max()
    borne = dernier_temps - pd.Timedelta(minutes=delai)
    
    return groupe[groupe['BaseDateTime'] > borne]


def regression_lineaire(futur, delai):
    df_train = futur.groupby('MMSI').apply(lambda group: data_train(group, delai)).reset_index(drop=True)
    df_test = futur.groupby('MMSI').apply(lambda group : data_test(group, delai)).reset_index(drop=True)

    print("Taille données entraînement :", df_train.shape)
    print("Taille données test :", df_test.shape)

    features = ['SOG', 'COG_sin', 'COG_cos', 'Heading_sin', 'Heading_cos']

    #definition des variable utiles pour le modèle
    X_train = df_train[features]
    X_test = df_test[features]

    y_train=df_train[['delta_LAT', 'delta_LON']]
    y_test= df_test[['delta_LAT', 'delta_LON']]

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    modele=LinearRegression()
    modele.fit(X_train_scaled, y_train)

    y_pred_delta=modele.predict(X_test_scaled)

    y_pred_lat_delta = y_pred_delta[:, 0]
    y_pred_lon_delta = y_pred_delta[:, 1]

    lat_pred_final = df_test['LAT'].values + y_pred_lat_delta
    lon_pred_final = df_test['LON'].values + y_pred_lon_delta

    Y_true = df_test[['LAT_future', 'LON_future']].values

    #prédictions finales
    Y_pred = np.column_stack([lat_pred_final, lon_pred_final])
    
    #analyse 
    r2_global = r2_score(Y_true, Y_pred)
    rmse_global = np.sqrt(mean_squared_error(Y_true, Y_pred))
    print(f'Performance globale : R² = {r2_global:.4f}, RMSE = {rmse_global:.6f}')

    haversine_errors_lib = [
        haversine((lat_true, lon_true), (lat_pred, lon_pred), unit=Unit.METERS)
        for (lat_true, lon_true), (lat_pred, lon_pred) in zip(Y_true, Y_pred)
    ]
    
    mean_haversine_error_lib = np.mean(haversine_errors_lib)
    std_haversine_error_lib = np.std(haversine_errors_lib)
    
    print(f"Erreur de Haversine moyenne : {mean_haversine_error_lib:.2f} mètres")
    print(f"Erreur de Haversine - écart type : {std_haversine_error_lib:.2f} mètres")
 

    return df_test, lat_pred_final, lon_pred_final


def random_forest(futur, delai):
    df_train = futur.groupby('MMSI').apply(lambda group: data_train(group, delai)).reset_index(drop=True)
    df_test = futur.groupby('MMSI').apply(lambda group : data_test(group, delai)).reset_index(drop=True)

    print("Taille données entraînement :", df_train.shape)
    print("Taille données test :", df_test.shape)

    features = ['SOG', 'COG_sin', 'COG_cos', 'Heading_sin', 'Heading_cos']
    
    #definition des variable utiles pour le modèle
    X_train = df_train[features]
    X_test = df_test[features]

    y_train = df_train[['delta_LAT', 'delta_LON']]
    y_test = df_test[['delta_LAT', 'delta_LON']]

    modele = RandomForestRegressor(n_estimators=100, random_state=42)
    modele.fit(X_train, y_train)

    y_pred_delta = modele.predict(X_test)

    y_pred_lat_delta = y_pred_delta[:, 0]
    y_pred_lon_delta = y_pred_delta[:, 1]

    lat_pred_final = df_test['LAT'].values + y_pred_lat_delta
    lon_pred_final = df_test['LON'].values + y_pred_lon_delta

    Y_true = df_test[['LAT_future', 'LON_future']].values
    Y_pred = np.column_stack([lat_pred_final, lon_pred_final])

    #analyse 
    r2_global = r2_score(Y_true, Y_pred)
    rmse_global = np.sqrt(mean_squared_error(Y_true, Y_pred))
    print(f'Performance globale : R² = {r2_global:.4f}, RMSE = {rmse_global:.6f}')

    haversine_errors_lib = [
        haversine((lat_true, lon_true), (lat_pred, lon_pred), unit=Unit.METERS)
        for (lat_true, lon_true), (lat_pred, lon_pred) in zip(Y_true, Y_pred)
    ]
    
    mean_haversine_error_lib = np.mean(haversine_errors_lib)
    std_haversine_error_lib = np.std(haversine_errors_lib)
    
    print(f"Erreur de Haversine moyenne : {mean_haversine_error_lib:.2f} mètres")
    print(f"Erreur de Haversine - écart type : {std_haversine_error_lib:.2f} mètres")
 

    return df_test, lat_pred_final, lon_pred_final, modele


def regression_polynomiale(futur, delai):
    df_train = futur.groupby('MMSI').apply(lambda group: data_train(group, delai)).reset_index(drop=True)
    df_test = futur.groupby('MMSI').apply(lambda group : data_test(group, delai)).reset_index(drop=True)

    print("Taille données entraînement :", df_train.shape)
    print("Taille données test :", df_test.shape)

    features = ['SOG', 'COG_sin', 'COG_cos', 'Heading_sin', 'Heading_cos']

    X_train = df_train[features]
    X_test = df_test[features]

    y_train = df_train[['delta_LAT', 'delta_LON']]
    y_test = df_test[['delta_LAT', 'delta_LON']]

    pipeline = Pipeline([
        ('poly_features', PolynomialFeatures(degree=2, include_bias=False)),
        ('reg', LinearRegression())
    ])

    pipeline.fit(X_train, y_train)

    y_pred_delta = pipeline.predict(X_test)

    y_pred_lat_delta = y_pred_delta[:, 0]
    y_pred_lon_delta = y_pred_delta[:, 1]

    lat_pred_final = df_test['LAT'].values + y_pred_lat_delta
    lon_pred_final = df_test['LON'].values + y_pred_lon_delta

    Y_true = df_test[['LAT_future', 'LON_future']].values
    Y_pred = np.column_stack([lat_pred_final, lon_pred_final])

    #analyse 
    r2_global = r2_score(Y_true, Y_pred)
    rmse_global = np.sqrt(mean_squared_error(Y_true, Y_pred))
    print(f'Performance globale : R² = {r2_global:.4f}, RMSE = {rmse_global:.6f}')

    haversine_errors_lib = [
        haversine((lat_true, lon_true), (lat_pred, lon_pred), unit=Unit.METERS)
        for (lat_true, lon_true), (lat_pred, lon_pred) in zip(Y_true, Y_pred)
    ]

    mean_haversine_error_lib = np.mean(haversine_errors_lib)
    std_haversine_error_lib = np.std(haversine_errors_lib)
    
    print(f"Erreur de Haversine moyenne : {mean_haversine_error_lib:.2f} mètres")
    print(f"Erreur de Haversine - écart type : {std_haversine_error_lib:.2f} mètres")

    return df_test, lat_pred_final, lon_pred_final


def affichage(df, df_test, df_sans, lat_pred_final, lon_pred_final, delai):
    fig = go.Figure()

    #trajectoires réelles des dernières minutes
    for mmsi, groupe in df.groupby('MMSI'):
        fig.add_trace(go.Scattermapbox(
            lat=groupe['LAT'],
            lon=groupe['LON'],
            mode='lines',
            line=dict(width=3, color='red'),
            name=f"{mmsi} ({delai}min)"
        ))

    #trajectoires prédites
    df_pred = df_test.copy()
    df_pred['LAT_PRED'] = lat_pred_final
    df_pred['LON_PRED'] = lon_pred_final

    for mmsi, groupe in df_pred.groupby('MMSI'):
        fig.add_trace(go.Scattermapbox(
            lat=groupe['LAT_PRED'],
            lon=groupe['LON_PRED'],
            mode='lines',
            line=dict(width=2, color='green'),
            name=f"{mmsi} (prédiction)"
        ))

    #centre de la carte
    lat_moyenne = df_sans['LAT'].mean()
    lon_moyenne = df_sans['LON'].mean()

    fig.update_layout(
        mapbox_style="open-street-map",
        mapbox=dict(
            center=dict(lat=lat_moyenne, lon=lon_moyenne),
            zoom=6
        ),
        margin={"r":0, "t":0, "l":0, "b":0},
        legend=dict(title="Trajectoires")
    )

    fig.write_html(f"carte_{model_name.replace(' ', '_').lower()}_{delai}min.html") #enregistre un html 
    fig.show()


if __name__ == "__main__":
    #préparation des données 
    filepath = "vessel_data_clean_v2.csv"
    df = load_data(filepath)
    cleaned = clean_data(df)
    futur = futur_target(cleaned)

    #prédictions
    for delai in [5, 10, 15]:
        print(f"\n### {delai} min ###")
        df_sans = futur.groupby('MMSI').apply(past_data, delai=delai).reset_index(drop=True)
        df_last = futur.groupby('MMSI').apply(last_sample, delai=delai).reset_index(drop=True)

        for model_name, model_func in [
            ("Régression Linéaire", regression_lineaire),
            ("Random Forest", random_forest),
            ("Régression Polynomiale", regression_polynomiale)
        ]:
            print(f"\n--- {model_name} ---")
            #on veut récupérer le modèle que nous avons estimer le plus performent, ici Random Forest
            if model_name == "Random Forest":
                df_test, lat_pred, lon_pred, model = model_func(df_sans, delai)
                joblib.dump(model, f"random_forest_{delai}.pkl")

            else: 
                df_test, lat_pred, lon_pred = model_func(df_sans, delai)
            affichage(df_last, df_test, df_sans, lat_pred, lon_pred, delai)
    
    print("\n")

    


