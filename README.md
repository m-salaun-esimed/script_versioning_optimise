# Script d’optimisation du versioning

Lors de la création d’un dépôt GitHub et de son clonage en local, il faut ajouter les deux scripts suivants à la racine du projet :  

- `merge_develop_to_main.sh`  
- `merge_feature.sh`  

---

## Initialisation des branches

Après avoir ajouté les scripts, crée une branche **develop** :  

```bash
git branch develop
git checkout develop
git add .
git commit -m "init branch develop"
git push --set-upstream origin develop
````


## Workflow de développement

Le développement doit se faire dans des branches **feature/xxx**.
Ensuite, ces branches sont mergées dans **develop**, et une fois une version stable validée, elle est propagée dans **main**.

---

### Création d’une branche feature

Exemple :

```bash
git branch feature/test
git checkout feature/test
```

Développe dans cette branche, puis commit et push :

```bash
git add .
git commit -m "init branch feature/test"
git push --set-upstream origin feature/test
```

---

### Merge d’une feature dans develop

Une fois la branche `feature/test` prête à être mergée dans **develop** :

```bash
git checkout develop
./merge_feature.sh
```

---

## Que fait `merge_feature.sh` ?

* Il liste les branches `feature/*` disponibles sur le dépôt distant.

* Après avoir choisi la branche à merger, il demande si cette branche correspond à :

  * une **nouvelle version (v)**
  * une **nouvelle fonctionnalité (f)**
  * un **patch (p)**

* Le script lit dans **`CARNET_BORD.md`** la **dernière version existante**, puis incrémente automatiquement :

  * **v → major**
  * **f → minor**
  * **p → patch**

* Il demande un **message de merge** et une **note complémentaire**.

* Il merge la branche choisie dans **develop** et **met à jour `CARNET_BORD.md`** avec la nouvelle version et les informations saisies.

---

## Ensuite : Merge develop → main

Une fois **develop** stable, on exécute :

```bash
git checkout main
./merge_develop_to_main.sh
```

Ce script :

1. Récupère la dernière version dans develop.
2. Propose d’incrémenter (ou non) la version pour main.
3. Merge develop dans main.
4. Met à jour **`CARNET_BORD.md`** si une nouvelle version est choisie.
5. Tag la version.
6. **Synchronise develop avec main** pour que les deux aient le même carnet de bord.

---

## Résumé du workflow

1. **Créer une branche feature/** → développement
2. **Merge feature → develop** avec `merge_feature.sh`
3. Une fois stable → **Merge develop → main** avec `merge_develop_to_main.sh`
4. Les scripts gèrent automatiquement :

   * l’incrémentation de version
   * la mise à jour de `CARNET_BORD.md`
   * la création du tag

---

**Avantages**

* Versioning automatisé
* Historique propre dans `CARNET_BORD.md`
* Synchronisation des branches garantie
