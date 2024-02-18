FROM ghcr.io/gleam-lang/gleam:v0.34.1-erlang-alpine


RUN apk add --no-cache gcc build-base ca-certificates

COPY . /source

RUN cd /source && gleam build && gleam export erlang-shipment \
 && mv build/erlang-shipment /app \
 && cd .. && rm -r /source && apk del gcc build-base

WORKDIR /app
EXPOSE 3000
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
