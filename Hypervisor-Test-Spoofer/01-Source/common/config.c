/*
 * Configuration System Implementation
 */

#include "config.h"
#include "utils.h"

// Global configuration
SPOOF_CONFIG g_SpoofConfig = { 0 };

// Random number generator state
static UINT32 g_RngState = 0x12345678;

// Simple LCG random number generator
static UINT32 Rand(VOID) {
    g_RngState = (g_RngState * 1103515245 + 12345) & 0x7FFFFFFF;
    return g_RngState;
}

static VOID SeedRand(UINT32 Seed) {
    g_RngState = Seed;
}

NTSTATUS ConfigInitialize(VOID) {
    LARGE_INTEGER perfCounter;
    
    HvZeroMemory(&g_SpoofConfig, sizeof(g_SpoofConfig));
    
    // Seed RNG with performance counter
    perfCounter = KeQueryPerformanceCounter(NULL);
    g_SpoofConfig.RandomSeed = (UINT32)perfCounter.QuadPart;
    SeedRand(g_SpoofConfig.RandomSeed);
    
    // Set defaults
    g_SpoofConfig.Enabled = FALSE;
    g_SpoofConfig.HideHypervisor = TRUE;
    g_SpoofConfig.CompensateTiming = TRUE;
    g_SpoofConfig.HideMemoryArtifacts = TRUE;
    
    HvLog(LOG_LEVEL_INFO, "Configuration initialized (seed=0x%08X)\n", g_SpoofConfig.RandomSeed);
    
    return STATUS_SUCCESS;
}

