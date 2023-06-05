# Instructions

```
 sudo docker build --rm -t postgres:15.3 --build-arg postgres_version=15.3 --build-arg pgvector_version=0.4.2 .
 sudo docker run --rm postgres:15.3
 psql -h localhost -U postgres -d postgres -p 5432
```
