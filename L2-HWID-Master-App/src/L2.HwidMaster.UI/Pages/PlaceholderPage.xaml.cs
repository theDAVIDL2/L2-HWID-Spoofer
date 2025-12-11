using System.Windows.Controls;

namespace L2.HwidMaster.UI.Pages
{
    public partial class PlaceholderPage : Page
    {
        public PlaceholderPage(string title = "Coming Soon", string description = "This feature is under development.")
        {
            InitializeComponent();
            TitleText.Text = title;
            DescriptionText.Text = description;
        }
    }
}
