class UIAddToBlackmarket extends UIScreenListener;

var UIBlackMarket_Sell SellScreen;
var UIText DisplayText;
var X2ItemTemplateManager ItemTemplateManager;

event OnInit(UIScreen Screen) {
	Maketh(UIBlackMarket_Sell(Screen));
}

Event OnReceiveFocus(UIScreen Screen) { 
	Maketh(UIBlackMarket_Sell(Screen));
} 

function Maketh(UIBlackMarket_Sell screen, optional bool refresh) {
	local int itemIndex;
	local UIBlackMarket_SellItem ListItem;	
	local string newText;
	local UIImage UsableImage;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for(itemIndex = 0; itemIndex < screen.List.ItemCount; itemIndex++) {
		ListItem = UIBlackMarket_SellItem(screen.List.GetItem(itemIndex));		

		newText = GetTooltipText(ListItem);
		if(newText != "") {			
			UsableImage = ListItem.Spawn(class'UIImage', ListItem).InitImage(, class'UIUtilities_Image'.static.GetToDoWidgetImagePath(eUIToDoCat_ProvingGround));		
			UsableImage.ProcessMouseEvents();
			UsableImage.SetScale(0.8);			
			UsableImage.SetPosition(318, 7); 
			UsableImage.SetAlpha(0.5);
			UsableImage.SetTooltipText(newText, "Used for:");
		}
	}
}

function string GetTooltipText(UIBlackMarket_SellItem ItemPanel) {
	local string newText;
	newText  = getBuildableItemsText(ItemPanel.ItemTemplate);
	newText $= getProvingGroundText(ItemPanel.ItemTemplate);
	newText $= getFacilitiesText(ItemPanel.ItemTemplate);
	newText $= getResearchText(ItemPanel.ItemTemplate);	
	return newText;
}




// ***********************************************
// * Data Retrieval Functions
// ***********************************************
function string getBuildableItemsText(X2ItemTemplate item) {
	local X2ItemTemplate BuildableItem;
	local array<X2ItemTemplate> BuildableItems;
	local string result;	
	local string htmlColor;

	result = "";
	htmlColor = class'UIUtilities_Colors'.const.CASH_HTML_COLOR;

	BuildableItems = ItemTemplateManager.GetBuildableItemTemplates();		
	foreach BuildableItems(BuildableItem) {	
		if(BuildableItem.ItemCat == 'weapon') {
			htmlColor = class'UIUtilities_Colors'.const.BAD_HTML_COLOR;
		}
		result $= GetStringForCostPart(BuildableItem.Cost.ResourceCosts, item, coloredText(BuildableItem.GetItemFriendlyName(), htmlColor));
		result $= GetStringForCostPart(BuildableItem.Cost.ArtifactCosts, item, coloredText(BuildableItem.GetItemFriendlyName(), htmlColor));
	}

	return result;
}

function string getProvingGroundText(X2ItemTemplate item) {
	return getTechStateText(GetProvingGroundProjects(), class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR, item);
}

function string getResearchText(X2ItemTemplate item) {
	return getTechStateText(GetTechs(), class'UIUtilities_Colors'.const.SCIENCE_HTML_COLOR, item);
}

function string getFacilitiesText(X2ItemTemplate item) {
	local array<X2FacilityTemplate> BuildableFacilities;
	local X2FacilityTemplate BuildableFacility;

	local array<X2FacilityUpgradeTemplate> BuildableFacilityUpgrades;	
	local X2FacilityUpgradeTemplate BuildableFacilityUpgrade;

	local X2StrategyElementTemplateManager SETM;
	local string result;
	
	result = "";

	SETM = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	BuildableFacilities = SETM.GetBuildableFacilityTemplates();
	foreach BuildableFacilities(BuildableFacility) {
		result $= GetStringForCostPart(BuildableFacility.Cost.ResourceCosts, item, coloredText(BuildableFacility.DisplayName, class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR));
		result $= GetStringForCostPart(BuildableFacility.Cost.ArtifactCosts, item, coloredText(BuildableFacility.DisplayName, class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR));
	}

	BuildableFacilityUpgrades = SETM.GetBuildableFacilityUpgradeTemplates();
	foreach BuildableFacilityUpgrades(BuildableFacilityUpgrade) {
		result $= GetStringForCostPart(BuildableFacilityUpgrade.Cost.ResourceCosts, item, coloredText(BuildableFacilityUpgrade.DisplayName, class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR));
		result $= GetStringForCostPart(BuildableFacilityUpgrade.Cost.ArtifactCosts, item, coloredText(BuildableFacilityUpgrade.DisplayName, class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR));
	}	

	return result;
}


function string getTechStateText(array<StateObjectReference> techs, string htmlColor, X2ItemTemplate item) {
	local XComGameState_Tech TechState;
	local XComGameStateHistory History;
	local StateObjectReference Project;
	local string result;
	result = "";

	History = `XCOMHISTORY;
	foreach techs(Project) {
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(Project.ObjectID));
		result $= GetStringForCostPart(TechState.GetMyTemplate().Cost.ResourceCosts, item, coloredText(TechState.GetDisplayName(), htmlColor));
		result $= GetStringForCostPart(TechState.GetMyTemplate().Cost.ArtifactCosts, item, coloredText(TechState.GetDisplayName(), htmlColor));
	}

	return result;	
}

function string GetStringForCostPart(array<ArtifactCost> costs, X2ItemTemplate item, string displayString) {
	local ArtifactCost cost;
	local X2ItemTemplate CostItem;

	foreach costs(cost) {
		CostItem = ItemTemplateManager.FindItemTemplate(cost.ItemTemplateName);
		if(CostItem != none && CostItem == item) {
			return displayString $ " (" $ cost.Quantity $ ")<br/>";
		}
	}

	return "";
}



function string coloredText(string text, string htmlColor) {
	return "<font color='#"$htmlColor$"'>"$text$"</font>";
}


simulated function array<StateObjectReference> GetTechs() {
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableTechsForResearch();
}


simulated function array<StateObjectReference> GetProvingGroundProjects() {
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableProvingGroundProjects();
}

defaultproperties {
	ScreenClass = class'UIBlackMarket_Sell';
}