#!/bin/bash

rm -rf deploy/html/dashboard/web
cd dashboard
sh scripts/build-web.sh production 
cp -r build/web ../deploy/html/dashboard/web
cd ..

rm -rf deploy/html/app/web
cd poliglots_app
sh scripts/build-web.sh production 

cp -r build/web ../deploy/html/app/web

