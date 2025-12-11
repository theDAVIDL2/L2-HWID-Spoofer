/*
 * AMD SVM-Specific VM Exit Handlers Header
 */

#ifndef VMEXIT_HANDLERS_AMD_H
#define VMEXIT_HANDLERS_AMD_H

#include "svm_amd.h"

/**
 * Handle CPUID exit (AMD SVM)
 * @param SvmCpu: Per-CPU SVM data
 */
VOID SvmHandleCpuidExit(PSVM_CPU SvmCpu);

/**
 * Handle MSR access exit (AMD SVM)
 * @param SvmCpu: Per-CPU SVM data
 */
VOID SvmHandleMsrExit(PSVM_CPU SvmCpu);

/**
 * Handle I/O instruction exit (AMD SVM)
 * @param SvmCpu: Per-CPU SVM data
 */
VOID SvmHandleIoExit(PSVM_CPU SvmCpu);

/**
 * Handle RDTSC exit (AMD SVM)
 * @param SvmCpu: Per-CPU SVM data
 */
VOID SvmHandleRdtscExit(PSVM_CPU SvmCpu);

/**
 * Handle VMMCALL exit (AMD SVM)
 * @param SvmCpu: Per-CPU SVM data
 */
VOID SvmHandleVmmcallExit(PSVM_CPU SvmCpu);

#endif // VMEXIT_HANDLERS_AMD_H

