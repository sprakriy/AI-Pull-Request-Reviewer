import json
from unittest.mock import patch
import lambda_function as lambda_module

def test_local_handler():
    # Simulate an HTTP POST payload sent by Function URL or API Gateway
    mock_event = {
        "body": json.dumps({
            "diff": "diff --git a/test.py b/test.py\n--- a/test.py\n+++ b/test.py\n@@ -1,1 +1,1 @@\n-print('old')\n+print('new')\n"
        })
    }

    # Invoke the handler
    response = lambda_module.lambda_handler(mock_event, {})
    
    print("Status Code:", response['statusCode'])
    body = json.loads(response['body'])
    
    if response['statusCode'] == 200:
        print("Success! Response body:\n", body.get('review'))
    else:
        print("Error encountered:", body.get('error'))

if __name__ == "__main__":
    test_local_handler()