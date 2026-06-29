FROM python:3.11-slim

RUN pip install mkdocs mkdocs-material mkdocs-mermaid2-plugin

WORKDIR /docs
EXPOSE 8000
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000"]
