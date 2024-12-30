FROM python:3.10

RUN pip install pydantic requests python-dotenv

COPY jellyfin /app/jellyfin

WORKDIR /app

ENTRYPOINT [ "python" ]