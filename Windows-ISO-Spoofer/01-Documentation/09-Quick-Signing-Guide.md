# ⚡ Quick Signing Guide - TL;DR

## 🚀 If You Just Want to Sign Your Spoofer NOW

**30-Second Version:**

```powershell
# 1. Generate your certificate (one-time)
cd Windows-ISO-Spoofer\07-Keys-And-Certs
.\generate-keys.ps1

# 2. Sign your spoofer
cd ..\03-Build-Scripts
.\03-sign-bootloader.ps1

# 3. Done!
```

---

## ❌ Stop Reading Guides That Say:

- ❌ "Use Microsoft certificates"
- ❌ "Obtain 2023 Microsoft UEFI certificate"  
- ❌ "Sign with Microsoft CA"
- ❌ "Use signtool.exe"

**These are WRONG. You cannot use Microsoft certificates.**

---

## ✅ What You Actually Do:

### 1️⃣ Create Your Own Certificate

```powershell
cd Windows-ISO-Spoofer\07-Keys-And-Certs
.\generate-keys.ps1
```

**What this does:**
- Creates YOUR private key (RSA 2048-bit)
- Creates YOUR public certificate
- Valid for 10 years

**Output files:**
- `my-signing-key.key` ← Keep this SECRET!
- `my-signing-cert.crt` ← Public certificate
- `my-signing-cert.cer` ← For MOK enrollment

---

### 2️⃣ Sign Your Spoofer

```powershell
cd ..\03-Build-Scripts
.\03-sign-bootloader.ps1
```

**What this does:**
- Finds your spoofer.efi
- Signs it with YOUR certificate
- Uses sbsign (correct tool for EFI)
- Creates backup of unsigned version

