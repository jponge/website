#!/bin/sh
set -ea

GHP_DIR=_gh-pages
REPO=https://github.com/jponge/website.git

echo "⚙️  Building..."
bundle exec jekyll clean
bundle exec jekyll build

echo "\n⚙️  Copying to gh-pages..."
rm -rf ${GHP_DIR}
git clone --depth=1 --branch gh-pages $REPO ${GHP_DIR}
rm -rf ${GHP_DIR}/*
cp -R _site/* ${GHP_DIR}
cd ${GHP_DIR}
git add -A
git commit -m "New build"

echo "\n️🚀   Push..."
git push $REPO gh-pages
