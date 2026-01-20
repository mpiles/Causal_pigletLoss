# Guía de Conversión a Word

Este documento explica cómo convertir `METODOLOGIA_DETALLADA.md` a formato Word (.docx) con fórmulas LaTeX editables.

## Requisitos

### Instalar Pandoc

**Windows:**
1. Descargar desde: https://pandoc.org/installing.html
2. Ejecutar el instalador
3. Reiniciar terminal/PowerShell

**macOS:**
```bash
brew install pandoc
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install pandoc
```

## Conversión Básica

### Comando Simple

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.docx
```

Este comando:
- Lee el archivo markdown con fórmulas LaTeX
- Convierte a formato .docx
- Las fórmulas LaTeX se convierten a ecuaciones de Word editables

## Conversión Avanzada (Recomendada)

### Con Plantilla de Word

Si deseas mantener un estilo específico, crea primero una plantilla:

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.docx --reference-doc=plantilla.docx
```

La plantilla debe ser un archivo .docx con:
- Estilos de párrafo personalizados
- Fuentes y tamaños deseados
- Márgenes y orientación

### Con Tabla de Contenidos

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.docx --toc --toc-depth=3
```

Opciones:
- `--toc`: Genera tabla de contenidos automática
- `--toc-depth=3`: Incluye hasta 3 niveles de encabezados

### Con Numeración de Secciones

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.docx --number-sections
```

### Comando Completo (Todas las opciones)

```bash
pandoc METODOLOGIA_DETALLADA.md \
  -o METODOLOGIA_DETALLADA.docx \
  --reference-doc=plantilla.docx \
  --toc \
  --toc-depth=3 \
  --number-sections \
  --highlight-style=tango
```

## Verificación de Fórmulas en Word

Después de la conversión:

1. Abrir `METODOLOGIA_DETALLADA.docx` en Microsoft Word
2. Hacer clic en cualquier fórmula
3. Debe aparecer la pestaña "Diseño de ecuación"
4. Las fórmulas son completamente editables

### Ejemplo de Fórmulas Convertidas

Las fórmulas LaTeX como:
```latex
$$P(X, Y | Z) = P(X | Z) \cdot P(Y | Z)$$
```

Se convierten a ecuaciones de Word editables con:
- Símbolos matemáticos correctos
- Formato profesional
- Capacidad de edición completa

## Solución de Problemas

### Problema: "pandoc: command not found"

**Solución**: Instalar pandoc (ver sección Requisitos)

### Problema: Fórmulas no se ven correctamente

**Solución**: Asegurarse de usar:
- Pandoc versión 2.0 o superior
- Microsoft Word 2010 o superior (para ecuaciones editables)

Verificar versión:
```bash
pandoc --version
```

### Problema: Formato no se respeta

**Solución**: Usar una plantilla de referencia:
1. Crear documento Word con formato deseado
2. Guardar como `plantilla.docx`
3. Usar opción `--reference-doc=plantilla.docx`

## Conversión a Otros Formatos

### PDF (requiere LaTeX instalado)

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.pdf --pdf-engine=xelatex
```

### HTML

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.html --standalone --mathjax
```

La opción `--mathjax` renderiza las fórmulas LaTeX en el navegador.

### ODT (LibreOffice/OpenOffice)

```bash
pandoc METODOLOGIA_DETALLADA.md -o METODOLOGIA_DETALLADA.odt
```

## Edición Post-Conversión en Word

### Ajustes Recomendados

1. **Revisar saltos de página**: Ajustar para evitar tablas/fórmulas cortadas
2. **Actualizar tabla de contenidos**: Clic derecho → Actualizar campo
3. **Ajustar márgenes**: Diseño → Márgenes
4. **Verificar numeración**: Asegurar consistencia en secciones
5. **Revisar tablas**: Ajustar anchos de columna si es necesario

### Modificar Fórmulas

Para editar una fórmula en Word:
1. Clic sobre la fórmula
2. Aparece la pestaña "Diseño de ecuación"
3. Modificar usando:
   - Panel de símbolos matemáticos
   - Escritura directa con LaTeX (Alt + =)
   - Menús de estructuras (fracciones, raíces, etc.)

## Script de Conversión Automática

Puedes crear un script para conversión rápida:

**Windows (PowerShell):**
```powershell
# convert.ps1
pandoc METODOLOGIA_DETALLADA.md `
  -o METODOLOGIA_DETALLADA.docx `
  --toc --number-sections
Write-Host "Conversión completada: METODOLOGIA_DETALLADA.docx"
```

**Linux/macOS (Bash):**
```bash
#!/bin/bash
# convert.sh
pandoc METODOLOGIA_DETALLADA.md \
  -o METODOLOGIA_DETALLADA.docx \
  --toc --number-sections
echo "Conversión completada: METODOLOGIA_DETALLADA.docx"
```

## Recursos Adicionales

- **Documentación Pandoc**: https://pandoc.org/MANUAL.html
- **Fórmulas LaTeX**: https://katex.org/docs/supported.html
- **Plantillas Word**: https://github.com/jgm/pandoc/wiki/User-contributed-templates

## Soporte

Para problemas con la conversión, verificar:
1. Versión de pandoc (`pandoc --version`)
2. Versión de Word (ecuaciones editables requieren Word 2010+)
3. Sintaxis LaTeX correcta en el documento original

---

**Nota**: El documento `METODOLOGIA_DETALLADA.md` está preparado específicamente para conversión con pandoc, con todas las fórmulas en formato LaTeX estándar compatible.
