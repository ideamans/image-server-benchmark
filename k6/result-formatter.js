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
    console.log('\n=== Benchmark Summary ===\n');
    
    // Group by framework
    const byFramework = {};
    for (const result of this.results) {
      if (!byFramework[result.Framework]) {
        byFramework[result.Framework] = [];
      }
      byFramework[result.Framework].push(result);
    }
    
    // Print summary for each framework
    for (const [framework, results] of Object.entries(byFramework)) {
      console.log(`${framework} (${results[0].Language}):`);
      
      // Calculate averages
      const localResults = results.filter(r => r.Type === 'local');
      const proxyResults = results.filter(r => r.Type === 'proxy');
      
      if (localResults.length > 0) {
        const avgLocalRPS = localResults.reduce((sum, r) => sum + parseFloat(r.Max_RPS), 0) / localResults.length;
        console.log(`  Local Avg RPS: ${avgLocalRPS.toFixed(2)}`);
      }
      
      if (proxyResults.length > 0) {
        const avgProxyRPS = proxyResults.reduce((sum, r) => sum + parseFloat(r.Max_RPS), 0) / proxyResults.length;
        console.log(`  Proxy Avg RPS: ${avgProxyRPS.toFixed(2)}`);
      }
      
      console.log('');
    }
    
    // Find best performers
    console.log('Best Performers:');
    
    const categories = [
      { type: 'local', size: '20k' },
      { type: 'local', size: '100k' },
      { type: 'proxy', size: '20k' },
      { type: 'proxy', size: '100k' },
    ];
    
    for (const category of categories) {
      const filtered = this.results.filter(r => r.Type === category.type && r.Image_Size === category.size);
      if (filtered.length > 0) {
        const best = filtered.reduce((prev, current) => 
          parseFloat(current.Max_RPS) > parseFloat(prev.Max_RPS) ? current : prev
        );
        console.log(`  ${category.type} ${category.size}: ${best.Framework} (${best.Max_RPS} RPS)`);
      }
    }
  }
}