import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export class ResultFormatter {
  constructor() {
    this.results = [];
    this.resultsDir = path.join(__dirname, '../results');
    
    // Ensure results directory exists
    if (!fs.existsSync(this.resultsDir)) {
      fs.mkdirSync(this.resultsDir, { recursive: true });
    }
  }
  
  addResult(testName, jsonResultPath) {
    try {
      const jsonData = fs.readFileSync(jsonResultPath, 'utf8');
      const result = JSON.parse(jsonData);
      
      // Extract key metrics
      const metrics = result.metrics;
      const httpReqs = metrics.http_reqs;
      const httpReqDuration = metrics.http_req_duration;
      const httpReqFailed = metrics.http_req_failed;
      
      // Parse test name to get framework, language, size, and type
      const parts = testName.split('-');
      const framework = parts[0];
      const language = parts[1];
      const size = parts[2];
      const type = parts[3];
      
      const formattedResult = {
        Framework: framework,
        Language: language,
        Image_Size: size,
        Type: type,
        Max_RPS: httpReqs ? httpReqs.values.rate.toFixed(2) : '0',
        Avg_Response_Time_ms: httpReqDuration ? httpReqDuration.values.avg.toFixed(2) : '0',
        P95_Response_Time_ms: httpReqDuration ? httpReqDuration.values['p(95)'].toFixed(2) : '0',
        Error_Rate: httpReqFailed ? (httpReqFailed.values.rate * 100).toFixed(2) : '0',
        Total_Requests: httpReqs ? httpReqs.values.count : 0,
        Timestamp: result.timestamp,
      };
      
      this.results.push(formattedResult);
      console.log(`Added result for ${testName}`);
      
    } catch (error) {
      console.error(`Error processing result for ${testName}:`, error);
    }
  }
  
  saveToTSV() {
    const tsvPath = path.join(this.resultsDir, 'benchmark-results.tsv');
    
    // Sort results by framework, then by image size
    this.results.sort((a, b) => {
      if (a.Framework !== b.Framework) {
        return a.Framework.localeCompare(b.Framework);
      }
      if (a.Type !== b.Type) {
        return a.Type.localeCompare(b.Type);
      }
      // Sort by size: 20k < 50k < 100k
      const sizeOrder = { '20k': 1, '50k': 2, '100k': 3 };
      return sizeOrder[a.Image_Size] - sizeOrder[b.Image_Size];
    });
    
    // Create TSV header
    const headers = [
      'Framework',
      'Language',
      'Image_Size',
      'Type',
      'Max_RPS',
      'Avg_Response_Time_ms',
      'P95_Response_Time_ms',
      'Error_Rate',
    ];
    
    // Create TSV content
    let tsvContent = headers.join('\t') + '\n';
    
    for (const result of this.results) {
      const row = headers.map(header => result[header] || '').join('\t');
      tsvContent += row + '\n';
    }
    
    // Save to file
    fs.writeFileSync(tsvPath, tsvContent);
    console.log(`\nResults saved to: ${tsvPath}`);
    
    // Also save detailed JSON results
    const jsonPath = path.join(this.resultsDir, 'benchmark-results-detailed.json');
    fs.writeFileSync(jsonPath, JSON.stringify(this.results, null, 2));
    console.log(`Detailed results saved to: ${jsonPath}`);
  }
  
  printSummary() {
    console.log('\n=== Benchmark Summary - Performance Rankings ===\n');
    
    // Define all test cases
    const testCases = [
      { type: 'local', size: '20k', name: 'Local 20KB Image' },
      { type: 'local', size: '50k', name: 'Local 50KB Image' },
      { type: 'local', size: '100k', name: 'Local 100KB Image' },
      { type: 'proxy', size: '20k', name: 'Proxy 20KB Image' },
      { type: 'proxy', size: '50k', name: 'Proxy 50KB Image' },
      { type: 'proxy', size: '100k', name: 'Proxy 100KB Image' },
    ];
    
    // Print ranking for each test case
    for (const testCase of testCases) {
      console.log(`--- ${testCase.name} ---`);
      
      // Filter and sort results for this test case
      const filtered = this.results
        .filter(r => r.Type === testCase.type && r.Image_Size === testCase.size)
        .sort((a, b) => parseFloat(b.Max_RPS) - parseFloat(a.Max_RPS));
      
      if (filtered.length > 0) {
        console.log('Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%');
        console.log('----  -----------  ----------   -------  --------  --------  ------');
        
        filtered.forEach((result, index) => {
          const rank = (index + 1).toString().padEnd(4);
          const framework = result.Framework.padEnd(11);
          const language = result.Language.padEnd(10);
          const rps = parseFloat(result.Max_RPS).toFixed(2).padStart(7);
          const avgRT = parseFloat(result.Avg_Response_Time_ms).toFixed(2).padStart(8) + 'ms';
          const p95RT = parseFloat(result.P95_Response_Time_ms).toFixed(2).padStart(8) + 'ms';
          const errorRate = (parseFloat(result.Error_Rate) * 100).toFixed(2).padStart(6);
          
          console.log(`${rank}  ${framework}  ${language}   ${rps}  ${avgRT}  ${p95RT}  ${errorRate}`);
        });
      } else {
        console.log('  No results available');
      }
      
      console.log('');
    }
    
    // Overall statistics
    console.log('--- Overall Statistics ---');
    
    // Best local performance
    const bestLocal = this.results
      .filter(r => r.Type === 'local')
      .reduce((best, current) => 
        parseFloat(current.Max_RPS) > parseFloat(best?.Max_RPS || 0) ? current : best, 
        null
      );
    
    if (bestLocal) {
      console.log(`Best Local Performance: ${bestLocal.Framework} (${bestLocal.Max_RPS} RPS for ${bestLocal.Image_Size})`);
    }
    
    // Best proxy performance
    const bestProxy = this.results
      .filter(r => r.Type === 'proxy')
      .reduce((best, current) => 
        parseFloat(current.Max_RPS) > parseFloat(best?.Max_RPS || 0) ? current : best, 
        null
      );
    
    if (bestProxy) {
      console.log(`Best Proxy Performance: ${bestProxy.Framework} (${bestProxy.Max_RPS} RPS for ${bestProxy.Image_Size})`);
    }
  }
}