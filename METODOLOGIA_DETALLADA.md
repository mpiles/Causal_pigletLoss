# Análisis Causal de Variables Asociadas a la Pérdida de Lechones

## Resumen Ejecutivo

Este documento presenta una metodología detallada para el análisis causal de variables relacionadas con pérdidas de lechones durante la lactación en granjas porcinas. El análisis implementa técnicas avanzadas de descubrimiento causal mediante algoritmos computacionales para identificar relaciones causales entre 12 variables predictoras y la variable objetivo: **pérdidas de lactación sobre nacidos vivos** (`losses.born.alive`).

---

## 1. Objetivos del Análisis

### 1.1. Objetivo General

Identificar y cuantificar las relaciones causales entre variables de manejo y reproducción porcina que influyen en las pérdidas de lechones durante el período de lactación, generando un Grafo Acíclico Dirigido (DAG) que represente la estructura causal del sistema.

### 1.2. Objetivos Específicos

1. **Identificar variables causales directas**: Determinar qué variables actúan como causas directas de las pérdidas de lactación.

2. **Establecer la dirección causal**: Distinguir entre correlación y causalidad, determinando la dirección de las relaciones causales (X → Y vs Y → X).

3. **Cuantificar la fuerza de las relaciones**: Evaluar la robustez y consistencia de las relaciones causales identificadas mediante análisis de bootstrap.

4. **Generar modelos predictivos interpretables**: Crear Redes Bayesianas que permitan entender el sistema causal y hacer predicciones informadas.

5. **Proporcionar evidencia estadística**: Validar las relaciones identificadas mediante pruebas de independencia condicional y criterios de información bayesiana.

---

## 2. Variables del Estudio

### 2.1. Variable Objetivo (Dependiente)

- **`losses.born.alive`** (Continua)
  - **Descripción**: Pérdidas de lactación sobre nacidos vivos
  - **Definición**: Proporción de lechones que mueren durante el período de lactación respecto al número de lechones nacidos vivos
  - **Rango**: [0, 1] donde 0 = sin pérdidas, 1 = pérdida total
  - **Interpretación**: Valores más altos indican mayor mortalidad durante lactación

### 2.2. Variables Predictoras (Independientes)

#### Variables Continuas (n=7)

1. **`avg.sows`**: Promedio de cerdas presentes en la granja
   - Representa el tamaño operacional de la granja

2. **`prev_sowlactpd`**: Período de lactación previo (días)
   - Duración de la lactación anterior de la cerda

3. **`Prev_PBA`**: Lechones nacidos vivos previamente
   - Número de lechones vivos en el parto anterior

4. **`previous_weaned`**: Lechones destetados previamente
   - Número de lechones que completaron lactación en ciclo previo

5. **`sow_age_first_mating`**: Edad de la cerda al primer servicio (días)
   - Indicador de madurez reproductiva inicial

6. **`F_light_hr`**: Horas de luz al parto
   - Fotoperiodo durante el evento del parto

7. **`AI_light_hr`**: Horas de luz en inseminación artificial
   - Fotoperiodo durante la inseminación

#### Variables Discretas (n=4)

8. **`Year`**: Año de observación
   - Factor temporal que captura efectos temporales y cambios de manejo

9. **`Seasons`**: Estación del año
   - Categorías: Primavera, Verano, Otoño, Invierno
   - Captura efectos estacionales y climáticos

10. **`Prev_PBD.cat`**: Lechones nacidos muertos previos (categórica)
    - Categorías: Bajo, Medio, Alto
    - Historial de mortinatalidad

11. **`prev_losses.born.alive.cat`**: Pérdidas de lactación previas (categórica)
    - Categorías: Bajo, Medio, Alto
    - Historial de pérdidas en lactaciones anteriores

#### Factor Aleatorio (n=1)

12. **`Company_farm`**: Identificador de granja
    - Código único de empresa y granja
    - Captura efectos específicos de cada unidad productiva

---

## 3. Metodología Estadística

### 3.1. Algoritmo PC (Peter-Clark)

#### 3.1.1. Fundamento Teórico

El algoritmo PC es un método de descubrimiento causal basado en pruebas de independencia condicional. El algoritmo construye un grafo causal mediante la eliminación iterativa de aristas no causales basándose en el principio de d-separación.

