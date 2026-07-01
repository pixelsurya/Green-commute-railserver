# Stage 1: Build OpenRailRouting from source
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y git nodejs npm && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v1.1 \
    https://github.com/geofabrik/OpenRailRouting.git .

RUN mvn clean package -DskipTests -q

# Extract the built-in custom model JSON files from the JAR
# so they're available on the filesystem at runtime
RUN mkdir -p /custom_models && \
    cd /custom_models && \
    jar xf /build/target/railway_routing-*.jar \
    com/graphhopper/custom_profiles/alltracks.json && \
    cp com/graphhopper/custom_profiles/alltracks.json . && \
    rm -rf com

# Stage 2: Runtime image
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY --from=builder /build/target/railway_routing-*.jar railway_routing.jar
COPY --from=builder /custom_models/alltracks.json ./custom_models/alltracks.json
COPY config.yml .
COPY india-rail.osm.pbf .

EXPOSE 8989

CMD ["java", "-Xmx450m", "-Xms50m", \
     "-Ddw.graphhopper.datareader.file=india-rail.osm.pbf", \
     "-jar", "railway_routing.jar", \
     "serve", "config.yml"]
