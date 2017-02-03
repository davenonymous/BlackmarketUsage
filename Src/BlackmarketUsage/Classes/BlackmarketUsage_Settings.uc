class BlackmarketUsage_Settings extends UIScreenListener config(BlackmarketUsage_Settings);

var config string ShowSpoilers;
var config int ConfigVersion;

`include(BlackmarketUsage/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(BlackmarketUsage/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)
`MCM_CH_VersionChecker(class'BlackmarketUsage_Settings_Defaults'.default.ConfigVersion, ConfigVersion)

event OnInit(UIScreen Screen)
{
    if (MCM_API(Screen) != none)
    {
        `MCM_API_Register(Screen, ClientModCallback);
    }

    if(UIShell(Screen) != none)
    {
        EnsureConfigExists();
    }
}

function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    // Build the settings UI
    local MCM_API_SettingsPage page;
    local MCM_API_SettingsGroup group;
    local array<string> options;

    LoadSavedSettings();

    page = ConfigAPI.NewSettingsPage("Blackmarket Usage");
    page.SetPageTitle("Blackmarket Usage");
    page.SetSaveHandler(SaveButtonClicked);

    options.AddItem("Don't show");
    options.AddItem("Show");
    options.AddItem("Obfuscate");

    group = Page.AddGroup('Group1', "");
    group.AddDropdown('ShowSpoilers', // Name
      "Show unresearched items?", // Text
      "Whether you see techs/gear you have not researched yet. If set to 'Obfuscate', non-researched items are shown as '???'", // Tooltip
      options, // Dropdown choices
      ShowSpoilers, // Initial value
      SaveShowSpoilers // Save handler
    );

    page.ShowSettings();
}

`MCM_API_BasicDropdownSaveHandler(SaveShowSpoilers, ShowSpoilers)

function LoadSavedSettings()
{
    ShowSpoilers = `MCM_CH_GetValue(class'BlackmarketUsage_Settings_Defaults'.default.ShowSpoilers, ShowSpoilers);
}

function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    self.ConfigVersion = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}

function EnsureConfigExists()
{
    if(ConfigVersion == 0)
    {
        LoadSavedSettings();
        SaveButtonClicked(none);
    }
}

defaultproperties
{
    ScreenClass = none;
}