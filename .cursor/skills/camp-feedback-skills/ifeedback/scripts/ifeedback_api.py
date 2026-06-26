#!/usr/bin/env python3
"""
iFeedback MCP CLI tool.

Usage:
    python ifeedback_api.py <command> [options]

Commands:
    search, distribute, trend, alarm_data, keyword_list, generate_url, search_by_url,
    parse_url, sample, fields

Environment variables:
    IFEEDBACK_MCP_TOKEN  (required) Authentication token (太湖个人令牌, sent as Authorization: Bearer header)
    IFEEDBACK_MCP_URL    (optional) MCP Server URL, default https://ifeedback.mcp.it.woa.com
    IFEEDBACK_RTX        (optional) End-user RTX for secondary permission check (sent as X-Ifeedback-Rtx header)
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error


# ── MCP Client (zero-dependency, stdlib only) ──

DEFAULT_MCP_URL = "https://ifeedback.mcp.it.woa.com"


class MCPClient:
    """Lightweight MCP client using only urllib (zero external dependencies)."""

    def __init__(self, url, token, rtx=None):
        self.url = url
        self.token = token
        self.rtx = rtx
        self._request_id = 0
        self._initialized = False

    def _next_id(self):
        self._request_id += 1
        return self._request_id

    def _send(self, method, params=None):
        """Send a JSON-RPC request to the MCP server and return parsed response."""
        payload = {
            "jsonrpc": "2.0",
            "id": self._next_id(),
            "method": method,
            "params": params or {},
        }
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json, text/event-stream",
        }
        if self.rtx:
            headers["X-Ifeedback-Rtx"] = self.rtx
        req = urllib.request.Request(self.url, data=body, headers=headers, method="POST")

        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                content_type = resp.headers.get("Content-Type", "")
                raw = resp.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            raw_err = e.read().decode("utf-8", errors="replace") if e.fp else ""
            print(f"HTTP {e.code}: {raw_err[:500]}", file=sys.stderr)
            sys.exit(1)
        except urllib.error.URLError as e:
            print(f"Connection error: {e.reason}", file=sys.stderr)
            sys.exit(1)

        # Parse response — may be plain JSON or SSE (text/event-stream)
        if "text/event-stream" in content_type or raw.lstrip().startswith(("event:", "data:")):
            return self._parse_sse(raw)
        return json.loads(raw)

    @staticmethod
    def _parse_sse(raw):
        """Parse SSE stream and return the JSON-RPC result."""
        last_parsed = None
        for event_block in raw.split("\n\n"):
            data_parts = []
            for line in event_block.split("\n"):
                if line.startswith("data:"):
                    data_parts.append(line[5:].strip())
            if data_parts:
                json_str = "".join(data_parts)
                if json_str:
                    try:
                        parsed = json.loads(json_str)
                        last_parsed = parsed
                        if isinstance(parsed, dict) and ("result" in parsed or "error" in parsed):
                            return parsed
                    except json.JSONDecodeError:
                        continue
        if last_parsed is not None:
            return last_parsed
        return {"error": {"code": -1, "message": "No valid JSON-RPC response in SSE stream"}}

    def _ensure_init(self):
        """Lazily initialize the MCP connection on first use."""
        if self._initialized:
            return
        resp = self._send("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "ifeedback-cli", "version": "2.0.0"},
        })
        if "error" in resp:
            print(f"MCP initialize failed: {resp['error']}", file=sys.stderr)
            sys.exit(1)
        self._initialized = True

    def call_tool(self, tool_name, arguments):
        """Call an MCP tool and return the parsed result data."""
        self._ensure_init()
        resp = self._send("tools/call", {"name": tool_name, "arguments": arguments})

        if "error" in resp:
            print(f"MCP error: {resp['error']}", file=sys.stderr)
            sys.exit(1)

        # Extract text content from MCP result
        result = resp.get("result", {})
        contents = result.get("content", [])
        for item in contents:
            if item.get("type") == "text":
                text = item.get("text", "")
                try:
                    return json.loads(text)
                except json.JSONDecodeError:
                    return text
        return result


# ── Config ──

def get_config():
    token = os.environ.get("IFEEDBACK_MCP_TOKEN", "")
    if not token:
        print("Error: IFEEDBACK_MCP_TOKEN environment variable is required", file=sys.stderr)
        sys.exit(1)
    return {
        "token": token,
        "mcp_url": os.environ.get("IFEEDBACK_MCP_URL", DEFAULT_MCP_URL).rstrip("/"),
        "rtx": os.environ.get("IFEEDBACK_RTX", ""),
    }


def get_client(config):
    return MCPClient(url=config["mcp_url"], token=config["token"], rtx=config.get("rtx"))


def parse_json_arg(value):
    """Parse a JSON string argument, returning the parsed object."""
    try:
        return json.loads(value)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)


# ── Subcommand handlers ──

def cmd_search(args, client):
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "page": args.page,
        "size": args.size,
        "order_key": args.order_key,
        "order": args.order,
        "keywords": args.keywords,
        "cut_word": args.cut_word,
        "conditions": parse_json_arg(args.conditions) if args.conditions else [],
        "return_fields": parse_json_arg(args.return_fields) if args.return_fields else ["uin", "time", "comment"],
        "cluster_threshold": args.cluster_threshold,
    }
    return client.call_tool("search", data)


def cmd_distribute(args, client):
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "key": args.key,
        "size": args.size,
        "conditions": parse_json_arg(args.conditions) if args.conditions else [],
    }
    return client.call_tool("distribute", data)


def cmd_trend(args, client):
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "interval": args.interval,
        "conditions": parse_json_arg(args.conditions) if args.conditions else [],
        "keywords": args.keywords,
        "cut_word": args.cut_word,
        "size": args.size,
    }
    return client.call_tool("trend", data)


def cmd_alarm_data(args, client):
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "type": args.type,
        "size": args.size,
    }
    return client.call_tool("alarm_data", data)


def cmd_keyword_list(args, client):
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "size": args.size,
        "conditions": parse_json_arg(args.conditions) if args.conditions else [],
        "vip_keywords": parse_json_arg(args.vip_keywords) if args.vip_keywords else [],
    }
    return client.call_tool("keyword_list", data)


def cmd_generate_url(args, client):
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "keywords": args.keywords,
        "cut_word": args.cut_word,
        "conditions": parse_json_arg(args.conditions) if args.conditions else [],
        "attr": args.attr,
    }
    return client.call_tool("generate_url", data)


def cmd_search_by_url(args, client):
    data = {
        "url": args.url,
        "page": args.page,
        "size": args.size,
        "order_key": args.order_key,
        "order": args.order,
        "return_fields": parse_json_arg(args.return_fields) if args.return_fields else ["uin", "time", "comment"],
    }
    return client.call_tool("search_by_url", data)


def cmd_parse_url(args, client):
    """Parse an iFeedback URL into structured query parameters."""
    return client.call_tool("parse_url", {"url": args.url})


def _truncate_long_values(obj, max_list=5, max_str=200):
    """Truncate overly long list/string values to save output tokens."""
    if isinstance(obj, dict):
        return {k: _truncate_long_values(v, max_list, max_str) for k, v in obj.items()}
    if isinstance(obj, list):
        if len(obj) > 0 and not isinstance(obj[0], dict):
            # Leaf list (e.g. exptid arrays): truncate
            if len(obj) > max_list:
                return obj[:max_list] + [f"... ({len(obj) - max_list} more)"]
            return obj
        # List of dicts (e.g. feedbacks): recurse into each
        return [_truncate_long_values(item, max_list, max_str) for item in obj]
    if isinstance(obj, str) and len(obj) > max_str:
        return obj[:max_str] + f"... ({len(obj)} chars)"
    return obj


def cmd_sample(args, client):
    """Fetch a few raw records with ALL fields to discover data schema."""
    data = {
        "app_name": args.app_name,
        "start_time": args.start_time,
        "end_time": args.end_time,
        "page": 0,
        "size": args.size,
        "order_key": "time",
        "order": "desc",
        "keywords": "",
        "cut_word": "1",
        "conditions": parse_json_arg(args.conditions) if args.conditions else [],
        "return_fields": [],  # empty = all fields
    }
    result = client.call_tool("search", data)
    return _truncate_long_values(result)


def cmd_fields(args, client):
    """Batch-check multiple fields for data availability."""
    keys = [k.strip() for k in args.keys.split(",") if k.strip()]
    conditions = parse_json_arg(args.conditions) if args.conditions else []
    top_n = args.top

    result = {}
    for key in keys:
        data = {
            "app_name": args.app_name,
            "start_time": args.start_time,
            "end_time": args.end_time,
            "key": key,
            "size": top_n,
            "conditions": conditions,
        }
        resp = client.call_tool("distribute", data)

        buckets = []
        if isinstance(resp, dict) and resp.get("code") == 0 and resp.get("data"):
            buckets = resp["data"].get("buckets", [])

        if not buckets:
            result[key] = {"status": "empty"}
        else:
            top_entries = []
            for b in buckets:
                entry = {"key": b.get("key", "")}
                if "pv" in b:
                    entry["pv"] = b["pv"]
                if "uv" in b:
                    entry["uv"] = b["uv"]
                if "doc_count" in b:
                    entry["count"] = b["doc_count"]
                top_entries.append(entry)
            result[key] = {
                "status": "has_data",
                "distinct": len(buckets),
                "top": top_entries,
            }

    return result


# ── Argument parser ──

def build_parser():
    parser = argparse.ArgumentParser(
        description="iFeedback MCP CLI tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command")
    sub.required = True

    # -- search --
    p = sub.add_parser("search", help="Search feedback data")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True, help="yyyy-MM-dd HH:mm:ss")
    p.add_argument("--end_time", required=True, help="yyyy-MM-dd HH:mm:ss")
    p.add_argument("--page", type=int, default=0)
    p.add_argument("--size", type=int, default=5000)
    p.add_argument("--order_key", default="time")
    p.add_argument("--order", default="desc", choices=["desc", "asc"])
    p.add_argument("--keywords", default="")
    p.add_argument("--cut_word", default="1", choices=["0", "1"])
    p.add_argument("--conditions", default="", help='JSON array, e.g. \'[{"key":"version","relation":"包含","value":"0x18"}]\'')
    p.add_argument("--return_fields", default="", help='JSON array, e.g. \'["uin","time","comment"]\'')
    p.add_argument("--cluster_threshold", type=float, default=0.3, help="Clustering similarity threshold, smaller = finer clusters (default: 0.3)")

    # -- distribute --
    p = sub.add_parser("distribute", help="TopK distribution by field")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True)
    p.add_argument("--end_time", required=True)
    p.add_argument("--key", required=True, help="Field name for distribution")
    p.add_argument("--size", type=int, default=10)
    p.add_argument("--conditions", default="")

    # -- trend --
    p = sub.add_parser("trend", help="Time-series feedback counts (PV/UV)")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True)
    p.add_argument("--end_time", required=True)
    p.add_argument("--interval", default="hour", help="minute, hour, day, or Nm (e.g. 10m)")
    p.add_argument("--keywords", default="")
    p.add_argument("--cut_word", default="1", choices=["0", "1"])
    p.add_argument("--size", type=int, default=1000)
    p.add_argument("--conditions", default="")

    # -- alarm_data --
    p = sub.add_parser("alarm_data", help="Alarm data query")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True)
    p.add_argument("--end_time", required=True)
    p.add_argument("--type", default="realtime",
                   choices=["realtime", "custom", "attr", "release",
                            "daily_report", "cluster_daily_report", "cluster_weekly_report"])
    p.add_argument("--size", type=int, default=10)

    # -- keyword_list --
    p = sub.add_parser("keyword_list", help="Top keyword distribution")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True)
    p.add_argument("--end_time", required=True)
    p.add_argument("--size", type=int, default=30)
    p.add_argument("--conditions", default="")
    p.add_argument("--vip_keywords", default="", help='JSON array, e.g. \'["crash","lag"]\'')

    # -- generate_url --
    p = sub.add_parser("generate_url", help="Generate iFeedback web UI URL")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True)
    p.add_argument("--end_time", required=True)
    p.add_argument("--keywords", default="")
    p.add_argument("--cut_word", default="1", choices=["0", "1"])
    p.add_argument("--conditions", default="")
    p.add_argument("--attr", default="", help="Field name for distribution display")

    # -- search_by_url --
    p = sub.add_parser("search_by_url", help="Search by iFeedback URL")
    p.add_argument("--url", required=True)
    p.add_argument("--page", type=int, default=0)
    p.add_argument("--size", type=int, default=5000)
    p.add_argument("--order_key", default="time")
    p.add_argument("--order", default="desc", choices=["desc", "asc"])
    p.add_argument("--return_fields", default="")

    # -- parse_url --
    p = sub.add_parser("parse_url", help="Parse iFeedback URL into query parameters")
    p.add_argument("--url", required=True, help="iFeedback URL (supports query_id, alarm_id, app_id)")

    # -- sample --
    p = sub.add_parser("sample", help="Fetch raw records with ALL fields to discover schema")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True, help="yyyy-MM-dd HH:mm:ss")
    p.add_argument("--end_time", required=True, help="yyyy-MM-dd HH:mm:ss")
    p.add_argument("--size", type=int, default=3, help="Number of records to fetch (default: 3)")
    p.add_argument("--conditions", default="", help="Optional filter conditions (JSON array)")

    # -- fields --
    p = sub.add_parser("fields", help="Batch-check field data availability")
    p.add_argument("--app_name", required=True)
    p.add_argument("--start_time", required=True, help="yyyy-MM-dd HH:mm:ss")
    p.add_argument("--end_time", required=True, help="yyyy-MM-dd HH:mm:ss")
    p.add_argument("--keys", required=True, help="Comma-separated field names to check")
    p.add_argument("--top", type=int, default=10, help="Number of top values per field (default: 10)")
    p.add_argument("--conditions", default="", help="Optional filter conditions (JSON array)")

    return parser


HANDLERS = {
    "search": cmd_search,
    "distribute": cmd_distribute,
    "trend": cmd_trend,
    "alarm_data": cmd_alarm_data,
    "keyword_list": cmd_keyword_list,
    "generate_url": cmd_generate_url,
    "search_by_url": cmd_search_by_url,
    "parse_url": cmd_parse_url,
    "sample": cmd_sample,
    "fields": cmd_fields,
}


def main():
    parser = build_parser()
    args = parser.parse_args()
    config = get_config()
    client = get_client(config)
    result = HANDLERS[args.command](args, client)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
