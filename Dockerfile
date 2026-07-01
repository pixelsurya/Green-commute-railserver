# Stage 1: Build OpenRailRouting from source
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y git nodejs npm && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v1.1 \
    https://github.com/geofabrik/OpenRailRouting.git .

RUN mvn clean package -DskipTests -q

# List JAR contents to find where custom profile JSONs actually are
RUN jar tf /build/target/railway_routing-*.jar | grep -i "json\|profile\|custom" || true

# Copy the entire source custom_profiles directory to filesystem
RUN mkdir -p /custom_models && \
    cp /build/src/main/resources/com/graphhopper/custom_profiles/alltracks.json \
       /custom_models/ || \
    find /build/src -name "alltracks.json" -exec cp {} /custom_models/ \; || \
    find /build -name "*.json" | head -20

# Stage 2: Runtime image
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY --from=builder /build/target/railway_routing-*.jar railway_routing.jar
COPY --from=builder /custom_models/ ./custom_models/
COPY config.yml .
COPY india-rail.osm.pbf .

EXPOSE 8989

CMD ["java", "-Xmx450m", "-Xms50m", \
     "-Ddw.graphhopper.datareader.file=india-rail.osm.pbf", \
     "-jar", "railway_routing.jar", \
     "serve", "config.yml"]
