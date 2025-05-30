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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Dwonloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "packaging the shipping application" 

mv target/shipping-1.0.jar shipping.jar  
VALIDATE $? "moving and renaming the shipping jar" 

cp $SCRIPT_DIR/shipping.sh /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copying shipping service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon-reload of shipping "

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enabling  shipping "

systemctl start shipping  &>>$LOG_FILE
VALIDATE $? "Starting shipping "

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing msql "

mysql -h msql.VarunDopathi.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
mysql -h msql.VarunDopathi.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
mysql -h msql.VarunDopathi.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
VALIDATE $? "Loading data to msql"

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"



SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$(( $SCRIPT_END_TIME-$SCRIPT_START_TIME ))

echo -e "Script executed succesfully $Y Time Taken: $TOTAL_TIME $N " | tee -a  $LOG_FILE
