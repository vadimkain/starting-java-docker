#syntax=docker/dockerfile:1

# Наш образ будет унаследован от этого образа
FROM eclipse-temurin:17-jdk-jammy AS base
# Устанавливаем рабочую директорию
WORKDIR /app
# Копируем файлы или диреткории из хост-машины в контейнер
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
# При первом запуске образа выполняется команда
RUN ./mvnw dependency:resolve
COPY src ./src

FROM base AS test
RUN ["./mvnw", "test"]

FROM base AS development
# Указываем команду, которую хотим вызвать когда образ запускается внутри контейнера
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run-profiles=mysql", "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

FROM base AS development
RUN ./mvnw package

FROM eclipse-temurin:17-jdk-jammy AS production
# На каком порту докер прослушивает входящие соединения. Не доступен для внешнего мира. Документируем какие порты контейнер будет использвать
EXPOSE 8080
COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]
