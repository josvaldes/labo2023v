#Se utiliza el algoritmo Random Forest, creado por Leo Breiman en el año 2001
#Una libreria que implementa Rando Forest se llama  ranger
#La libreria esta implementada en lenguaje C y corre en paralelo, utiliza TODOS los nucleos del procesador
#Leo Breiman provenia de la estadistica y tenia "horror a los nulos", con lo cual el algoritmo necesita imputar nulos antes

#Este script esta pensado para correr en la PC local

#limpio la memoria
rm( list=ls() )  #Borro todos los objetos
gc()   #Garbage Collection

require("data.table")
require("ranger")
require("randomForest")  #solo se usa para imputar nulos

#Aqui se debe poner la carpeta de la computadora local
setwd("C:/Users/Josvaldes/Documents/Maestria/Austral/1ano/laboratorioImp1")  #Establezco el Working Directory

#cargo los datos donde entreno
dataset  <- fread("./datasets/dataset_pequeno.csv", stringsAsFactors= TRUE)

#paso a trabajar con clase binaria POS={BAJA+2}   NEG={BAJA+1, CONTINUA}
dataset[ , clase_binaria := as.factor(ifelse( clase_ternaria=="BAJA+2", "POS", "NEG" )) ]
dataset[ , clase_ternaria := NULL ]  #elimino la clase_ternaria, ya no la necesito


#imputo los nulos, ya que ranger no acepta nulos
#Leo Breiman, ¿por que le temias a los nulos?
dataset  <- na.roughfix(dataset)


dtrain  <- dataset[foto_mes == 202107]
dapply  <- dataset[foto_mes == 202109]


#genero el modelo de Random Forest con la libreria ranger
#notar como la suma de muchos arboles contrarresta el efecto de min.node.size=1
param  <- list( "num.trees"=       500,  #cantidad de arboles
                "mtry"=             7,  #cantidad de variables que evalua para hacer un split  sqrt(ncol(dtrain))
                "min.node.size"=  370,  #tamaño minimo de las hojas
                "max.depth"=        24   # 0 significa profundidad infinita
              )

set.seed(792637) #Establezco la semilla aleatoria

setorder(dtrain, clase_binaria)  


#genero el modelo de Random Forest llamando a ranger()
modelo  <- ranger( formula= "clase_binaria ~ .",
                   data=  dtrain, 
                   probability=   TRUE,  #para que devuelva las probabilidades
                   num.trees=     param$num.trees,
                   mtry=          param$mtry,
                   min.node.size= param$min.node.size,
                   max.depth=     param$max.depth
                   ,class.weights= c(1,40)  #servira cambiar los pesos ?
                 )

#aplico el modelo recien creado a los datos del futuro
prediccion  <- predict( modelo, dapply )

#Genero la entrega para Kaggle
entrega  <- as.data.table( list( "numero_de_cliente"= dapply[  , numero_de_cliente],
                                 "Predicted"= as.numeric(prediccion$predictions[ ,"POS" ] > 1/40) ) ) #genero la salida

#creo la carpeta donde va el experimento
# HT  representa  Hiperparameter Tuning
dir.create( "./exp/",  showWarnings = FALSE ) 
dir.create( "./exp/KA3340/", showWarnings = FALSE )
archivo_salida  <- "./exp/KA3340/KA3340_005.csv"

#genero el archivo para Kaggle
fwrite( entrega, 
        file= archivo_salida, 
        sep="," )
