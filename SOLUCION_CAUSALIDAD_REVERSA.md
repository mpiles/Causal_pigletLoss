# Explicación de la Solución al Problema de Causalidad Reversa

## Problema Identificado

El análisis mostraba que la variable ambiental `F_light_hr` (horas de luz al parto) era **causalmente afectada** por variables reproductivas como:
- `prev_PBA` (lechones nacidos vivos previos)
- `Prev_PBD.cat` (lechones nacidos muertos previos, categórica)
- `avg.sows` (promedio de cerdas)

**¿Por qué esto es un problema?**

Esta relación causal es **biológicamente imposible** porque:
1. Las horas de luz son determinadas por factores externos (estación del año, latitud, política de iluminación de la granja)
2. Las variables reproductivas **NO pueden causar** las horas de luz
3. La dirección correcta es: horas de luz → resultados reproductivos (el fotoperiodo afecta la reproducción)

## Causa del Problema

Los algoritmos de descubrimiento causal (como PC y Hill-Climbing) pueden inferir direcciones causales incorrectas cuando:

1. **Variables confusoras no observadas**: La estación del año afecta tanto las horas de luz como el rendimiento reproductivo
2. **Correlaciones espurias**: Variables correlacionadas a través de una causa común (estación) pueden parecer causalmente relacionadas
3. **Falta de conocimiento del dominio**: El algoritmo no conoce qué relaciones son biológicamente plausibles

### Ejemplo del Problema

Sin restricciones, el algoritmo podría inferir:
```
Estación (no observada/medida explícitamente)
    ↓
prev_PBA ← correlación → F_light_hr
```

El algoritmo "ve" la correlación y puede inferir incorrectamente:
```
prev_PBA → F_light_hr (INCORRECTO)
```

Cuando la realidad es:
```
Estación → F_light_hr
Estación → prev_PBA
```

## Solución Implementada

Se han agregado **restricciones de conocimiento del dominio** al análisis causal usando **listas negras (blacklists)**.

### Qué hace la solución:

1. **Identifica variables ambientales**: `F_light_hr`, `AI_light_hr`

2. **Crea lista negra**: Bloquea TODAS las aristas de la forma `X → variable_ambiental`

3. **Permite direcciones correctas**: Las variables ambientales SÍ pueden causar otras variables

### Código implementado

En `causal_analysis.R`, líneas 426-487:

```r
# Identificar variables ambientales
environmental_vars <- c()
if ("F_light_hr" %in% names(bnlearn_data)) {
  environmental_vars <- c(environmental_vars, "F_light_hr")
}
if ("AI_light_hr" %in% names(bnlearn_data)) {
  environmental_vars <- c(environmental_vars, "AI_light_hr")
}

# Crear lista negra
blacklist_edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)

for (env_var in environmental_vars) {
  other_vars <- setdiff(names(bnlearn_data), env_var)
  for (other_var in other_vars) {
    # Bloquear: other_var → env_var
    blacklist_edges <- rbind(blacklist_edges,
                             data.frame(from = other_var, to = env_var))
  }
}

# Aprender estructura con restricciones
bn_structure <- hc(bnlearn_data, score = selected_score, blacklist = blacklist_edges)
```

### Relaciones bloqueadas (ejemplos)

❌ `prev_PBA → F_light_hr` (BLOQUEADA)
❌ `avg.sows → F_light_hr` (BLOQUEADA)
❌ `Prev_PBD.cat → F_light_hr` (BLOQUEADA)
❌ `losses.born.alive → F_light_hr` (BLOQUEADA)

### Relaciones permitidas (ejemplos)

✅ `F_light_hr → losses.born.alive` (PERMITIDA)
✅ `F_light_hr → prev_PBA` (PERMITIDA)
✅ `AI_light_hr → losses.born.alive` (PERMITIDA)

## Justificación Biológica

### Por qué las horas de luz pueden afectar la reproducción:

1. **Regulación hormonal**: El fotoperiodo afecta la producción de melatonina y hormonas reproductivas
2. **Comportamiento materno**: La luz influye en el comportamiento de cuidado maternal
3. **Estrés térmico**: La luz está asociada con temperatura y confort ambiental
4. **Ritmos circadianos**: El ciclo luz-oscuridad regula procesos fisiológicos

### Por qué los resultados reproductivos NO pueden afectar las horas de luz:

1. Las horas de luz son una **variable exógena** (externa al sistema productivo)
2. Están determinadas por:
   - Latitud geográfica
   - Época del año (estación)
   - Políticas de iluminación artificial de la granja
3. No hay mecanismo biológico por el cual los cerdos puedan "causar" cambios en el fotoperiodo

## Resultados Esperados

Con las restricciones implementadas, el análisis ahora:

1. **NO mostrará** relaciones de la forma: `variable_reproductiva → F_light_hr`
2. **SÍ puede mostrar** relaciones de la forma: `F_light_hr → variable_reproductiva`
3. **Respeta** el conocimiento biológico del dominio
4. **Evita** inferencias causales imposibles

## Documentación Actualizada

Los siguientes archivos han sido actualizados con información sobre las restricciones:

1. **causal_analysis.R**: Código con implementación de restricciones (líneas 426-487, 629-636)
2. **METODOLOGIA_DETALLADA.md**: Sección 6.3 sobre restricciones de conocimiento del dominio
3. **ANALYSIS_README.md**: Nueva sección "Domain Knowledge Constraints"
4. **test_domain_constraints.R**: Script de prueba para validar las restricciones

## Cómo Ejecutar el Análisis Corregido

El análisis ahora aplica automáticamente las restricciones. Simplemente ejecute:

```r
source("causal_analysis.R")
```

El script mostrará:

```
*** Applying Domain Knowledge Constraints ***
Environmental variables identified: F_light_hr, AI_light_hr
These variables can only be CAUSES, not EFFECTS (based on biological knowledge)

Blacklisted XXX edges to prevent environmental variables from being effects
Examples of blacklisted relationships:
  - prev_PBA -> F_light_hr (BLOCKED: reproductive variable cannot cause light hours)
  - avg.sows -> F_light_hr (BLOCKED: herd size cannot cause light hours)
  - Prev_PBD.cat -> F_light_hr (BLOCKED: mortality cannot cause light hours)

Structure learning completed with domain knowledge constraints applied.
```

## Validación

Para validar que las restricciones funcionan correctamente:

```r
Rscript test_domain_constraints.R
```

Este script:
1. Crea datos de prueba
2. Aprende estructura SIN restricciones (puede mostrar problemas)
3. Aprende estructura CON restricciones (corregido)
4. Verifica que NO hay aristas causando variables ambientales

## Referencias

- **Pearl, J.** (2009). *Causality: Models, Reasoning, and Inference*. Cambridge University Press.
  - Capítulo sobre conocimiento previo y restricciones en grafos causales

- **Scutari, M. & Denis, J.B.** (2014). *Bayesian Networks: With Examples in R*. CRC Press.
  - Sección sobre blacklists y whitelists en aprendizaje de estructura

## Conclusión

La solución implementada corrige el problema de causalidad reversa incorporando conocimiento biológico al proceso de descubrimiento causal. Esto asegura que:

1. Las inferencias causales sean **biológicamente plausibles**
2. Las variables ambientales mantengan su **rol correcto** como causas, no efectos
3. Los resultados sean **interpretables** y **accionables** para mejorar el manejo reproductivo

---

**Fecha de implementación**: 2026-01-20
**Autor**: GitHub Copilot Agent
