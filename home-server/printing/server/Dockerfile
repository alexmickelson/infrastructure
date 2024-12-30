FROM python:3

RUN apt-get update \
    && apt-get install -y libcups2-dev python3-pip cups python3-cups gcc \
    && pip install pycups fastapi "uvicorn[standard]" python-multipart


WORKDIR /app
COPY ./src .

CMD python -m uvicorn print_api:app --reload --host 0.0.0.0 --port 6311