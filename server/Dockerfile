FROM python:3.14-alpine
RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip install psycopg2
WORKDIR /tmp
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
RUN mkdir /audio
RUN mkdir /app
WORKDIR /app
COPY . .
VOLUME [ "/app", "/audio" ]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8003" ]