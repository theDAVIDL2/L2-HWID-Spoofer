/*
 * RDTSC Evasion Module Implementation
 */

#include "rdtsc_evasion.h"
#include "../common/utils.h"

// Global TSC offset (subtracted from real TSC to compensate for overhead)
static UINT64 g_TscOffset = 0;

// Average VM exit overhead (in TSC cycles)
static UINT64 g_VmExitOverhead = TSC_COMPENSATION_OFFSET;

NTSTATUS RdtscEvasionInitialize(VOID) {
    g_TscOffset = 0;
    
    // Calibrate VM exit overhead
    CalibrateVmExitOverhead();
    
    HvLog(LOG_LEVEL_INFO, "RDTSC evasion initialized (overhead=%llu cycles)\n", 
          g_VmExitOverhead);
    
    return STATUS_SUCCESS;
}

UINT64 CompensateTscTiming(UINT64 OriginalTsc) {
    // Compensate for VM exit overhead by adding cycles
    // This makes timing appear more "native"
    
    UINT64 compensatedTsc = OriginalTsc + g_TscOffset + g_VmExitOverhead;
    
    // Update offset for next read
    // This accumulates overhead over multiple reads
    g_TscOffset += g_VmExitOverhead;
    
    return compensatedTsc;
}

VOID CalibrateVmExitOverhead(VOID) {
    // Measure approximate VM exit overhead
    // This is done by measuring TSC difference before/after several VM exits
    
    // For initial implementation, use a fixed value
    // Real implementation would measure actual overhead
    
    g_VmExitOverhead = TSC_COMPENSATION_OFFSET;
    
    // TODO: Implement dynamic calibration
    // Sample code:
    // UINT64 tscBefore = __rdtsc();
    // // Trigger controlled VM exits
    // UINT64 tscAfter = __rdtsc();
    // g_VmExitOverhead = (tscAfter - tscBefore) / numberOfVmExits;
    
    HvLog(LOG_LEVEL_DEBUG, "VM exit overhead calibrated: %llu cycles\n", 
          g_VmExitOverhead);
}

UINT64 GetTscOffset(VOID) {
    return g_TscOffset;
}

VOID SetTscOffset(UINT64 Offset) {
    g_TscOffset = Offset;
    HvLog(LOG_LEVEL_DEBUG, "TSC offset set to %llu\n", Offset);
}

