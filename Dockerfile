FROM rust:trixie AS builder

COPY --from=golang:1.26-trixie /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:$PATH" \
    GOTOOLCHAIN=local

WORKDIR /src
COPY . .

ENV RUSTFLAGS="-C target-feature=+crt-static"
RUN cargo install --locked --path . --bin rustbin \
    --target "$(uname -m)-unknown-linux-gnu" --root /out \
    && mkdir /out/data

FROM scratch
COPY --from=builder /out/bin/rustbin /rustbin
COPY --from=builder /out/data /data

ENV HOST=0.0.0.0
ENV PORT=3000
ENV DATABASE_URL=sqlite:///data/rustbin.db
ENV MAX_PASTE_SIZE=2MB
ENV CLASSIFIER_MAX_BYTES=64KB
ENV HIGHLIGHT_MAX_BYTES=256KB
ENV RENDER_CACHE_CAPACITY=128
ENV CLEANUP_INTERVAL=3600
ENV DB_MIN_CONNECTIONS=1
ENV DB_MAX_CONNECTIONS=5
ENV RUST_LOG=rustbin=info,sqlx=warn

VOLUME ["/data"]
EXPOSE 3000

ENTRYPOINT ["/rustbin"]
