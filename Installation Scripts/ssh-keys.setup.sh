#!/bin/bash
chmod g-w,o-w ~; #home directory is not writeable by other users
mkdir ~/.ssh/;
chmod 700 ~/.ssh/;
wget https://github.com/littlebearz.keys -O ~/.ssh/authorized_keys;
chmod 644 ~/.ssh/authorized_keys;
sudo service ssh restart;