#### 3.1.2. Principios Matemáticos

**Independencia Condicional**: Dos variables $X$ y $Y$ son condicionalmente independientes dado un conjunto $Z$ si:

$$P(X, Y | Z) = P(X | Z) \cdot P(Y | Z)$$

Notación: $X \perp\!\!\perp Y \mid Z$

**Test de Independencia Gaussiana**: Para variables continuas con distribución normal, utilizamos la correlación parcial:

$$\rho_{XY \cdot Z} = \frac{\rho_{XY} - \rho_{XZ} \cdot \rho_{YZ}}{\sqrt{(1 - \rho_{XZ}^2)(1 - \rho_{YZ}^2)}}$$

**Estadístico de Prueba**: Bajo la hipótesis nula de independencia condicional:

$$T = \frac{1}{2} \log\left(\frac{1 + \rho_{XY \cdot Z}}{1 - \rho_{XY \cdot Z}}\right) \sqrt{n - |Z| - 3} \sim \mathcal{N}(0, 1)$$

donde $n$ es el tamaño muestral y $|Z|$ es el tamaño del conjunto de condicionamiento.

#### 3.1.3. Algoritmo PC - Procedimiento

**Paso 1: Inicialización**
- Comenzar con un grafo completo no dirigido conectando todas las variables

**Paso 2: Eliminación de Aristas (Skeleton)**
- Para cada par de nodos adyacentes $(X, Y)$:
  - Para cada subconjunto $Z \subseteq \text{adj}(X) \setminus \{Y\}$:
    - Si $X \perp\!\!\perp Y \mid Z$ (con nivel de significancia $\alpha = 0.05$):
      - Eliminar arista entre $X$ y $Y$
      - Guardar $Z$ como conjunto separador

**Paso 3: Orientación de V-estructuras**
- Para cada triple $(X, Y, Z)$ donde $X$ y $Z$ son no adyacentes pero ambos conectados a $Y$:
  - Si $Y \notin \text{SepSet}(X, Z)$:
    - Orientar como $X \rightarrow Y \leftarrow Z$ (V-estructura o colisionador)

**Paso 4: Propagación de Orientaciones**
- Aplicar reglas de orientación para evitar ciclos:
  - Si $X \rightarrow Y - Z$ y $X, Z$ no adyacentes: orientar $Y \rightarrow Z$
  - Si $X \rightarrow Y \rightarrow Z$ con $X - Z$: orientar $X \rightarrow Z$

#### 3.1.4. Configuración del Análisis

- **Nivel de significancia**: $\alpha = 0.05$
- **Test de independencia**: `gaussCItest` (test de correlación gaussiana)
- **Datos**: Variables continuas estandarizadas (media=0, sd=1)

**Estandarización**:

$$Z_i = \frac{X_i - \mu}{\sigma}$$

donde $\mu = \frac{1}{n}\sum_{i=1}^{n} X_i$ y $\sigma = \sqrt{\frac{1}{n-1}\sum_{i=1}^{n}(X_i - \mu)^2}$

#### 3.1.5. Interpretación de Resultados

- **Aristas dirigidas** ($X \rightarrow Y$): Relación causal potencial de $X$ a $Y$
- **Aristas no dirigidas** ($X - Y$): Asociación sin dirección clara determinada
- **Ausencia de arista**: Independencia condicional dado otras variables

---

### 3.2. Redes Bayesianas con Hill-Climbing

#### 3.2.1. Fundamento Teórico

Las Redes Bayesianas (BN) son modelos probabilísticos gráficos que representan variables aleatorias mediante un Grafo Acíclico Dirigido (DAG) donde:
- Nodos representan variables
- Aristas dirigidas representan dependencias probabilísticas directas
- La estructura codifica la factorización de la distribución conjunta

#### 3.2.2. Factorización de Probabilidad Conjunta

Para un conjunto de variables $X_1, X_2, ..., X_n$ con padres $\text{Pa}(X_i)$:

$$P(X_1, X_2, ..., X_n) = \prod_{i=1}^{n} P(X_i | \text{Pa}(X_i))$$

Esta factorización implica las **independencias condicionales** de Markov:
- Cada variable es independiente de sus no-descendientes dado sus padres
- Matemáticamente: $X_i \perp\!\!\perp \text{NonDesc}(X_i) \mid \text{Pa}(X_i)$

