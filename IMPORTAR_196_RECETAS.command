#!/bin/zsh
set -e
cd -- "${0:A:h}"
if ! command -v node >/dev/null 2>&1; then
  echo "Necesitas instalar Node.js para importar las recetas."
  exit 1
fi
printf '\nPASO 1: Comprobando las 196 recetas (sin subir nada)...\n'
node tool/import_recipe_drafts.mjs
printf '\nPASO 2: Importar borradores a Supabase.\n'
read -r 'decision?¿Quieres subir las 196 recetas ahora? (s/n): '
if [[ "$decision" != "s" && "$decision" != "S" ]]; then
  echo "Importación cancelada. Ninguna receta fue subida."
  exit 0
fi
read -rs 'SUPABASE_SERVICE_ROLE_KEY?Pega tu clave SERVICE_ROLE de Supabase y pulsa Enter (no se muestra): '
printf '\n'
export SUPABASE_SERVICE_ROLE_KEY
if [[ -z "$SUPABASE_SERVICE_ROLE_KEY" ]]; then
  echo 'La clave está vacía; no se ha realizado ninguna importación.'
  exit 1
fi
printf '\nSubiendo recetas como BORRADORES...\n'
node tool/import_recipe_drafts.mjs --apply
unset SUPABASE_SERVICE_ROLE_KEY
printf '\nLISTO. Comprueba en Supabase SQL Editor:\n'
printf "SELECT status, COUNT(*) FROM public.miga_recipes GROUP BY status;\n"