**NOT signtool!** (That's for Windows .exe files, not EFI)

---

### 3️⃣ Build Your ISO

```powershell
.\00-BUILD-ALL.ps1
```

**What this includes:**
- Microsoft-signed shim bootloader
- YOUR signed spoofer
- YOUR certificate for MOK enrollment

---

### 4️⃣ Enroll MOK (First Boot Only)

**On first boot from USB:**

```
1. You see "MOK Management" screen
2. Select "Enroll MOK"
3. Navigate to \EFI\Keys\my-signing-cert.cer
4. Select it
5. Confirm "Yes"
6. Reboot
7. Done forever!
```

**After this:** Your spoofer is trusted, Secure Boot stays ON.

---

## 📊 Tool Comparison

| Tool | Purpose | Use For | Don't Use For |
|------|---------|---------|---------------|
| **sbsign** | ✅ Sign EFI files | **Your spoofer.efi** | Windows .exe |
| **signtool** | Sign Windows PE | Windows .exe/.dll | **EFI files** ❌ |
| **OpenSSL** | Generate certs | Key/cert generation | Signing EFI |

---

## 🔑 Certificate Types

### What You HAVE:
```
Self-Signed Certificate
├─ Private Key (my-signing-key.key)
│  └─ You own this
│  └─ Only YOU can sign with this
│  └─ Keep SECRET!
└─ Public Certificate (my-signing-cert.crt)
   └─ Anyone can have this
   └─ Used to verify signatures
   └─ Enrolled in MOK
```

### What You DON'T HAVE (and can't get):
```
Microsoft Certificate
├─ Private Key
│  └─ Owned by Microsoft
│  └─ In hardware security modules
│  └─ NOT AVAILABLE to public
│  └─ Never will be
└─ Public Certificate
   └─ Already in your UEFI firmware
   └─ Used to verify Microsoft-signed shim
```

---

## 🎯 The Boot Chain

```
UEFI Firmware (Secure Boot ON)
    ↓
    ├─ Checks: Microsoft's certificate (built-in)
    ↓
shimx64.efi (Microsoft signed) ✅
    ↓
    ├─ Checks: MOK database
    ↓
YOUR spoofer.efi (YOUR certificate) ✅
    ↓
    ├─ Spoofs SMBIOS
    ↓
Windows bootmgfw.efi
    ↓
Windows (sees spoofed values!)
```

**Key point:** Shim is signed by Microsoft. Your spoofer is signed by YOU. Shim checks YOUR signature against MOK.

---

## 💡 Common Questions

### Q: Can I get a Microsoft certificate?
**A:** No. Impossible. They're not available. Period.

### Q: What about the "2023 Microsoft UEFI certificate" guides online?
**A:** Misleading. Those refer to Microsoft's internal certs. You can't use them.

### Q: Is self-signed secure enough?
**A:** Yes! It's what Ubuntu, Fedora, and all Linux distros use.

### Q: Will this work with Secure Boot ON?
**A:** Yes! That's the entire point. Secure Boot stays enabled.

### Q: Do I need to re-sign after updating my spoofer?
**A:** Yes. Every time you modify spoofer.efi, re-sign it.

### Q: Can I use the same certificate on multiple machines?
**A:** Yes! But you'll need to enroll MOK on each machine once.

---

## 🚨 Troubleshooting

### "sbsign not found"

**Option 1 - MSYS2 (Recommended):**
```bash
# Install MSYS2 from https://www.msys2.org/
# Then in MSYS2 terminal:
pacman -S mingw-w64-x86_64-sbsigntools
```

**Option 2 - WSL:**
```bash
wsl sudo apt-get install sbsigntool
# Then run signing script - it will detect WSL
```

---

### "Signature verification failed at boot"

**Solution:**
- Boot from USB again
- MOK Management screen should appear
- Enroll your certificate: `\EFI\Keys\my-signing-cert.cer`
- Reboot

---

### "Certificate not found"

**Make sure you ran:**
```powershell
cd Windows-ISO-Spoofer\07-Keys-And-Certs
.\generate-keys.ps1
```

**Check files exist:**
```powershell
dir my-signing-*
```

You should see:
- `my-signing-key.key`
- `my-signing-cert.crt`
- `my-signing-cert.cer`

---

## 📝 Complete Workflow

### First Time Setup (15 minutes)

```powershell
# 1. Setup environment
cd Windows-ISO-Spoofer\03-Build-Scripts
.\00-SETUP.ps1

# 2. Generate certificate
cd ..\07-Keys-And-Certs
.\generate-keys.ps1

# 3. Place your files
cd ..
# Copy your Windows 10 ISO to: 02-Source-Files\Windows10.iso
# Copy your spoofer to: 04-EFI-Spoofer\spoofer.efi

# 4. Build ISO
cd 03-Build-Scripts
.\00-BUILD-ALL.ps1

# This will automatically:
# - Extract ISO
# - Sign your spoofer
# - Integrate everything
# - Create final ISO
```

---

## 🎓 For the Technical Explanation

Read the full documentation:
- **Certificate reality:** `08-Certificate-Signing-Reality.md`
- **Master guide:** `00-MASTER-GUIDE.md`
- **MOK enrollment:** `05-MOK-Enrollment-Guide.md`

---

## 💻 Command Reference

### Generate Certificate
```powershell
.\generate-keys.ps1
.\generate-keys.ps1 -CommonName "My Custom Key"
.\generate-keys.ps1 -ValidDays 7300  # 20 years
```

### Sign Spoofer
```powershell
.\03-sign-bootloader.ps1
.\03-sign-bootloader.ps1 -SpooferPath "custom\path\spoofer.efi"
.\03-sign-bootloader.ps1 -SkipValidation
```

### Verify Signature (if sbverify available)
```bash
sbverify --cert my-signing-cert.crt spoofer.efi
```

### Manual Signing (advanced)
```bash
sbsign --key my-signing-key.key \
       --cert my-signing-cert.crt \
       --output signed.efi \
       unsigned.efi
```

---

## ✅ Checklist

Before building ISO:
- [ ] Certificate generated (`.\generate-keys.ps1`)
- [ ] Spoofer present (`04-EFI-Spoofer\spoofer.efi`)
- [ ] Spoofer signed (`.\03-sign-bootloader.ps1`)
- [ ] Windows ISO present (`02-Source-Files\Windows10.iso`)

After building ISO:
- [ ] ISO created successfully
- [ ] Tested in VM first
- [ ] MOK enrollment tested
- [ ] Spoofing verified

Before hardware deployment:
- [ ] VM testing completed successfully
- [ ] Secure Boot verified working
- [ ] Backup USB created
- [ ] Recovery plan ready

---

## 🎯 Key Takeaways

1. **You use YOUR certificate, not Microsoft's**
2. **Use sbsign, not signtool**
3. **MOK enrollment is one-time per machine**
4. **Secure Boot stays enabled**
5. **This is the professional standard**

---

## 🚀 Quick Start (Copy-Paste)

```powershell
# Navigate to project
cd "C:\Users\davie\OneDrive\Área de Trabalho\L2 ISO project\Windows-ISO-Spoofer"

# Generate certificate (one-time)
cd 07-Keys-And-Certs
.\generate-keys.ps1
cd ..

# Place your spoofer
# Copy your spoofer.efi to: 04-EFI-Spoofer\spoofer.efi

# Build (includes signing)
cd 03-Build-Scripts
.\00-BUILD-ALL.ps1

# Done! ISO is in: 05-Output\Windows10-Spoofed.iso
```

---

## 📱 Need Help?

1. **Read:** `08-Certificate-Signing-Reality.md` - Full explanation
2. **Read:** `00-MASTER-GUIDE.md` - Complete guide
3. **Check:** Build logs in `05-Output\build-logs\`

---

**Remember:** Any guide telling you to "use Microsoft certificates" is **wrong**. You create and use **your own certificate** with **MOK enrollment**. This is the **correct professional approach**.

**Now go build your ISO! 🚀**

