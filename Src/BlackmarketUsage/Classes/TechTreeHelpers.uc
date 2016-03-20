class TechTreeHelpers extends Object;

Static function bool IsTechCurrentlyBeingResearched(XComGameState_Tech TechState) {
	local XComGameState_HeadquartersXCom XComHQ;
	XComHQ = `XCOMHQ;

	if(TechState.GetMyTemplate().bProvingGround) {
		return XComHQ.IsTechCurrentlyBeingResearched(TechState);
	} else if(TechState.GetMyTemplate().bShadowProject) {
		return (XComHQ.HasActiveShadowProject() && TechState.ObjectID == XComHQ.GetCurrentShadowTech().ObjectID);
	} else {
		return (XComHQ.HasResearchProject() && TechState.ObjectID == XComHQ.GetCurrentResearchTech().ObjectID);
	}

	return false;
}

Static function array<XComGameState_Tech> GetFutureTechs() {
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local array<XComGameState_Tech> AvailableProjects;

	AvailableProjects.Length = 0;
	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState) {
		// Already built and not repeatable
		if((XComHQ.TechIsResearched(TechState.GetReference()) || IsTechCurrentlyBeingResearched(TechState)) && !TechState.GetMyTemplate().bRepeatable) {
			continue;
		}

		AvailableProjects.AddItem(TechState);
	}

	return AvailableProjects;	
}

Static function array<X2ItemTemplate> GetFutureBuildableItems() {
	local array<X2ItemTemplate> arrBuildTemplates;
	local X2DataTemplate Template;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = `XCOMHQ;

	foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(Template, none) {
		ItemTemplate = X2ItemTemplate(Template);
		// Ignore all items that cannot exist or be built
		if(ItemTemplate == none || !ItemTemplate.CanBeBuilt) {
			continue;
		}

		// Ignore all items that can only be in the inventory once
		if(ItemTemplate.bOneTimeBuild && (XComHQ.HasItem(ItemTemplate) || XComHQ.GetNumItemBeingBuilt(ItemTemplate) > 0)) {
			continue;
		}

		// Ignore all items that have been made obsolete by technology
		if(XComHQ.IsTechResearched(ItemTemplate.HideIfResearched) || XComHQ.HasItemByName(ItemTemplate.HideIfPurchased)) {
			continue;
		}

		arrBuildTemplates.AddItem(ItemTemplate);
	}

	return arrBuildTemplates;
}

Static function array<X2FacilityTemplate> GetFutureFacilities() {
	local array<X2FacilityTemplate> result;
	local X2DataTemplate StrategyTemplate;
	local X2FacilityTemplate FacilityTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = `XCOMHQ;

	foreach class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().IterateTemplates(StrategyTemplate, none) {
		if(!ClassIsChildOf(StrategyTemplate.Class, class'X2FacilityTemplate')) {
			continue;
		}

		FacilityTemplate = X2FacilityTemplate(StrategyTemplate);		
		if(FacilityTemplate.bIsUniqueFacility && (XComHQ.HasFacility(FacilityTemplate) || XComHQ.IsBuildingFacility(FacilityTemplate))) {
			continue;
		}

		result.AddItem(FacilityTemplate);
	}

	return result;
}

Static function int CountFacilityUpgradesByName(X2FacilityUpgradeTemplate UpgradeTemplate) {
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local int idx;
	local int count;

	History = `XCOMHISTORY;
	count = 0;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState) {
		for(idx = 0; idx < FacilityState.Upgrades.Length; idx++) {
			UpgradeState = XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(FacilityState.Upgrades[idx].ObjectID));
			
			if(UpgradeState != none && UpgradeState.GetMyTemplate() == UpgradeTemplate)	{
				count++;
			}
		}
	}

	return count;
}

Static function array<X2FacilityUpgradeTemplate> GetFutureFacilityUpgrades() {
	local array<X2FacilityUpgradeTemplate> result;
	local X2DataTemplate StrategyTemplate;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local X2FacilityTemplate FacilityTemplate;
	local Name UpgradeRef;

	foreach class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().IterateTemplates(StrategyTemplate, none) {
		if(!ClassIsChildOf(StrategyTemplate.Class, class'X2FacilityTemplate')) {
			continue;
		}

		FacilityTemplate = X2FacilityTemplate(StrategyTemplate);
		foreach FacilityTemplate.Upgrades(UpgradeRef) {
			UpgradeTemplate = X2FacilityUpgradeTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(UpgradeRef));
			
			if(UpgradeTemplate.bHidden) {
				continue;
			}

			// If the building is unique and it already has the maximum amount of this upgrade, ignore it.
			if(FacilityTemplate.bIsUniqueFacility && CountFacilityUpgradesByName(UpgradeTemplate) >= UpgradeTemplate.MaxBuild) {
				continue;
			}

			if(result.Find(UpgradeTemplate) == INDEX_NONE) {
				result.AddItem(UpgradeTemplate);
			}
		}		
	}

	return result;
}