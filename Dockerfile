# Stage 1: Build OpenRailRouting from source
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Clone the repo at the v1.1 release tag
RUN apt-get update && apt-get install -y git && \
    git clone --depth 1 --branch v1.1 \
    https://github.com/geofabrik/OpenRailRouting.git .

# Build the JAR (skip tests to keep build fast)
RUN mvn clean package -DskipTests -q

# Stage 2: Runtime image — much smaller, no Maven/JDK needed
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy only the built JAR from Stage 1
COPY --from=builder /build/target/railway_routing-*.jar railway_routing.jar

# Copy your config and OSM data
COPY config.yml .
COPY india-rail.osm.pbf .

# GraphHopper/OpenRailRouting runs on port 8989 by default
EXPOSE 8989

# On startup: import the OSM data and start serving
# -Xmx450m limits memory to stay within Render's free tier (512MB RAM)
CMD ["java", "-Xmx450m", "-Xms50m", \
     "-Ddw.graphhopper.datareader.file=india-rail.osm.pbf", \
     "-jar", "railway_routing.jar", \
     "serve", "config.yml"]
