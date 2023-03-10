#!/bin/bash

# Get list of all running containers
containers=$(docker ps -a | awk '{print $1}' | sed '/CONTAINER/d')

# Iterate through list of containers
for container in $containers
do
  # Get the ports in use by the container
  ports=$(docker container port $container | awk '{print $1}')

  # Iterate through the list of ports
  for port in $ports
  do
    # Open the port in UFW
    ufw allow $port
  done
done