NTSTATUS ConfigLoadPreset(HWID_PRESET Preset) {
    switch (Preset) {
        case PRESET_INTEL_I5_9400F:
            // CPU
            g_SpoofConfig.SpoofCpu = TRUE;
            g_SpoofConfig.FakeCpuSignature = 0x000906EC;  // Family 6, Model 158, Stepping 12
            RtlCopyMemory(g_SpoofConfig.FakeCpuVendor, "GenuineIntel", 13);
            RtlCopyMemory(g_SpoofConfig.FakeCpuBrand, "Intel(R) Core(TM) i5-9400F CPU @ 2.90GHz", 41);
            
            // Motherboard
            g_SpoofConfig.SpoofMotherboard = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeMbManufacturer, "ASUSTeK COMPUTER INC.", 22);
            RtlCopyMemory(g_SpoofConfig.FakeMbProduct, "PRIME Z390-A", 13);
            RtlCopyMemory(g_SpoofConfig.FakeMbVersion, "Rev X.0x", 9);
            ConfigGenerateRandomSerial(g_SpoofConfig.FakeMbSerial, 20);
            ConfigGenerateRandomUuid(g_SpoofConfig.FakeMbUuid);
            
            // BIOS
            g_SpoofConfig.SpoofBios = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeBiosVendor, "American Megatrends Inc.", 25);
            RtlCopyMemory(g_SpoofConfig.FakeBiosVersion, "2417", 5);
            RtlCopyMemory(g_SpoofConfig.FakeBiosDate, "07/19/2019", 11);
            break;
            
        case PRESET_INTEL_I7_9700K:
            g_SpoofConfig.SpoofCpu = TRUE;
            g_SpoofConfig.FakeCpuSignature = 0x000906EC;
            RtlCopyMemory(g_SpoofConfig.FakeCpuVendor, "GenuineIntel", 13);
            RtlCopyMemory(g_SpoofConfig.FakeCpuBrand, "Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz", 41);
            
            g_SpoofConfig.SpoofMotherboard = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeMbManufacturer, "Gigabyte Technology Co., Ltd.", 30);
            RtlCopyMemory(g_SpoofConfig.FakeMbProduct, "Z390 AORUS PRO", 15);
            RtlCopyMemory(g_SpoofConfig.FakeMbVersion, "Default string", 15);
            ConfigGenerateRandomSerial(g_SpoofConfig.FakeMbSerial, 20);
            ConfigGenerateRandomUuid(g_SpoofConfig.FakeMbUuid);
            
            g_SpoofConfig.SpoofBios = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeBiosVendor, "American Megatrends Inc.", 25);
            RtlCopyMemory(g_SpoofConfig.FakeBiosVersion, "F10", 4);
            RtlCopyMemory(g_SpoofConfig.FakeBiosDate, "05/20/2019", 11);
            break;
            
        case PRESET_INTEL_I9_9900K:
            g_SpoofConfig.SpoofCpu = TRUE;
            g_SpoofConfig.FakeCpuSignature = 0x000906EC;
            RtlCopyMemory(g_SpoofConfig.FakeCpuVendor, "GenuineIntel", 13);
            RtlCopyMemory(g_SpoofConfig.FakeCpuBrand, "Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz", 41);
            
            g_SpoofConfig.SpoofMotherboard = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeMbManufacturer, "MSI", 4);
            RtlCopyMemory(g_SpoofConfig.FakeMbProduct, "MPG Z390 GAMING EDGE AC (MS-7B17)", 34);
            RtlCopyMemory(g_SpoofConfig.FakeMbVersion, "1.0", 4);
            ConfigGenerateRandomSerial(g_SpoofConfig.FakeMbSerial, 20);
            ConfigGenerateRandomUuid(g_SpoofConfig.FakeMbUuid);
            
            g_SpoofConfig.SpoofBios = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeBiosVendor, "American Megatrends Inc.", 25);
            RtlCopyMemory(g_SpoofConfig.FakeBiosVersion, "1.70", 5);
            RtlCopyMemory(g_SpoofConfig.FakeBiosDate, "06/13/2019", 11);
            break;
            
        case PRESET_AMD_RYZEN_5_3600:
            g_SpoofConfig.SpoofCpu = TRUE;
            g_SpoofConfig.FakeCpuSignature = 0x00870F10;  // Family 23, Model 113, Stepping 0
            RtlCopyMemory(g_SpoofConfig.FakeCpuVendor, "AuthenticAMD", 13);
            RtlCopyMemory(g_SpoofConfig.FakeCpuBrand, "AMD Ryzen 5 3600 6-Core Processor", 34);
            
            g_SpoofConfig.SpoofMotherboard = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeMbManufacturer, "ASUSTeK COMPUTER INC.", 22);
            RtlCopyMemory(g_SpoofConfig.FakeMbProduct, "ROG STRIX B450-F GAMING", 24);
            RtlCopyMemory(g_SpoofConfig.FakeMbVersion, "Rev X.0x", 9);
            ConfigGenerateRandomSerial(g_SpoofConfig.FakeMbSerial, 20);
            ConfigGenerateRandomUuid(g_SpoofConfig.FakeMbUuid);
            
            g_SpoofConfig.SpoofBios = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeBiosVendor, "American Megatrends Inc.", 25);
            RtlCopyMemory(g_SpoofConfig.FakeBiosVersion, "3003", 5);
            RtlCopyMemory(g_SpoofConfig.FakeBiosDate, "07/23/2019", 11);
            break;
            
        case PRESET_AMD_RYZEN_7_3700X:
            g_SpoofConfig.SpoofCpu = TRUE;
            g_SpoofConfig.FakeCpuSignature = 0x00870F10;
            RtlCopyMemory(g_SpoofConfig.FakeCpuVendor, "AuthenticAMD", 13);
            RtlCopyMemory(g_SpoofConfig.FakeCpuBrand, "AMD Ryzen 7 3700X 8-Core Processor", 35);
            
            g_SpoofConfig.SpoofMotherboard = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeMbManufacturer, "Gigabyte Technology Co., Ltd.", 30);
            RtlCopyMemory(g_SpoofConfig.FakeMbProduct, "X570 AORUS ELITE", 17);
            RtlCopyMemory(g_SpoofConfig.FakeMbVersion, "Default string", 15);
            ConfigGenerateRandomSerial(g_SpoofConfig.FakeMbSerial, 20);
            ConfigGenerateRandomUuid(g_SpoofConfig.FakeMbUuid);
            
            g_SpoofConfig.SpoofBios = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeBiosVendor, "American Megatrends Inc.", 25);
            RtlCopyMemory(g_SpoofConfig.FakeBiosVersion, "F4", 3);
            RtlCopyMemory(g_SpoofConfig.FakeBiosDate, "07/30/2019", 11);
            break;
            
        case PRESET_AMD_RYZEN_9_3900X:
            g_SpoofConfig.SpoofCpu = TRUE;
            g_SpoofConfig.FakeCpuSignature = 0x00870F10;
            RtlCopyMemory(g_SpoofConfig.FakeCpuVendor, "AuthenticAMD", 13);
            RtlCopyMemory(g_SpoofConfig.FakeCpuBrand, "AMD Ryzen 9 3900X 12-Core Processor", 36);
            
            g_SpoofConfig.SpoofMotherboard = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeMbManufacturer, "MSI", 4);
            RtlCopyMemory(g_SpoofConfig.FakeMbProduct, "MEG X570 GODLIKE (MS-7C34)", 27);
            RtlCopyMemory(g_SpoofConfig.FakeMbVersion, "1.0", 4);
            ConfigGenerateRandomSerial(g_SpoofConfig.FakeMbSerial, 20);
            ConfigGenerateRandomUuid(g_SpoofConfig.FakeMbUuid);
            
            g_SpoofConfig.SpoofBios = TRUE;
            RtlCopyMemory(g_SpoofConfig.FakeBiosVendor, "American Megatrends Inc.", 25);
            RtlCopyMemory(g_SpoofConfig.FakeBiosVersion, "1.20", 5);
            RtlCopyMemory(g_SpoofConfig.FakeBiosDate, "08/06/2019", 11);
            break;
            
        case PRESET_RANDOM:
            return ConfigGenerateRandom();
            
        default:
            return STATUS_INVALID_PARAMETER;
    }
    
    // Common settings for all presets
    g_SpoofConfig.SpoofDisk = TRUE;
    g_SpoofConfig.SpoofMac = TRUE;
    g_SpoofConfig.SpoofWindows = TRUE;
    
    ConfigGenerateRandomSerial(g_SpoofConfig.FakeDiskSerial, 20);
    RtlCopyMemory(g_SpoofConfig.FakeDiskModel, "Samsung SSD 860 EVO 500GB", 26);
    RtlCopyMemory(g_SpoofConfig.FakeDiskFirmware, "RVT02B6Q", 9);
    
    ConfigGenerateRandomMac(g_SpoofConfig.FakeMacAddress);
    ConfigGenerateRandomUuid(g_SpoofConfig.FakeMachineGuid);
    
    HvLog(LOG_LEVEL_INFO, "Loaded preset: %d\n", Preset);
    
    return STATUS_SUCCESS;
}

