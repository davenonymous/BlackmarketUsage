class UIAddToBlackmarket extends UIScreenListener config(BlackmarketUsage);

var UIBlackMarket_Sell SellScreen;
var UIText DisplayText;
var X2ItemTemplateManager ItemTemplateManager;

var config int ShowSpoilers;

// TODO: Clean this up: No global variables, don't pass text around etc.
var bool hasUnknownTech;

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
			UsableImage = ListItem.Spawn(class'UIImage', ListItem).InitImage(, class'UIUtilities_Image'.static.GetToDoWidgetImagePath(eUIToDoCat_MAX));
			UsableImage.ProcessMouseEvents();
			UsableImage.SetScale(0.8);			
			UsableImage.SetPosition(318, 7);
			UsableImage.SetColor(class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR);
			UsableImage.SetAlpha(0.3);
			UsableImage.SetTooltipText("<font size=\"16\">"$newText$"</font>", "Used for:");
		}
	}
}

function string GetTooltipText(UIBlackMarket_SellItem ItemPanel) {
	local string newText;
	hasUnknownTech = false;
	newText  = getBuildableItemsText(ItemPanel.ItemTemplate);
	newText $= getFacilitiesText(ItemPanel.ItemTemplate);
	newText $= getTechsText(ItemPanel.ItemTemplate);

	if(hasUnknownTech && ShowSpoilers == 1) {
		newText $= coloredText("???", class'UIUtilities_Colors'.const.FADED_HTML_COLOR);
	}

	return newText;
}




function string getBuildableItemsText(X2ItemTemplate item) {
	local X2ItemTemplate BuildableItem;
	local array<X2ItemTemplate> BuildableItems;
	local string itemName;
	local string itemColor;
	local string result;

	result = "";

	BuildableItems = ItemTemplateManager.GetBuildableItemTemplates();		
	BuildableItems = class'TechTreeHelpers'.static.GetFutureBuildableItems();
	foreach BuildableItems(BuildableItem) {	
		if(!IsItemRequired(BuildableItem.Cost, item)) {
			continue;
		}

		itemName = BuildableItem.GetItemFriendlyName();
		itemColor = class'UIUtilities_Colors'.const.CASH_HTML_COLOR;
		if(BuildableItem.ItemCat == 'weapon') {
			itemColor = class'UIUtilities_Colors'.const.BAD_HTML_COLOR;
		}

		if(!IsItemVisible(BuildableItem)) {
			if(ShowSpoilers == 0) {
				continue;
			} else if(ShowSpoilers == 1) {
				hasUnknownTech = true;
				continue;
			} else if(ShowSpoilers == 2) {
				itemName = itemName$"*";
			}
		}

		result $= GetStringForCosts(BuildableItem.Cost, item, coloredText(itemName, itemColor));
	}

	return result;
}

