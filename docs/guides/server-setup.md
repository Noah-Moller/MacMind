# MacMind Server Setup Guide

This guide will walk you through setting up and running a MacMind server, which allows you to provide LLM processing capabilities over your network.

## Prerequisites

- macOS 13.0 or later
- Ollama installed and running
- Network access and appropriate permissions
- Basic understanding of terminal commands

## Installation

### 1. Install MacMind

If you haven't already, clone the MacMind repository:

```bash
git clone https://github.com/Noah-Moller/MacMind.git
cd MacMind
```

### 2. Build the Server

Build the server using Swift Package Manager:

```bash
swift build
```

## Running the Server

### Basic Usage

Start the server with default settings (0.0.0.0:3467):

```bash
swift run macmind-server
```

### Custom Configuration

Start with custom host and port:

```bash
swift run macmind-server --host 127.0.0.1 --port 8080
```

### Available Options

- `--host`: Server host address (default: 0.0.0.0)
- `--port`: Server port (default: 3467)

## Server Endpoints

### 1. Health Check
```bash
GET http://localhost:3467/health
```
Returns 200 OK if server is healthy

### 2. Status Check
```bash
GET http://localhost:3467/status
```
Returns server status information

### 3. Prompt (Non-streaming)
```bash
POST http://localhost:3467/prompt
Content-Type: application/json

{
    "prompt": "What is quantum computing?",
    "stream": false,
    "showThinking": true
}
```

### 4. Prompt (Streaming)
```bash
POST http://localhost:3467/prompt
Content-Type: application/json

{
    "prompt": "What is quantum computing?",
    "stream": true,
    "showThinking": true
}
```

### 5. PDF Context
```bash
POST http://localhost:3467/prompt
Content-Type: application/json

{
    "prompt": "Summarize this document",
    "stream": false,
    "showThinking": true,
    "pdfURLs": ["file:///path/to/document.pdf"]
}
```

## Security Considerations

### Network Security

1. **Firewall Configuration**
   - Configure your firewall to allow incoming connections on the server port
   - Consider restricting access to specific IP ranges

2. **Access Control**
   - Run the server on a private network when possible
   - Use reverse proxy for public access
   - Implement authentication if needed

### File System Security

1. **PDF Access**
   - Ensure the server has access to PDF directories
   - Use absolute paths for PDF files
   - Validate file paths to prevent directory traversal

### Resource Management

1. **Memory Usage**
   - Monitor memory usage with large documents
   - Consider implementing request size limits
   - Use streaming for large responses

2. **CPU Usage**
   - Monitor CPU usage during heavy loads
   - Implement rate limiting if needed
   - Consider running on dedicated hardware

## Monitoring

### Logs

The server logs important events to help with monitoring and debugging:

```bash
# View server logs
tail -f /var/log/macmind-server.log
```

### Health Monitoring

Set up regular health checks:

```bash
# Using curl
while true; do
    curl -s http://localhost:3467/health
    sleep 60
done
```

## Running as a Service

### Create a Launch Daemon

1. Create a plist file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macmind.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/macmind-server</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/var/log/macmind-server.err</string>
    <key>StandardOutPath</key>
    <string>/var/log/macmind-server.log</string>
</dict>
</plist>
```

2. Install the service:

```bash
sudo cp com.macmind.server.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.macmind.server.plist
```

## Troubleshooting

### Common Issues

1. **Server Won't Start**
   - Check if port is already in use
   - Verify Ollama is running
   - Check file permissions

2. **Connection Refused**
   - Verify firewall settings
   - Check host/port configuration
   - Ensure server is running

3. **Performance Issues**
   - Monitor system resources
   - Check network bandwidth
   - Consider scaling options

### Debugging

Enable verbose logging:

```bash
swift run macmind-server --verbose
```

## Best Practices

1. **Production Setup**
   - Use a process manager
   - Implement proper logging
   - Set up monitoring
   - Configure automatic restarts

2. **Maintenance**
   - Regular health checks
   - Log rotation
   - Resource monitoring
   - Security updates

3. **Scaling**
   - Monitor usage patterns
   - Implement load balancing if needed
   - Consider distributed deployment

## See Also

- [Remote Model API](../api/remote-model.md)
- [Remote Communication Guide](remote-communication.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Security Best Practices](security.md) 