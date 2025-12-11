using System;
using System.Linq;
using System.Net.NetworkInformation;
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
            LoadSystemInfo();
        }

        private void LoadSystemInfo()
        {
            try
            {
                LoadNetworkInfo();
                LoadStorageInfo();
                LoadWindowsInfo();
                LoadDisplayInfo();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading system info: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void LoadNetworkInfo()
        {
            NetworkInfo.Children.Clear();
            
            var adapters = NetworkInterface.GetAllNetworkInterfaces()
                .Where(n => n.OperationalStatus == OperationalStatus.Up 
                         && n.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                .Take(4);

            foreach (var adapter in adapters)
            {
                var mac = adapter.GetPhysicalAddress().ToString();
                var formattedMac = string.Join(":", Enumerable.Range(0, 6)
                    .Select(i => mac.Substring(i * 2, 2)));
                
                AddInfoItem(NetworkInfo, adapter.Name, formattedMac);
                
                // Update status card with first adapter
                if (MacValue.Text == "AA:BB:CC:DD:EE:FF")
                {
                    MacValue.Text = formattedMac;
                }
            }

            if (!adapters.Any())
            {
                AddInfoItem(NetworkInfo, "No adapters", "None found");
            }
        }

        private void LoadStorageInfo()
        {
            StorageInfo.Children.Clear();
            
            var drives = System.IO.DriveInfo.GetDrives()
                .Where(d => d.IsReady && d.DriveType == System.IO.DriveType.Fixed);

            foreach (var drive in drives)
            {
                string volumeSerial = "Unknown";
                try
                {
                    // Get volume serial from WMI
                    using var searcher = new System.Management.ManagementObjectSearcher(
                        $"SELECT VolumeSerialNumber FROM Win32_LogicalDisk WHERE DeviceID = '{drive.Name.TrimEnd('\\')}'" );
                    foreach (var obj in searcher.Get())
                    {
                        var serial = obj["VolumeSerialNumber"]?.ToString();
                        if (!string.IsNullOrEmpty(serial) && serial.Length == 8)
                        {
                            volumeSerial = $"{serial.Substring(0, 4)}-{serial.Substring(4, 4)}";
                        }
                    }
                }
                catch { }
                
                AddInfoItem(StorageInfo, $"{drive.Name} ({drive.VolumeLabel})", volumeSerial);
                
                // Update status card
                if (VolumeValue.Text == "XXXX-XXXX")
                {
                    VolumeValue.Text = volumeSerial;
                }
            }
        }

        private void LoadWindowsInfo()
        {
            WindowsInfo.Children.Clear();
            
            // Machine GUID
            try
            {
                using var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Cryptography");
                var machineGuid = key?.GetValue("MachineGuid")?.ToString() ?? "Unknown";
                AddInfoItem(WindowsInfo, "MachineGuid", TruncateGuid(machineGuid));
                GuidValue.Text = TruncateGuid(machineGuid);
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
                AddInfoItem(WindowsInfo, "MachineId", TruncateGuid(machineId));
            }
            catch
            {
                AddInfoItem(WindowsInfo, "MachineId", "Not found");
            }

            // Computer Name
            AddInfoItem(WindowsInfo, "Computer Name", Environment.MachineName);
        }

        private void LoadDisplayInfo()
        {
            DisplayInfo.Children.Clear();
            
            try
            {
                using var searcher = new System.Management.ManagementObjectSearcher(
                    "SELECT * FROM Win32_DesktopMonitor");
                var monitors = searcher.Get().Cast<System.Management.ManagementObject>().ToList();
                
                if (monitors.Any())
                {
                    foreach (var monitor in monitors)
                    {
                        var name = monitor["Name"]?.ToString() ?? "Unknown Monitor";
                        var pnpId = monitor["PNPDeviceID"]?.ToString() ?? "";
                        AddInfoItem(DisplayInfo, name, pnpId.Length > 30 ? pnpId.Substring(0, 30) + "..." : pnpId);
                        
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
                Text = value, 
                FontSize = 14,
                Foreground = (System.Windows.Media.Brush)Application.Current.Resources["TextPrimaryBrush"]
            });
            parent.Children.Add(sp);
        }

        private string TruncateGuid(string guid)
        {
            if (guid.Length > 20)
                return guid.Substring(0, 18) + "...";
            return guid;
        }

        private void CopyFingerprint_Click(object sender, RoutedEventArgs e)
        {
            // TODO: Copy all fingerprint info to clipboard
            MessageBox.Show("Fingerprint copied to clipboard!", "L2 HWID Master");
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
