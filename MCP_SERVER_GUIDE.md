# PrintMyRide MCP Server Guide

## Overview
The PrintMyRide MCP Server provides comprehensive iOS development tools through Claude Code's Model Context Protocol. It integrates all 4 requested functionalities:

1. **Xcode Build Tools** - Building, testing, and simulator management
2. **Strava API Tools** - Strava integration testing and development
3. **File Management Tools** - iOS project file analysis and management
4. **Testing Tools** - Comprehensive test execution and profiling

## Available Tools

### 🔨 Xcode Build Tools
- `xcode_build` - Build the Xcode project with optional clean
- `xcode_test` - Run tests (all, unit, ui, snapshot, links)
- `simulator_control` - Control iOS Simulator (boot, shutdown, list, install, launch, uninstall)

### 🏃 Strava API Tools
- `strava_test_setup` - Set up Strava API testing environment
- `strava_api_call` - Make Strava API calls for testing

### 📁 File Management Tools
- `analyze_project_structure` - Analyze iOS project file structure
- `swift_file_analysis` - Analyze Swift files for patterns, dependencies, or issues

### 🧪 Testing Tools
- `run_regression_tests` - Run comprehensive regression test suite
- `memory_profiling` - Run memory and performance profiling
- `generate_test_matrix` - Generate comprehensive test coverage matrix

## Server Status
✅ **Connected and Running**
```bash
claude mcp list
# printmyride-server: node /Users/donnysmith/CC/printmyride/mcp-server/src/index.js - ✅ Connected
```

## Quick Usage Examples

### Build and Test
```
Use the xcode_build tool to build the project with Debug configuration
Use the xcode_test tool to run all tests
Use the simulator_control tool to list available simulators
```

### Strava Development
```
Use the strava_test_setup tool with action "demo" to run Strava API demos
Use the strava_api_call tool to make specific API calls
```

### Project Analysis
```
Use the analyze_project_structure tool to get an overview of Swift files
Use the swift_file_analysis tool with pattern "StravaAPI" to find Strava-related code
```

### Testing and Profiling
```
Use the run_regression_tests tool to run the full regression suite
Use the memory_profiling tool with duration 60 for a 1-minute profile
Use the generate_test_matrix tool to update the comprehensive test matrix
```

## Server Configuration
- **Location**: `/Users/donnysmith/CC/printmyride/mcp-server/`
- **Entry Point**: `src/index.js`
- **Project Root**: `/Users/donnysmith/CC/printmyride`
- **Dependencies**: @modelcontextprotocol/sdk, node-fetch, fs-extra

## Integration with Existing Scripts
The MCP server leverages existing project automation:
- `run_tests.sh` - Test execution
- `scripts/strava_api_demo.sh` - Strava API testing
- `scripts/write_test_matrix.sh` - Test matrix generation
- `artifacts/instruments_profiling.sh` - Performance profiling

## Next Steps
The MCP server is fully configured and ready to use. You can now:
1. Use Claude Code with natural language to trigger any of these tools
2. Build and test the iOS project through MCP commands
3. Analyze project structure and Swift code patterns
4. Run comprehensive testing and profiling workflows
5. Test Strava API integration and OAuth flows

All tools are tested and working properly. The server provides a unified interface for iOS development workflows in the PrintMyRide project.