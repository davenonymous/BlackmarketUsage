class UIAddToBlackmarket extends UIScreenListener;

// performance optimization (lessen the amount of function calls)
`define coloredtext(text, color) "<font color='#"$`color$"'>"$`text$"</font>"

var X2ItemTemplateManager ItemTemplateManager;

var BlackmarketUsage_Settings Settings;

// iterate over everything buildable, and fill the list
// lookups using .Find happen in native code and are fast
struct UsedResource
{
	var name TemplateName;
	var string Uses;
	var bool bHasUnknownCost;
};

var array<UsedResource> GatheredCosts;

var array<name> ItemsToSell;

event OnInit(UIScreen Screen) {
	if (UIBlackMarket_Sell(Screen) != none) {
		Maketh(UIBlackMarket_Sell(Screen));
	}
}

Event OnReceiveFocus(UIScreen Screen) { 
	if (UIBlackMarket_Sell(Screen) != none) {
		Maketh(UIBlackMarket_Sell(Screen));
	}
} 

function Maketh(UIBlackMarket_Sell screen, optional bool refresh) {
	local int itemIndex;
	local UIBlackMarket_SellItem ListItem;	
	
	local UIImage UsableImage;

	local UsedResource Res;
	local int IndexInArray;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	Settings = new class'BlackmarketUsage_Settings';

	// initialize in case of multiple runs
	GatheredCosts.Length = 0;
	ItemsToSell.Length = 0;

	for(itemIndex = 0; itemIndex < screen.List.ItemCount; itemIndex++) {
		ListItem = UIBlackMarket_SellItem(screen.List.GetItem(itemIndex));		
		
		// build a cache list of items we can actually sell to not calculate unneccessary costs
		ItemsToSell.AddItem(ListItem.ItemTemplate.DataName);
	}
	
	// fill all known costs
	SearchAllBuildableItems();
	SearchAllFacilities();
	SearchAllTechs();

	// read the costs and apply them to the specific list item
	for(itemIndex = 0; itemIndex < screen.List.ItemCount; itemIndex++) {
		ListItem = UIBlackMarket_SellItem(screen.List.GetItem(itemIndex));		
		IndexInArray = GatheredCosts.Find('TemplateName', ListItem.ItemTemplate.DataName);

		if (IndexInArray == INDEX_NONE)
		{
			continue;
		}
		Res = GatheredCosts[IndexInArray];
		if (Res.Uses != "" || Res.bHasUnknownCost == true)
		{
			UsableImage = ListItem.Spawn(class'UIImage', ListItem).InitImage(, class'UIUtilities_Image'.static.GetToDoWidgetImagePath(eUIToDoCat_MAX));
			UsableImage.ProcessMouseEvents();
			UsableImage.SetScale(0.8);			
			UsableImage.SetPosition(318, 7);
			UsableImage.SetColor(class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR);
			UsableImage.SetAlpha(0.3);
			UsableImage.SetTooltipText("<font size=\"16\">"$Res.Uses $ ((Res.bHasUnknownCost) ? `coloredText("???", class'UIUtilities_Colors'.const.FADED_HTML_COLOR) : "") $"</font>", "Used for:");
		}

	}
}



// first normal items, then squad upgrades
function int SortBuildableItems(X2ItemTemplate A, X2ItemTemplate B) {
	if (A.bOneTimeBuild && !B.bOneTimeBuild)
	{
		return -1;
	}
	return 0;
}


