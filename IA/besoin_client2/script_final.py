import argparse
import pandas as pd
from joblib import load

# Chargement des objets pré-entraînés
model = load("model.pkl")
# scaler = load("scaler.pkl")

# Dictionnaire des types exacts
vessel_type_labels= {
    60: "Passenger, all ships of this type",
    61: "Passenger, hazardous category A",
    62: "Passenger, hazardous category B",
    63: "Passenger, hazardous category C",
    64: "Passenger, hazardous category D",
    65: "Passenger, reserved for future use",
    66: "Passenger, reserved for future use",
    67: "Passenger, reserved for future use",
    68: "Passenger, reserved for future use",
    69: "Passenger, no additional information",
    70: "Cargo, all ships of this type",
    71: "Cargo, hazardous category A",
    72: "Cargo, hazardous category B",
    73: "Cargo, hazardous category C",
    74: "Cargo, hazardous category D",
    75: "Cargo, reserved for future use",
    76: "Cargo, reserved for future use",
    77: "Cargo, reserved for future use",
    78: "Cargo, reserved for future use",
    79: "Cargo, no additional information",
    80: "Tanker, all ships of this type",
    81: "Tanker, hazardous category A",
    82: "Tanker, hazardous category B",
    83: "Tanker, hazardous category C",
    84: "Tanker, hazardous category D",
    85: "Tanker, reserved for future use",
    86: "Tanker, reserved for future use",
    87: "Tanker, reserved for future use",
    88: "Tanker, reserved for future use",
    89: "Tanker, no additional information"
}

def checkArguments():
    """Check program arguments and return program parameters."""
    parser = argparse.ArgumentParser(description="Prédiction du type de navire")
    parser.add_argument('--heading', type=float, required=True, help='Heading (cap du navire)')
    parser.add_argument('--draft', type=float, required=True, help='Draft (tirant d\'eau)l')
    parser.add_argument('--length', type=float, required=True, help='Longueur du navire')
    parser.add_argument('--width', type=float, required=True, help='Largeur du navire')
    parser.add_argument('--sog', type=float, required=True, help='Speed Over Ground')
    parser.add_argument('--status', type=str, required=True, help='Statut du navire (catégoriel)')
    #parser.add_argument('--cargo', type=float, required=True, help='Code Cargo')
    return parser.parse_args()
def main():
    args = checkArguments()

    # Préparation du DataFrame avec les colonnes attendues par le modèle
    data = pd.DataFrame([[args.heading, args.draft, args.length, args.width, args.sog, args.status]], columns=["Heading", "Draft", "Length", "Width", "SOG", "Status"])
   
    # Prédiction
    prediction = model.predict(data)
    vessel_type = int(prediction[0])

    # Déduction de la catégorie générale
    if 60 <= vessel_type <= 69:
        category = "Passenger"
    elif 70 <= vessel_type <= 79:
        category = "Cargo"
    elif 80 <= vessel_type <= 89:
        category = "Tanker"
    else:
        category = "Autres"

    # Affichage du résultat
    print(f"\nCatégorie prédit : {category}")
    print(f"Type prédit : {vessel_type}")
    print(f"Détail exact : {vessel_type_labels.get(vessel_type, 'Autres')}")

if __name__ == "__main__":
    main()