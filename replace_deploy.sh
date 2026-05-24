#!/bin/bash

rm -rf deploy/html/app/web
rm -rf deploy/html/dashboard/web

cp -r poliglots_app/build/web deploy/html/app/web
cp -r dashboard/build/web deploy/html/dashboard/web