#### 3.2.3. Criterio de Información Bayesiano (BIC)

El BIC evalúa la calidad de ajuste del modelo penalizando la complejidad:

$$\text{BIC} = -2 \log L(\theta | D) + k \log(n)$$

donde:
- $L(\theta | D)$ es la verosimilitud del modelo con parámetros $\theta$ dados los datos $D$
- $k$ es el número de parámetros libres del modelo
- $n$ es el tamaño muestral

**Objetivo**: Minimizar BIC $\Rightarrow$ Mejor balance entre ajuste y complejidad

#### 3.2.4. BIC para Redes Bayesianas

Para datos continuos (Gaussianos), el BIC tiene la forma:

$$\text{BIC}_g = -2 \sum_{i=1}^{p} \log P(X_i | \text{Pa}(X_i)) + k \log(n)$$

Para datos mixtos (Gaussianos Condicionales):

$$\text{BIC}_{cg} = -2 \sum_{i \in C} \log P(X_i | \text{Pa}(X_i)) - 2 \sum_{j \in D} \log P(X_j | \text{Pa}(X_j)) + k \log(n)$$

donde $C$ son variables continuas y $D$ son variables discretas.

#### 3.2.5. Algoritmo Hill-Climbing

**Hill-Climbing** es un algoritmo de búsqueda heurística que explora el espacio de DAGs para maximizar el score (minimizar BIC).

**Procedimiento**:

**Inicialización**:
- Comenzar con un DAG inicial (vacío o grafo generado aleatoriamente)

**Iteración**:
1. Evaluar todas las operaciones legales:
   - **Agregar arista**: $X \rightarrow Y$ (si no crea ciclo)
   - **Eliminar arista**: Remover $X \rightarrow Y$ existente
   - **Revertir arista**: Cambiar $X \rightarrow Y$ a $X \leftarrow Y$ (si no crea ciclo)

2. Calcular $\Delta\text{BIC}$ para cada operación

3. Seleccionar la operación con mejor mejora:
   $$\text{op}^* = \arg\max_{\text{op}} \Delta\text{BIC}(\text{op})$$

4. Si $\Delta\text{BIC}(\text{op}^*) > 0$: aplicar operación y continuar

5. Si no hay mejora: **terminar** (máximo local alcanzado)

**Restricción de Aciclicidad**: En cada paso, verificar que $\text{DAG} \cup \{\text{nueva arista}\}$ no contenga ciclos dirigidos.

#### 3.2.6. Scores Específicos por Tipo de Datos

**Para datos continuos**: BIC-Gaussiano (`bic-g`)
$$\text{BIC}_g(X_i | \text{Pa}(X_i)) = -\frac{n}{2}\log(2\pi\sigma_i^2) - \frac{n}{2} + |\text{Pa}(X_i)| \log(n)$$

**Para datos mixtos**: BIC-Gaussiano Condicional (`bic-cg`)
- Variables continuas: Regresión lineal condicional a padres discretos
- Variables discretas: Tablas de contingencia

**Selección automática**: El análisis detecta el tipo de datos y selecciona el score apropiado.

---

### 3.3. Análisis de Bootstrap

#### 3.3.1. Objetivo

Evaluar la **robustez** y **estabilidad** de las relaciones causales identificadas mediante remuestreo con reemplazo.

#### 3.3.2. Procedimiento

**Paso 1**: Generar $R = 200$ muestras bootstrap

Para cada muestra bootstrap $b = 1, ..., R$:
- Muestrear con reemplazo $n$ observaciones de los datos originales: $D_b^* \sim \text{Bootstrap}(D)$
- Aprender estructura de BN usando Hill-Climbing: $G_b^* = \text{HC}(D_b^*)$
- Registrar todas las aristas en $G_b^*$

**Paso 2**: Calcular métricas de confianza

Para cada arista potencial $X \rightarrow Y$:

**Fuerza (Strength)**:
$$S(X \rightarrow Y) = \frac{1}{R} \sum_{b=1}^{R} \mathbb{1}[(X \rightarrow Y) \in G_b^* \text{ o } (Y \rightarrow X) \in G_b^*]$$

