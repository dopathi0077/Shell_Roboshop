#! /bin/bash
SCRIPT_START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop_automation-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR="$PWD"

mkdir -p $LOGS_FOLDER

#checkif user has root privilages or not 
if [ $USERID -ne 0 ]
then
   echo "ERROR: $R Please run the script with root access $N " | tee -a $LOG_FILE
   exit 1 # give other than 0 till 127
else
   echo "You are running with root access" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ] # it will pass the exit status args VALIDATE $? "nginx" as $1 and $2 to this 
    then
      echo -e "$2 is .... $G Succesfull $N" | tee -a $LOG_FILE
    else
      echo -e "$2 is .... $R Failure $N" | tee -a $LOG_FILE
      exit 1
    fi
}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling default redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling  redis:7"

dnf install redis -y  &>>$LOG_FILE
VALIDATE $? "Installing redis:7"

# sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>>$LOG_FILE
# VALIDATE $? "Changing redis permissions"

# systemctl enable redis  &>>$LOG_FILE
# systemctl start redis &>>$LOG_FILE
# VALIDATE $? "Starting redis"

