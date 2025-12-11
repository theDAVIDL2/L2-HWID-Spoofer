# 📁 File Index - Windows ISO Spoofer Project

## 🔥 Start Here

| File | Purpose | When to Read |
|------|---------|--------------|
| **[START-HERE.md](START-HERE.md)** | Quick orientation | **First time** |
| **[SIGNING-SUMMARY.md](SIGNING-SUMMARY.md)** | Certificate reality check | **If confused about certificates** |
| **[README.md](README.md)** | Project overview | For general understanding |

---

## 📚 Documentation (01-Documentation/)

### Essential Guides

| File | Purpose | Audience |
|------|---------|----------|
| **[00-MASTER-GUIDE.md](01-Documentation/00-MASTER-GUIDE.md)** | Complete step-by-step tutorial | Everyone |
| **[08-Certificate-Signing-Reality.md](01-Documentation/08-Certificate-Signing-Reality.md)** | Why you can't use Microsoft certificates | Everyone |
| **[09-Quick-Signing-Guide.md](01-Documentation/09-Quick-Signing-Guide.md)** | Quick reference commands | Experienced users |

### Additional Documentation

| File | Purpose | Audience |
|------|---------|----------|
| **[05-MOK-Enrollment-Guide.md](01-Documentation/05-MOK-Enrollment-Guide.md)** | MOK enrollment walkthrough | First-time users |
| **[06-Security-Testing-Framework.md](01-Documentation/06-Security-Testing-Framework.md)** | Security testing procedures | Security-conscious users |
| **[07-Competition-Winning-Features.md](01-Documentation/07-Competition-Winning-Features.md)** | Advanced features | Advanced users |

---

## 🔧 Build Scripts (03-Build-Scripts/)

| File | Purpose | When to Run |
|------|---------|-------------|
| **00-SETUP.ps1** | Initial environment setup | **Once (first time)** |
| **00-BUILD-ALL.ps1** | Complete build automation | **Every build** |
| **01-extract-iso.ps1** | Extract Windows ISO | Manual build only |
| **02-integrate-spoofer.ps1** | Integrate spoofer into ISO | Manual build only |
| **03-sign-bootloader.ps1** | **Sign YOUR spoofer with YOUR certificate** | **Every spoofer update** |
| **04-create-iso.ps1** | Create final bootable ISO | Manual build only |

### 🔑 Key Script: 03-sign-bootloader.ps1

**What it does:**
- ✅ Signs YOUR spoofer with YOUR certificate
- ✅ Uses sbsign (correct tool for EFI)
- ❌ NOT using Microsoft certificates (impossible)
- ❌ NOT using signtool (wrong tool)

**Usage:**
```powershell
cd 03-Build-Scripts
.\03-sign-bootloader.ps1
```

---

## 🔐 Keys and Certificates (07-Keys-And-Certs/)

| File | Purpose | Security Level |
|------|---------|----------------|
| **generate-keys.ps1** | Generate YOUR certificate | Run once |
| **my-signing-key.key** | YOUR private key | 🔴 **TOP SECRET** |
| **my-signing-cert.crt** | YOUR public certificate (PEM) | Public |
| **my-signing-cert.cer** | YOUR public certificate (DER) | Public (for MOK) |

### 🚨 Security Notice

**my-signing-key.key:**
- 🔴 **NEVER share this file**
- 🔴 **NEVER commit to git**
- 🔴 **NEVER email**
- ✅ Keep encrypted backup
- ✅ Anyone with this can sign trusted EFI files!

---

## 🎯 Your Spoofer (04-EFI-Spoofer/)

| File | Purpose | You Provide |
|------|---------|-------------|
| **spoofer.efi** | Your EFI spoofer executable | ✅ YES |
| **config.ini** | SMBIOS configuration | ✅ YES (edit) |
| **config-template.ini** | Configuration template | Reference |
| **README.md** | Spoofer integration guide | Read |

### Checklist Before Building:

- [ ] `spoofer.efi` present (your compiled spoofer)
- [ ] `config.ini` configured (SMBIOS values)
- [ ] Config values are realistic
- [ ] UUID and serials are customized

---

## 📦 Source Files (02-Source-Files/)

