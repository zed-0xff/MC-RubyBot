#!/bin/sh

while true; do
    ./chicken_race.rb cleanup
    RANDOM_ROUTE=`ls route_*.yml | sort -R | head -1`
    if [ "$RANDOM_ROUTE" = "route_empty.yml" ]; then
        ./chicken_race.rb
    else
        ./chicken_race.rb $RANDOM_ROUTE
    fi
    sleep 2
done
