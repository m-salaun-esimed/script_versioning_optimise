#!/bin/bash

set -e

CARNET="CARNET_BORD.md"

echo "Passage sur develop et mise à jour..."
git checkout develop
git pull origin develop

echo -e "\nBranches disponibles :"
branches=($(git branch -r | grep "feature/" | sed 's|origin/||' | sort -u))

if [ ${#branches[@]} -eq 0 ]; then
  echo "Aucune branche feature/ trouvée."
  exit 1
fi

for i in "${!branches[@]}"; do
  echo "$((i+1)). ${branches[$i]}"
done

echo -ne "\nChoisis une branche (numéro) : "
read -r choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#branches[@]} ]; then
  echo "Choix invalide."
  exit 1
fi

branch_to_merge=${branches[$((choice-1))]}
echo "Branche sélectionnée : $branch_to_merge"

if [[ -n "$(git status --porcelain)" ]]; then
  echo -e "\nLa branche locale contient des modifications non commit."
  read -rp "Voulez-vous les stasher automatiquement ? (o/n) : " stash_choice
  if [[ "$stash_choice" =~ ^[oOyY]$ ]]; then
    git stash push -m "stash auto avant merge $branch_to_merge"
    echo "✅ Changements stashed temporairement."
  else
    echo "Annulation du script."
    exit 1
  fi
fi

git fetch origin "$branch_to_merge"
LOCAL=$(git rev-parse "$branch_to_merge" 2>/dev/null || echo "")
REMOTE=$(git rev-parse "origin/$branch_to_merge" 2>/dev/null || echo "")

if [ -z "$LOCAL" ]; then
  echo "Branche locale inexistante, création temporaire..."
  git branch "$branch_to_merge" "origin/$branch_to_merge"
  LOCAL=$(git rev-parse "$branch_to_merge")
fi

if [ "$LOCAL" != "$REMOTE" ]; then
  echo -e "\nLa branche $branch_to_merge n’est pas synchronisée avec origin."
  read -rp "Voulez-vous faire un pull automatique ? (o/n) : " pull_choice
  if [[ "$pull_choice" =~ ^[oOyY]$ ]]; then
    git checkout "$branch_to_merge"
    git pull origin "$branch_to_merge"
    git checkout develop
    echo "Branche synchronisée."
  else
    echo "Annulation du merge."
    exit 1
  fi
fi

echo -ne "\nType de version ? (v=major, f=feature/minor, p=patch) : "
read -r version_type

last_line=$(grep "^-" "$CARNET" | tail -n 1 || echo "")
last_version=$(echo "$last_line" | awk '{print $2}')

if [ -z "$last_version" ]; then
  echo "Pas de version trouvée, on part sur 0.0.0"
  last_version="0.0.0"
fi

echo "Dernière version détectée : $last_version"

IFS='.' read -r major minor patch <<< "$last_version"

case $version_type in
  f)
    minor=$((minor+1))
    patch=0
    ;;
  p)
    patch=$((patch+1))
    ;;
  v)
    major=$((major+1))
    minor=0
    patch=0
    ;;
  *)
    echo "Type inconnu. Utilise f/p/v"
    exit 1
    ;;
esac

new_version="$major.$minor.$patch"
echo "Nouvelle version : $new_version"

echo -ne "\nMessage de merge (court) : "
read -r msg_merge

echo -ne "Message complémentaire : "
read -r msg_compl

echo -e "\nRésumé avant merge :"
echo "  • Branche        : $branch_to_merge"
echo "  • Nouvelle version : v$new_version"
echo "  • Message court    : $msg_merge"
echo "  • Message compl.   : $msg_compl"
read -rp "Confirmer le merge ? (o/n) : " confirm_merge
if [[ ! "$confirm_merge" =~ ^[oOyY]$ ]]; then
  echo "Merge annulé."
  exit 1
fi

echo -e "\nMerge $branch_to_merge dans develop..."
git merge --no-ff "origin/$branch_to_merge" -m "v$new_version $msg_merge"

new_line="- $new_version - $branch_to_merge - $msg_merge - $msg_compl"
echo "$new_line" >> "$CARNET"
echo "Ajouté dans $CARNET : $new_line"

git add "$CARNET"
git commit -m "Maj carnet de bord v$new_version"
git push origin develop

read -rp "Voulez-vous supprimer la branche feature/$branch_to_merge après merge ? (o/n) : " del_choice
if [[ "$del_choice" =~ ^[oOyY]$ ]]; then
  git push origin --delete "$branch_to_merge"
  echo "Branche distante $branch_to_merge supprimée."
fi

echo -e "\nMerge terminé avec succès !"
echo "Version : v$new_version"
echo "Branche mergée : $branch_to_merge"
[ "$del_choice" = "o" ] && echo "Branche supprimée après merge."

if git stash list | grep -q "stash auto avant merge $branch_to_merge"; then
  read -rp "Voulez-vous réappliquer vos changements stashed ? (o/n) : " pop_choice
  if [[ "$pop_choice" =~ ^[oOyY]$ ]]; then
    git stash pop
    echo "changements restaurés."
  else
    echo "Les changements restent dans le stash."
  fi
fi