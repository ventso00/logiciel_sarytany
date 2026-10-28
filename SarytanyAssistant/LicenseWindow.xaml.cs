using System.Windows;
using System.Windows.Input;

namespace SarytanyAssistant;

/// <summary>
/// Ecran d'activation (port de src\55-License.ps1) : un seul code debloque
/// l'acces, saisie masquee, aucun code affiche. Fermer sans valider arrete
/// l'application (DialogResult != true).
/// </summary>
public partial class LicenseWindow : Window
{
    private const string LicenseEnvironmentVariable = "SARYTANY_APP_LICENSE_CODE";

    public string LicenseLabel { get; private set; } = "Licence : verrouillee";

    public LicenseWindow()
    {
        InitializeComponent();
        Loaded += (_, _) => TxtCode.Focus();
    }

    private bool TryValidate()
    {
        var trimmed = TxtCode.Password.Trim().ToUpperInvariant();
        var expectedCode = System.Environment.GetEnvironmentVariable(LicenseEnvironmentVariable);
        if (!string.IsNullOrWhiteSpace(expectedCode) &&
            string.Equals(trimmed, expectedCode.Trim(), System.StringComparison.OrdinalIgnoreCase))
        {
            LicenseLabel = "Licence : Bentley CONNECT";
            DialogResult = true;   // verrou leve
            return true;
        }
        LblError.Text = "Code invalide. Verifiez aupres de votre administrateur.";
        LblError.Visibility = Visibility.Visible;
        TxtCode.SelectAll();
        return false;
    }

    private void Activate_Click(object sender, RoutedEventArgs e) => TryValidate();

    private void TxtCode_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) TryValidate();
    }
}