function SearchAllBuildableItems()
{
	local X2ItemTemplate BuildableItem;

	local array<X2ItemTemplate> BuildableItems;
	local string itemName;
	local string itemColor;


	local bool bUnknown;

	BuildableItems = class'TechTreeHelpers'.static.GetFutureBuildableItems();
	BuildableItems.Sort(SortBuildableItems);
	
	foreach BuildableItems(BuildableItem) {	
		
		itemName = BuildableItem.GetItemFriendlyName();
		itemColor = class'UIUtilities_Colors'.const.CASH_HTML_COLOR;
		if(BuildableItem.ItemCat == 'weapon') {
			itemColor = class'UIUtilities_Colors'.const.BAD_HTML_COLOR;
		}
		bUnknown = false;
		if(!IsItemVisible(BuildableItem)) {
			if(Settings.ShowSpoilers == "Don't show") {
				continue;
			} else if(Settings.ShowSpoilers == "Obfuscate") {
				bUnknown = true;
			} else if(Settings.ShowSpoilers == "Show") {
				itemName = itemName$"*";
			}
		}

		FillInCostsForCost(BuildableItem.Cost, `coloredText(itemName, itemColor), bUnknown);
	}
}

function SearchAllFacilities() {
	local array<X2FacilityTemplate> BuildableFacilities;
	local X2FacilityTemplate BuildableFacility;

	local array<X2FacilityUpgradeTemplate> BuildableFacilityUpgrades;	
	local X2FacilityUpgradeTemplate BuildableFacilityUpgrade;

	local XComGameState_HeadquartersXCom XComHQ;
	local string facilityName;
	local string facilityColor;

	local bool bUnknown;

	XComHQ = `XCOMHQ;
	facilityColor = class'UIUtilities_Colors'.const.PERK_HTML_COLOR;
	

	BuildableFacilities = class'TechTreeHelpers'.static.GetFutureFacilities();
	foreach BuildableFacilities(BuildableFacility) {

		facilityName = BuildableFacility.DisplayName;
		bUnknown = false;
		if(!XComHQ.MeetsEnoughRequirementsToBeVisible(BuildableFacility.Requirements)) {
			if(Settings.ShowSpoilers == "Don't show") {
				continue;
			} else if(Settings.ShowSpoilers == "Obfuscate") {
				bUnknown = true;
				//continue;
			} else if(Settings.ShowSpoilers == "Show") {
				facilityName = facilityName$"*";
			}
		}
		FillInCostsForCost(BuildableFacility.Cost, `coloredText(facilityName, facilityColor), bUnknown);
	}

	BuildableFacilityUpgrades = class'TechTreeHelpers'.static.GetFutureFacilityUpgrades();
	foreach BuildableFacilityUpgrades(BuildableFacilityUpgrade) {

		facilityName = BuildableFacilityUpgrade.DisplayName;
		bUnknown = false;
		if(!XComHQ.MeetsEnoughRequirementsToBeVisible(BuildableFacilityUpgrade.Requirements) || !HasFacilityToBuildUpgrade(BuildableFacilityUpgrade)) {
			if(Settings.ShowSpoilers == "Don't show") {
				continue;
			} else if(Settings.ShowSpoilers == "Obfuscate") {
				bUnknown = true;
				//continue;
			} else if(Settings.ShowSpoilers == "Show") {
				facilityName = facilityName$"*";
			}
		}

		FillInCostsForCost(BuildableFacilityUpgrade.Cost, `coloredText(facilityName, facilityColor), bUnknown);
	}	
}


function bool HasFacilityToBuildUpgrade(X2FacilityUpgradeTemplate UpgradeTemplate) {
	local array<X2FacilityUpgradeTemplate> arrFacilityUpgrades;
	local X2FacilityUpgradeTemplate BuildableUpgradeTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local StateObjectReference FacilityState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;

	foreach XComHQ.Facilities(FacilityState) {
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityState.ObjectID));
		arrFacilityUpgrades = Facility.GetBuildableUpgrades();

		foreach arrFacilityUpgrades(BuildableUpgradeTemplate) {
			if(BuildableUpgradeTemplate == UpgradeTemplate) {
				return true;
			}
		}
	}

	return false;
}

function int GetTechType(XComGameState_Tech TechState) {
	if(TechState.GetMyTemplate().bProvingGround) {
		return 0;
	} else if(TechState.GetMyTemplate().bShadowProject) {
		return 2;
	} else {
		return 1;
	}
}

function int SortTechs(XComGameState_Tech A, XComGameState_Tech B) {
	local int typeA;
	local int typeB;

	typeA = GetTechType(A);
	typeB = GetTechType(B);

	if(typeA == typeB) {
		return A.GetDisplayName() < B.GetDisplayName() ? 0 : -1;
	}
	return typeB - typeA;
}