Proporción de muestras bootstrap que contienen la arista (en cualquier dirección).

**Dirección (Direction)**:
$$D(X \rightarrow Y) = \frac{\sum_{b=1}^{R} \mathbb{1}[(X \rightarrow Y) \in G_b^*]}{\sum_{b=1}^{R} \mathbb{1}[(X \rightarrow Y) \in G_b^* \text{ o } (Y \rightarrow X) \in G_b^*]}$$

Proporción de veces que la arista tiene la dirección $X \rightarrow Y$ cuando está presente.

#### 3.3.3. Criterios de Clasificación

**Relaciones Fuertes**: Se considera una relación causal robusta si:
- $S(X \rightarrow Y) > 0.5$ (presente en más del 50% de las muestras)
- $D(X \rightarrow Y) > 0.5$ (dirección consistente en más del 50% de las veces)

**Interpretación**:
- $S = 0.85, D = 0.92$: Relación muy robusta con dirección muy consistente
- $S = 0.60, D = 0.52$: Relación moderada con dirección apenas consistente
- $S = 0.40, D = 0.80$: Relación débil pero cuando aparece, la dirección es consistente

---

### 3.4. Pruebas de Independencia Condicional

#### 3.4.1. Objetivo

Validar hipótesis específicas sobre independencias condicionales entre variables.

#### 3.4.2. Test de Correlación para Variables Continuas

**Hipótesis**:
- $H_0$: $X \perp\!\!\perp Y \mid Z$ (independencia condicional)
- $H_1$: $X \not\perp Y \mid Z$ (dependencia condicional)

**Estadístico**: Correlación parcial

$$r_{XY \cdot Z} = \text{Corr}(e_X, e_Y)$$

donde $e_X$ y $e_Y$ son los residuos de las regresiones:
- $X = \beta_X^T Z + e_X$
- $Y = \beta_Y^T Z + e_Y$

**Transformación de Fisher**:

$$z = \frac{1}{2}\log\left(\frac{1 + r_{XY \cdot Z}}{1 - r_{XY \cdot Z}}\right) \sim \mathcal{N}\left(0, \frac{1}{n - |Z| - 3}\right)$$

**P-valor**: $p = 2\Phi(-|z|\sqrt{n - |Z| - 3})$ donde $\Phi$ es la función de distribución acumulada normal estándar.

**Decisión**: Rechazar $H_0$ si $p < \alpha$ (típicamente $\alpha = 0.05$).

---

## 4. Flujo de Trabajo del Análisis

### 4.1. Preparación de Datos

```
1. Carga de datos: bdporc_dataC2.RData
2. Selección de variables de interés (13 variables totales)
3. Manejo de valores faltantes: eliminación listwise
4. Conversión de tipos:
   - Variables discretas → factores
   - Variables continuas → numéricos
   - Character → factores (para Company_farm)
```

### 4.2. Análisis con Algoritmo PC

```
Entrada: Variables continuas estandarizadas (n=8)
↓
Cálculo de matriz de correlación
↓
Algoritmo PC (α = 0.05)
↓
Salida: Grafo causal parcialmente dirigido (CPDAG)
↓
Visualización: causal_graph_continuous.pdf
```

### 4.3. Análisis con Redes Bayesianas

```
Entrada: Todas las variables (continuas + discretas)
↓
Detección automática de tipos de datos
↓
Selección de score BIC apropiado:
  - bic-cg para datos mixtos
  - bic-g para solo continuos
  - bic para solo discretos
↓
Hill-Climbing con score seleccionado
↓
Salida: DAG completo
↓
Visualización: causal_graph_bayesian_network.pdf
  (con nodo objetivo resaltado)
```

### 4.4. Análisis de Robustez (Bootstrap)

```
Entrada: Datos completos, estructura aprendida
↓
Para b = 1 hasta 200:
  - Generar muestra bootstrap
  - Aprender estructura BN
  - Registrar aristas
↓
Calcular métricas:
  - Strength (S)
  - Direction (D)
↓
Filtrar relaciones fuertes (S > 0.5, D > 0.5)
↓
Salidas:
  - arc_strength_plot.pdf
  - strong_causal_relationships.csv
  - target_causal_relationships.csv
```

### 4.5. Análisis Específico de Variable Objetivo

