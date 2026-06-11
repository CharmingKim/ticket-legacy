FROM tomcat:9.0-jdk11-temurin
RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/ticket-user.war /usr/local/tomcat/webapps/ROOT.war
ENV JAVA_OPTS="-Xms128m -Xmx256m"
EXPOSE 8080
CMD ["catalina.sh", "run"]