function SearchAllTechs() {
	local array<XComGameState_Tech> techs;
	local XComGameState_Tech TechState;
	local X2TechTemplate Template;
	local XComGameState_HeadquartersXCom XComHQ;
	local string techName;
	local string techColor;

	local bool bUnknown;

	XComHQ = `XCOMHQ;


	techs = class'TechTreeHelpers'.static.GetFutureTechs();
	techs.Sort(SortTechs);
	foreach techs(TechState) {
		Template = TechState.GetMyTemplate();

		techName = TechState.GetDisplayName();
		switch (GetTechType(TechState)) {
			case 0: // Proving Ground
				techColor = class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR;
				break;
			case 1: // Science Project
				techColor = class'UIUtilities_Colors'.const.SCIENCE_HTML_COLOR;
				break;
			case 2: // Shadow Project
				techColor = class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
				break;
			default:
				techColor = class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;
				break;
		}
		bUnknown = false;
		if(!XComHQ.MeetsEnoughRequirementsToBeVisible(Template.Requirements)) {
			if(Settings.ShowSpoilers == "Don't show") {
				continue;
			} else if(Settings.ShowSpoilers == "Obfuscate") {
				bUnknown = true;
				// continue;
			} else if(Settings.ShowSpoilers == "Show") {
				techName = techName$"*";
			}
		}

		FillInCostsForCost(Template.Cost, `coloredText(techName, techColor), bUnknown);
	}

}

function bool IsResearch(XComGameState_Tech TechState) {
	return (!TechState.GetMyTemplate().bProvingGround && !TechState.GetMyTemplate().bShadowProject);
}

function bool IsItemVisible(X2ItemTemplate ItemTemplate) {
	local XComGameState_HeadquartersXCom XComHQ;
	XComHQ = `XCOMHQ;

	// Item is blocked and not on the list of exceptions --> not visible
	if(ItemTemplate.bBlocked && XComHQ.UnlockedItems.Find(ItemTemplate.DataName) == INDEX_NONE) {
		return false;
	}

	if(!XComHQ.MeetsEnoughRequirementsToBeVisible(ItemTemplate.Requirements)) {
		return false;
	}

	return true;
}


function FillInCostsForCost(StrategyCost StrategyCost, string displayString, bool bUnknown)
{
	local ArtifactCost ArtifactCost;
	
	local UsedResource EmptyRes;

	local int FoundIdx;

	foreach StrategyCost.ResourceCosts(ArtifactCost) {
		// relevant?
		if (ItemsToSell.Find(ArtifactCost.ItemTemplateName) == INDEX_NONE)
		{
			continue;
		}
		// is it already in there?
		FoundIdx = GatheredCosts.Find('TemplateName', ArtifactCost.ItemTemplateName);
		// if not, do so
		if (FoundIdx == INDEX_NONE)
		{
			FoundIdx = GatheredCosts.Length;
			GatheredCosts[FoundIdx] = EmptyRes;
			GatheredCosts[FoundIdx].TemplateName = ArtifactCost.ItemTemplateName;
		}
		if (bUnknown)
		{
			GatheredCosts[FoundIdx].bHasUnknownCost = true;
		}
		else
		{
			GatheredCosts[FoundIdx].Uses =  GatheredCosts[FoundIdx].Uses $ displayString $ " (" $ ArtifactCost.Quantity $ ")<br/>";
		}
	}

	foreach StrategyCost.ArtifactCosts(ArtifactCost) {
		// relevant?
		if (ItemsToSell.Find(ArtifactCost.ItemTemplateName) == INDEX_NONE)
		{
			continue;
		}
		// is it already in there?
		FoundIdx = GatheredCosts.Find('TemplateName', ArtifactCost.ItemTemplateName);
		// if not, do so
		if (FoundIdx == INDEX_NONE)
		{
			FoundIdx = GatheredCosts.Length;
			GatheredCosts[FoundIdx] = EmptyRes;
			GatheredCosts[FoundIdx].TemplateName = ArtifactCost.ItemTemplateName;
		}
		if (bUnknown)
		{
			GatheredCosts[FoundIdx].bHasUnknownCost = true;
		}
		else
		{
			GatheredCosts[FoundIdx].Uses =  GatheredCosts[FoundIdx].Uses $ displayString $ " (" $ ArtifactCost.Quantity $ ")<br/>";
		}
	}
}

defaultproperties
{
	ScreenClass = none;
}