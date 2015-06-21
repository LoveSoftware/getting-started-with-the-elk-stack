while [ true ]
do
curl http://web.logstashdemo.com/flappy
printf "\n"
curl --silent http://web.logstashdemo.com/ > /dev/null

done
