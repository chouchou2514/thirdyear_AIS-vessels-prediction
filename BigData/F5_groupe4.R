#Régression logistique :
  #➢ Prédiction de la variable VesselType en fonction des variables pertinentes.
  #➢ Autre exemple : sélection de quelques bateaux, calculer leur vitesse et mesurer
    #quantitativement l’erreur commise par votre méthode.

#packages
library(nnet)      # pour multinom
library(dplyr)     # pour manipulation
library(caret)     # pour évaluation (confusionMatrix)

db <- read.csv("~/Documents/COURS/S6/Projet Outils numériques/Projet Big Data/Projet Big Data/vessel_data_clean_v2.csv") #importation des données csv
head(db) #affiche le début des données

#######################################################################################################################

###Prédiction de la variable VesselType###
#psca
#sem

#préparation des données
data_logit <- db %>%
  select(VesselType, SOG, COG, Heading, Length, Width, Draft, Cargo) %>%
  mutate(VesselType = as.factor(VesselType))

#modèle de régression logistique multinomiale
model_logit <- multinom(VesselType ~ ., data = data_logit, maxit = 100)

#prédictions et évaluation
pred <- predict(model_logit, newdata = data_logit)
confusionMatrix(as.factor(pred), data_logit$VesselType)

tab <- table(Predicted = pred, Actual = data_logit$VesselType)

# Barplot pour comparer les classes prédites vs réelles
barplot(tab,
        beside = TRUE,
        col = rainbow(nrow(tab)),
        legend = TRUE,
        main = "Comparaison des classes réelles vs prédites",
        xlab = "VesselType réel",
        ylab = "Nombre de bateaux")

#######################################################################################################################

###Prédiction : vitesse et erreur###

#créer un sous-ensemble pour la régression de la vitesse
data_speed <- db %>%
  select(SOG, Length, Width, Draft, Cargo)

head(data_speed)

#modèle de régression linéaire
model_speed <- lm(SOG ~ Length + Width + Draft + Cargo, data = data_speed)

#prédiction de la vitesse
data_speed$SOG_pred <- predict(model_speed, newdata = data_speed)

#calcul de l'erreur (RMSE)
rmse <- sqrt(mean((data_speed$SOG - data_speed$SOG_pred)^2))
cat("Erreur moyenne (RMSE) :", round(rmse, 3), "\n")

plot(data_speed$SOG, data_speed$SOG_pred,
     main = "SOG réel vs SOG prédit",
     xlab = "SOG réel",
     ylab = "SOG prédit",
     pch = 16, col = "blue")

# Ajouter la ligne idéale (SOG = SOG_pred)
abline(a = 0, b = 1, col = "red", lty = 2)

