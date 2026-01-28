# Custom Liquibase Docker image with PostgreSQL JDBC driver
FROM liquibase/liquibase:5.0-alpine

# add postgresql driver
RUN lpm add postgresql --global

