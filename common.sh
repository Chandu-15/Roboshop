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
START_TIME=$(date +%s)
mkdir -p $FOLDER_PATH
echo "script execution started at $(date)" | tee -a $log_file
check_root(){
    if [ $USER_ID -ne 0 ] ; then
    echo -e "$R ERROR : Please run this script with root access $N" | tee -a $log_file
    exit 1
    fi
}
Validate(){
    if [ $1 -ne 0 ]; then 
        echo -e " ERROR : Installing $2 is $R failure $N" | tee -a $log_file
        exit 1
    else
        echo -e "Installing $2 is $G SUCCESS $N" | tee -a $log_file
    fi
}
nodejs_setup()
{
    dnf module disable nodejs -y &>>$log_file
    Validate $? "Disable Nodejs" 
    dnf module enable nodejs:20 -y &>>$log_file
    Validate $? "enable Nodejs"
    dnf install nodejs -y &>>$log_file
    Validate $? "installing Nodejs"
    npm install &>>$log_file
    Validate $? "installing dependencies"
    cd
    chown -R roboshop:roboshop  /app &>>$log_file
    Validate $? "Permissions changed"
    }

app_setup(){
    id roboshop &>>$log_file
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    else 
        echo -e "User already exists.....$Y Skipping $N"
    fi
    Validate $? "Create SystemUser"
    mkdir -p /app
    Validate $? "Create App directory"
    curl -o /tmp/$appname.zip https://roboshop-artifacts.s3.amazonaws.com/$appname-v3.zip &>>$log_file
    Validate $? "downloading code to temporary folder"
    cd /app
    rm -rf /app/*
    unzip /tmp/$appname.zip &>>$log_file
    Validate $? "move code to app directory"
}

systemd_setup(){
    cp $script_dir/$appname.service /etc/systemd/system/$appname.service
    Validate $? "Adding $appname service"
    systemctl daemon-reload
    systemctl enable $appname
    Validate $? "Enable service"
}
system_restart(){
    systemctl restart $appname
}
print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
}