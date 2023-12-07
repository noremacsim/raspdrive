#!/bin/bash

echo "Content-type: text/plain"
echo

tac /var/log/events.log
