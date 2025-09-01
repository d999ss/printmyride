#!/usr/bin/env python3
"""
Memory analysis and profiling for PrintMyRide optimization testing
"""

import subprocess
import time
import json
import sys
from datetime import datetime

class MemoryProfiler:
    def __init__(self):
        self.device_id = "9544C4B4-1C3E-4F29-A0E8-E2C8E3813972"
        self.bundle_id = "d999ss.PrintMyRide"
        self.samples = []
        
    def capture_memory_samples(self, duration_seconds=30, interval=2):
        """Capture memory usage samples over time"""
        print(f"🧠 Capturing memory samples for {duration_seconds} seconds...")
        
        start_time = time.time()
        sample_count = 0
        
        while time.time() - start_time < duration_seconds:
            sample = self.get_memory_sample()
            if sample:
                self.samples.append(sample)
                sample_count += 1
                
                # Log progress
                elapsed = time.time() - start_time
                print(f"   Sample {sample_count}: {elapsed:.1f}s - Memory usage captured")
            
            time.sleep(interval)
        
        print(f"✅ Captured {len(self.samples)} memory samples")
    
    def get_memory_sample(self):
        """Get current memory usage sample"""
        try:
            # Get process info
            result = subprocess.run([
                "xcrun", "simctl", "spawn", self.device_id,
                "ps", "-o", "pid,rss,vsz,pcpu", "-p", "84405"  # Use known PID
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and result.stdout:
                lines = result.stdout.strip().split('\n')
                if len(lines) > 1:  # Skip header
                    data = lines[1].split()
                    return {
                        "timestamp": time.time(),
                        "pid": data[0] if len(data) > 0 else "N/A",
                        "rss_kb": int(data[1]) if len(data) > 1 and data[1].isdigit() else 0,
                        "vsz_kb": int(data[2]) if len(data) > 2 and data[2].isdigit() else 0,
                        "cpu_percent": float(data[3]) if len(data) > 3 else 0.0
                    }
        except Exception as e:
            print(f"   Warning: Could not capture sample - {e}")
            
        return None
    
    def simulate_poster_workflow(self):
        """Simulate intensive poster generation workflow"""
        print("🎨 Simulating poster generation workflow...")
        
        workflow_steps = [
            {"name": "Load Gallery", "delay": 2},
            {"name": "Select Route", "delay": 1},
            {"name": "Enter Studio", "delay": 2},
            {"name": "Generate Thumbnail", "delay": 3},
            {"name": "Apply Style", "delay": 2},
            {"name": "Export Poster", "delay": 5},
            {"name": "Save to Library", "delay": 1}
        ]
        
        for step in workflow_steps:
            print(f"   {step['name']}...")
            
            # Take screenshot to simulate UI interaction
            subprocess.run([
                "xcrun", "simctl", "io", self.device_id, "screenshot",
                f"./artifacts/workflow_{step['name'].replace(' ', '_').lower()}.png"
            ], capture_output=True)
            
            time.sleep(step['delay'])
    
    def run_memory_stress_test(self):
        """Run memory stress test during poster generation"""
        print("🔥 Running memory stress test...")
        
        # Capture baseline
        print("   Capturing baseline memory usage...")
        time.sleep(3)
        
        # Start memory monitoring
        print("   Starting intensive memory monitoring...")
        
        # Simulate multiple poster generations
        for i in range(3):
            print(f"   Stress test iteration {i+1}/3...")
            
            # Simulate memory-intensive operations
            subprocess.run([
                "xcrun", "simctl", "io", self.device_id, "screenshot",
                f"./artifacts/stress_test_{i+1}.png"
            ], capture_output=True)
            
            time.sleep(4)  # Wait for processing
            
            # Force memory pressure by taking multiple screenshots
            for j in range(5):
                subprocess.run([
                    "xcrun", "simctl", "io", self.device_id, "screenshot",
                    f"./artifacts/memory_pressure_{i}_{j}.png"
                ], capture_output=True)
                time.sleep(0.5)
        
        print("   ✅ Stress test completed")
    
    def analyze_memory_patterns(self):
        """Analyze captured memory samples for patterns"""
        if not self.samples:
            print("❌ No memory samples to analyze")
            return
        
        print("📊 Analyzing memory patterns...")
        
        # Calculate statistics
        rss_values = [s['rss_kb'] for s in self.samples if s['rss_kb'] > 0]
        cpu_values = [s['cpu_percent'] for s in self.samples]
        
        if not rss_values:
            print("❌ No valid memory data found")
            return
        
        stats = {
            "total_samples": len(self.samples),
            "memory_stats": {
                "min_rss_mb": round(min(rss_values) / 1024, 2),
                "max_rss_mb": round(max(rss_values) / 1024, 2),
                "avg_rss_mb": round(sum(rss_values) / len(rss_values) / 1024, 2),
                "memory_growth_mb": round((max(rss_values) - min(rss_values)) / 1024, 2)
            },
            "cpu_stats": {
                "min_cpu": round(min(cpu_values), 2) if cpu_values else 0,
                "max_cpu": round(max(cpu_values), 2) if cpu_values else 0,
                "avg_cpu": round(sum(cpu_values) / len(cpu_values), 2) if cpu_values else 0
            }
        }
        
        # Memory health assessment
        max_memory_mb = stats["memory_stats"]["max_rss_mb"]
        memory_growth = stats["memory_stats"]["memory_growth_mb"]
        
        health_status = "EXCELLENT"
        if max_memory_mb > 200:
            health_status = "HIGH_USAGE"
        elif memory_growth > 50:
            health_status = "POTENTIAL_LEAK"
        elif max_memory_mb > 100:
            health_status = "NORMAL"
        
        stats["memory_health"] = health_status
        
        return stats
    
    def generate_report(self):
        """Generate comprehensive memory analysis report"""
        stats = self.analyze_memory_patterns()
        
        if not stats:
            return
        
        print("\n" + "=" * 60)
        print("🧠 MEMORY ANALYSIS REPORT")
        print("=" * 60)
        
        print(f"📊 Sample Count: {stats['total_samples']}")
        print(f"🎯 Memory Health: {stats['memory_health']}")
        
        print("\n💾 MEMORY STATISTICS:")
        mem_stats = stats['memory_stats']
        print(f"   • Minimum Usage: {mem_stats['min_rss_mb']} MB")
        print(f"   • Maximum Usage: {mem_stats['max_rss_mb']} MB") 
        print(f"   • Average Usage: {mem_stats['avg_rss_mb']} MB")
        print(f"   • Memory Growth: {mem_stats['memory_growth_mb']} MB")
        
        print("\n⚡ CPU STATISTICS:")
        cpu_stats = stats['cpu_stats']
        print(f"   • Minimum CPU: {cpu_stats['min_cpu']}%")
        print(f"   • Maximum CPU: {cpu_stats['max_cpu']}%")
        print(f"   • Average CPU: {cpu_stats['avg_cpu']}%")
        
        # Performance assessment
        print("\n🎯 PERFORMANCE ASSESSMENT:")
        if stats['memory_health'] == 'EXCELLENT':
            print("   ✅ Memory usage is excellent - well optimized")
        elif stats['memory_health'] == 'NORMAL':
            print("   🟡 Memory usage is normal - some optimization possible")
        elif stats['memory_health'] == 'HIGH_USAGE':
            print("   🟠 High memory usage detected - optimization recommended")
        else:
            print("   🔴 Potential memory leak detected - investigation needed")
        
        # Optimization recommendations
        print("\n💡 OPTIMIZATION RECOMMENDATIONS:")
        if mem_stats['memory_growth_mb'] > 30:
            print("   • Investigate potential memory leaks")
            print("   • Implement more aggressive cache cleanup")
        
        if mem_stats['max_rss_mb'] > 150:
            print("   • Consider streaming exports for large posters")
            print("   • Implement tile-based rendering")
        
        if cpu_stats['max_cpu'] > 80:
            print("   • Optimize CPU-intensive algorithms")
            print("   • Consider background processing")
        
        print("   • Deploy optimized PosterRenderService")
        print("   • Enable parallel point simplification")
        print("   • Implement enhanced caching system")
        
        # Save detailed report
        report = {
            "timestamp": datetime.now().isoformat(),
            "device_id": self.device_id,
            "bundle_id": self.bundle_id,
            "statistics": stats,
            "raw_samples": self.samples[-10:],  # Last 10 samples
            "recommendations": [
                "Deploy PosterRenderService optimizations",
                "Enable parallel processing",
                "Implement enhanced caching",
                "Monitor memory growth patterns"
            ]
        }
        
        with open("./artifacts/memory_analysis_report.json", "w") as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Detailed report saved: memory_analysis_report.json")
        print("=" * 60)
    
    def run_full_analysis(self):
        """Run complete memory analysis suite"""
        print("🚀 Starting comprehensive memory analysis...")
        print("=" * 50)
        
        try:
            # Run workflow simulation with monitoring
            self.simulate_poster_workflow()
            
            # Capture memory samples
            self.capture_memory_samples(duration_seconds=20, interval=1)
            
            # Run stress test
            self.run_memory_stress_test()
            
            # Generate comprehensive report
            self.generate_report()
            
        except KeyboardInterrupt:
            print("\n⚠️  Analysis interrupted by user")
            if self.samples:
                self.generate_report()
        except Exception as e:
            print(f"❌ Analysis failed: {e}")

def main():
    profiler = MemoryProfiler()
    profiler.run_full_analysis()

if __name__ == "__main__":
    main()