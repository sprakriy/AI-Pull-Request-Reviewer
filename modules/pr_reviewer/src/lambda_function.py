import json
import os
import boto3

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

def lambda_handler(event, context):
    try:
        # Load request body from event
        body = json.loads(event.get('body', '{}'))
        diff_text = body.get('diff', '')
        
        if not diff_text:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing pull request diff payload.'})
            }
            
        model_id = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-5-sonnet-20241022-v2:0')
        
        prompt = f"""
        You are an expert software engineer and SRE. Analyze the following pull request code diff and review it for:
        1. Security vulnerabilities.
        2. Performance improvements and optimizations.
        3. Code style, readability, and modularity.

        Diff:
        {diff_text}

        Please provide your review in a concise markdown format.
        """
        
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1200,
            "temperature": 0.1,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": prompt}]
                }
            ]
        }
        
        response = bedrock.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        review_text = response_body['content'][0]['text']
        
        return {
            'statusCode': 200,
            'body': json.dumps({'review': review_text}),
            'headers': {'Content-Type': 'application/json'}
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }