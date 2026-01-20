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
5. **NUEVO**: Respeta el ordenamiento temporal (eventos futuros no causan eventos pasados)

## Restricciones de Ordenamiento Temporal (NUEVO)

### Problema de Violaciones Temporales

Además de las variables exógenas, se identificó que el análisis mostraba **violaciones del ordenamiento temporal**, donde eventos futuros causaban eventos pasados:

**Ejemplo problemático**:
```
previous_weaned → prev_PBA  (INCORRECTO)
previous_weaned → Prev_PBD.cat  (INCORRECTO)
previous_weaned → prev_sowlactpd  (INCORRECTO)
```

**Interpretación errónea**: Estos resultados sugerirían que el número de lechones destetados (evento que ocurre AL FINAL de la lactación) **causa** el número de lechones nacidos o la duración de la lactación (eventos que ocurren ANTES). Esto viola el principio fundamental de causalidad: las causas preceden a los efectos en el tiempo.

### Solución: Restricciones Temporales

Se implementaron **restricciones de ordenamiento temporal** que respetan la secuencia cronológica del ciclo reproductivo:

**Secuencia Temporal**:
1. **Nacimiento** (T1 - primero): `prev_PBA`, `Prev_PBD.cat` (lechones nacidos vivos/muertos)
2. **Lactación** (T2): `prev_sowlactpd` (duración del período de lactación)
3. **Destete** (T3 - último): `previous_weaned` (lechones destetados)

**Código implementado**:

```r
# Restricciones de ordenamiento temporal
temporal_constraints <- list(
  list(
    later = c("previous_weaned", "Previous_weaned"),  # Evento posterior (T3)
    earlier = c("prev_PBA", "Prev_PBA",               # Eventos anteriores (T1)
                "prev_PBD.cat", "Prev_PBD.cat",       
                "prev_sowlactpd", "Prev_sowlactpd")   # (T2)
  )
)

# Bloquear: evento_futuro → evento_pasado
for (later_var in later_vars) {
  for (earlier_var in earlier_vars) {
    blacklist_edges <- rbind(blacklist_edges,
                             data.frame(from = later_var, to = earlier_var))
  }
}
```

### Relaciones Bloqueadas (Temporalmente Imposibles)

❌ `previous_weaned → prev_PBA` (BLOQUEADA: destete no puede causar número de nacidos)  
❌ `previous_weaned → Prev_PBD.cat` (BLOQUEADA: destete no puede causar mortinatos)  
❌ `previous_weaned → prev_sowlactpd` (BLOQUEADA: destete no puede causar duración de lactación)

### Relaciones Permitidas (Orden Temporal Correcto)

✅ `prev_PBA → previous_weaned` (PERMITIDA: nacidos vivos puede afectar destetados)  
✅ `Prev_PBD.cat → previous_weaned` (PERMITIDA: mortinatos puede afectar destetados)  
✅ `prev_sowlactpd → previous_weaned` (PERMITIDA: duración lactación puede afectar destetados)

### Justificación

**Principio de causalidad temporal**: Un evento en el tiempo T2 no puede causar un evento en el tiempo T1 si T2 > T1.

En el ciclo reproductivo:
- El destete ocurre **DESPUÉS** del nacimiento y la lactación
- Por lo tanto, el destete puede ser **efecto** de variables de nacimiento/lactación
- Pero el destete **NO puede ser causa** de variables de nacimiento/lactación

## Documentación Actualizada

Los siguientes archivos han sido actualizados con información sobre las restricciones:

1. **causal_analysis.R**: Código con implementación de restricciones (líneas 426-557, 710-717)
   - Restricciones exógenas (líneas 426-494)
   - **NUEVO**: Restricciones temporales (líneas 496-557)
2. **METODOLOGIA_DETALLADA.md**: Sección 6.3 sobre restricciones de conocimiento del dominio
   - **NUEVO**: Subsección 6.3.5 sobre ordenamiento temporal
3. **ANALYSIS_README.md**: Nueva sección "Domain Knowledge Constraints"
   - **NUEVO**: Subsección sobre "Temporal Ordering Constraints"
4. **test_domain_constraints.R**: Script de prueba para validar las restricciones
   - **NUEVO**: Validación de restricciones temporales

## Cómo Ejecutar el Análisis Corregido

El análisis ahora aplica automáticamente las restricciones. Simplemente ejecute:

```r
source("causal_analysis.R")
```

El script mostrará:

```
*** Applying Domain Knowledge Constraints ***
Exogenous variables identified: f_light_hr, AI_light_hr, avg.sows, Year, Seasons, company_farm
These variables can only be CAUSES, not EFFECTS (based on domain knowledge)

Blacklisted XXX edges to prevent exogenous variables from being effects
Categories of exogenous variables:
  - Environmental: f_light_hr, AI_light_hr (photoperiod determined by season)
  - Temporal: Year, Seasons, yearseason (time cannot be caused)
  - Farm identity: company_farm (farm ID is fixed)
  - Herd size: avg.sows (management decision, not outcome)

*** Applying Temporal Ordering Constraints ***
Temporal constraint: Variables at later timepoint cannot cause earlier variables
  Later (cannot be causes of earlier): previous_weaned
  Earlier (can cause later): prev_PBA, Prev_PBD.cat, prev_sowlactpd

Blacklisted XX edges to enforce temporal ordering
Examples of temporally impossible relationships blocked:
  - previous_weaned -> prev_PBA (BLOCKED: weaning cannot cause birth count)
  - previous_weaned -> Prev_PBD.cat (BLOCKED: weaning cannot cause stillbirth count)
  - previous_weaned -> prev_sowlactpd (BLOCKED: weaning cannot cause lactation duration)

Structure learning completed with domain knowledge and temporal ordering constraints applied.
Total blacklisted edges: XXX
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
