# API Calls
## Trigger Full Search
```
source /opt/docker/secrets.env
docker exec -it cross-seed curl -XPOST http://localhost:2468/api/job?apikey=$CROSS_SEED_API_KEY \
  -d 'name=search' \
  -d 'ignoreExcludeRecentSearch=true' \
  -d 'ignoreExcludeOlder=true'
```

## Trigger Search
```
source /opt/docker/secrets.env
docker exec -it cross-seed curl -XPOST http://localhost:2468/api/job?apikey=$CROSS_SEED_API_KEY -d 'name=search'
```