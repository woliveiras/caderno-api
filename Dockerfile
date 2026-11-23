FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir "psycopg[binary]==3.3.9"
COPY --chmod=0644 app.py /app/app.py
USER 1000:1000
EXPOSE 8000
CMD ["python", "-u", "/app/app.py"]
