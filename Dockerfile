FROM rust as build

ENV LODESTONE_CORE_VERSION=v0.4.4

RUN apt-get update && apt-get install -y wget unzip

RUN mkdir -p /app && \
    wget https://github.com/Lodestone-Team/lodestone_core/archive/refs/tags/${LODESTONE_CORE_VERSION}.zip && \
    unzip ${LODESTONE_CORE_VERSION}.zip && \
    mv lodestone_core-${LODESTONE_CORE_VERSION#v}/* /app && \
    chmod +x /app

WORKDIR /app

RUN cargo build --release --features "vendored-openssl"


FROM debian:bullseye-slim as production

RUN apt-get update \
  && apt-get install -y ca-certificates \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/target/release/main ./

EXPOSE 16662

ENV PUID=1000
ENV PGID=1000

RUN groupadd -g ${PGID} usergroup \
  && useradd -u ${PUID} -g usergroup -m user

RUN mkdir -p /home/user/.lodestone

RUN chown -R $user:usergroup /app /home/user/.lodestone

USER user

VOLUME ["/home/user/.lodestone"]

CMD ["./main"]