| Directory | Purpose | You Provide |
|-----------|---------|-------------|
| **Windows10.iso** | Windows 10 installation ISO | ✅ YES |
| **extracted/** | Extracted ISO contents | Auto-created |
| **modified/** | Modified ISO contents | Auto-created |

### Where to Get Windows 10 ISO:

- **Official:** https://www.microsoft.com/software-download/windows10
- **Size:** ~4-5 GB
- **Edition:** Any (Home, Pro, Enterprise)

---

## 📤 Output (05-Output/)

| File/Directory | Purpose | Generated |
|----------------|---------|-----------|
| **Windows10-Spoofed.iso** | Your final bootable ISO | ✅ Yes |
| **build-logs/** | Build logs for debugging | ✅ Yes |

### What's in the Final ISO:

```
Windows10-Spoofed.iso
├── Standard Windows 10 files
├── shimx64.efi (Microsoft-signed)
├── YOUR spoofer.efi (YOUR signature)
└── YOUR my-signing-cert.cer (for MOK)
```

---

## 🛠️ Tools (06-Tools/)

| Tool | Purpose | Auto-Downloaded |
|------|---------|-----------------|
| **7z.exe** | Archive extraction | ✅ Yes |
| **oscdimg.exe** | ISO creation | Manual (from ADK) |
| **sbsign.exe** | EFI signing | Manual (MSYS2/WSL) |

### Tool Installation Status:

```powershell
# Check which tools are installed
cd 06-Tools
dir

# Expected after setup:
# ✅ 7z.exe (auto-downloaded)
# ⚠️  oscdimg.exe (manual - from Windows ADK)
# ⚠️  sbsign.exe (manual - from MSYS2 or WSL)
```

### Installing Missing Tools:

**OSCDIMG:**
```powershell
# Install Windows ADK
# Copy oscdimg.exe to: 06-Tools\
```

**sbsign:**
```bash
# MSYS2 (Recommended)
pacman -S mingw-w64-x86_64-sbsigntools

# WSL
wsl sudo apt-get install sbsigntool
```

---

## 🧪 Testing (08-Testing/)

| File | Purpose | When to Use |
|------|---------|-------------|
| **test-vm.ps1** | Create and test VM | Before hardware deployment |
| **results/** | Test results | Auto-created |

### Testing Workflow:

```powershell
cd 08-Testing

# Create test VM
.\test-vm.ps1 -IsoPath "..\05-Output\Windows10-Spoofed.iso"

# Test checklist:
# [ ] VM boots successfully
# [ ] MOK enrollment works
# [ ] Secure Boot stays enabled
# [ ] SMBIOS values are spoofed
# [ ] Windows installs normally
```

---

## 📊 Project Files

| File | Purpose |
|------|---------|
| **PROJECT-STRUCTURE.txt** | Directory structure |
| **PROJECT-SUMMARY.md** | Project overview |
| **MERGE-NOTES.md** | Development notes |

---

## 🎯 Typical Workflow

### First Time Setup

1. Read **START-HERE.md**
2. Read **SIGNING-SUMMARY.md**
3. Run **03-Build-Scripts/00-SETUP.ps1**
4. Run **07-Keys-And-Certs/generate-keys.ps1**
5. Copy files to **02-Source-Files/** and **04-EFI-Spoofer/**
6. Run **03-Build-Scripts/00-BUILD-ALL.ps1**
7. Test with **08-Testing/test-vm.ps1**

### Updating Spoofer

1. Replace **04-EFI-Spoofer/spoofer.efi**
2. Run **03-Build-Scripts/03-sign-bootloader.ps1**
3. Run **03-Build-Scripts/04-create-iso.ps1**
4. Test again

### Updating Configuration

1. Edit **04-EFI-Spoofer/config.ini**
2. Run **03-Build-Scripts/00-BUILD-ALL.ps1**
3. Test again

---

## 🔍 File Dependencies

### Signing Process Flow

```
07-Keys-And-Certs/
├── my-signing-key.key ────┐
└── my-signing-cert.crt ───┤
                           │
                           ├──> 03-Build-Scripts/
04-EFI-Spoofer/            │     03-sign-bootloader.ps1
├── spoofer.efi ───────────┘             │
                                         ▼
                                   Signed spoofer.efi
                                         │
                                         ▼
                                   Integrated into ISO
                                         │
                                         ▼
                                   05-Output/
                                   Windows10-Spoofed.iso
```

### Build Process Flow

```
02-Source-Files/
├── Windows10.iso
│       │
│       ├──> 01-extract-iso.ps1
│       │         │
│       │         ▼
│       │    extracted/
│       │         │
│       ├─────────┘
│       │
04-EFI-Spoofer/    │
├── spoofer.efi ───┤
└── config.ini ────┤
                   │
07-Keys-And-Certs/ │
├── *.key ─────────┤
└── *.crt ─────────┤
                   │
                   ├──> 02-integrate-spoofer.ps1
                   │         │
                   │         ▼
                   │    modified/
                   │         │
                   ├─────────┘
                   │
                   ├──> 03-sign-bootloader.ps1
                   │         │
                   │         ▼
                   │    Signed EFI files
                   │         │
                   ├─────────┘
                   │
                   ├──> 04-create-iso.ps1
                   │         │
                   │         ▼
                   └────> 05-Output/
                         Windows10-Spoofed.iso
```

---

## 📋 File Checklist

### Before Building

- [ ] **START-HERE.md** - Read (orientation)
- [ ] **SIGNING-SUMMARY.md** - Read (understand certificates)
- [ ] **00-MASTER-GUIDE.md** - Read (full instructions)
- [ ] **07-Keys-And-Certs/my-signing-key.key** - Generated
- [ ] **02-Source-Files/Windows10.iso** - Present
- [ ] **04-EFI-Spoofer/spoofer.efi** - Present
- [ ] **04-EFI-Spoofer/config.ini** - Configured
- [ ] **06-Tools/oscdimg.exe** - Installed
- [ ] **06-Tools/sbsign** - Installed (MSYS2/WSL)

### After Building

- [ ] **05-Output/Windows10-Spoofed.iso** - Created
- [ ] **05-Output/build-logs/** - No errors
- [ ] **08-Testing/test-vm.ps1** - Ran successfully
- [ ] MOK enrollment tested in VM
- [ ] Spoofing verified in VM
- [ ] Secure Boot verified enabled

---

## 🚀 Quick Reference

### Most Important Files

1. **START-HERE.md** ← Begin here
2. **SIGNING-SUMMARY.md** ← Understand certificates
3. **03-Build-Scripts/00-BUILD-ALL.ps1** ← Build ISO
4. **07-Keys-And-Certs/generate-keys.ps1** ← Create certificate

### Most Important Concept

```
YOU create YOUR certificate.
NOT Microsoft's certificate (impossible).
Sign with sbsign (NOT signtool).
Enroll in MOK (one-time per machine).
Secure Boot stays ENABLED.
```

---

## 📞 Getting Help

### If You're Stuck:

1. **Check:** Build logs in `05-Output/build-logs/`
2. **Read:** `SIGNING-SUMMARY.md` (most common confusion)
3. **Read:** `00-MASTER-GUIDE.md` (complete tutorial)
4. **Verify:** Files present in checklist above

### Common Confusions:

| Confusion | Reality | Read This |
|-----------|---------|-----------|
| "Need Microsoft cert" | Use YOUR cert | SIGNING-SUMMARY.md |
| "Use signtool" | Use sbsign | 09-Quick-Signing-Guide.md |
| "How to get MS cert" | You don't | 08-Certificate-Signing-Reality.md |

---

## ✅ Success Indicators

You've succeeded when:

- ✅ All files in "Before Building" checklist present
- ✅ `00-BUILD-ALL.ps1` completes without errors
- ✅ `Windows10-Spoofed.iso` created
- ✅ VM boots with Secure Boot enabled
- ✅ MOK enrollment succeeds
- ✅ SMBIOS values are spoofed
- ✅ `Confirm-SecureBootUEFI` returns True in Windows

---

**NOW YOU KNOW WHAT EVERY FILE DOES! 🎯**

**Ready to build?** → Read [START-HERE.md](START-HERE.md)

**Need commands?** → Read [09-Quick-Signing-Guide.md](01-Documentation/09-Quick-Signing-Guide.md)

**Want tutorial?** → Read [00-MASTER-GUIDE.md](01-Documentation/00-MASTER-GUIDE.md)
