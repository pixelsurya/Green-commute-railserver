# Use Java 17 slim — OpenRailRouting needs Java to run
FROM eclipse-temurin:17-jre-jammy

# Install wget to download OSM data at build time
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Set working directory inside the container
WORKDIR /app

# Download OpenRailRouting JAR from GitHub releases
# This is the prebuilt JAR so you don't need to compile Java yourself
ARG ORR_VERSION=0.0.1-SNAPSHOT
RUN wget -O railway_routing.jar \
    https://github.com/geofabrik/OpenRailRouting/releases/latest/download/railway_routing.jar

# Copy your config and OSM data into the container
COPY config.yml .
COPY india-rail.osm.pbf .

# GraphHopper/OpenRailRouting runs on port 8989 by default
EXPOSE 8989

# On startup: import the OSM data and start serving
# -Xmx512m limits memory to stay within Render's free tier (512MB RAM)
CMD ["java", "-Xmx450m", "-Xms50m", \
     "-Ddw.graphhopper.datareader.file=india-rail.osm.pbf", \
     "-jar", "railway_routing.jar", \
     "serve", "config.yml"]