```
Identificar padres (causas directas) de losses.born.alive
↓
Identificar hijos (efectos directos)
↓
Construir subgrafo enfocado:
  - Causas → Objetivo
  - Objetivo → Efectos
↓
Visualización: causal_dag_target_focused.pdf
```

---

## 5. Interpretación de Resultados

### 5.1. Grafos Causales

#### Elementos Gráficos

- **Nodos**: Representan variables del sistema
- **Aristas dirigidas** ($X \rightarrow Y$): $X$ es causa directa de $Y$
- **Aristas no dirigidas** ($X - Y$): Asociación sin dirección determinada (solo en CPDAG de PC)
- **Nodo resaltado**: Variable objetivo del análisis

#### Interpretación Causal

**Relación directa**: $X \rightarrow Y$ implica que cambios en $X$ causan cambios en $Y$ (controlando por otras variables)

**Relación indirecta**: $X \rightarrow Z \rightarrow Y$ implica que $X$ afecta a $Y$ a través del mediador $Z$

**Independencia condicional**: Ausencia de arista entre $X$ e $Y$ implica $X \perp\!\!\perp Y \mid \text{resto de variables}$

### 5.2. Métricas de Confianza (Bootstrap)

#### Strength (Fuerza)

- **Rango**: [0, 1]
- **Interpretación**:
  - $S \geq 0.8$: Relación muy robusta
  - $0.5 \leq S < 0.8$: Relación moderadamente robusta
  - $S < 0.5$: Relación débil o inestable

#### Direction (Dirección)

- **Rango**: [0, 1]
- **Interpretación**:
  - $D \geq 0.8$: Dirección muy consistente
  - $0.5 \leq D < 0.8$: Dirección moderadamente consistente
  - $D < 0.5$: Dirección inconsistente

#### Criterio Combinado

Para aceptar una relación causal como confiable:
$$S(X \rightarrow Y) > 0.5 \quad \text{AND} \quad D(X \rightarrow Y) > 0.5$$

### 5.3. Score BIC

**Interpretación**:
- El BIC es una medida de **calidad del modelo** (ajuste vs complejidad)
- Valores más **negativos** (menores) indican mejor modelo
- **Comparación**: Entre dos modelos, preferir el de menor BIC
- **Magnitud absoluta**: No tiene interpretación directa, solo comparativa

**Ejemplo**:
- Modelo A: BIC = -5000
- Modelo B: BIC = -4800
- **Conclusión**: Modelo A es mejor (más negativo)

### 5.4. Identificación de Causas del Objetivo

#### Causas Directas (Padres)

Variables que tienen arista directa hacia `losses.born.alive`:
$$\text{Pa}(\text{losses.born.alive}) = \{X : X \rightarrow \text{losses.born.alive}\}$$

**Interpretación**: Estas variables tienen efecto causal directo sobre las pérdidas de lactación.

#### Causas Indirectas (Ancestros)

Variables que afectan al objetivo a través de otras variables:
$$\text{Anc}(\text{losses.born.alive}) = \{X : \exists \text{ camino dirigido de } X \text{ a losses.born.alive}\}$$

**Interpretación**: Estas variables tienen efecto causal mediado por otras variables.

#### Efectos del Objetivo (Hijos)

Variables afectadas por el objetivo:
$$\text{Ch}(\text{losses.born.alive}) = \{Y : \text{losses.born.alive} \rightarrow Y\}$$

**Interpretación**: (Poco esperado en este contexto, indicaría variables de confusión temporal)

---

## 6. Supuestos y Limitaciones

### 6.1. Supuestos del Análisis

1. **Suficiencia Causal**: Las variables medidas contienen información suficiente para identificar relaciones causales
   - No hay variables confusoras ocultas importantes

2. **Estacionariedad**: Las relaciones causales son estables en el tiempo
   - La estructura causal no cambia entre períodos

3. **No interferencia**: Las observaciones son independientes entre sí
   - Excepto por dependencias explícitas en el modelo

4. **Correcta especificación funcional**:
   - Para PC: Relaciones lineales, errores gaussianos
   - Para BN continuas: Modelos de regresión lineal condicional

5. **Aciclicidad**: No hay bucles de retroalimentación instantánea
   - El sistema puede ser representado como DAG

