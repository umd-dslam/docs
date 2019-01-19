#!/bin/bash

set -o errexit -o nounset

echo 'Building...'
mdbook build

cd book

touch .

rev=$(git rev-parse --short HEAD)
git add -A .
git commit -m "rebuild pages at ${rev}"
git push -q upstream HEAD:gh-pages
