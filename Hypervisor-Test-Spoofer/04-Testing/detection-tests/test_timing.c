/*
 * Timing-Based VM Detection Test
 * Tests for timing anomalies caused by VM exits
 */

#include <Windows.h>
#include <stdio.h>
#include <intrin.h>

#define NUM_SAMPLES 1000
#define THRESHOLD_CYCLES 1000  // Adjust based on system

void TestRDTSCTiming() {
    unsigned __int64 start, end;
    unsigned __int64 minDelta = ULLONG_MAX;
    unsigned __int64 maxDelta = 0;
    unsigned __int64 totalDelta = 0;
    unsigned __int64 avgDelta;
    int suspiciousCount = 0;
    
    printf("[+] Testing RDTSC Timing...\n");
    printf("  Measuring %d RDTSC executions...\n", NUM_SAMPLES);
    
    for (int i = 0; i < NUM_SAMPLES; i++) {
        start = __rdtsc();
        end = __rdtsc();
        
        unsigned __int64 delta = end - start;
        
        if (delta < minDelta) minDelta = delta;
        if (delta > maxDelta) maxDelta = delta;
        totalDelta += delta;
        
        if (delta > THRESHOLD_CYCLES) {
            suspiciousCount++;
        }
    }
    
    avgDelta = totalDelta / NUM_SAMPLES;
    
    printf("  Min cycles: %llu\n", minDelta);
    printf("  Max cycles: %llu\n", maxDelta);
    printf("  Avg cycles: %llu\n", avgDelta);
    printf("  Suspicious readings (>%d cycles): %d\n", THRESHOLD_CYCLES, suspiciousCount);
    
    if (avgDelta > 100) {
        printf("  [DETECTED] Average timing is suspiciously high\n");
    }
    else if (maxDelta > THRESHOLD_CYCLES) {
        printf("  [WARNING] Some readings show high latency\n");
    }
    else {
        printf("  [PASS] Timing appears normal\n");
    }
}

void TestCPUIDTiming() {
    unsigned __int64 start, end;
    unsigned __int64 totalDelta = 0;
    unsigned __int64 avgDelta;
    int cpuInfo[4];
    
    printf("\n[+] Testing CPUID Timing...\n");
    printf("  Measuring %d CPUID executions...\n", NUM_SAMPLES);
    
    for (int i = 0; i < NUM_SAMPLES; i++) {
        start = __rdtsc();
        __cpuid(cpuInfo, 1);
        end = __rdtsc();
        
        totalDelta += (end - start);
    }
    
    avgDelta = totalDelta / NUM_SAMPLES;
    
    printf("  Avg cycles: %llu\n", avgDelta);
    
    if (avgDelta > 5000) {
        printf("  [DETECTED] CPUID timing is suspiciously high (likely VM exit)\n");
    }
    else if (avgDelta > 2000) {
        printf("  [WARNING] CPUID timing is higher than typical\n");
    }
    else {
        printf("  [PASS] CPUID timing appears normal\n");
    }
}

void TestConsistency() {
    unsigned __int64 samples[10];
    unsigned __int64 start, end;
    int cpuInfo[4];
    
    printf("\n[+] Testing Timing Consistency...\n");
    
    for (int i = 0; i < 10; i++) {
        start = __rdtsc();
        __cpuid(cpuInfo, 1);
        end = __rdtsc();
        samples[i] = end - start;
    }
    
    printf("  Individual CPUID timings:\n");
    for (int i = 0; i < 10; i++) {
        printf("    Sample %d: %llu cycles\n", i + 1, samples[i]);
    }
    
    // Check for high variance
    unsigned __int64 min = samples[0], max = samples[0];
    for (int i = 1; i < 10; i++) {
        if (samples[i] < min) min = samples[i];
        if (samples[i] > max) max = samples[i];
    }
    
    unsigned __int64 variance = max - min;
    printf("  Variance: %llu cycles\n", variance);
    
    if (variance > 5000) {
        printf("  [DETECTED] High timing variance (VM inconsistency)\n");
    }
    else {
        printf("  [PASS] Timing is consistent\n");
    }
}

void TestMSRTiming() {
    unsigned __int64 start, end;
    unsigned __int64 totalDelta = 0;
    unsigned __int64 avgDelta;
    
    printf("\n[+] Testing MSR Read Timing (IA32_TIME_STAMP_COUNTER)...\n");
    printf("  Note: Requires admin privileges\n");
    
    // Test if we can read MSRs
    __try {
        for (int i = 0; i < NUM_SAMPLES; i++) {
            start = __rdtsc();
            __readmsr(0x10);  // IA32_TIME_STAMP_COUNTER
            end = __rdtsc();
            
            totalDelta += (end - start);
        }
        
        avgDelta = totalDelta / NUM_SAMPLES;
        
        printf("  Avg cycles: %llu\n", avgDelta);
        
        if (avgDelta > 5000) {
            printf("  [DETECTED] MSR read timing is high (likely intercepted)\n");
        }
        else {
            printf("  [PASS] MSR timing appears normal\n");
        }
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        printf("  [ERROR] Cannot read MSR (insufficient privileges or exception)\n");
    }
}

int main() {
    printf("===========================================\n");
    printf("Timing-Based VM Detection Test\n");
    printf("===========================================\n\n");
    
    TestRDTSCTiming();
    TestCPUIDTiming();
    TestConsistency();
    TestMSRTiming();
    
    printf("\n===========================================\n");
    printf("Test Complete\n");
    printf("===========================================\n");
    
    return 0;
}

