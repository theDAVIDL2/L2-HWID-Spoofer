/*
 * Configuration System Header
 * Manages HWID spoofing configuration and presets
 */

#ifndef CONFIG_H
#define CONFIG_H

#include <ntddk.h>

// Maximum lengths for strings
#define MAX_SERIAL_LENGTH       64
#define MAX_MODEL_LENGTH        64
#define MAX_VENDOR_LENGTH       64
#define MAX_VERSION_LENGTH      64

// Configuration structure
typedef struct _SPOOF_CONFIG {
    // CPU Information
    BOOLEAN SpoofCpu;
    UINT32 FakeCpuSignature;        // CPUID leaf 1, EAX
    CHAR FakeCpuVendor[13];         // e.g., "GenuineIntel"
    CHAR FakeCpuBrand[49];          // e.g., "Intel(R) Core(TM) i7-9700K"
    
    // Disk Information
    BOOLEAN SpoofDisk;
    CHAR FakeDiskSerial[MAX_SERIAL_LENGTH];
    CHAR FakeDiskModel[MAX_MODEL_LENGTH];
    CHAR FakeDiskFirmware[MAX_VERSION_LENGTH];
    
    // MAC Address
    BOOLEAN SpoofMac;
    UINT8 FakeMacAddress[6];
    
    // Motherboard
    BOOLEAN SpoofMotherboard;
    CHAR FakeMbManufacturer[MAX_VENDOR_LENGTH];
    CHAR FakeMbProduct[MAX_MODEL_LENGTH];
    CHAR FakeMbVersion[MAX_VERSION_LENGTH];
    CHAR FakeMbSerial[MAX_SERIAL_LENGTH];
    UINT8 FakeMbUuid[16];           // System UUID
    
    // BIOS
    BOOLEAN SpoofBios;
    CHAR FakeBiosVendor[MAX_VENDOR_LENGTH];
    CHAR FakeBiosVersion[MAX_VERSION_LENGTH];
    CHAR FakeBiosDate[16];          // MM/DD/YYYY format
    
    // Windows
    BOOLEAN SpoofWindows;
    UINT8 FakeMachineGuid[16];      // HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid
    CHAR FakeProductId[32];         // Windows Product ID
    CHAR FakeComputerName[64];      // Computer name
    
    // Anti-Detection Settings
    BOOLEAN HideHypervisor;         // Hide hypervisor presence
    BOOLEAN CompensateTiming;       // Compensate for VM exit overhead
    BOOLEAN HideMemoryArtifacts;    // Hide VMCS/VMCB from memory scans
    
    // Global Settings
    BOOLEAN Enabled;                // Master enable/disable
    UINT32 RandomSeed;              // For random generation
    
} SPOOF_CONFIG, *PSPOOF_CONFIG;

// Preset profiles
typedef enum _HWID_PRESET {
    PRESET_CUSTOM = 0,
    PRESET_INTEL_I5_9400F,
    PRESET_INTEL_I7_9700K,
    PRESET_INTEL_I9_9900K,
    PRESET_AMD_RYZEN_5_3600,
    PRESET_AMD_RYZEN_7_3700X,
    PRESET_AMD_RYZEN_9_3900X,
    PRESET_RANDOM
} HWID_PRESET;

// Global configuration instance
extern SPOOF_CONFIG g_SpoofConfig;

/**
 * Initialize configuration system
 */
NTSTATUS ConfigInitialize(VOID);

/**
 * Load configuration from preset
 * @param Preset: Preset to load
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS ConfigLoadPreset(HWID_PRESET Preset);

/**
 * Generate random HWID configuration
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS ConfigGenerateRandom(VOID);

/**
 * Generate random serial number
 * @param Buffer: Buffer to store serial (must be at least MAX_SERIAL_LENGTH)
 * @param Length: Desired length
 */
VOID ConfigGenerateRandomSerial(CHAR* Buffer, UINT32 Length);

/**
 * Generate random MAC address
 * @param MacAddress: Buffer to store MAC (6 bytes)
 */
VOID ConfigGenerateRandomMac(UINT8* MacAddress);

/**
 * Generate random UUID
 * @param Uuid: Buffer to store UUID (16 bytes)
 */
VOID ConfigGenerateRandomUuid(UINT8* Uuid);

/**
 * Validate configuration
 * @return TRUE if valid, FALSE otherwise
 */
BOOLEAN ConfigValidate(VOID);

/**
 * Get current configuration
 * @param Config: Pointer to receive configuration copy
 */
VOID ConfigGet(PSPOOF_CONFIG Config);

/**
 * Set configuration
 * @param Config: Configuration to set
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS ConfigSet(PSPOOF_CONFIG Config);

/**
 * Reset configuration to defaults
 */
VOID ConfigReset(VOID);

/**
 * Enable/disable all spoofing
 * @param Enable: TRUE to enable, FALSE to disable
 */
VOID ConfigSetEnabled(BOOLEAN Enable);

/**
 * Check if spoofing is enabled
 * @return TRUE if enabled, FALSE otherwise
 */
BOOLEAN ConfigIsEnabled(VOID);

#endif // CONFIG_H

