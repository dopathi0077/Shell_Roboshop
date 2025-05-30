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



dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disableing default NODE JS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling  NODE JS:20" 

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install Node Js"

id roboshop
if [ $? -ne 0 ]
then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
   VALIDATE $? "Creating roboshop system user"
else 
   echo "Roboshop user already.So $Y Skipping $N"
fi 


mkdir -p /app  
VALIDATE $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "Dwonloading user"

rm -rf /app/*
cd /app 
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzip user"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"


cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service 
VALIDATE $? "Copying user service"

cp user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "copying user repo file"


systemctl daemon-reload &>>$LOG_FILE
systemctl enable user &>>$LOG_FILE
systemctl start user
VALIDATE $? "Starting user"


SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$(( $SCRIPT_END_TIME-$SCRIPT_START_TIME ))

echo -e "Script executed succesfully $Y Time Taken: $TOTAL_TIME $N " | tee -a  $LOG_FILE
