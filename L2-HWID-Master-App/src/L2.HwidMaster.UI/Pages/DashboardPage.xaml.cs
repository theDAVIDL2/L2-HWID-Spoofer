using System;
using System.Linq;
using System.Net.NetworkInformation;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;

namespace L2.HwidMaster.UI.Pages
{
    public partial class DashboardPage : Page
    {
        public DashboardPage()
        {
            InitializeComponent();
            Loaded += (s, e) => LoadSystemInfo();
        }

        private void LoadSystemInfo()
        {
            LoadNetworkInfo();
            LoadStorageInfo();
            LoadWindowsInfo();
            LoadDisplayInfo();
        }

        private void LoadNetworkInfo()
        {
            try
            {
                NetworkInfo.Children.Clear();
                
                var adapters = NetworkInterface.GetAllNetworkInterfaces()
                    .Where(n => n.OperationalStatus == OperationalStatus.Up 
                             && n.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                    .Take(4);

                foreach (var adapter in adapters)
                {
                    var mac = adapter.GetPhysicalAddress().ToString();
                    string formattedMac = "N/A";
                    
                    if (!string.IsNullOrEmpty(mac) && mac.Length >= 12)
                    {
                        formattedMac = string.Join(":", Enumerable.Range(0, 6)
                            .Select(i => mac.Substring(i * 2, 2)));
                    }
                    else if (!string.IsNullOrEmpty(mac))
                    {
                        formattedMac = mac;
                    }
                    
                    AddInfoItem(NetworkInfo, adapter.Name, formattedMac);
                    
                    if (MacValue.Text == "AA:BB:CC:DD:EE:FF" && formattedMac != "N/A")
                    {
                        MacValue.Text = formattedMac;
                    }
                }

                if (!adapters.Any())
                {
                    AddInfoItem(NetworkInfo, "No adapters", "None found");
                }
            }
            catch (Exception ex)
            {
                AddInfoItem(NetworkInfo, "Error", ex.Message);
            }
        }

        private void LoadStorageInfo()
        {
            try
            {
                StorageInfo.Children.Clear();
                
                var drives = System.IO.DriveInfo.GetDrives()
                    .Where(d => d.IsReady && d.DriveType == System.IO.DriveType.Fixed);

                foreach (var drive in drives)
                {
                    string volumeSerial = "Unknown";
                    try
                    {
                        using var searcher = new System.Management.ManagementObjectSearcher(
                            $"SELECT VolumeSerialNumber FROM Win32_LogicalDisk WHERE DeviceID = '{drive.Name.TrimEnd('\\')}'" );
                        foreach (var obj in searcher.Get())
                        {
                            var serial = obj["VolumeSerialNumber"]?.ToString();
                            if (!string.IsNullOrEmpty(serial) && serial.Length >= 8)
                            {
                                volumeSerial = $"{serial.Substring(0, 4)}-{serial.Substring(4, 4)}";
                            }
                            else if (!string.IsNullOrEmpty(serial))
                            {
                                volumeSerial = serial;
                            }
                        }
                    }
                    catch { }
                    
                    var label = string.IsNullOrEmpty(drive.VolumeLabel) ? "Local Disk" : drive.VolumeLabel;
                    AddInfoItem(StorageInfo, $"{drive.Name} ({label})", volumeSerial);
                    
                    if (VolumeValue.Text == "XXXX-XXXX")
                    {
                        VolumeValue.Text = volumeSerial;
                    }
                }
            }
            catch (Exception ex)
            {
                AddInfoItem(StorageInfo, "Error", ex.Message);
            }
        }

        private void LoadWindowsInfo()
        {
            try
            {
                WindowsInfo.Children.Clear();
                
                // Machine GUID
                try
                {
                    using var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Cryptography");
                    var machineGuid = key?.GetValue("MachineGuid")?.ToString() ?? "Unknown";
                    AddInfoItem(WindowsInfo, "MachineGuid", SafeTruncate(machineGuid, 18));
                    GuidValue.Text = SafeTruncate(machineGuid, 18);
                }
                catch
                {
                    AddInfoItem(WindowsInfo, "MachineGuid", "Access denied");
                }

                // Machine ID
                try
                {
                    using var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\SQMClient");
                    var machineId = key?.GetValue("MachineId")?.ToString() ?? "Not found";
                    AddInfoItem(WindowsInfo, "MachineId", SafeTruncate(machineId, 18));
                }
                catch
                {
                    AddInfoItem(WindowsInfo, "MachineId", "Not found");
                }

                AddInfoItem(WindowsInfo, "Computer Name", Environment.MachineName);
            }
            catch (Exception ex)
            {
                AddInfoItem(WindowsInfo, "Error", ex.Message);
            }
        }

        private void LoadDisplayInfo()
        {
            try
            {
                DisplayInfo.Children.Clear();
                
                using var searcher = new System.Management.ManagementObjectSearcher(
                    "SELECT * FROM Win32_DesktopMonitor");
                var monitors = searcher.Get().Cast<System.Management.ManagementObject>().ToList();
                
                if (monitors.Any())
                {
                    foreach (var monitor in monitors)
                    {
                        var name = monitor["Name"]?.ToString() ?? "Unknown Monitor";
                        var pnpId = monitor["PNPDeviceID"]?.ToString() ?? "";
                        AddInfoItem(DisplayInfo, name, SafeTruncate(pnpId, 30));
                        
                        if (MonitorValue.Text == "Generic Monitor")
                        {
                            MonitorValue.Text = name;
                        }
                    }
                }
                else
                {
                    AddInfoItem(DisplayInfo, "Monitor", "No info available");
                }
            }
            catch
            {
                AddInfoItem(DisplayInfo, "Error", "Could not query monitors");
            }
        }

        private void AddInfoItem(StackPanel parent, string label, string value)
        {
            var sp = new StackPanel { Margin = new Thickness(0, 0, 0, 8) };
            sp.Children.Add(new TextBlock 
            { 
                Text = label, 
                FontSize = 12,
                Foreground = (System.Windows.Media.Brush)Application.Current.Resources["TextMutedBrush"]
            });
            sp.Children.Add(new TextBlock 
            { 
                Text = value ?? "N/A", 
                FontSize = 14,
                Foreground = (System.Windows.Media.Brush)Application.Current.Resources["TextPrimaryBrush"]
            });
            parent.Children.Add(sp);
        }

        private string SafeTruncate(string text, int maxLength)
        {
            if (string.IsNullOrEmpty(text)) return "N/A";
            if (text.Length <= maxLength) return text;
            return text.Substring(0, maxLength) + "...";
        }

        private void CopyFingerprint_Click(object sender, RoutedEventArgs e)
        {
            var sb = new StringBuilder();
            sb.AppendLine("=== L2 HWID Master - Hardware Fingerprint ===");
            sb.AppendLine($"Computer: {Environment.MachineName}");
            sb.AppendLine($"MAC: {MacValue.Text}");
            sb.AppendLine($"Volume: {VolumeValue.Text}");
            sb.AppendLine($"GUID: {GuidValue.Text}");
            sb.AppendLine($"Monitor: {MonitorValue.Text}");
            
            Clipboard.SetText(sb.ToString());
            MessageBox.Show("Fingerprint copied to clipboard!", "L2 HWID Master", 
                MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void SpoofAll_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Quick Spoof All - Coming soon!", "L2 HWID Master");
        }

        private void CreateBackup_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Creating backup... Coming soon!", "L2 HWID Master");
        }

        private void RestoreOriginal_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Restore Original - Coming soon!", "L2 HWID Master");
        }

        private void RefreshInfo_Click(object sender, RoutedEventArgs e)
        {
            LoadSystemInfo();
        }
    }
}
