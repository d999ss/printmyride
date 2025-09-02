#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { spawn, exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const execAsync = promisify(exec);

class PrintMyRideMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'printmyride-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.projectRoot = path.resolve(__dirname, '../..');
    this.setupToolHandlers();
  }

  setupToolHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        // Xcode Build Tools
        {
          name: 'xcode_build',
          description: 'Build the Xcode project',
          inputSchema: {
            type: 'object',
            properties: {
              scheme: { type: 'string', default: 'PrintMyRide' },
              configuration: { type: 'string', enum: ['Debug', 'Release'], default: 'Debug' },
              clean: { type: 'boolean', default: false }
            }
          }
        },
        {
          name: 'xcode_test',
          description: 'Run Xcode tests',
          inputSchema: {
            type: 'object',
            properties: {
              testType: { 
                type: 'string', 
                enum: ['all', 'unit', 'ui', 'snapshot', 'links'], 
                default: 'all' 
              },
              device: { type: 'string', default: 'iPhone 16 Pro' }
            }
          }
        },
        {
          name: 'simulator_control',
          description: 'Control iOS Simulator',
          inputSchema: {
            type: 'object',
            properties: {
              action: { 
                type: 'string', 
                enum: ['boot', 'shutdown', 'list', 'install', 'launch', 'uninstall'] 
              },
              device: { type: 'string', default: 'iPhone 16 Pro' },
              bundleId: { type: 'string', default: 'd999ss.PrintMyRide' }
            }
          }
        },
        
        // Strava API Tools
        {
          name: 'strava_test_setup',
          description: 'Set up Strava API testing environment',
          inputSchema: {
            type: 'object',
            properties: {
              action: { 
                type: 'string', 
                enum: ['setup', 'demo', 'validate'] 
              }
            }
          }
        },
        {
          name: 'strava_api_call',
          description: 'Make Strava API calls for testing',
          inputSchema: {
            type: 'object',
            properties: {
              endpoint: { type: 'string' },
              method: { type: 'string', enum: ['GET', 'POST'], default: 'GET' },
              params: { type: 'object' }
            }
          }
        },
        
        // File Management Tools
        {
          name: 'analyze_project_structure',
          description: 'Analyze iOS project file structure',
          inputSchema: {
            type: 'object',
            properties: {
              includeTests: { type: 'boolean', default: true },
              showSizes: { type: 'boolean', default: false }
            }
          }
        },
        {
          name: 'swift_file_analysis',
          description: 'Analyze Swift files for patterns, dependencies, or issues',
          inputSchema: {
            type: 'object',
            properties: {
              pattern: { type: 'string' },
              fileType: { type: 'string', enum: ['swift', 'h', 'm', 'all'], default: 'swift' }
            }
          }
        },
        
        // Testing Tools
        {
          name: 'run_regression_tests',
          description: 'Run comprehensive regression test suite',
          inputSchema: {
            type: 'object',
            properties: {
              generateReport: { type: 'boolean', default: true }
            }
          }
        },
        {
          name: 'memory_profiling',
          description: 'Run memory and performance profiling',
          inputSchema: {
            type: 'object',
            properties: {
              duration: { type: 'number', default: 30 }
            }
          }
        },
        {
          name: 'generate_test_matrix',
          description: 'Generate comprehensive test coverage matrix',
          inputSchema: {
            type: 'object',
            properties: {
              outputFormat: { type: 'string', enum: ['markdown', 'json'], default: 'markdown' }
            }
          }
        }
      ]
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'xcode_build':
            return await this.handleXcodeBuild(args);
          case 'xcode_test':
            return await this.handleXcodeTest(args);
          case 'simulator_control':
            return await this.handleSimulatorControl(args);
          case 'strava_test_setup':
            return await this.handleStravaTestSetup(args);
          case 'strava_api_call':
            return await this.handleStravaAPICall(args);
          case 'analyze_project_structure':
            return await this.handleAnalyzeProjectStructure(args);
          case 'swift_file_analysis':
            return await this.handleSwiftFileAnalysis(args);
          case 'run_regression_tests':
            return await this.handleRunRegressionTests(args);
          case 'memory_profiling':
            return await this.handleMemoryProfiling(args);
          case 'generate_test_matrix':
            return await this.handleGenerateTestMatrix(args);
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error executing ${name}: ${error.message}`,
            },
          ],
        };
      }
    });
  }

  // Xcode Build Handler
  async handleXcodeBuild(args) {
    const { scheme = 'PrintMyRide', configuration = 'Debug', clean = false } = args;
    
    let command = `cd "${this.projectRoot}" && `;
    if (clean) {
      command += 'xcodebuild clean && ';
    }
    
    command += `xcodebuild -scheme "${scheme}" -configuration ${configuration} -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`;

    const result = await this.executeCommand(command);
    return {
      content: [
        {
          type: 'text',
          text: `Xcode Build (${scheme}, ${configuration}):\n${result.stdout}${result.stderr ? '\nErrors: ' + result.stderr : ''}`,
        },
      ],
    };
  }

  // Xcode Test Handler
  async handleXcodeTest(args) {
    const { testType = 'all', device = 'iPhone 16 Pro' } = args;
    
    const command = `cd "${this.projectRoot}" && ./run_tests.sh ${testType}`;
    const result = await this.executeCommand(command);
    
    return {
      content: [
        {
          type: 'text',
          text: `Test Results (${testType}):\n${result.stdout}${result.stderr ? '\nErrors: ' + result.stderr : ''}`,
        },
      ],
    };
  }

  // Simulator Control Handler
  async handleSimulatorControl(args) {
    const { action, device = 'iPhone 16 Pro', bundleId = 'd999ss.PrintMyRide' } = args;
    
    let command;
    switch (action) {
      case 'boot':
        command = `xcrun simctl boot "${device}"`;
        break;
      case 'shutdown':
        command = `xcrun simctl shutdown "${device}"`;
        break;
      case 'list':
        command = 'xcrun simctl list devices available';
        break;
      case 'install':
        command = `cd "${this.projectRoot}" && xcrun simctl install "${device}" build/DerivedData/Build/Products/Debug-iphonesimulator/PrintMyRide.app`;
        break;
      case 'launch':
        command = `xcrun simctl launch "${device}" ${bundleId}`;
        break;
      case 'uninstall':
        command = `xcrun simctl uninstall "${device}" ${bundleId}`;
        break;
      default:
        throw new Error(`Unknown simulator action: ${action}`);
    }

    const result = await this.executeCommand(command);
    return {
      content: [
        {
          type: 'text',
          text: `Simulator ${action} result:\n${result.stdout}${result.stderr ? '\nErrors: ' + result.stderr : ''}`,
        },
      ],
    };
  }

  // Strava Test Setup Handler
  async handleStravaTestSetup(args) {
    const { action } = args;
    
    let command;
    switch (action) {
      case 'setup':
        command = `cd "${this.projectRoot}" && ./scripts/strava_test_setup.sh`;
        break;
      case 'demo':
        command = `cd "${this.projectRoot}" && ./scripts/strava_api_demo.sh`;
        break;
      case 'validate':
        command = `cd "${this.projectRoot}" && ./scripts/strava_api_demo.sh validate`;
        break;
      default:
        throw new Error(`Unknown Strava action: ${action}`);
    }

    const result = await this.executeCommand(command);
    return {
      content: [
        {
          type: 'text',
          text: `Strava ${action} result:\n${result.stdout}${result.stderr ? '\nErrors: ' + result.stderr : ''}`,
        },
      ],
    };
  }

  // Strava API Call Handler
  async handleStravaAPICall(args) {
    const { endpoint, method = 'GET', params = {} } = args;
    
    // This would integrate with the actual Strava API
    // For now, we'll simulate it with a command that uses the existing setup
    const command = `cd "${this.projectRoot}" && echo "Strava API ${method} ${endpoint} with params: ${JSON.stringify(params)}"`;
    const result = await this.executeCommand(command);
    
    return {
      content: [
        {
          type: 'text',
          text: `Strava API Call:\n${result.stdout}`,
        },
      ],
    };
  }

  // Project Structure Analysis Handler
  async handleAnalyzeProjectStructure(args) {
    const { includeTests = true, showSizes = false } = args;
    
    let command = `cd "${this.projectRoot}" && find . -name "*.swift" -o -name "*.h" -o -name "*.m"`;
    if (!includeTests) {
      command += ' | grep -v Test';
    }
    if (showSizes) {
      command += ' | xargs ls -la';
    }
    
    const result = await this.executeCommand(command);
    return {
      content: [
        {
          type: 'text',
          text: `Project Structure Analysis:\n${result.stdout}`,
        },
      ],
    };
  }

  // Swift File Analysis Handler
  async handleSwiftFileAnalysis(args) {
    const { pattern, fileType = 'swift' } = args;
    
    let fileExtension = '';
    switch (fileType) {
      case 'swift':
        fileExtension = '*.swift';
        break;
      case 'h':
        fileExtension = '*.h';
        break;
      case 'm':
        fileExtension = '*.m';
        break;
      case 'all':
        fileExtension = '*.swift -o -name *.h -o -name *.m';
        break;
    }
    
    const command = `cd "${this.projectRoot}" && find . -name "${fileExtension}" -exec grep -l "${pattern}" {} \\;`;
    const result = await this.executeCommand(command);
    
    return {
      content: [
        {
          type: 'text',
          text: `Swift File Analysis (pattern: ${pattern}):\n${result.stdout}`,
        },
      ],
    };
  }

  // Regression Tests Handler
  async handleRunRegressionTests(args) {
    const { generateReport = true } = args;
    
    const command = `cd "${this.projectRoot}" && ./scripts/run_regression_tests.sh`;
    const result = await this.executeCommand(command);
    
    return {
      content: [
        {
          type: 'text',
          text: `Regression Tests:\n${result.stdout}${result.stderr ? '\nErrors: ' + result.stderr : ''}`,
        },
      ],
    };
  }

  // Memory Profiling Handler
  async handleMemoryProfiling(args) {
    const { duration = 30 } = args;
    
    const command = `cd "${this.projectRoot}" && ./artifacts/instruments_profiling.sh ${duration}`;
    const result = await this.executeCommand(command);
    
    return {
      content: [
        {
          type: 'text',
          text: `Memory Profiling (${duration}s):\n${result.stdout}${result.stderr ? '\nErrors: ' + result.stderr : ''}`,
        },
      ],
    };
  }

  // Test Matrix Generation Handler
  async handleGenerateTestMatrix(args) {
    const { outputFormat = 'markdown' } = args;
    
    const command = `cd "${this.projectRoot}" && ./scripts/write_test_matrix.sh`;
    const result = await this.executeCommand(command);
    
    return {
      content: [
        {
          type: 'text',
          text: `Test Matrix (${outputFormat}):\n${result.stdout}`,
        },
      ],
    };
  }

  // Utility method to execute commands
  async executeCommand(command) {
    try {
      const { stdout, stderr } = await execAsync(command);
      return { stdout: stdout || '', stderr: stderr || '' };
    } catch (error) {
      return { stdout: '', stderr: error.message };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('PrintMyRide MCP Server running on stdio');
  }
}

const server = new PrintMyRideMCPServer();
server.run().catch(console.error);