### 6.2. Limitaciones Metodológicas

1. **Equivalencia de Markov**: Múltiples DAGs pueden representar las mismas independencias condicionales
   - La dirección de algunas aristas puede ser ambigua

2. **Complejidad computacional**: Hill-Climbing encuentra óptimos locales
   - No garantiza encontrar la estructura óptima global

3. **Sensibilidad al tamaño muestral**: 
   - Muestras pequeñas reducen poder estadístico
   - Muestras muy grandes pueden detectar efectos triviales

4. **Causalidad vs Asociación**: Aunque los métodos están diseñados para identificar causalidad, siempre se requiere conocimiento del dominio para validar las inferencias

### 6.3. Consideraciones Prácticas

- Los resultados deben interpretarse junto con conocimiento experto del dominio
- Las relaciones causales identificadas son hipótesis que pueden requerir validación experimental
- La ausencia de relación detectada no implica necesariamente ausencia de causalidad (puede deberse a poder estadístico insuficiente)

---

## 7. Archivos de Salida

### 7.1. Grafos Visuales (PDF)

| Archivo | Descripción | Contenido |
|---------|-------------|-----------|
| `causal_graph_continuous.pdf` | Grafo del algoritmo PC | Solo variables continuas, CPDAG |
| `causal_graph_bayesian_network.pdf` | Red Bayesiana completa | Todas las variables, DAG completo |
| `causal_dag_target_focused.pdf` | Subgrafo enfocado | Causas y efectos directos del objetivo |
| `arc_strength_plot.pdf` | Visualización de fuerza | Grosor de aristas proporcional a strength |

### 7.2. Datos Tabulares (CSV)

| Archivo | Descripción | Columnas |
|---------|-------------|----------|
| `strong_causal_relationships.csv` | Todas las relaciones robustas | from, to, strength, direction |
| `target_causal_relationships.csv` | Relaciones con variable objetivo | from, to, strength, direction |

### 7.3. Workspace Completo (RData)

| Archivo | Descripción | Objetos |
|---------|-------------|---------|
| `causal_analysis_results.RData` | Workspace R completo | Todos los objetos, estructuras, resultados |

---

## 8. Software y Paquetes Utilizados

### 8.1. Entorno Computacional

- **Lenguaje**: R (versión ≥ 4.0.0)
- **IDE recomendado**: RStudio

### 8.2. Paquetes R

#### CRAN

- **bnlearn** (v4.8+): Aprendizaje de estructura de Redes Bayesianas
  - Implementa Hill-Climbing, scores BIC, bootstrap
  - Referencia: Scutari (2010) *Journal of Statistical Software*

- **dplyr**: Manipulación de datos
  - Filtrado, selección, transformación de datos

- **ggplot2**: Visualización de datos
  - Gráficos estadísticos avanzados

#### Bioconductor

- **pcalg** (v2.7+): Implementación del algoritmo PC
  - Referencia: Kalisch et al. (2012) *Journal of Statistical Software*

- **graph**: Estructuras de datos para grafos
  - Requerido por pcalg y Rgraphviz

- **Rgraphviz**: Visualización de grafos
  - Interface R para Graphviz

### 8.3. Instalación

```r
# Instalar CRAN packages
install.packages(c("bnlearn", "dplyr", "ggplot2"))

# Instalar Bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(c("pcalg", "graph", "Rgraphviz"))
```

---

## 9. Referencias Bibliográficas

### 9.1. Metodología de Inferencia Causal

1. **Pearl, J.** (2009). *Causality: Models, Reasoning, and Inference* (2nd ed.). Cambridge University Press.
   - Texto fundamental sobre teoría de causalidad y DAGs

2. **Spirtes, P., Glymour, C., & Scheines, R.** (2000). *Causation, Prediction, and Search* (2nd ed.). MIT Press.
   - Desarrollo del algoritmo PC y fundamentos teóricos

3. **Peters, J., Janzing, D., & Schölkopf, B.** (2017). *Elements of Causal Inference: Foundations and Learning Algorithms*. MIT Press.
   - Perspectiva moderna de inferencia causal con machine learning

### 9.2. Redes Bayesianas

4. **Koller, D., & Friedman, N.** (2009). *Probabilistic Graphical Models: Principles and Techniques*. MIT Press.
   - Tratado comprehensivo sobre modelos gráficos probabilísticos

