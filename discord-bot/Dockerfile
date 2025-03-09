FROM node:20 AS build-stage

WORKDIR /app

COPY client/package.json client/package-lock.json ./
RUN npm install

COPY client/ ./
RUN npm run build

FROM python:3.12
RUN apt-get update && apt-get install -y ffmpeg
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY src src
COPY main.py main.py
RUN mkdir songs

RUN mkdir client
COPY --from=build-stage /app/dist /client

ENTRYPOINT [ "fastapi", "run", "main.py", "--port", "5677" ]

