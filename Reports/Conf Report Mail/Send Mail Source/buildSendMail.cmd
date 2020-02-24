echo off
@echo Deleting SendMail.jar
del SendMail.jar
@echo Compiling SendMail
%JAVA_HOME%\bin\javac -classpath ".;mail.jar;activation.jar" SendMail.java
@echo Building new SendMail.jar
%JAVA_HOME%\bin\jar cf SendMail.jar SendMail.class SendMail$1.class
echo on
@pause