function string getFacilitiesText(X2ItemTemplate item) {
	local array<X2FacilityTemplate> BuildableFacilities;
	local X2FacilityTemplate BuildableFacility;

	local array<X2FacilityUpgradeTemplate> BuildableFacilityUpgrades;	
	local X2FacilityUpgradeTemplate BuildableFacilityUpgrade;

	local XComGameState_HeadquartersXCom XComHQ;
	local string facilityName;
	local string facilityColor;
	local string result;

	XComHQ = `XCOMHQ;
	facilityColor = class'UIUtilities_Colors'.const.PERK_HTML_COLOR;
	
	result = "";

	BuildableFacilities = class'TechTreeHelpers'.static.GetFutureFacilities();
	foreach BuildableFacilities(BuildableFacility) {
		if(!IsItemRequired(BuildableFacility.Cost, item)) {
			continue;
		}

		facilityName = BuildableFacility.DisplayName;
		if(!XComHQ.MeetsEnoughRequirementsToBeVisible(BuildableFacility.Requirements)) {
			if(ShowSpoilers == 0) {
				continue;
			} else if(ShowSpoilers == 1) {
				hasUnknownTech = true;
				continue;
			} else if(ShowSpoilers == 2) {
				facilityName = facilityName$"*";
			}
		}

		result $= GetStringForCosts(BuildableFacility.Cost, item, coloredText(facilityName, facilityColor));
	}

	BuildableFacilityUpgrades = class'TechTreeHelpers'.static.GetFutureFacilityUpgrades();
	foreach BuildableFacilityUpgrades(BuildableFacilityUpgrade) {
		if(!IsItemRequired(BuildableFacilityUpgrade.Cost, item)) {
			continue;
		}

		facilityName = BuildableFacilityUpgrade.DisplayName;
		if(!XComHQ.MeetsEnoughRequirementsToBeVisible(BuildableFacilityUpgrade.Requirements) || !HasFacilityToBuildUpgrade(BuildableFacilityUpgrade)) {
			if(ShowSpoilers == 0) {
				continue;
			} else if(ShowSpoilers == 1) {
				hasUnknownTech = true;
				continue;
			} else if(ShowSpoilers == 2) {
				facilityName = facilityName$"*";
			}
		}

		result $= GetStringForCosts(BuildableFacilityUpgrade.Cost, item, coloredText(facilityName, facilityColor));
	}	

	return result;
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

function string getTechsText(X2ItemTemplate item) {
	local array<XComGameState_Tech> techs;
	local XComGameState_Tech TechState;
	local X2TechTemplate Template;
	local XComGameState_HeadquartersXCom XComHQ;
	local string techName;
	local string techColor;
	local string result;

	XComHQ = `XCOMHQ;
	result = "";

	techs = class'TechTreeHelpers'.static.GetFutureTechs();
	techs.Sort(SortTechs);
	foreach techs(TechState) {
		Template = TechState.GetMyTemplate();
		if(!IsItemRequired(Template.Cost, item)) {
			continue;
		}

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

		if(!XComHQ.MeetsEnoughRequirementsToBeVisible(Template.Requirements)) {
			if(ShowSpoilers == 0) {
				continue;
			} else if(ShowSpoilers == 1) {
				hasUnknownTech = true;
				continue;
			} else if(ShowSpoilers == 2) {
				techName = techName$"*";
			}
		}

		result $= GetStringForCosts(Template.Cost, item, coloredText(techName, techColor));
	}


	return result;
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


function string getTechStateText(array<StateObjectReference> techs, string htmlColor, X2ItemTemplate item) {
	local XComGameState_Tech TechState;
	local XComGameStateHistory History;
	local StateObjectReference Project;
	local string result;
	result = "";

	History = `XCOMHISTORY;
	foreach techs(Project) {
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(Project.ObjectID));
		result $= GetStringForCosts(TechState.GetMyTemplate().Cost, item, coloredText(TechState.GetDisplayName(), htmlColor));
	}

	return result;	
}

function bool IsItemRequired(StrategyCost StrategyCost, X2ItemTemplate item) {
	local ArtifactCost ArtifactCost;
	local X2ItemTemplate CostItem;

	foreach StrategyCost.ResourceCosts(ArtifactCost) {
		CostItem = ItemTemplateManager.FindItemTemplate(ArtifactCost.ItemTemplateName);
		if(CostItem != none && CostItem == item) {
			return true;
		}
	}

	foreach StrategyCost.ArtifactCosts(ArtifactCost) {
		CostItem = ItemTemplateManager.FindItemTemplate(ArtifactCost.ItemTemplateName);
		if(CostItem != none && CostItem == item) {
			return true;
		}
	}

	return false;
}

function string GetStringForCosts(StrategyCost StrategyCost, X2ItemTemplate item, string displayString) {
	local string result;
	local ArtifactCost ArtifactCost;
	local X2ItemTemplate CostItem;

	result = "";

	foreach StrategyCost.ResourceCosts(ArtifactCost) {
		CostItem = ItemTemplateManager.FindItemTemplate(ArtifactCost.ItemTemplateName);
		if(CostItem != none && CostItem == item) {
			result $= displayString $ " (" $ ArtifactCost.Quantity $ ")<br/>";
		}
	}

	foreach StrategyCost.ArtifactCosts(ArtifactCost) {
		CostItem = ItemTemplateManager.FindItemTemplate(ArtifactCost.ItemTemplateName);
		if(CostItem != none && CostItem == item) {
			result $= displayString $ " (" $ ArtifactCost.Quantity $ ")<br/>";
		}
	}

	return result;
}


function string coloredText(string text, string htmlColor) {
	return "<font color='#"$htmlColor$"'>"$text$"</font>";
}

defaultproperties {
	ScreenClass = class'UIBlackMarket_Sell';
}