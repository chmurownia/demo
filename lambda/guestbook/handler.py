"""
Guest book Lambda function.

Backs the demo site's guest book via API Gateway (HTTP API):
  - GET  /entries  → returns the most recent entries (newest first).
  - POST /entries  → stores a new entry ({author, message}).

Entries are stored in DynamoDB with a fixed partition key so they can be
queried together and sorted by timestamp.
"""

from __future__ import annotations

import json
import logging
import os
import time
import uuid
from decimal import Decimal
from typing import Any

import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["GUESTBOOK_TABLE"]
MAX_ENTRIES = int(os.environ.get("MAX_ENTRIES", "50"))
MAX_AUTHOR_LEN = 60
MAX_MESSAGE_LEN = 500

# Single partition groups all entries; sort key orders them by time.
PARTITION_VALUE = "guestbook"

dynamodb = boto3.resource("dynamodb", region_name=os.environ.get("AWS_REGION_NAME"))
table = dynamodb.Table(TABLE_NAME)


class _DecimalEncoder(json.JSONEncoder):
    """JSON encoder that renders DynamoDB Decimal values as int/float."""

    def default(self, o: Any) -> Any:
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super().default(o)


def _response(status: int, body: Any) -> dict[str, Any]:
    """Build an API Gateway HTTP API response with permissive CORS headers.

    Args:
        status: HTTP status code.
        body: JSON-serialisable response body.

    Returns:
        dict: API Gateway-compatible response.
    """
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(body, cls=_DecimalEncoder),
    }


def _get_entries() -> dict[str, Any]:
    """Fetch the most recent guest book entries, newest first.

    Returns:
        dict: API Gateway response containing a list of entries.
    """
    result = table.query(
        KeyConditionExpression=Key("pk").eq(PARTITION_VALUE),
        ScanIndexForward=False,  # newest first
        Limit=MAX_ENTRIES,
    )
    entries = [
        {
            "author": item["author"],
            "message": item["message"],
            "timestamp": item["timestamp"],
        }
        for item in result.get("Items", [])
    ]
    return _response(200, entries)


def _post_entry(raw_body: str | None) -> dict[str, Any]:
    """Validate and store a new guest book entry.

    Args:
        raw_body: Raw JSON request body from API Gateway.

    Returns:
        dict: API Gateway response describing the outcome.
    """
    try:
        payload = json.loads(raw_body or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Invalid JSON body"})

    author = str(payload.get("author", "")).strip()
    message = str(payload.get("message", "")).strip()

    if not author or not message:
        return _response(400, {"error": "Both 'author' and 'message' are required"})

    if len(author) > MAX_AUTHOR_LEN or len(message) > MAX_MESSAGE_LEN:
        return _response(413, {"error": "Author or message too long"})

    timestamp = int(time.time() * 1000)  # epoch milliseconds
    item = {
        "pk": PARTITION_VALUE,
        "sk": f"{timestamp}#{uuid.uuid4().hex[:8]}",
        "author": author,
        "message": message,
        "timestamp": timestamp,
    }
    table.put_item(Item=item)
    logger.info("Stored guest book entry from %s", author)
    return _response(201, {"message": "Entry saved"})


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Route API Gateway HTTP API requests to the correct handler.

    Args:
        event: API Gateway HTTP API (payload format v2) event.
        context: Lambda context object.

    Returns:
        dict: API Gateway-compatible HTTP response.
    """
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    try:
        if method == "OPTIONS":
            return _response(200, {})
        if method == "GET":
            return _get_entries()
        if method == "POST":
            return _post_entry(event.get("body"))
        return _response(405, {"error": f"Method {method} not allowed"})
    except ClientError:
        logger.exception("DynamoDB error handling %s", method)
        return _response(500, {"error": "Internal server error"})
