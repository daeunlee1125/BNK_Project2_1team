# 1. Base Image: 사용자가 요청한 가벼운 Alpine Linux 기반 Java 21
FROM eclipse-temurin:21-jdk-alpine

# 2. 작업 디렉터리 설정
WORKDIR /app

# 3. GitHub Actions에서 빌드된 JAR 파일 복사
COPY app.jar app.jar

# 4. 타임존 설정 (한국 시간)
ENV TZ=Asia/Seoul
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# 5. 실행 명령어
ENTRYPOINT ["java", "-jar", "app.jar"]