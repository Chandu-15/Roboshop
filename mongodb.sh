#!/bin/bash
source ./common.sh
check_root
cp mongo.repo /etc/yum.repos.d/mongo.repo
Validate $? "Adding Mongo repo"
dnf install mongodb-org -y &>>$log_file
Validate $? "Installing Mongodb"
systemctl enable mongod | tee -a $log_file
Validate $? "Enable Mongodb"
systemctl start mongod | tee -a $log_file
Validate $? "start Mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
Validate $? "Allowing remote connections to mongodb"

systemctl restart mongod | tee -a $log_file
Validate $? "restart mongodb"
print_total_time
