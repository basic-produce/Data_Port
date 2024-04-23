FROM apache/airflow:2.9.0

ARG AIRFLOW_VERSION=2.9.0

ADD requirements.txt .

RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements.txt

