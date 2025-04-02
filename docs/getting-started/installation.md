# Installation Guide

This guide will walk you through the process of installing MacMind in your macOS application.

## Prerequisites

Before installing MacMind, ensure you have:

- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5+
- [Ollama](https://ollama.ai) installed
- Homebrew (optional, for installing Ollama)

## Installing Ollama

Ollama is required for local model inference. You have two options for installation:

### Option 1: Using Homebrew

```bash
brew install ollama
```

### Option 2: Direct Download

1. Download Ollama from [ollama.com/download/Ollama-darwin.zip](https://ollama.com/download/Ollama-darwin.zip)
2. Extract and install the application
3. Run Ollama at least once to complete setup

## Adding MacMind to Your Project

### Using Swift Package Manager (Recommended)

1. In Xcode, select File > Add Packages...
2. Enter the repository URL:
   ```
   https://github.com/Noah-Moller/MacMind.git
   ```
3. Select the version you want to use
4. Click "Add Package"

### Manual Integration

1. Clone the repository:
   ```bash
   git clone https://github.com/Noah-Moller/MacMind.git
   ```
2. Drag the `Sources/MacMind` folder into your Xcode project
3. Make sure to check "Copy items if needed" and add to your target

## Post-Installation Setup

### 1. Disable App Sandbox

MacMind requires network access and file system access to function properly:

1. In Xcode, select your target
2. Go to "Signing & Capabilities"
3. If App Sandbox is enabled, disable it or configure the following entitlements:
   - Network access (incoming/outgoing)
   - File system access (if using PDF features)

### 2. Import the Module

Add the import statement to your Swift files:

```swift
import MacMind
```

### 3. Verify Installation

You can verify the installation by running this simple test:

```swift
import MacMind

// Check if Ollama is installed
if SetupManager.isOllamaInstalled() {
    print("MacMind is ready to use!")
} else {
    print("Please install Ollama to use MacMind")
}
```

## Troubleshooting

### Common Issues

1. **"Ollama not found" error**
   - Ensure Ollama is installed and running
   - Check if Ollama is in your PATH

2. **Package resolution fails**
   - Clean the build folder (Cmd + Shift + K)
   - Delete derived data
   - Try removing and re-adding the package

3. **Network access denied**
   - Check app sandbox settings
   - Verify network permissions

### Getting Help

If you encounter any issues:
1. Check the [Troubleshooting Guide](../guides/troubleshooting.md)
2. [Open an issue](https://github.com/Noah-Moller/MacMind/issues)
3. Review the [FAQ](faq.md)

## Next Steps

- Read the [Quick Start Guide](quick-start.md)
- Explore [Basic Concepts](basic-concepts.md)
- Try the [Example Projects](../examples/README.md) 