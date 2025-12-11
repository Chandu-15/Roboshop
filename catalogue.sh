#!/bin/bash
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
FOLDER_PATH="/var/log/Scripting"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$FOLDER_PATH/$script_name.log"
script_dir=$PWD
MONGODB_HOST=mongodb.daws-86.shop
mkdir -p $FOLDER_PATH
echo "script execution started at $(date)" | tee -a $log_file
if [ $USER_ID -ne 0 ] ; then
    echo -e "$R ERROR : Please run this script with root access $N" | tee -a $log_file
    exit 1
fi

Validate(){
    if [ $1 -ne 0 ]; then 
    echo -e " ERROR : Installing $2 is $R failure $N" | tee -a $log_file
    exit 1
else
    echo -e "Installing $2 is $G SUCCESS $N" | tee -a $log_file
fi
}

dnf module disable nodejs -y &>>$log_file
Validate $? "Disable Nodejs" 
dnf module enable nodejs:20 -y &>>$log_file
Validate $? "enable Nodejs"
dnf install nodejs -y &>>$log_file
Validate $? "installing Nodejs"
id Roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
else 
    echo -e "User already exists.....$Y Skipping $N"
fi
Validate $? "Create SystemUser"
mkdir app
Validate $? "Create App directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
Validate $? "downloading code to temporary folder"
cd app
unzip /tmp/catalogue.zip &>>$log_file
Validate $? "move code to app directory"
npm install &>>$log_file
Validate $? "installing dependencies"
cd
chown -R Roboshop:Roboshop  app/
Validate $? "Permissions changed"
cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
Validate $? "Adding Catalogue service"
systemctl daemon-reload
systemctl start catalogue
Validate $? "Start service"
systemctl enable catalogue
Validate $? "Enable service"
cp mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y
Validate $? "Installed mongodb client"
INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi
systemctl restart catalogue