NTSTATUS ConfigGenerateRandom(VOID) {
    UINT32 cpuChoice = Rand() % 6;
    
    // Generate random configuration based on random preset
    return ConfigLoadPreset((HWID_PRESET)(PRESET_INTEL_I5_9400F + cpuChoice));
}

VOID ConfigGenerateRandomSerial(CHAR* Buffer, UINT32 Length) {
    const CHAR charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    UINT32 i;
    
    if (!Buffer || Length == 0) {
        return;
    }
    
    for (i = 0; i < Length && i < (MAX_SERIAL_LENGTH - 1); i++) {
        Buffer[i] = charset[Rand() % (sizeof(charset) - 1)];
    }
    Buffer[i] = '\0';
}

VOID ConfigGenerateRandomMac(UINT8* MacAddress) {
    UINT32 i;
    
    if (!MacAddress) {
        return;
    }
    
    for (i = 0; i < 6; i++) {
        MacAddress[i] = (UINT8)(Rand() & 0xFF);
    }
    
    // Set locally administered bit, clear multicast bit
    MacAddress[0] = (MacAddress[0] & 0xFE) | 0x02;
}

VOID ConfigGenerateRandomUuid(UINT8* Uuid) {
    UINT32 i;
    
    if (!Uuid) {
        return;
    }
    
    for (i = 0; i < 16; i++) {
        Uuid[i] = (UINT8)(Rand() & 0xFF);
    }
    
    // Set version 4 (random UUID)
    Uuid[6] = (Uuid[6] & 0x0F) | 0x40;
    Uuid[8] = (Uuid[8] & 0x3F) | 0x80;
}

BOOLEAN ConfigValidate(VOID) {
    // Basic validation
    if (g_SpoofConfig.SpoofCpu) {
        if (g_SpoofConfig.FakeCpuVendor[0] == '\0' || 
            g_SpoofConfig.FakeCpuBrand[0] == '\0') {
            return FALSE;
        }
    }
    
    return TRUE;
}

VOID ConfigGet(PSPOOF_CONFIG Config) {
    if (Config) {
        RtlCopyMemory(Config, &g_SpoofConfig, sizeof(SPOOF_CONFIG));
    }
}

NTSTATUS ConfigSet(PSPOOF_CONFIG Config) {
    if (!Config) {
        return STATUS_INVALID_PARAMETER;
    }
    
    RtlCopyMemory(&g_SpoofConfig, Config, sizeof(SPOOF_CONFIG));
    
    if (!ConfigValidate()) {
        HvLog(LOG_LEVEL_ERROR, "Configuration validation failed\n");
        return STATUS_INVALID_PARAMETER;
    }
    
    return STATUS_SUCCESS;
}

VOID ConfigReset(VOID) {
    HvZeroMemory(&g_SpoofConfig, sizeof(g_SpoofConfig));
    ConfigInitialize();
}

VOID ConfigSetEnabled(BOOLEAN Enable) {
    g_SpoofConfig.Enabled = Enable;
    HvLog(LOG_LEVEL_INFO, "Spoofing %s\n", Enable ? "enabled" : "disabled");
}

BOOLEAN ConfigIsEnabled(VOID) {
    return g_SpoofConfig.Enabled;
}

