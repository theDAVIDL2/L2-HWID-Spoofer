using System.Windows;

namespace L2.HwidMaster.UI
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            
            // Load dashboard by default
            NavigateTo("Dashboard", "Overview of your system and spoofing status");
            ContentFrame.Navigate(new Pages.DashboardPage());
        }

        private void NavigateTo(string title, string subtitle)
        {
            PageTitle.Text = title;
            PageSubtitle.Text = subtitle;
        }

        private void NavDashboard_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Dashboard", "Overview of your system and spoofing status");
            ContentFrame.Navigate(new Pages.DashboardPage());
        }

        private void NavSpoof_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Quick Spoof", "Spoof all hardware identifiers at once");
        }

        private void NavGuides_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Guided Setup", "Step-by-step spoofing wizards");
        }

        private void NavMAC_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("MAC Address Spoofer", "Change your network adapter MAC addresses");
        }

        private void NavVolume_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Volume ID Spoofer", "Change your drive volume serial numbers");
        }

        private void NavGUID_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Machine GUID Spoofer", "Change Windows machine identifiers");
        }

        private void NavMonitor_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Monitor EDID Spoofer", "Change monitor serial and model information");
        }

        private void NavBios_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("BIOS Spoofer (AFUWIN)", "Permanent BIOS-level serial spoofing");
        }

        private void NavTools_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Manage Tools", "Download and manage spoofing tools");
        }

        private void NavBackup_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Backup and Restore", "Manage system backups and restore points");
        }

        private void NavSettings_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Settings", "Configure application preferences");
        }

        private void QuickSpoof_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Quick Spoof functionality coming soon!", "L2 HWID Master", 
                MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }
}