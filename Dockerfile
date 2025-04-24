FROM python:3.8 AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LT_LOAD_ONLY=en,es \
    LT_LOAD_ONLY_EXTRA=en,es
WORKDIR /app

RUN python -m venv .venv
#COPY pyproject.toml VERSION LICENSE README.md libretranslate ./
COPY . .
RUN .venv/bin/pip install .

FROM python:3.8-slim
WORKDIR /app

# Add environment variables for language configuration
ENV LT_LOAD_ONLY=en,es \
    LT_LOAD_ONLY_EXTRA=en,es

COPY --from=builder /app/.venv .venv/
COPY . .

# Create a script to handle language loading
RUN echo '#!/bin/bash\n\
if [ "$LT_LOAD_ONLY" != "all" ]; then\n\
    echo "Loading only languages: $LT_LOAD_ONLY"\n\
    export LT_LOAD_ONLY="$LT_LOAD_ONLY"\n\
fi\n\
if [ "$LT_LOAD_ONLY_EXTRA" != "all" ]; then\n\
    echo "Loading only extra languages: $LT_LOAD_ONLY_EXTRA"\n\
    export LT_LOAD_ONLY_EXTRA="$LT_LOAD_ONLY_EXTRA"\n\
fi\n\
exec /app/.venv/bin/flask run --host=0.0.0.0 --port=8080' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
