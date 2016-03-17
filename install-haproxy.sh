#!/bin/bash

apt-get install haproxy

service stop haproxy
cp haproxy.cfg /etc/haproxy
service start haproxy