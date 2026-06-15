# Polyglots.social

## Create school - Manual 

1. Add a record with school_slug -- *.works
2. Add the school to the api cors 
3. Add add school_slug.app.polyglots.social and school_slug.dashboard.polyglots.social
4. create the certificates with certbot
5. create the new nginx configuration
6. will require a auth0 configuration and new redirect - for the future it is maybe easier as I can add costs the login to the school charge. 


## Create school - Automatic
Create a scripts that does all the above 


## Build clients
./scripts/build-web.sh production --deploy