5. **Scutari, M., & Denis, J.-B.** (2014). *Bayesian Networks: With Examples in R*. CRC Press.
   - Guía práctica con implementaciones en R

### 9.3. Software y Aplicaciones

6. **Scutari, M.** (2010). Learning Bayesian Networks with the bnlearn R Package. *Journal of Statistical Software*, 35(3), 1-22.
   - Documentación del paquete bnlearn

7. **Kalisch, M., Mächler, M., Colombo, D., Maathuis, M. H., & Bühlmann, P.** (2012). Causal Inference Using Graphical Models with the R Package pcalg. *Journal of Statistical Software*, 47(11), 1-26.
   - Documentación del paquete pcalg

### 9.4. Aplicaciones en Producción Animal

8. **Maes, D., Larriestra, A., Deen, J., & Morrison, R.** (2016). A retrospective study of mortality in grow-finish pigs in a multi-site production system. *Journal of Swine Health and Production*, 9(6), 267-273.
   - Contexto de mortalidad porcina

9. **Pandolfi, F., Edwards, S. A., Robert, F., & Kyriazakis, I.** (2017). Risk factors associated with the different categories of piglet perinatal mortality in French farms. *Preventive Veterinary Medicine*, 137, 1-12.
   - Factores de riesgo en mortalidad perinatal

---

## 10. Glosario de Términos

- **DAG (Directed Acyclic Graph)**: Grafo dirigido sin ciclos, representa estructura causal sin retroalimentación instantánea

- **CPDAG (Complete Partially Directed Acyclic Graph)**: Clase de equivalencia de DAGs que comparten las mismas independencias condicionales

- **V-estructura (Colisionador)**: Patrón $X \rightarrow Y \leftarrow Z$ donde $X$ y $Z$ son independientes pero ambos causan $Y$

- **d-separación**: Criterio gráfico para determinar independencia condicional en DAGs

- **Independencia condicional**: $X \perp\!\!\perp Y \mid Z$ significa que $X$ e $Y$ son independientes dado $Z$

- **Bootstrap**: Técnica de remuestreo con reemplazo para evaluar variabilidad y estabilidad de estimadores

- **BIC (Bayesian Information Criterion)**: Criterio para selección de modelos que penaliza complejidad

- **Arco (Arc)**: Arista dirigida en un grafo, representa relación causal directa

- **Padres (Parents)**: Nodos con aristas dirigidas hacia un nodo dado

- **Hijos (Children)**: Nodos con aristas dirigidas desde un nodo dado

- **Ancestros (Ancestors)**: Nodos alcanzables siguiendo aristas dirigidas hacia atrás

- **Descendientes (Descendants)**: Nodos alcanzables siguiendo aristas dirigidas hacia adelante

---

## Apéndice A: Fórmulas Completas

### A.1. Test de Independencia Gaussiana

Para variables continuas $(X, Y)$ con conjunto de condicionamiento $Z$:

**Correlación Parcial**:
$$r_{XY \cdot Z} = \frac{r_{XY} - r_{XZ} r_{YZ}}{\sqrt{(1 - r_{XZ}^2)(1 - r_{YZ}^2)}}$$

**Generalización para $|Z| > 1$**: Usar regresión de $X$ y $Y$ sobre $Z$:
$$r_{XY \cdot Z} = \text{Corr}(\text{residuos}_X, \text{residuos}_Y)$$

**Transformación Fisher**:
$$z = \frac{1}{2}\log\left(\frac{1 + r}{1 - r}\right) = \text{arctanh}(r)$$

**Estadístico de prueba**:
$$T = z \sqrt{n - |Z| - 3} \sim \mathcal{N}(0, 1)$$

**P-valor bilateral**:
$$p = 2 \cdot P(|T| > |t_{\text{obs}}|) = 2 \cdot \Phi(-|t_{\text{obs}}|)$$

### A.2. BIC para Redes Bayesianas Gaussianas

**Likelihood para nodo $X_i$ con padres $\text{Pa}(X_i)$**:

$$L(X_i | \text{Pa}(X_i)) = \prod_{j=1}^{n} \frac{1}{\sqrt{2\pi\sigma_i^2}} \exp\left(-\frac{(x_{ij} - \mu_{ij})^2}{2\sigma_i^2}\right)$$

