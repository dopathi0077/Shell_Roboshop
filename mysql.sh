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


echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

VALIDATE(){
    if [ $1 -eq 0 ] # it will pass the exit status args VALIDATE $? "nginx" as $1 and $2 to this 
    then
      echo -e "$2 is .... $G Succesfull $N" | tee -a $LOG_FILE
    else
      echo -e "$2 is .... $R Failure $N" | tee -a $LOG_FILE
      exit 1
    fi
}

dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "Installing  msql server"

systemctl enable mysqld  &>>$LOG_FILE
systemctl start mysqld   &>>$LOG_FILE
VALIDATE $? "Enabling msql and starting msql server" 

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD  &>>$LOG_FILE
VALIDATE $? "Setting msql root password" 



SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$(( $SCRIPT_END_TIME-$SCRIPT_START_TIME ))

echo -e "Script executed succesfully $Y Time Taken: $TOTAL_TIME $N " | tee -a  $LOG_FILE
