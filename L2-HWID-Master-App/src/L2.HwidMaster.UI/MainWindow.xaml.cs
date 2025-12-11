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
            ContentFrame.Navigate(new Pages.PlaceholderPage("Quick Spoof", "One-click spoofing for all hardware identifiers."));
        }

        private void NavGuides_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Guided Setup", "Step-by-step spoofing wizards");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Guided Setup", "Interactive step-by-step guides for each spoofing method."));
        }

        private void NavMAC_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("MAC Address Spoofer", "Change your network adapter MAC addresses");
            ContentFrame.Navigate(new Pages.PlaceholderPage("MAC Address Spoofer", "Change network adapter MAC addresses to bypass hardware bans."));
        }

        private void NavVolume_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Volume ID Spoofer", "Change your drive volume serial numbers");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Volume ID Spoofer", "Change drive volume serial numbers using VolumeID tool."));
        }

        private void NavGUID_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Machine GUID Spoofer", "Change Windows machine identifiers");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Machine GUID Spoofer", "Change Windows MachineGuid and HwProfile GUIDs."));
        }

        private void NavMonitor_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Monitor EDID Spoofer", "Change monitor serial and model information");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Monitor EDID Spoofer", "Modify monitor EDID data including serial numbers."));
        }

        private void NavBios_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("BIOS Spoofer (AFUWIN)", "Permanent BIOS-level serial spoofing");
            ContentFrame.Navigate(new Pages.PlaceholderPage("BIOS Spoofer (AFUWIN)", 
                "Permanently change BIOS serials using AFUWIN, DMIEdit, and HxD.\n\nSteps: Dump BIOS > Edit serials > Flash with /GAN"));
        }

        private void NavTools_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Manage Tools", "Download and manage spoofing tools");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Manage Tools", "Download VolumeID, MonitorSpoofer, AFUWIN, DMIEdit, HxD, and more."));
        }

        private void NavBackup_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Backup and Restore", "Manage system backups and restore points");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Backup and Restore", "Create backups before spoofing and restore original values."));
        }

        private void NavSettings_Click(object sender, RoutedEventArgs e)
        {
            NavigateTo("Settings", "Configure application preferences");
            ContentFrame.Navigate(new Pages.PlaceholderPage("Settings", "Application preferences and configuration options."));
        }

        private void QuickSpoof_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Quick Spoof functionality coming soon!", "L2 HWID Master", 
                MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }
}