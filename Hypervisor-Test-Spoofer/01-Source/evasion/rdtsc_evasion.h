/*
 * RDTSC Evasion Module Header
 * Compensates for timing anomalies caused by VM exits
 */

#ifndef RDTSC_EVASION_H
#define RDTSC_EVASION_H

#include <ntddk.h>

// TSC compensation offset (in cycles)
#define TSC_COMPENSATION_OFFSET     1000

/**
 * Initialize RDTSC evasion module
 */
NTSTATUS RdtscEvasionInitialize(VOID);

/**
 * Compensate TSC value to hide VM exit overhead
 * @param OriginalTsc: Original TSC value
 * @return Compensated TSC value
 */
UINT64 CompensateTscTiming(UINT64 OriginalTsc);

/**
 * Calibrate TSC offset based on VM exit overhead
 */
VOID CalibrateVmExitOverhead(VOID);

/**
 * Get current TSC offset
 * @return TSC offset value
 */
UINT64 GetTscOffset(VOID);

/**
 * Set TSC offset
 * @param Offset: New TSC offset
 */
VOID SetTscOffset(UINT64 Offset);

#endif // RDTSC_EVASION_H

