#!/bin/bash
# Initialize Elasticsearch with ILM policies
# Run after Elasticsearch is healthy

ES_URL="${ES_URL:-http://127.0.0.1:9200}"

echo "Waiting for Elasticsearch..."
until curl -s "$ES_URL/_cluster/health" | grep -q '"status":"green"\|"status":"yellow"'; do
  sleep 2
done
echo "Elasticsearch is ready"

echo "Creating ILM policy (30-day retention)..."
curl -s -X PUT "$ES_URL/_ilm/policy/openclaw-logs-policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_age": "7d",
              "max_size": "5gb"
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
echo ""

echo "Creating index template..."
curl -s -X PUT "$ES_URL/_index_template/openclaw-logs-template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["openclaw-logs-*"],
    "data_stream": {},
    "template": {
      "settings": {
        "index.lifecycle.name": "openclaw-logs-policy"
      }
    },
    "priority": 200
  }'
echo ""

echo "Done! Logs older than 30 days will be automatically deleted."
