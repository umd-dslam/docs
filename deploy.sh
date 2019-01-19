#!/bin/bash

set -o errexit -o nounset

rev=$(git rev-parse --short HEAD)

rm -rf book

echo 'Building...'
mdbook build

cd book && mv html/* . && rm -rf html

git init
git config user.name "${U_NAME}"
git config user.email "${U_EMAIL}"

git add .
git commit -m "rebuild pages at ${rev}"
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:${P_BRANCH}