donde $\mu_{ij} = \beta_0 + \sum_{k \in \text{Pa}(X_i)} \beta_k x_{kj}$

**Log-likelihood**:
$$\log L(X_i | \text{Pa}(X_i)) = -\frac{n}{2}\log(2\pi\sigma_i^2) - \frac{1}{2\sigma_i^2}\sum_{j=1}^{n}(x_{ij} - \mu_{ij})^2$$

**BIC para nodo $X_i$**:
$$\text{BIC}(X_i | \text{Pa}(X_i)) = -2\log L(X_i | \text{Pa}(X_i)) + (|\text{Pa}(X_i)| + 2)\log(n)$$

El término $+2$ cuenta los parámetros: coeficientes de regresión $(\beta_0, \beta_1, ..., \beta_{|\text{Pa}(X_i)|})$ más la varianza $\sigma_i^2$.

**BIC total del grafo $G$**:
$$\text{BIC}(G) = \sum_{i=1}^{p} \text{BIC}(X_i | \text{Pa}_G(X_i))$$

### A.3. Métricas Bootstrap

**Strength (Presencia)**:
$$S(i \rightarrow j) = \frac{1}{R}\sum_{r=1}^{R} \mathbb{1}_{i \rightarrow j \in G_r \text{ o } j \rightarrow i \in G_r}$$

**Direction (Consistencia Direccional)**:
$$D(i \rightarrow j) = \frac{\sum_{r=1}^{R} \mathbb{1}_{i \rightarrow j \in G_r}}{\sum_{r=1}^{R} \mathbb{1}_{i \rightarrow j \in G_r \text{ o } j \rightarrow i \in G_r}}$$

**Interpretación**:
- $S(i \rightarrow j) = 1$: Arista presente en todos los bootstraps
- $D(i \rightarrow j) = 1$: Dirección $i \rightarrow j$ consistente en todas las apariciones
- $D(i \rightarrow j) = 0.5$: Dirección no es consistente (equiprobable $i \rightarrow j$ o $j \rightarrow i$)

---

## Apéndice B: Ejemplo de Interpretación

### Escenario Hipotético

Supongamos que el análisis identifica:

```
prev_sowlactpd → losses.born.alive
  Strength: 0.87
  Direction: 0.94
  
Prev_PBA → losses.born.alive
  Strength: 0.72
  Direction: 0.68
```

### Interpretación

1. **Relación 1**: `prev_sowlactpd → losses.born.alive`
   - **Fuerza**: 0.87 (87% de muestras bootstrap contienen esta arista)
   - **Dirección**: 0.94 (94% de las veces con dirección correcta)
   - **Conclusión**: **Relación causal muy robusta**. El período de lactación previo tiene un efecto causal directo muy consistente sobre las pérdidas de lactación actuales.
   - **Implicación práctica**: Modificar el manejo del período de lactación podría reducir pérdidas en ciclos subsiguientes.

2. **Relación 2**: `Prev_PBA → losses.born.alive`
   - **Fuerza**: 0.72 (72% de muestras bootstrap)
   - **Dirección**: 0.68 (68% con dirección correcta)
   - **Conclusión**: **Relación moderadamente robusta**. El número de lechones nacidos vivos en el parto previo parece afectar las pérdidas actuales, pero con menor consistencia.
   - **Implicación práctica**: Efecto causal probable pero requiere validación adicional antes de implementar intervenciones.

### Recomendaciones

- **Alta prioridad**: Investigar y optimizar el período de lactación (relación muy robusta)
- **Prioridad media**: Monitorear el efecto del tamaño de camada previo (relación moderada)
- **Investigación futura**: Estudiar mecanismos biológicos subyacentes de ambas relaciones

---

**Documento preparado para conversión a formato .docx mediante pandoc**

```bash
# Comando de conversión recomendado:
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.docx --reference-doc=plantilla.docx
```

**Notas**:
- Las fórmulas LaTeX se convertirán a ecuaciones editables en Word
- Se recomienda usar una plantilla de Word (`plantilla.docx`) para formato consistente
- Para mejor compatibilidad, usar pandoc versión 2.0 o superior
