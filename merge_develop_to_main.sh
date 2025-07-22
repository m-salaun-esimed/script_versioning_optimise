#!/bin/bash

set -e

CARNET="CARNET_BORD.md"

echo "📌 Passage sur main et mise à jour..."
git checkout main
git pull origin main

echo "📌 Récupération de la dernière version dans develop..."
git fetch origin develop
git show origin/develop:$CARNET > /tmp/$CARNET

last_line=$(grep "^-" /tmp/$CARNET | tail -n 1)
last_version=$(echo "$last_line" | awk '{print $2}')
if [ -z "$last_version" ]; then
  echo "❌ Pas de version trouvée dans $CARNET (develop), on part sur 0.0.0"
  last_version="0.0.0"
fi

IFS='.' read -r major minor patch <<< "$last_version"
echo "✅ Dernière version de develop détectée : $last_version"

echo -e "\nChoisis la version pour main :"
echo "1) Garder la même ($last_version)"
echo "2) Incrémenter patch ($major.$minor.$((patch+1)))"
echo "3) Incrémenter minor ($major.$((minor+1)).0)"
echo "4) Incrémenter major ($((major+1)).0.0)"
read -p "Choix (1-4) : " choice

case $choice in
  1)
    new_version="$last_version"
    ;;
  2)
    patch=$((patch+1))
    new_version="$major.$minor.$patch"
    ;;
  3)
    minor=$((minor+1))
    patch=0
    new_version="$major.$minor.$patch"
    ;;
  4)
    major=$((major+1))
    minor=0
    patch=0
    new_version="$major.$minor.$patch"
    ;;
  *)
    echo "❌ Choix invalide."
    exit 1
    ;;
esac

echo "✅ Nouvelle version pour main : $new_version"

echo "📌 Mise à jour de develop avant merge..."
git fetch origin develop

echo "📌 Merge develop dans main..."
git merge --no-ff origin/develop -m "Release v$new_version"

# Si on a changé la version, on ajoute une ligne dans le carnet
if [ "$new_version" != "$last_version" ]; then
  echo -n "📝 Message complémentaire pour la release main : "
  read msg_compl

  new_line="- $new_version - develop -> main - release - $msg_compl"
  echo "$new_line" >> "$CARNET"

  git add "$CARNET"
  git commit -m "📖 Maj carnet de bord pour release v$new_version"
fi

echo "Push main + tag..."
git push origin main
git tag -a "v$new_version" -m "Tag version $new_version"
git push origin "v$new_version"

echo "Synchronisation develop avec la dernière version de main..."
git checkout main
git pull origin main

echo "Mise à jour de develop avec les dernières modifs de main..."
git checkout develop
git pull origin develop
git merge --no-ff main -m "Sync main (v$new_version) vers develop"
git push origin develop

git checkout main

echo -e "\n✅ Merge develop -> main terminé, version taggée $new_version et carnet synchronisé avec develop."
