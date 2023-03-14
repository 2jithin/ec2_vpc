#!usr/bin/env bash

read -p "Enter number of instance count you want eg 1,2,3.. : " name

echo "Hello, $name"

echo "Please select amazon linux instance type:"
echo "1. t2.small"
echo "2. t2.medium"
echo "3. t2.large"
echo "4. Quit"

read -p "Enter your choice [1-4]: " choice

case $choice in
  1)
    echo "You chose Option t2.small"
    # Add code for Option One here
    ec2type=t2.small
    ;;
  2)
    echo "You chose Option t2.medium"
    # Add code for Option Two here
    ec2type=t2.medium
    ;;
  3)
    echo "You chose Option t2.large"
    # Add code for Option Three here
    ec2type=t2.large
    ;;
  4)
    echo "Goodbye!"
    exit 0
    ;;
  *)
    echo "Invalid choice, please try again."
    ;;
esac