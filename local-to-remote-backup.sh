#!/bin/bash

src=$1  #your source directory
remote_tgt=$2 #your remote location(ubuntu@ec2-54-80-140-20.compute-1.amazonaws.com:/home/ubuntu/backup/)
current_timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
local_backup_file=backup_$current_timestamp.tgz

function taking_backup {
    
    tar -czf ${local_backup_file} --absolute-names ${src}

    if [ $? -eq 0 ]; then
        echo "Backup of $src successful at $current_timestamp"

        
        scp -o StrictHostKeyChecking=no -i "linux-admin.pem" ${local_backup_file} ${remote_tgt}
        if [ $? -eq 0 ]; then
            echo "Backup file successfully transferred to remote server"
        else
            echo "Failed to transfer the backup file to the remote server"
            return 1
        fi

        
        rm -f ${local_backup_file}
    else
        echo "Unable to take backup at $current_timestamp"
        return 1
    fi
}

function simple_report {
    local status=$1
    echo "$(date): Backup of $src - $status" >> backup_report.log
    echo "Backup report: $status"
}

function performing_rotation {
    
    ssh -o StrictHostKeyChecking=no -i "linux-admin.pem" ubuntu@ec2-54-80-140-20.compute-1.amazonaws.com << EOF
    backup_count=\$(ls /home/ubuntu/backup | grep -c ^backup_)
    
    if [ \$backup_count -gt 5 ]; then
        older_backup=\$(ls -t /home/ubuntu/backup | grep backup_ | tail -n 1)
        rm -f /home/ubuntu/backup/\$older_backup
        echo "Removing older backup: \$older_backup"
    fi
EOF
}


taking_backup
backup_exit=$?


if [ $backup_exit -eq 0 ]; then
    simple_report "SUCCESS"
    
    performing_rotation
else
    simple_report "FAILURE"
    echo "Backup failed, skipping rotation."
fi
