| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

|  |  |
| --- | --- |
| [Icon-api-48x48.png](File:Icon-api-48x48.png.md) | **This article documents [API changes](API_change_summaries.md "API change summaries") made in [Patch 12.0.0](Patch_12.0.0.md "Patch 12.0.0").**  * Previous patch: [Patch 11.2.7](Patch_11.2.7/API_changes.md "Patch 11.2.7/API changes"). * Next patch: [Patch 12.0.1](Patch_12.0.1/API_changes.md "Patch 12.0.1/API changes"). |

|  |  |
| --- | --- |
|  | [Markdown important.png](File:Markdown_important.png.md)  **Important** [Secret values](Secret_Values.md "Secret Values") are a new mechanism that restrict the ability for addons to perform some operations on Lua values on tainted execution paths. |

| Added (437) | Removed (138) |
| --- | --- |
| [AbbreviateLargeNumbers](API_AbbreviateLargeNumbers.md "API AbbreviateLargeNumbers")  [AbbreviateNumbers](API_AbbreviateNumbers.md "API AbbreviateNumbers")  [AddSourceLocationExclude](API_AddSourceLocationExclude.md "API AddSourceLocationExclude")  [C\_ActionBar.GetActionAutocast](API_C_ActionBar.GetActionAutocast.md "API C ActionBar.GetActionAutocast")  [C\_ActionBar.GetActionBarPage](API_C_ActionBar.GetActionBarPage.md "API C ActionBar.GetActionBarPage")  [C\_ActionBar.GetActionChargeDuration](API_C_ActionBar.GetActionChargeDuration.md "API C ActionBar.GetActionChargeDuration")  [C\_ActionBar.GetActionCharges](API_C_ActionBar.GetActionCharges.md "API C ActionBar.GetActionCharges")  [C\_ActionBar.GetActionCooldownDuration](API_C_ActionBar.GetActionCooldownDuration.md "API C ActionBar.GetActionCooldownDuration")  [C\_ActionBar.GetActionCooldown](API_C_ActionBar.GetActionCooldown.md "API C ActionBar.GetActionCooldown")  [C\_ActionBar.GetActionDisplayCount](API_C_ActionBar.GetActionDisplayCount.md "API C ActionBar.GetActionDisplayCount")  [C\_ActionBar.GetActionLossOfControlCooldownDuration](API_C_ActionBar.GetActionLossOfControlCooldownDuration.md "API C ActionBar.GetActionLossOfControlCooldownDuration")  [C\_ActionBar.GetActionLossOfControlCooldown](API_C_ActionBar.GetActionLossOfControlCooldown.md "API C ActionBar.GetActionLossOfControlCooldown")  [C\_ActionBar.GetActionTexture](API_C_ActionBar.GetActionTexture.md "API C ActionBar.GetActionTexture")  [C\_ActionBar.GetActionText](API_C_ActionBar.GetActionText.md "API C ActionBar.GetActionText")  [C\_ActionBar.GetActionUseCount](API_C_ActionBar.GetActionUseCount.md "API C ActionBar.GetActionUseCount")  [C\_ActionBar.GetBonusBarIndex](API_C_ActionBar.GetBonusBarIndex.md "API C ActionBar.GetBonusBarIndex")  [C\_ActionBar.GetBonusBarOffset](API_C_ActionBar.GetBonusBarOffset.md "API C ActionBar.GetBonusBarOffset")  [C\_ActionBar.GetExtraBarIndex](API_C_ActionBar.GetExtraBarIndex.md "API C ActionBar.GetExtraBarIndex")  [C\_ActionBar.GetMultiCastBarIndex](API_C_ActionBar.GetMultiCastBarIndex.md "API C ActionBar.GetMultiCastBarIndex")  [C\_ActionBar.GetOverrideBarIndex](API_C_ActionBar.GetOverrideBarIndex.md "API C ActionBar.GetOverrideBarIndex")  [C\_ActionBar.GetOverrideBarSkin](API_C_ActionBar.GetOverrideBarSkin.md "API C ActionBar.GetOverrideBarSkin")  [C\_ActionBar.GetProfessionQualityInfo](API_C_ActionBar.GetProfessionQualityInfo.md "API C ActionBar.GetProfessionQualityInfo")  [C\_ActionBar.GetTempShapeshiftBarIndex](API_C_ActionBar.GetTempShapeshiftBarIndex.md "API C ActionBar.GetTempShapeshiftBarIndex")  [C\_ActionBar.GetVehicleBarIndex](API_C_ActionBar.GetVehicleBarIndex.md "API C ActionBar.GetVehicleBarIndex")  [C\_ActionBar.HasAction](API_C_ActionBar.HasAction.md "API C ActionBar.HasAction")  [C\_ActionBar.HasBonusActionBar](API_C_ActionBar.HasBonusActionBar.md "API C ActionBar.HasBonusActionBar")  [C\_ActionBar.HasExtraActionBar](API_C_ActionBar.HasExtraActionBar.md "API C ActionBar.HasExtraActionBar")  [C\_ActionBar.HasOverrideActionBar](API_C_ActionBar.HasOverrideActionBar.md "API C ActionBar.HasOverrideActionBar")  [C\_ActionBar.HasRangeRequirements](API_C_ActionBar.HasRangeRequirements.md "API C ActionBar.HasRangeRequirements")  [C\_ActionBar.HasTempShapeshiftActionBar](API_C_ActionBar.HasTempShapeshiftActionBar.md "API C ActionBar.HasTempShapeshiftActionBar")  [C\_ActionBar.HasVehicleActionBar](API_C_ActionBar.HasVehicleActionBar.md "API C ActionBar.HasVehicleActionBar")  [C\_ActionBar.IsActionInRange](API_C_ActionBar.IsActionInRange.md "API C ActionBar.IsActionInRange")  [C\_ActionBar.IsAttackAction](API_C_ActionBar.IsAttackAction.md "API C ActionBar.IsAttackAction")  [C\_ActionBar.IsAutoRepeatAction](API_C_ActionBar.IsAutoRepeatAction.md "API C ActionBar.IsAutoRepeatAction")  [C\_ActionBar.IsConsumableAction](API_C_ActionBar.IsConsumableAction.md "API C ActionBar.IsConsumableAction")  [C\_ActionBar.IsCurrentAction](API_C_ActionBar.IsCurrentAction.md "API C ActionBar.IsCurrentAction")  [C\_ActionBar.IsEquippedAction](API_C_ActionBar.IsEquippedAction.md "API C ActionBar.IsEquippedAction")  [C\_ActionBar.IsEquippedGearOutfitAction](API_C_ActionBar.IsEquippedGearOutfitAction.md "API C ActionBar.IsEquippedGearOutfitAction")  [C\_ActionBar.IsItemAction](API_C_ActionBar.IsItemAction.md "API C ActionBar.IsItemAction")  [C\_ActionBar.IsPossessBarVisible](API_C_ActionBar.IsPossessBarVisible.md "API C ActionBar.IsPossessBarVisible")  [C\_ActionBar.IsStackableAction](API_C_ActionBar.IsStackableAction.md "API C ActionBar.IsStackableAction")  [C\_ActionBar.IsUsableAction](API_C_ActionBar.IsUsableAction.md "API C ActionBar.IsUsableAction")  [C\_ActionBar.RegisterActionUIButton](API_C_ActionBar.RegisterActionUIButton.md "API C ActionBar.RegisterActionUIButton")  [C\_ActionBar.SetActionBarPage](API_C_ActionBar.SetActionBarPage.md "API C ActionBar.SetActionBarPage")  [C\_ActionBar.UnregisterActionUIButton](API_C_ActionBar.UnregisterActionUIButton.md "API C ActionBar.UnregisterActionUIButton")  [C\_AdventureMap.GetQuestPortraitInfo](API_C_AdventureMap.GetQuestPortraitInfo.md "API C AdventureMap.GetQuestPortraitInfo")  [C\_BattleNet.SendGameData](API_C_BattleNet.SendGameData.md "API C BattleNet.SendGameData")  [C\_BattleNet.SendWhisper](API_C_BattleNet.SendWhisper.md "API C BattleNet.SendWhisper")  [C\_BattleNet.SetCustomMessage](API_C_BattleNet.SetCustomMessage.md "API C BattleNet.SetCustomMessage")  [C\_CatalogShop.BulkPurchaseProducts](API_C_CatalogShop.BulkPurchaseProducts.md "API C CatalogShop.BulkPurchaseProducts")  [C\_CatalogShop.ConfirmHousingPurchase](API_C_CatalogShop.ConfirmHousingPurchase.md "API C CatalogShop.ConfirmHousingPurchase")  [C\_CatalogShop.GetFirstCategoryByProductID](API_C_CatalogShop.GetFirstCategoryByProductID.md "API C CatalogShop.GetFirstCategoryByProductID")  [C\_CatalogShop.GetNewProducts](API_C_CatalogShop.GetNewProducts.md "API C CatalogShop.GetNewProducts")  [C\_CatalogShop.GetProductIDsForCategory](API_C_CatalogShop.GetProductIDsForCategory.md "API C CatalogShop.GetProductIDsForCategory")  [C\_CatalogShop.GetRefundableDecors](API_C_CatalogShop.GetRefundableDecors.md "API C CatalogShop.GetRefundableDecors")  [C\_CatalogShop.GetVirtualCurrencyBalance](API_C_CatalogShop.GetVirtualCurrencyBalance.md "API C CatalogShop.GetVirtualCurrencyBalance")  [C\_CatalogShop.HasNewProducts](API_C_CatalogShop.HasNewProducts.md "API C CatalogShop.HasNewProducts")  [C\_CatalogShop.OpenCatalogShopInteractionFromHouse](API_C_CatalogShop.OpenCatalogShopInteractionFromHouse.md "API C CatalogShop.OpenCatalogShopInteractionFromHouse")  [C\_CatalogShop.OpenCatalogShopInteractionFromShop](API_C_CatalogShop.OpenCatalogShopInteractionFromShop.md "API C CatalogShop.OpenCatalogShopInteractionFromShop")  [C\_CatalogShop.RefreshRefundableDecors](API_C_CatalogShop.RefreshRefundableDecors.md "API C CatalogShop.RefreshRefundableDecors")  [C\_CatalogShop.RefreshVirtualCurrencyBalance](API_C_CatalogShop.RefreshVirtualCurrencyBalance.md "API C CatalogShop.RefreshVirtualCurrencyBalance")  [C\_CatalogShop.StartHousingVCPurchaseConfirmation](API_C_CatalogShop.StartHousingVCPurchaseConfirmation.md "API C CatalogShop.StartHousingVCPurchaseConfirmation")  [C\_CharacterServices.AssignFCMDistribution](API_C_CharacterServices.AssignFCMDistribution.md "API C CharacterServices.AssignFCMDistribution (page does not exist)")  [C\_ChatInfo.CancelEmote](API_C_ChatInfo.CancelEmote.md "API C ChatInfo.CancelEmote")  [C\_ChatInfo.InChatMessagingLockdown](API_C_ChatInfo.InChatMessagingLockdown.md "API C ChatInfo.InChatMessagingLockdown")  [C\_ChatInfo.PerformEmote](API_C_ChatInfo.PerformEmote.md "API C ChatInfo.PerformEmote")  [C\_ColorUtil.ConvertHSLToHSV](API_C_ColorUtil.ConvertHSLToHSV.md "API C ColorUtil.ConvertHSLToHSV")  [C\_ColorUtil.ConvertHSVToHSL](API_C_ColorUtil.ConvertHSVToHSL.md "API C ColorUtil.ConvertHSVToHSL")  [C\_ColorUtil.ConvertHSVToRGB](API_C_ColorUtil.ConvertHSVToRGB.md "API C ColorUtil.ConvertHSVToRGB")  [C\_ColorUtil.ConvertRGBToHSV](API_C_ColorUtil.ConvertRGBToHSV.md "API C ColorUtil.ConvertRGBToHSV")  [C\_ColorUtil.GenerateTextColorCode](API_C_ColorUtil.GenerateTextColorCode.md "API C ColorUtil.GenerateTextColorCode")  [C\_ColorUtil.WrapTextInColorCode](API_C_ColorUtil.WrapTextInColorCode.md "API C ColorUtil.WrapTextInColorCode")  [C\_ColorUtil.WrapTextInColor](API_C_ColorUtil.WrapTextInColor.md "API C ColorUtil.WrapTextInColor")  [C\_CombatAudioAlert.GetFormatSetting](API_C_CombatAudioAlert.GetFormatSetting.md "API C CombatAudioAlert.GetFormatSetting")  [C\_CombatAudioAlert.GetSpeakerSpeed](API_C_CombatAudioAlert.GetSpeakerSpeed.md "API C CombatAudioAlert.GetSpeakerSpeed")  [C\_CombatAudioAlert.GetSpeakerVolume](API_C_CombatAudioAlert.GetSpeakerVolume.md "API C CombatAudioAlert.GetSpeakerVolume")  [C\_CombatAudioAlert.GetSpecSetting](API_C_CombatAudioAlert.GetSpecSetting.md "API C CombatAudioAlert.GetSpecSetting")  [C\_CombatAudioAlert.GetThrottle](API_C_CombatAudioAlert.GetThrottle.md "API C CombatAudioAlert.GetThrottle")  [C\_CombatAudioAlert.IsEnabled](API_C_CombatAudioAlert.IsEnabled.md "API C CombatAudioAlert.IsEnabled")  [C\_CombatAudioAlert.SetFormatSetting](API_C_CombatAudioAlert.SetFormatSetting.md "API C CombatAudioAlert.SetFormatSetting")  [C\_CombatAudioAlert.SetSpeakerSpeed](API_C_CombatAudioAlert.SetSpeakerSpeed.md "API C CombatAudioAlert.SetSpeakerSpeed")  [C\_CombatAudioAlert.SetSpeakerVolume](API_C_CombatAudioAlert.SetSpeakerVolume.md "API C CombatAudioAlert.SetSpeakerVolume")  [C\_CombatAudioAlert.SetSpecSetting](API_C_CombatAudioAlert.SetSpecSetting.md "API C CombatAudioAlert.SetSpecSetting")  [C\_CombatAudioAlert.SetThrottle](API_C_CombatAudioAlert.SetThrottle.md "API C CombatAudioAlert.SetThrottle")  [C\_CombatAudioAlert.SpeakText](API_C_CombatAudioAlert.SpeakText.md "API C CombatAudioAlert.SpeakText")  [C\_CombatLog.ApplyFilterSettings](API_C_CombatLog.ApplyFilterSettings.md "API C CombatLog.ApplyFilterSettings")  [C\_CombatLog.AreFilteredEventsEnabled](API_C_CombatLog.AreFilteredEventsEnabled.md "API C CombatLog.AreFilteredEventsEnabled")  [C\_CombatLog.ClearEntries](API_C_CombatLog.ClearEntries.md "API C CombatLog.ClearEntries")  [C\_CombatLog.DoesObjectMatchFilter](API_C_CombatLog.DoesObjectMatchFilter.md "API C CombatLog.DoesObjectMatchFilter")  [C\_CombatLog.GetEntryRetentionTime](API_C_CombatLog.GetEntryRetentionTime.md "API C CombatLog.GetEntryRetentionTime")  [C\_CombatLog.GetMessageLimit](API_C_CombatLog.GetMessageLimit.md "API C CombatLog.GetMessageLimit")  [C\_CombatLog.IsCombatLogRestricted](API_C_CombatLog.IsCombatLogRestricted.md "API C CombatLog.IsCombatLogRestricted")  [C\_CombatLog.RefilterEntries](API_C_CombatLog.RefilterEntries.md "API C CombatLog.RefilterEntries")  [C\_CombatLog.SetEntryRetentionTime](API_C_CombatLog.SetEntryRetentionTime.md "API C CombatLog.SetEntryRetentionTime")  [C\_CombatLog.SetFilteredEventsEnabled](API_C_CombatLog.SetFilteredEventsEnabled.md "API C CombatLog.SetFilteredEventsEnabled")  [C\_CombatLog.SetMessageLimit](API_C_CombatLog.SetMessageLimit.md "API C CombatLog.SetMessageLimit")  [C\_CombatText.GetActiveUnit](API_C_CombatText.GetActiveUnit.md "API C CombatText.GetActiveUnit")  [C\_CombatText.GetCurrentEventInfo](API_C_CombatText.GetCurrentEventInfo.md "API C CombatText.GetCurrentEventInfo")  [C\_CombatText.SetActiveUnit](API_C_CombatText.SetActiveUnit.md "API C CombatText.SetActiveUnit")  [C\_Commentator.GetCombatEventInfo](API_C_Commentator.GetCombatEventInfo.md "API C Commentator.GetCombatEventInfo")  [C\_CooldownViewer.GetValidAlertTypes](API_C_CooldownViewer.GetValidAlertTypes.md "API C CooldownViewer.GetValidAlertTypes")  [C\_CreatureInfo.GetCreatureID](API_C_CreatureInfo.GetCreatureID.md "API C CreatureInfo.GetCreatureID")  [C\_CurveUtil.CreateColorCurve](API_C_CurveUtil.CreateColorCurve.md "API C CurveUtil.CreateColorCurve")  [C\_CurveUtil.CreateCurve](API_C_CurveUtil.CreateCurve.md "API C CurveUtil.CreateCurve")  [C\_CurveUtil.EvaluateColorFromBoolean](API_C_CurveUtil.EvaluateColorFromBoolean.md "API C CurveUtil.EvaluateColorFromBoolean")  [C\_CurveUtil.EvaluateColorValueFromBoolean](API_C_CurveUtil.EvaluateColorValueFromBoolean.md "API C CurveUtil.EvaluateColorValueFromBoolean")  [C\_CurveUtil.EvaluateGameCurve](API_C_CurveUtil.EvaluateGameCurve.md "API C CurveUtil.EvaluateGameCurve")  [C\_DamageMeter.GetAvailableCombatSessions](API_C_DamageMeter.GetAvailableCombatSessions.md "API C DamageMeter.GetAvailableCombatSessions")  [C\_DamageMeter.GetCombatSessionFromID](API_C_DamageMeter.GetCombatSessionFromID.md "API C DamageMeter.GetCombatSessionFromID")  [C\_DamageMeter.GetCombatSessionFromType](API_C_DamageMeter.GetCombatSessionFromType.md "API C DamageMeter.GetCombatSessionFromType")  [C\_DamageMeter.GetCombatSessionSourceFromID](API_C_DamageMeter.GetCombatSessionSourceFromID.md "API C DamageMeter.GetCombatSessionSourceFromID")  [C\_DamageMeter.GetCombatSessionSourceFromType](API_C_DamageMeter.GetCombatSessionSourceFromType.md "API C DamageMeter.GetCombatSessionSourceFromType")  [C\_DamageMeter.IsDamageMeterAvailable](API_C_DamageMeter.IsDamageMeterAvailable.md "API C DamageMeter.IsDamageMeterAvailable")  [C\_DamageMeter.ResetAllCombatSessions](API_C_DamageMeter.ResetAllCombatSessions.md "API C DamageMeter.ResetAllCombatSessions")  [C\_DeathRecap.GetRecapEvents](API_C_DeathRecap.GetRecapEvents.md "API C DeathRecap.GetRecapEvents")  [C\_DeathRecap.GetRecapLink](API_C_DeathRecap.GetRecapLink.md "API C DeathRecap.GetRecapLink")  [C\_DeathRecap.HasRecapEvents](API_C_DeathRecap.HasRecapEvents.md "API C DeathRecap.HasRecapEvents")  [C\_DelvesUI.GetLockedTextForCompanion](API_C_DelvesUI.GetLockedTextForCompanion.md "API C DelvesUI.GetLockedTextForCompanion")  [C\_DelvesUI.IsTraitTreeForCompanion](API_C_DelvesUI.IsTraitTreeForCompanion.md "API C DelvesUI.IsTraitTreeForCompanion")  [C\_DurationUtil.CreateDuration](API_C_DurationUtil.CreateDuration.md "API C DurationUtil.CreateDuration")  [C\_DurationUtil.GetCurrentTime](API_C_DurationUtil.GetCurrentTime.md "API C DurationUtil.GetCurrentTime")  [C\_EncounterTimeline.AddEditModeEvents](API_C_EncounterTimeline.AddEditModeEvents.md "API C EncounterTimeline.AddEditModeEvents")  [C\_EncounterTimeline.AddScriptEvent](API_C_EncounterTimeline.AddScriptEvent.md "API C EncounterTimeline.AddScriptEvent")  [C\_EncounterTimeline.CancelAllScriptEvents](API_C_EncounterTimeline.CancelAllScriptEvents.md "API C EncounterTimeline.CancelAllScriptEvents")  [C\_EncounterTimeline.CancelEditModeEvents](API_C_EncounterTimeline.CancelEditModeEvents.md "API C EncounterTimeline.CancelEditModeEvents")  [C\_EncounterTimeline.CancelScriptEvent](API_C_EncounterTimeline.CancelScriptEvent.md "API C EncounterTimeline.CancelScriptEvent")  [C\_EncounterTimeline.FinishScriptEvent](API_C_EncounterTimeline.FinishScriptEvent.md "API C EncounterTimeline.FinishScriptEvent")  [C\_EncounterTimeline.GetCurrentTime](API_C_EncounterTimeline.GetCurrentTime.md "API C EncounterTimeline.GetCurrentTime")  [C\_EncounterTimeline.GetEventCountBySource](API_C_EncounterTimeline.GetEventCountBySource.md "API C EncounterTimeline.GetEventCountBySource")  [C\_EncounterTimeline.GetEventInfo](API_C_EncounterTimeline.GetEventInfo.md "API C EncounterTimeline.GetEventInfo")  [C\_EncounterTimeline.GetEventList](API_C_EncounterTimeline.GetEventList.md "API C EncounterTimeline.GetEventList")  [C\_EncounterTimeline.GetEventState](API_C_EncounterTimeline.GetEventState.md "API C EncounterTimeline.GetEventState")  [C\_EncounterTimeline.GetEventTimeElapsed](API_C_EncounterTimeline.GetEventTimeElapsed.md "API C EncounterTimeline.GetEventTimeElapsed")  [C\_EncounterTimeline.GetEventTimeRemaining](API_C_EncounterTimeline.GetEventTimeRemaining.md "API C EncounterTimeline.GetEventTimeRemaining")  [C\_EncounterTimeline.GetEventTrack](API_C_EncounterTimeline.GetEventTrack.md "API C EncounterTimeline.GetEventTrack")  [C\_EncounterTimeline.GetTrackInfo](API_C_EncounterTimeline.GetTrackInfo.md "API C EncounterTimeline.GetTrackInfo")  [C\_EncounterTimeline.GetTrackList](API_C_EncounterTimeline.GetTrackList.md "API C EncounterTimeline.GetTrackList")  [C\_EncounterTimeline.HasActiveEvents](API_C_EncounterTimeline.HasActiveEvents.md "API C EncounterTimeline.HasActiveEvents")  [C\_EncounterTimeline.HasAnyEvents](API_C_EncounterTimeline.HasAnyEvents.md "API C EncounterTimeline.HasAnyEvents")  [C\_EncounterTimeline.HasPausedEvents](API_C_EncounterTimeline.HasPausedEvents.md "API C EncounterTimeline.HasPausedEvents")  [C\_EncounterTimeline.HasVisibleEvents](API_C_EncounterTimeline.HasVisibleEvents.md "API C EncounterTimeline.HasVisibleEvents")  [C\_EncounterTimeline.IsEventBlocked](API_C_EncounterTimeline.IsEventBlocked.md "API C EncounterTimeline.IsEventBlocked")  [C\_EncounterTimeline.IsFeatureAvailable](API_C_EncounterTimeline.IsFeatureAvailable.md "API C EncounterTimeline.IsFeatureAvailable")  [C\_EncounterTimeline.IsFeatureEnabled](API_C_EncounterTimeline.IsFeatureEnabled.md "API C EncounterTimeline.IsFeatureEnabled")  [C\_EncounterTimeline.PauseScriptEvent](API_C_EncounterTimeline.PauseScriptEvent.md "API C EncounterTimeline.PauseScriptEvent")  [C\_EncounterTimeline.ResumeScriptEvent](API_C_EncounterTimeline.ResumeScriptEvent.md "API C EncounterTimeline.ResumeScriptEvent")  [C\_EncounterTimeline.SetEventIconTextures](API_C_EncounterTimeline.SetEventIconTextures.md "API C EncounterTimeline.SetEventIconTextures")  [C\_EncounterWarnings.GetEditModeWarningInfo](API_C_EncounterWarnings.GetEditModeWarningInfo.md "API C EncounterWarnings.GetEditModeWarningInfo")  [C\_EncounterWarnings.GetSoundKitForSeverity](API_C_EncounterWarnings.GetSoundKitForSeverity.md "API C EncounterWarnings.GetSoundKitForSeverity")  [C\_EncounterWarnings.IsFeatureAvailable](API_C_EncounterWarnings.IsFeatureAvailable.md "API C EncounterWarnings.IsFeatureAvailable")  [C\_EncounterWarnings.IsFeatureEnabled](API_C_EncounterWarnings.IsFeatureEnabled.md "API C EncounterWarnings.IsFeatureEnabled")  [C\_EncounterWarnings.PlaySound](API_C_EncounterWarnings.PlaySound.md "API C EncounterWarnings.PlaySound")  [C\_EventScheduler.CanShowEvents](API_C_EventScheduler.CanShowEvents.md "API C EventScheduler.CanShowEvents")  [C\_EventUtils.IsCallbackEvent](API_C_EventUtils.IsCallbackEvent.md "API C EventUtils.IsCallbackEvent")  [C\_GameRules.IsPersonalResourceDisplayEnabled](API_C_GameRules.IsPersonalResourceDisplayEnabled.md "API C GameRules.IsPersonalResourceDisplayEnabled")  [C\_HouseExterior.GetCurrentHouseExteriorType](API_C_HouseExterior.GetCurrentHouseExteriorType.md "API C HouseExterior.GetCurrentHouseExteriorType")  [C\_HouseExterior.GetFixtureDebugInfoForGUID](API_C_HouseExterior.GetFixtureDebugInfoForGUID.md "API C HouseExterior.GetFixtureDebugInfoForGUID (page does not exist)")  [C\_HouseExterior.GetHouseExteriorSizeOptions](API_C_HouseExterior.GetHouseExteriorSizeOptions.md "API C HouseExterior.GetHouseExteriorSizeOptions")  [C\_HouseExterior.GetHouseExteriorTypeOptions](API_C_HouseExterior.GetHouseExteriorTypeOptions.md "API C HouseExterior.GetHouseExteriorTypeOptions")  [C\_HouseExterior.GetHoveredFixtureDebugInfo](API_C_HouseExterior.GetHoveredFixtureDebugInfo.md "API C HouseExterior.GetHoveredFixtureDebugInfo (page does not exist)")  [C\_HouseExterior.GetSelectedFixtureDebugInfo](API_C_HouseExterior.GetSelectedFixtureDebugInfo.md "API C HouseExterior.GetSelectedFixtureDebugInfo (page does not exist)")  [C\_HouseExterior.SetHouseExteriorSize](API_C_HouseExterior.SetHouseExteriorSize.md "API C HouseExterior.SetHouseExteriorSize")  [C\_HouseExterior.SetHouseExteriorType](API_C_HouseExterior.SetHouseExteriorType.md "API C HouseExterior.SetHouseExteriorType")  [C\_Housing.IsHousingMarketShopEnabled](API_C_Housing.IsHousingMarketShopEnabled.md "API C Housing.IsHousingMarketShopEnabled")  [C\_Housing.OnHouseFinderClickPlot](API_C_Housing.OnHouseFinderClickPlot.md "API C Housing.OnHouseFinderClickPlot")  [C\_HousingBasicMode.IsFreePlaceEnabled](API_C_HousingBasicMode.IsFreePlaceEnabled.md "API C HousingBasicMode.IsFreePlaceEnabled")  [C\_HousingBasicMode.SetFreePlaceEnabled](API_C_HousingBasicMode.SetFreePlaceEnabled.md "API C HousingBasicMode.SetFreePlaceEnabled")  [C\_HousingBasicMode.StartPlacingPreviewDecor](API_C_HousingBasicMode.StartPlacingPreviewDecor.md "API C HousingBasicMode.StartPlacingPreviewDecor")  [C\_HousingCatalog.DeletePreviewCartDecor](API_C_HousingCatalog.DeletePreviewCartDecor.md "API C HousingCatalog.DeletePreviewCartDecor")  [C\_HousingCatalog.GetBundleInfo](API_C_HousingCatalog.GetBundleInfo.md "API C HousingCatalog.GetBundleInfo")  [C\_HousingCatalog.GetCartSizeLimit](API_C_HousingCatalog.GetCartSizeLimit.md "API C HousingCatalog.GetCartSizeLimit")  [C\_HousingCatalog.GetCatalogEntryRefundTimeStampByRecordID](API_C_HousingCatalog.GetCatalogEntryRefundTimeStampByRecordID.md "API C HousingCatalog.GetCatalogEntryRefundTimeStampByRecordID")  [C\_HousingCatalog.HasFeaturedEntries](API_C_HousingCatalog.HasFeaturedEntries.md "API C HousingCatalog.HasFeaturedEntries")  [C\_HousingCatalog.IsPreviewCartItemShown](API_C_HousingCatalog.IsPreviewCartItemShown.md "API C HousingCatalog.IsPreviewCartItemShown")  [C\_HousingCatalog.PromotePreviewDecor](API_C_HousingCatalog.PromotePreviewDecor.md "API C HousingCatalog.PromotePreviewDecor")  [C\_HousingCatalog.RequestHousingMarketRefundInfo](API_C_HousingCatalog.RequestHousingMarketRefundInfo.md "API C HousingCatalog.RequestHousingMarketRefundInfo")  [C\_HousingCatalog.SetPreviewCartItemShown](API_C_HousingCatalog.SetPreviewCartItemShown.md "API C HousingCatalog.SetPreviewCartItemShown")  [C\_HousingCustomizeMode.IsHouseExteriorDoorHovered](API_C_HousingCustomizeMode.IsHouseExteriorDoorHovered.md "API C HousingCustomizeMode.IsHouseExteriorDoorHovered")  [C\_HousingDecor.EnterPreviewState](API_C_HousingDecor.EnterPreviewState.md "API C HousingDecor.EnterPreviewState")  [C\_HousingDecor.ExitPreviewState](API_C_HousingDecor.ExitPreviewState.md "API C HousingDecor.ExitPreviewState")  [C\_HousingDecor.GetNumPreviewDecor](API_C_HousingDecor.GetNumPreviewDecor.md "API C HousingDecor.GetNumPreviewDecor")  [C\_HousingDecor.IsModeDisabledForPreviewState](API_C_HousingDecor.IsModeDisabledForPreviewState.md "API C HousingDecor.IsModeDisabledForPreviewState")  [C\_HousingDecor.IsPreviewState](API_C_HousingDecor.IsPreviewState.md "API C HousingDecor.IsPreviewState")  [C\_InstanceEncounter.IsEncounterInProgress](API_C_InstanceEncounter.IsEncounterInProgress.md "API C InstanceEncounter.IsEncounterInProgress")  [C\_InstanceEncounter.IsEncounterLimitingResurrections](API_C_InstanceEncounter.IsEncounterLimitingResurrections.md "API C InstanceEncounter.IsEncounterLimitingResurrections")  [C\_InstanceEncounter.IsEncounterSuppressingRelease](API_C_InstanceEncounter.IsEncounterSuppressingRelease.md "API C InstanceEncounter.IsEncounterSuppressingRelease")  [C\_InstanceEncounter.ShouldShowTimelineForEncounter](API_C_InstanceEncounter.ShouldShowTimelineForEncounter.md "API C InstanceEncounter.ShouldShowTimelineForEncounter")  [C\_Item.IsItemBindToAccount](API_C_Item.IsItemBindToAccount.md "API C Item.IsItemBindToAccount")  [C\_LimitedInput.LimitedInputAllowed](API_C_LimitedInput.LimitedInputAllowed.md "API C LimitedInput.LimitedInputAllowed")  [C\_MajorFactions.ShouldDisplayMajorFactionAsJourney](API_C_MajorFactions.ShouldDisplayMajorFactionAsJourney.md "API C MajorFactions.ShouldDisplayMajorFactionAsJourney")  [C\_MajorFactions.ShouldUseJourneyRewardTrack](API_C_MajorFactions.ShouldUseJourneyRewardTrack.md "API C MajorFactions.ShouldUseJourneyRewardTrack")  [C\_NamePlate.GetNamePlateSize](API_C_NamePlate.GetNamePlateSize.md "API C NamePlate.GetNamePlateSize")  [C\_NamePlate.SetNamePlateSize](API_C_NamePlate.SetNamePlateSize.md "API C NamePlate.SetNamePlateSize")  [C\_NamePlateManager.GetNamePlateHitTestInsets](API_C_NamePlateManager.GetNamePlateHitTestInsets.md "API C NamePlateManager.GetNamePlateHitTestInsets")  [C\_NamePlateManager.IsNamePlateUnitBehindCamera](API_C_NamePlateManager.IsNamePlateUnitBehindCamera.md "API C NamePlateManager.IsNamePlateUnitBehindCamera")  [C\_NamePlateManager.SetNamePlateHitTestFrame](API_C_NamePlateManager.SetNamePlateHitTestFrame.md "API C NamePlateManager.SetNamePlateHitTestFrame")  [C\_NamePlateManager.SetNamePlateHitTestInsets](API_C_NamePlateManager.SetNamePlateHitTestInsets.md "API C NamePlateManager.SetNamePlateHitTestInsets")  [C\_NamePlateManager.SetNamePlateSimplified](API_C_NamePlateManager.SetNamePlateSimplified.md "API C NamePlateManager.SetNamePlateSimplified")  [C\_NeighborhoodInitiative.AddTrackedInitiativeTask](API_C_NeighborhoodInitiative.AddTrackedInitiativeTask.md "API C NeighborhoodInitiative.AddTrackedInitiativeTask")  [C\_NeighborhoodInitiative.GetActiveNeighborhood](API_C_NeighborhoodInitiative.GetActiveNeighborhood.md "API C NeighborhoodInitiative.GetActiveNeighborhood")  [C\_NeighborhoodInitiative.GetInitiativeActivityLogInfo](API_C_NeighborhoodInitiative.GetInitiativeActivityLogInfo.md "API C NeighborhoodInitiative.GetInitiativeActivityLogInfo")  [C\_NeighborhoodInitiative.GetInitiativeTaskChatLink](API_C_NeighborhoodInitiative.GetInitiativeTaskChatLink.md "API C NeighborhoodInitiative.GetInitiativeTaskChatLink")  [C\_NeighborhoodInitiative.GetInitiativeTaskInfo](API_C_NeighborhoodInitiative.GetInitiativeTaskInfo.md "API C NeighborhoodInitiative.GetInitiativeTaskInfo")  [C\_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo](API_C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo.md "API C NeighborhoodInitiative.GetNeighborhoodInitiativeInfo")  [C\_NeighborhoodInitiative.GetRequiredLevel](API_C_NeighborhoodInitiative.GetRequiredLevel.md "API C NeighborhoodInitiative.GetRequiredLevel")  [C\_NeighborhoodInitiative.GetTrackedInitiativeTasks](API_C_NeighborhoodInitiative.GetTrackedInitiativeTasks.md "API C NeighborhoodInitiative.GetTrackedInitiativeTasks")  [C\_NeighborhoodInitiative.IsInitiativeEnabled](API_C_NeighborhoodInitiative.IsInitiativeEnabled.md "API C NeighborhoodInitiative.IsInitiativeEnabled")  [C\_NeighborhoodInitiative.IsPlayerInNeighborhoodGroup](API_C_NeighborhoodInitiative.IsPlayerInNeighborhoodGroup.md "API C NeighborhoodInitiative.IsPlayerInNeighborhoodGroup")  [C\_NeighborhoodInitiative.IsViewingActiveNeighborhood](API_C_NeighborhoodInitiative.IsViewingActiveNeighborhood.md "API C NeighborhoodInitiative.IsViewingActiveNeighborhood")  [C\_NeighborhoodInitiative.PlayerHasInitiativeAccess](API_C_NeighborhoodInitiative.PlayerHasInitiativeAccess.md "API C NeighborhoodInitiative.PlayerHasInitiativeAccess")  [C\_NeighborhoodInitiative.PlayerMeetsRequiredLevel](API_C_NeighborhoodInitiative.PlayerMeetsRequiredLevel.md "API C NeighborhoodInitiative.PlayerMeetsRequiredLevel")  [C\_NeighborhoodInitiative.RemoveTrackedInitiativeTask](API_C_NeighborhoodInitiative.RemoveTrackedInitiativeTask.md "API C NeighborhoodInitiative.RemoveTrackedInitiativeTask")  [C\_NeighborhoodInitiative.RequestInitiativeActivityLog](API_C_NeighborhoodInitiative.RequestInitiativeActivityLog.md "API C NeighborhoodInitiative.RequestInitiativeActivityLog")  [C\_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo](API_C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo.md "API C NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo")  [C\_NeighborhoodInitiative.SetActiveNeighborhood](API_C_NeighborhoodInitiative.SetActiveNeighborhood.md "API C NeighborhoodInitiative.SetActiveNeighborhood")  [C\_NeighborhoodInitiative.SetViewingNeighborhood](API_C_NeighborhoodInitiative.SetViewingNeighborhood.md "API C NeighborhoodInitiative.SetViewingNeighborhood")  [C\_Ping.IsPingSystemEnabled](API_C_Ping.IsPingSystemEnabled.md "API C Ping.IsPingSystemEnabled")  [C\_PvP.AreTrainingGroundsEnabled](API_C_PvP.AreTrainingGroundsEnabled.md "API C PvP.AreTrainingGroundsEnabled")  [C\_PvP.CanPlayerUseTrainingGroundsUI](API_C_PvP.CanPlayerUseTrainingGroundsUI.md "API C PvP.CanPlayerUseTrainingGroundsUI")  [C\_PvP.GetBattlegroundInfo](API_C_PvP.GetBattlegroundInfo.md "API C PvP.GetBattlegroundInfo")  [C\_PvP.GetRandomTrainingGroundRewards](API_C_PvP.GetRandomTrainingGroundRewards.md "API C PvP.GetRandomTrainingGroundRewards")  [C\_PvP.GetTrainingGrounds](API_C_PvP.GetTrainingGrounds.md "API C PvP.GetTrainingGrounds")  [C\_PvP.HasMatchStarted](API_C_PvP.HasMatchStarted.md "API C PvP.HasMatchStarted")  [C\_PvP.HasRandomTrainingGroundWinToday](API_C_PvP.HasRandomTrainingGroundWinToday.md "API C PvP.HasRandomTrainingGroundWinToday")  [C\_PvP.JoinRandomTrainingGround](API_C_PvP.JoinRandomTrainingGround.md "API C PvP.JoinRandomTrainingGround")  [C\_PvP.JoinTrainingGround](API_C_PvP.JoinTrainingGround.md "API C PvP.JoinTrainingGround")  [C\_QuestInfoSystem.GetQuestLogRewardFavor](API_C_QuestInfoSystem.GetQuestLogRewardFavor.md "API C QuestInfoSystem.GetQuestLogRewardFavor")  [C\_QuestLog.GetActivePreyQuest](API_C_QuestLog.GetActivePreyQuest.md "API C QuestLog.GetActivePreyQuest")  [C\_Reputation.IsFactionParagonForCurrentPlayer](API_C_Reputation.IsFactionParagonForCurrentPlayer.md "API C Reputation.IsFactionParagonForCurrentPlayer")  [C\_RestrictedActions.CheckAllowProtectedFunctions](API_C_RestrictedActions.CheckAllowProtectedFunctions.md "API C RestrictedActions.CheckAllowProtectedFunctions")  [C\_RestrictedActions.GetAddOnRestrictionState](API_C_RestrictedActions.GetAddOnRestrictionState.md "API C RestrictedActions.GetAddOnRestrictionState")  [C\_RestrictedActions.IsAddOnRestrictionActive](API_C_RestrictedActions.IsAddOnRestrictionActive.md "API C RestrictedActions.IsAddOnRestrictionActive")  [C\_Secrets.GetPowerTypeSecrecy](API_C_Secrets.GetPowerTypeSecrecy.md "API C Secrets.GetPowerTypeSecrecy")  [C\_Secrets.GetSpellAuraSecrecy](API_C_Secrets.GetSpellAuraSecrecy.md "API C Secrets.GetSpellAuraSecrecy")  [C\_Secrets.GetSpellCastSecrecy](API_C_Secrets.GetSpellCastSecrecy.md "API C Secrets.GetSpellCastSecrecy")  [C\_Secrets.GetSpellCooldownSecrecy](API_C_Secrets.GetSpellCooldownSecrecy.md "API C Secrets.GetSpellCooldownSecrecy")  [C\_Secrets.HasSecretRestrictions](API_C_Secrets.HasSecretRestrictions.md "API C Secrets.HasSecretRestrictions")  [C\_Secrets.ShouldActionCooldownBeSecret](API_C_Secrets.ShouldActionCooldownBeSecret.md "API C Secrets.ShouldActionCooldownBeSecret")  [C\_Secrets.ShouldAurasBeSecret](API_C_Secrets.ShouldAurasBeSecret.md "API C Secrets.ShouldAurasBeSecret")  [C\_Secrets.ShouldCooldownsBeSecret](API_C_Secrets.ShouldCooldownsBeSecret.md "API C Secrets.ShouldCooldownsBeSecret")  [C\_Secrets.ShouldSpellAuraBeSecret](API_C_Secrets.ShouldSpellAuraBeSecret.md "API C Secrets.ShouldSpellAuraBeSecret")  [C\_Secrets.ShouldSpellBookItemCooldownBeSecret](API_C_Secrets.ShouldSpellBookItemCooldownBeSecret.md "API C Secrets.ShouldSpellBookItemCooldownBeSecret")  [C\_Secrets.ShouldSpellCooldownBeSecret](API_C_Secrets.ShouldSpellCooldownBeSecret.md "API C Secrets.ShouldSpellCooldownBeSecret")  [C\_Secrets.ShouldTotemSlotBeSecret](API_C_Secrets.ShouldTotemSlotBeSecret.md "API C Secrets.ShouldTotemSlotBeSecret")  [C\_Secrets.ShouldTotemSpellBeSecret](API_C_Secrets.ShouldTotemSpellBeSecret.md "API C Secrets.ShouldTotemSpellBeSecret")  [C\_Secrets.ShouldUnitAuraIndexBeSecret](API_C_Secrets.ShouldUnitAuraIndexBeSecret.md "API C Secrets.ShouldUnitAuraIndexBeSecret")  [C\_Secrets.ShouldUnitAuraInstanceBeSecret](API_C_Secrets.ShouldUnitAuraInstanceBeSecret.md "API C Secrets.ShouldUnitAuraInstanceBeSecret")  [C\_Secrets.ShouldUnitAuraSlotBeSecret](API_C_Secrets.ShouldUnitAuraSlotBeSecret.md "API C Secrets.ShouldUnitAuraSlotBeSecret")  [C\_Secrets.ShouldUnitComparisonBeSecret](API_C_Secrets.ShouldUnitComparisonBeSecret.md "API C Secrets.ShouldUnitComparisonBeSecret")  [C\_Secrets.ShouldUnitHealthMaxBeSecret](API_C_Secrets.ShouldUnitHealthMaxBeSecret.md "API C Secrets.ShouldUnitHealthMaxBeSecret")  [C\_Secrets.ShouldUnitIdentityBeSecret](API_C_Secrets.ShouldUnitIdentityBeSecret.md "API C Secrets.ShouldUnitIdentityBeSecret")  [C\_Secrets.ShouldUnitPowerBeSecret](API_C_Secrets.ShouldUnitPowerBeSecret.md "API C Secrets.ShouldUnitPowerBeSecret")  [C\_Secrets.ShouldUnitPowerMaxBeSecret](API_C_Secrets.ShouldUnitPowerMaxBeSecret.md "API C Secrets.ShouldUnitPowerMaxBeSecret")  [C\_Secrets.ShouldUnitSpellCastBeSecret](API_C_Secrets.ShouldUnitSpellCastBeSecret.md "API C Secrets.ShouldUnitSpellCastBeSecret")  [C\_Secrets.ShouldUnitSpellCastingBeSecret](API_C_Secrets.ShouldUnitSpellCastingBeSecret.md "API C Secrets.ShouldUnitSpellCastingBeSecret")  [C\_SettingsUtil.NotifySettingsLoaded](API_C_SettingsUtil.NotifySettingsLoaded.md "API C SettingsUtil.NotifySettingsLoaded")  [C\_SettingsUtil.OpenSettingsPanel](API_C_SettingsUtil.OpenSettingsPanel.md "API C SettingsUtil.OpenSettingsPanel")  [C\_Sound.PlaySound](API_C_Sound.PlaySound.md "API C Sound.PlaySound")  [C\_Spell.GetSpellChargeDuration](API_C_Spell.GetSpellChargeDuration.md "API C Spell.GetSpellChargeDuration")  [C\_Spell.GetSpellCooldownDuration](API_C_Spell.GetSpellCooldownDuration.md "API C Spell.GetSpellCooldownDuration")  [C\_Spell.GetSpellDisplayCount](API_C_Spell.GetSpellDisplayCount.md "API C Spell.GetSpellDisplayCount")  [C\_Spell.GetSpellLossOfControlCooldownDuration](API_C_Spell.GetSpellLossOfControlCooldownDuration.md "API C Spell.GetSpellLossOfControlCooldownDuration")  [C\_Spell.GetSpellMaxCumulativeAuraApplications](API_C_Spell.GetSpellMaxCumulativeAuraApplications.md "API C Spell.GetSpellMaxCumulativeAuraApplications")  [C\_Spell.GetVisibilityInfo](API_C_Spell.GetVisibilityInfo.md "API C Spell.GetVisibilityInfo")  [C\_Spell.IsConsumableSpell](API_C_Spell.IsConsumableSpell.md "API C Spell.IsConsumableSpell")  [C\_Spell.IsExternalDefensive](API_C_Spell.IsExternalDefensive.md "API C Spell.IsExternalDefensive")  [C\_Spell.IsPriorityAura](API_C_Spell.IsPriorityAura.md "API C Spell.IsPriorityAura")  [C\_Spell.IsSelfBuff](API_C_Spell.IsSelfBuff.md "API C Spell.IsSelfBuff")  [C\_Spell.IsSpellCrowdControl](API_C_Spell.IsSpellCrowdControl.md "API C Spell.IsSpellCrowdControl")  [C\_Spell.IsSpellImportant](API_C_Spell.IsSpellImportant.md "API C Spell.IsSpellImportant")  [C\_SpellBook.FindBaseSpellByID](API_C_SpellBook.FindBaseSpellByID.md "API C SpellBook.FindBaseSpellByID")  [C\_SpellBook.FindFlyoutSlotBySpellID](API_C_SpellBook.FindFlyoutSlotBySpellID.md "API C SpellBook.FindFlyoutSlotBySpellID")  [C\_SpellBook.FindSpellOverrideByID](API_C_SpellBook.FindSpellOverrideByID.md "API C SpellBook.FindSpellOverrideByID")  [C\_SpellBook.GetSpellBookItemChargeDuration](API_C_SpellBook.GetSpellBookItemChargeDuration.md "API C SpellBook.GetSpellBookItemChargeDuration")  [C\_SpellBook.GetSpellBookItemCooldownDuration](API_C_SpellBook.GetSpellBookItemCooldownDuration.md "API C SpellBook.GetSpellBookItemCooldownDuration")  [C\_SpellBook.GetSpellBookItemLossOfControlCooldownDuration](API_C_SpellBook.GetSpellBookItemLossOfControlCooldownDuration.md "API C SpellBook.GetSpellBookItemLossOfControlCooldownDuration")  [C\_SpellDiminish.GetAllSpellDiminishCategories](API_C_SpellDiminish.GetAllSpellDiminishCategories.md "API C SpellDiminish.GetAllSpellDiminishCategories")  [C\_SpellDiminish.GetSpellDiminishCategoryInfo](API_C_SpellDiminish.GetSpellDiminishCategoryInfo.md "API C SpellDiminish.GetSpellDiminishCategoryInfo")  [C\_SpellDiminish.IsSystemSupported](API_C_SpellDiminish.IsSystemSupported.md "API C SpellDiminish.IsSystemSupported")  [C\_SpellDiminish.ShouldTrackSpellDiminishCategory](API_C_SpellDiminish.ShouldTrackSpellDiminishCategory.md "API C SpellDiminish.ShouldTrackSpellDiminishCategory")  [C\_StableInfo.IsBonusPetSlotAvailable](API_C_StableInfo.IsBonusPetSlotAvailable.md "API C StableInfo.IsBonusPetSlotAvailable")  [C\_StringUtil.EscapeLuaFormatString](API_C_StringUtil.EscapeLuaFormatString.md "API C StringUtil.EscapeLuaFormatString")  [C\_StringUtil.EscapeLuaPatterns](API_C_StringUtil.EscapeLuaPatterns.md "API C StringUtil.EscapeLuaPatterns")  [C\_StringUtil.EscapeQuotedCodes](API_C_StringUtil.EscapeQuotedCodes.md "API C StringUtil.EscapeQuotedCodes")  [C\_StringUtil.FloorToNearestString](API_C_StringUtil.FloorToNearestString.md "API C StringUtil.FloorToNearestString")  [C\_StringUtil.RemoveContiguousSpaces](API_C_StringUtil.RemoveContiguousSpaces.md "API C StringUtil.RemoveContiguousSpaces")  [C\_StringUtil.RoundToNearestString](API_C_StringUtil.RoundToNearestString.md "API C StringUtil.RoundToNearestString")  [C\_StringUtil.StripHyperlinks](API_C_StringUtil.StripHyperlinks.md "API C StringUtil.StripHyperlinks")  [C\_StringUtil.TruncateWhenZero](API_C_StringUtil.TruncateWhenZero.md "API C StringUtil.TruncateWhenZero")  [C\_StringUtil.WrapString](API_C_StringUtil.WrapString.md "API C StringUtil.WrapString")  [C\_TaskQuest.GetQuestUIWidgetSetByType](API_C_TaskQuest.GetQuestUIWidgetSetByType.md "API C TaskQuest.GetQuestUIWidgetSetByType")  [C\_TooltipComparison.CompareItem](API_C_TooltipComparison.CompareItem.md "API C TooltipComparison.CompareItem")  [C\_TooltipInfo.GetOutfit](API_C_TooltipInfo.GetOutfit.md "API C TooltipInfo.GetOutfit")  [C\_TooltipInfo.GetUnitAuraByAuraInstanceID](API_C_TooltipInfo.GetUnitAuraByAuraInstanceID.md "API C TooltipInfo.GetUnitAuraByAuraInstanceID")  [C\_TradeSkillUI.GetDependentReagents](API_C_TradeSkillUI.GetDependentReagents.md "API C TradeSkillUI.GetDependentReagents")  [C\_TradeSkillUI.GetItemCraftedQualityInfo](API_C_TradeSkillUI.GetItemCraftedQualityInfo.md "API C TradeSkillUI.GetItemCraftedQualityInfo")  [C\_TradeSkillUI.GetItemReagentQualityInfo](API_C_TradeSkillUI.GetItemReagentQualityInfo.md "API C TradeSkillUI.GetItemReagentQualityInfo")  [C\_TradeSkillUI.GetRecipeItemQualityInfo](API_C_TradeSkillUI.GetRecipeItemQualityInfo.md "API C TradeSkillUI.GetRecipeItemQualityInfo")  [C\_TradeSkillUI.GetRecipeQualityReagentLink](API_C_TradeSkillUI.GetRecipeQualityReagentLink.md "API C TradeSkillUI.GetRecipeQualityReagentLink")  [C\_TransmogCollection.DeleteCustomSet](API_C_TransmogCollection.DeleteCustomSet.md "API C TransmogCollection.DeleteCustomSet")  [C\_TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList](API_C_TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList.md "API C TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList")  [C\_TransmogCollection.GetCustomSetInfo](API_C_TransmogCollection.GetCustomSetInfo.md "API C TransmogCollection.GetCustomSetInfo")  [C\_TransmogCollection.GetCustomSetItemTransmogInfoList](API_C_TransmogCollection.GetCustomSetItemTransmogInfoList.md "API C TransmogCollection.GetCustomSetItemTransmogInfoList")  [C\_TransmogCollection.GetCustomSets](API_C_TransmogCollection.GetCustomSets.md "API C TransmogCollection.GetCustomSets")  [C\_TransmogCollection.GetItemTransmogInfoListFromCustomSetHyperlink](API_C_TransmogCollection.GetItemTransmogInfoListFromCustomSetHyperlink.md "API C TransmogCollection.GetItemTransmogInfoListFromCustomSetHyperlink")  [C\_TransmogCollection.GetNumMaxCustomSets](API_C_TransmogCollection.GetNumMaxCustomSets.md "API C TransmogCollection.GetNumMaxCustomSets")  [C\_TransmogCollection.IsValidCustomSetName](API_C_TransmogCollection.IsValidCustomSetName.md "API C TransmogCollection.IsValidCustomSetName")  [C\_TransmogCollection.IsValidTransmogSource](API_C_TransmogCollection.IsValidTransmogSource.md "API C TransmogCollection.IsValidTransmogSource")  [C\_TransmogCollection.ModifyCustomSet](API_C_TransmogCollection.ModifyCustomSet.md "API C TransmogCollection.ModifyCustomSet")  [C\_TransmogCollection.NewCustomSet](API_C_TransmogCollection.NewCustomSet.md "API C TransmogCollection.NewCustomSet")  [C\_TransmogCollection.RenameCustomSet](API_C_TransmogCollection.RenameCustomSet.md "API C TransmogCollection.RenameCustomSet")  [C\_TransmogOutfitInfo.AddNewOutfit](API_C_TransmogOutfitInfo.AddNewOutfit.md "API C TransmogOutfitInfo.AddNewOutfit")  [C\_TransmogOutfitInfo.ChangeDisplayedOutfit](API_C_TransmogOutfitInfo.ChangeDisplayedOutfit.md "API C TransmogOutfitInfo.ChangeDisplayedOutfit")  [C\_TransmogOutfitInfo.ChangeViewedOutfit](API_C_TransmogOutfitInfo.ChangeViewedOutfit.md "API C TransmogOutfitInfo.ChangeViewedOutfit")  [C\_TransmogOutfitInfo.ClearAllPendingSituations](API_C_TransmogOutfitInfo.ClearAllPendingSituations.md "API C TransmogOutfitInfo.ClearAllPendingSituations")  [C\_TransmogOutfitInfo.ClearAllPendingTransmogs](API_C_TransmogOutfitInfo.ClearAllPendingTransmogs.md "API C TransmogOutfitInfo.ClearAllPendingTransmogs")  [C\_TransmogOutfitInfo.ClearDisplayedOutfit](API_C_TransmogOutfitInfo.ClearDisplayedOutfit.md "API C TransmogOutfitInfo.ClearDisplayedOutfit")  [C\_TransmogOutfitInfo.CommitAndApplyAllPending](API_C_TransmogOutfitInfo.CommitAndApplyAllPending.md "API C TransmogOutfitInfo.CommitAndApplyAllPending")  [C\_TransmogOutfitInfo.CommitOutfitInfo](API_C_TransmogOutfitInfo.CommitOutfitInfo.md "API C TransmogOutfitInfo.CommitOutfitInfo")  [C\_TransmogOutfitInfo.CommitPendingSituations](API_C_TransmogOutfitInfo.CommitPendingSituations.md "API C TransmogOutfitInfo.CommitPendingSituations")  [C\_TransmogOutfitInfo.GetActiveOutfitID](API_C_TransmogOutfitInfo.GetActiveOutfitID.md "API C TransmogOutfitInfo.GetActiveOutfitID")  [C\_TransmogOutfitInfo.GetAllSlotLocationInfo](API_C_TransmogOutfitInfo.GetAllSlotLocationInfo.md "API C TransmogOutfitInfo.GetAllSlotLocationInfo")  [C\_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption](API_C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption.md "API C TransmogOutfitInfo.GetCollectionInfoForSlotAndOption")  [C\_TransmogOutfitInfo.GetCurrentlyViewedOutfitID](API_C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID.md "API C TransmogOutfitInfo.GetCurrentlyViewedOutfitID")  [C\_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot](API_C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot.md "API C TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot")  [C\_TransmogOutfitInfo.GetIllusionDefaultIMAIDForCollectionType](API_C_TransmogOutfitInfo.GetIllusionDefaultIMAIDForCollectionType.md "API C TransmogOutfitInfo.GetIllusionDefaultIMAIDForCollectionType")  [C\_TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory](API_C_TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory.md "API C TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory")  [C\_TransmogOutfitInfo.GetLinkedSlotInfo](API_C_TransmogOutfitInfo.GetLinkedSlotInfo.md "API C TransmogOutfitInfo.GetLinkedSlotInfo")  [C\_TransmogOutfitInfo.GetMaxNumberOfTotalOutfitsForSource](API_C_TransmogOutfitInfo.GetMaxNumberOfTotalOutfitsForSource.md "API C TransmogOutfitInfo.GetMaxNumberOfTotalOutfitsForSource")  [C\_TransmogOutfitInfo.GetMaxNumberOfUsableOutfits](API_C_TransmogOutfitInfo.GetMaxNumberOfUsableOutfits.md "API C TransmogOutfitInfo.GetMaxNumberOfUsableOutfits")  [C\_TransmogOutfitInfo.GetNextOutfitCost](API_C_TransmogOutfitInfo.GetNextOutfitCost.md "API C TransmogOutfitInfo.GetNextOutfitCost")  [C\_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource](API_C_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource.md "API C TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource")  [C\_TransmogOutfitInfo.GetOutfitInfo](API_C_TransmogOutfitInfo.GetOutfitInfo.md "API C TransmogOutfitInfo.GetOutfitInfo")  [C\_TransmogOutfitInfo.GetOutfitSituationsEnabled](API_C_TransmogOutfitInfo.GetOutfitSituationsEnabled.md "API C TransmogOutfitInfo.GetOutfitSituationsEnabled")  [C\_TransmogOutfitInfo.GetOutfitSituation](API_C_TransmogOutfitInfo.GetOutfitSituation.md "API C TransmogOutfitInfo.GetOutfitSituation")  [C\_TransmogOutfitInfo.GetOutfitsInfo](API_C_TransmogOutfitInfo.GetOutfitsInfo.md "API C TransmogOutfitInfo.GetOutfitsInfo")  [C\_TransmogOutfitInfo.GetPendingTransmogCost](API_C_TransmogOutfitInfo.GetPendingTransmogCost.md "API C TransmogOutfitInfo.GetPendingTransmogCost")  [C\_TransmogOutfitInfo.GetSecondarySlotState](API_C_TransmogOutfitInfo.GetSecondarySlotState.md "API C TransmogOutfitInfo.GetSecondarySlotState")  [C\_TransmogOutfitInfo.GetSetSourcesForSlot](API_C_TransmogOutfitInfo.GetSetSourcesForSlot.md "API C TransmogOutfitInfo.GetSetSourcesForSlot")  [C\_TransmogOutfitInfo.GetSlotGroupInfo](API_C_TransmogOutfitInfo.GetSlotGroupInfo.md "API C TransmogOutfitInfo.GetSlotGroupInfo")  [C\_TransmogOutfitInfo.GetSourceIDsForSlot](API_C_TransmogOutfitInfo.GetSourceIDsForSlot.md "API C TransmogOutfitInfo.GetSourceIDsForSlot")  [C\_TransmogOutfitInfo.GetTransmogOutfitSlotForInventoryType](API_C_TransmogOutfitInfo.GetTransmogOutfitSlotForInventoryType.md "API C TransmogOutfitInfo.GetTransmogOutfitSlotForInventoryType")  [C\_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot](API_C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot.md "API C TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot")  [C\_TransmogOutfitInfo.GetUISituationCategoriesAndOptions](API_C_TransmogOutfitInfo.GetUISituationCategoriesAndOptions.md "API C TransmogOutfitInfo.GetUISituationCategoriesAndOptions")  [C\_TransmogOutfitInfo.GetUnassignedAtlasForSlot](API_C_TransmogOutfitInfo.GetUnassignedAtlasForSlot.md "API C TransmogOutfitInfo.GetUnassignedAtlasForSlot")  [C\_TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot](API_C_TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot.md "API C TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot")  [C\_TransmogOutfitInfo.GetViewedOutfitSlotInfo](API_C_TransmogOutfitInfo.GetViewedOutfitSlotInfo.md "API C TransmogOutfitInfo.GetViewedOutfitSlotInfo")  [C\_TransmogOutfitInfo.GetWeaponOptionsForSlot](API_C_TransmogOutfitInfo.GetWeaponOptionsForSlot.md "API C TransmogOutfitInfo.GetWeaponOptionsForSlot")  [C\_TransmogOutfitInfo.HasPendingOutfitSituations](API_C_TransmogOutfitInfo.HasPendingOutfitSituations.md "API C TransmogOutfitInfo.HasPendingOutfitSituations")  [C\_TransmogOutfitInfo.HasPendingOutfitTransmogs](API_C_TransmogOutfitInfo.HasPendingOutfitTransmogs.md "API C TransmogOutfitInfo.HasPendingOutfitTransmogs")  [C\_TransmogOutfitInfo.IsEquippedGearOutfitDisplayed](API_C_TransmogOutfitInfo.IsEquippedGearOutfitDisplayed.md "API C TransmogOutfitInfo.IsEquippedGearOutfitDisplayed")  [C\_TransmogOutfitInfo.IsEquippedGearOutfitLocked](API_C_TransmogOutfitInfo.IsEquippedGearOutfitLocked.md "API C TransmogOutfitInfo.IsEquippedGearOutfitLocked")  [C\_TransmogOutfitInfo.IsLockedOutfit](API_C_TransmogOutfitInfo.IsLockedOutfit.md "API C TransmogOutfitInfo.IsLockedOutfit")  [C\_TransmogOutfitInfo.IsSlotWeaponSlot](API_C_TransmogOutfitInfo.IsSlotWeaponSlot.md "API C TransmogOutfitInfo.IsSlotWeaponSlot")  [C\_TransmogOutfitInfo.IsValidTransmogOutfitName](API_C_TransmogOutfitInfo.IsValidTransmogOutfitName.md "API C TransmogOutfitInfo.IsValidTransmogOutfitName")  [C\_TransmogOutfitInfo.PickupOutfit](API_C_TransmogOutfitInfo.PickupOutfit.md "API C TransmogOutfitInfo.PickupOutfit")  [C\_TransmogOutfitInfo.ResetOutfitSituations](API_C_TransmogOutfitInfo.ResetOutfitSituations.md "API C TransmogOutfitInfo.ResetOutfitSituations")  [C\_TransmogOutfitInfo.RevertPendingTransmog](API_C_TransmogOutfitInfo.RevertPendingTransmog.md "API C TransmogOutfitInfo.RevertPendingTransmog")  [C\_TransmogOutfitInfo.SetOutfitSituationsEnabled](API_C_TransmogOutfitInfo.SetOutfitSituationsEnabled.md "API C TransmogOutfitInfo.SetOutfitSituationsEnabled")  [C\_TransmogOutfitInfo.SetOutfitToCustomSet](API_C_TransmogOutfitInfo.SetOutfitToCustomSet.md "API C TransmogOutfitInfo.SetOutfitToCustomSet")  [C\_TransmogOutfitInfo.SetOutfitToSet](API_C_TransmogOutfitInfo.SetOutfitToSet.md "API C TransmogOutfitInfo.SetOutfitToSet")  [C\_TransmogOutfitInfo.SetPendingTransmog](API_C_TransmogOutfitInfo.SetPendingTransmog.md "API C TransmogOutfitInfo.SetPendingTransmog")  [C\_TransmogOutfitInfo.SetSecondarySlotState](API_C_TransmogOutfitInfo.SetSecondarySlotState.md "API C TransmogOutfitInfo.SetSecondarySlotState")  [C\_TransmogOutfitInfo.SetViewedWeaponOptionForSlot](API_C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot.md "API C TransmogOutfitInfo.SetViewedWeaponOptionForSlot")  [C\_TransmogOutfitInfo.SlotHasSecondary](API_C_TransmogOutfitInfo.SlotHasSecondary.md "API C TransmogOutfitInfo.SlotHasSecondary")  [C\_TransmogOutfitInfo.UpdatePendingSituation](API_C_TransmogOutfitInfo.UpdatePendingSituation.md "API C TransmogOutfitInfo.UpdatePendingSituation")  [C\_TransmogSets.GetAvailableSets](API_C_TransmogSets.GetAvailableSets.md "API C TransmogSets.GetAvailableSets")  [C\_TransmogSets.GetSetsFilter](API_C_TransmogSets.GetSetsFilter.md "API C TransmogSets.GetSetsFilter")  [C\_TransmogSets.IsUsingDefaultSetsFilters](API_C_TransmogSets.IsUsingDefaultSetsFilters.md "API C TransmogSets.IsUsingDefaultSetsFilters")  [C\_TransmogSets.SetDefaultSetsFilters](API_C_TransmogSets.SetDefaultSetsFilters.md "API C TransmogSets.SetDefaultSetsFilters")  [C\_TransmogSets.SetSetsFilter](API_C_TransmogSets.SetSetsFilter.md "API C TransmogSets.SetSetsFilter")  [C\_Tutorial.GetCombatEventInfo](API_C_Tutorial.GetCombatEventInfo.md "API C Tutorial.GetCombatEventInfo")  [C\_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo](API_C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo.md "API C UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo")  [C\_UnitAuras.AuraIsBigDefensive](API_C_UnitAuras.AuraIsBigDefensive.md "API C UnitAuras.AuraIsBigDefensive")  [C\_UnitAuras.DoesAuraHaveExpirationTime](API_C_UnitAuras.DoesAuraHaveExpirationTime.md "API C UnitAuras.DoesAuraHaveExpirationTime")  [C\_UnitAuras.GetAuraApplicationDisplayCount](API_C_UnitAuras.GetAuraApplicationDisplayCount.md "API C UnitAuras.GetAuraApplicationDisplayCount")  [C\_UnitAuras.GetAuraBaseDuration](API_C_UnitAuras.GetAuraBaseDuration.md "API C UnitAuras.GetAuraBaseDuration")  [C\_UnitAuras.GetAuraDispelTypeColor](API_C_UnitAuras.GetAuraDispelTypeColor.md "API C UnitAuras.GetAuraDispelTypeColor")  [C\_UnitAuras.GetAuraDuration](API_C_UnitAuras.GetAuraDuration.md "API C UnitAuras.GetAuraDuration")  [C\_UnitAuras.GetRefreshExtendedDuration](API_C_UnitAuras.GetRefreshExtendedDuration.md "API C UnitAuras.GetRefreshExtendedDuration")  [C\_UnitAuras.GetUnitAuraInstanceIDs](API_C_UnitAuras.GetUnitAuraInstanceIDs.md "API C UnitAuras.GetUnitAuraInstanceIDs")  [C\_UnitAuras.TriggerPrivateAuraShowDispelType](API_C_UnitAuras.TriggerPrivateAuraShowDispelType.md "API C UnitAuras.TriggerPrivateAuraShowDispelType")  [C\_WeeklyRewards.GetSortedProgressForActivity](API_C_WeeklyRewards.GetSortedProgressForActivity.md "API C WeeklyRewards.GetSortedProgressForActivity")  [CreateAbbreviateConfig](API_CreateAbbreviateConfig.md "API CreateAbbreviateConfig")  [CreateUnitHealPredictionCalculator](API_CreateUnitHealPredictionCalculator.md "API CreateUnitHealPredictionCalculator")  [GetCollapsingStarCost](API_GetCollapsingStarCost.md "API GetCollapsingStarCost")  [IsRaidMarkerSystemEnabled](API_IsRaidMarkerSystemEnabled.md "API IsRaidMarkerSystemEnabled")  [RegisterEventCallback](API_RegisterEventCallback.md "API RegisterEventCallback")  [RegisterUnitEventCallback](API_RegisterUnitEventCallback.md "API RegisterUnitEventCallback")  [SetCursorPosition](API_SetCursorPosition.md "API SetCursorPosition")  [SetTableSecurityOption](API_SetTableSecurityOption.md "API SetTableSecurityOption")  [ShowCloak](API_ShowCloak.md "API ShowCloak")  [ShowHelm](API_ShowHelm.md "API ShowHelm")  [ShowingCloak](API_ShowingCloak.md "API ShowingCloak")  [ShowingHelm](API_ShowingHelm.md "API ShowingHelm")  [SimulateMouseClick](API_SimulateMouseClick.md "API SimulateMouseClick")  [SimulateMouseDown](API_SimulateMouseDown.md "API SimulateMouseDown")  [SimulateMouseUp](API_SimulateMouseUp.md "API SimulateMouseUp")  [SimulateMouseWheel](API_SimulateMouseWheel.md "API SimulateMouseWheel")  [UnitCastingDuration](API_UnitCastingDuration.md "API UnitCastingDuration")  [UnitChannelDuration](API_UnitChannelDuration.md "API UnitChannelDuration")  [UnitClassFromGUID](API_UnitClassFromGUID.md "API UnitClassFromGUID")  [UnitCreatureID](API_UnitCreatureID.md "API UnitCreatureID")  [UnitEmpoweredChannelDuration](API_UnitEmpoweredChannelDuration.md "API UnitEmpoweredChannelDuration")  [UnitEmpoweredStageDurations](API_UnitEmpoweredStageDurations.md "API UnitEmpoweredStageDurations")  [UnitEmpoweredStagePercentages](API_UnitEmpoweredStagePercentages.md "API UnitEmpoweredStagePercentages")  [UnitGetDetailedHealPrediction](API_UnitGetDetailedHealPrediction.md "API UnitGetDetailedHealPrediction")  [UnitHealthMissing](API_UnitHealthMissing.md "API UnitHealthMissing")  [UnitHealthPercent](API_UnitHealthPercent.md "API UnitHealthPercent")  [UnitIsHumanPlayer](API_UnitIsHumanPlayer.md "API UnitIsHumanPlayer")  [UnitIsLieutenant](API_UnitIsLieutenant.md "API UnitIsLieutenant")  [UnitIsMinion](API_UnitIsMinion.md "API UnitIsMinion")  [UnitIsNPCAsPlayer](API_UnitIsNPCAsPlayer.md "API UnitIsNPCAsPlayer")  [UnitIsSpellTarget](API_UnitIsSpellTarget.md "API UnitIsSpellTarget")  [UnitNameFromGUID](API_UnitNameFromGUID.md "API UnitNameFromGUID")  [UnitPowerMissing](API_UnitPowerMissing.md "API UnitPowerMissing")  [UnitPowerPercent](API_UnitPowerPercent.md "API UnitPowerPercent")  [UnitSexBase](API_UnitSexBase.md "API UnitSexBase")  [UnitShouldDisplaySpellTargetName](API_UnitShouldDisplaySpellTargetName.md "API UnitShouldDisplaySpellTargetName")  [UnitSpellTargetClass](API_UnitSpellTargetClass.md "API UnitSpellTargetClass")  [UnitSpellTargetName](API_UnitSpellTargetName.md "API UnitSpellTargetName")  [UnitThreatLeadSituation](API_UnitThreatLeadSituation.md "API UnitThreatLeadSituation")  [UnregisterEventCallback](API_UnregisterEventCallback.md "API UnregisterEventCallback")  [UnregisterUnitEventCallback](API_UnregisterUnitEventCallback.md "API UnregisterUnitEventCallback")  [canaccessallvalues](API_canaccessallvalues.md "API canaccessallvalues")  [canaccesssecrets](API_canaccesssecrets.md "API canaccesssecrets")  [canaccesstable](API_canaccesstable.md "API canaccesstable")  [canaccessvalue](API_canaccessvalue.md "API canaccessvalue")  [dropsecretaccess](API_dropsecretaccess.md "API dropsecretaccess")  [hasanysecretvalues](API_hasanysecretvalues.md "API hasanysecretvalues")  [issecrettable](API_issecrettable.md "API issecrettable")  [issecretvalue](API_issecretvalue.md "API issecretvalue")  [mapvalues](API_mapvalues.md "API mapvalues")  [scrubsecretvalues](API_scrubsecretvalues.md "API scrubsecretvalues")  [secretwrap](API_secretwrap.md "API secretwrap")  [securecallmethod](API_securecallmethod.md "API securecallmethod")  [string.concat](API_string.concat.md "API string.concat") | [ActionHasRange](API_ActionHasRange.md "API ActionHasRange")  [BNSendGameData](API_BNSendGameData.md "API BNSendGameData")  [BNSendWhisper](API_BNSendWhisper.md "API BNSendWhisper")  [BNSetCustomMessage](API_BNSetCustomMessage.md "API BNSetCustomMessage")  [C\_CatalogShop.OpenCatalogShopInteraction](API_C_CatalogShop.OpenCatalogShopInteraction.md "API C CatalogShop.OpenCatalogShopInteraction")  [C\_EventUtils.NotifySettingsLoaded](API_C_EventUtils.NotifySettingsLoaded.md "API C EventUtils.NotifySettingsLoaded")  [C\_HouseExterior.GetCurrentHouseExteriorTypeName](API_C_HouseExterior.GetCurrentHouseExteriorTypeName.md "API C HouseExterior.GetCurrentHouseExteriorTypeName")  [C\_HousingBasicMode.IsNudgeEnabled](API_C_HousingBasicMode.IsNudgeEnabled.md "API C HousingBasicMode.IsNudgeEnabled")  [C\_HousingBasicMode.SetNudgeEnabled](API_C_HousingBasicMode.SetNudgeEnabled.md "API C HousingBasicMode.SetNudgeEnabled")  [C\_HousingDecor.GetMaxDecorPlaced](API_C_HousingDecor.GetMaxDecorPlaced.md "API C HousingDecor.GetMaxDecorPlaced")  [C\_NamePlate.GetNamePlateEnemyClickThrough](API_C_NamePlate.GetNamePlateEnemyClickThrough.md "API C NamePlate.GetNamePlateEnemyClickThrough (page does not exist)")  [C\_NamePlate.GetNamePlateEnemyPreferredClickInsets](API_C_NamePlate.GetNamePlateEnemyPreferredClickInsets.md "API C NamePlate.GetNamePlateEnemyPreferredClickInsets (page does not exist)")  [C\_NamePlate.GetNamePlateEnemySize](API_C_NamePlate.GetNamePlateEnemySize.md "API C NamePlate.GetNamePlateEnemySize (page does not exist)")  [C\_NamePlate.GetNamePlateFriendlyClickThrough](API_C_NamePlate.GetNamePlateFriendlyClickThrough.md "API C NamePlate.GetNamePlateFriendlyClickThrough (page does not exist)")  [C\_NamePlate.GetNamePlateFriendlyPreferredClickInsets](API_C_NamePlate.GetNamePlateFriendlyPreferredClickInsets.md "API C NamePlate.GetNamePlateFriendlyPreferredClickInsets (page does not exist)")  [C\_NamePlate.GetNamePlateFriendlySize](API_C_NamePlate.GetNamePlateFriendlySize.md "API C NamePlate.GetNamePlateFriendlySize (page does not exist)")  [C\_NamePlate.GetNamePlateSelfClickThrough](API_C_NamePlate.GetNamePlateSelfClickThrough.md "API C NamePlate.GetNamePlateSelfClickThrough (page does not exist)")  [C\_NamePlate.GetNamePlateSelfPreferredClickInsets](API_C_NamePlate.GetNamePlateSelfPreferredClickInsets.md "API C NamePlate.GetNamePlateSelfPreferredClickInsets (page does not exist)")  [C\_NamePlate.GetNamePlateSelfSize](API_C_NamePlate.GetNamePlateSelfSize.md "API C NamePlate.GetNamePlateSelfSize (page does not exist)")  [C\_NamePlate.GetNumNamePlateMotionTypes](API_C_NamePlate.GetNumNamePlateMotionTypes.md "API C NamePlate.GetNumNamePlateMotionTypes (page does not exist)")  [C\_NamePlate.SetNamePlateEnemyClickThrough](API_C_NamePlate.SetNamePlateEnemyClickThrough.md "API C NamePlate.SetNamePlateEnemyClickThrough")  [C\_NamePlate.SetNamePlateEnemyPreferredClickInsets](API_C_NamePlate.SetNamePlateEnemyPreferredClickInsets.md "API C NamePlate.SetNamePlateEnemyPreferredClickInsets")  [C\_NamePlate.SetNamePlateEnemySize](API_C_NamePlate.SetNamePlateEnemySize.md "API C NamePlate.SetNamePlateEnemySize")  [C\_NamePlate.SetNamePlateFriendlyClickThrough](API_C_NamePlate.SetNamePlateFriendlyClickThrough.md "API C NamePlate.SetNamePlateFriendlyClickThrough")  [C\_NamePlate.SetNamePlateFriendlyPreferredClickInsets](API_C_NamePlate.SetNamePlateFriendlyPreferredClickInsets.md "API C NamePlate.SetNamePlateFriendlyPreferredClickInsets")  [C\_NamePlate.SetNamePlateFriendlySize](API_C_NamePlate.SetNamePlateFriendlySize.md "API C NamePlate.SetNamePlateFriendlySize")  [C\_NamePlate.SetNamePlateSelfClickThrough](API_C_NamePlate.SetNamePlateSelfClickThrough.md "API C NamePlate.SetNamePlateSelfClickThrough")  [C\_NamePlate.SetNamePlateSelfPreferredClickInsets](API_C_NamePlate.SetNamePlateSelfPreferredClickInsets.md "API C NamePlate.SetNamePlateSelfPreferredClickInsets")  [C\_NamePlate.SetNamePlateSelfSize](API_C_NamePlate.SetNamePlateSelfSize.md "API C NamePlate.SetNamePlateSelfSize")  [C\_PlayerInfo.CanPlayerUseEventScheduler](API_C_PlayerInfo.CanPlayerUseEventScheduler.md "API C PlayerInfo.CanPlayerUseEventScheduler")  [C\_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer](API_C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer.md "API C PlayerInfo.IsExpansionLandingPageUnlockedForPlayer")  [C\_PvP.CanDisplayDamage](API_C_PvP.CanDisplayDamage.md "API C PvP.CanDisplayDamage")  [C\_PvP.CanDisplayHealing](API_C_PvP.CanDisplayHealing.md "API C PvP.CanDisplayHealing")  [C\_PvP.CanDisplayKillingBlows](API_C_PvP.CanDisplayKillingBlows.md "API C PvP.CanDisplayKillingBlows")  [C\_StorePublic.IsDisabledByParentalControls](API_C_StorePublic.IsDisabledByParentalControls.md "API C StorePublic.IsDisabledByParentalControls")  [C\_TaskQuest.GetQuestIconUIWidgetSet](API_C_TaskQuest.GetQuestIconUIWidgetSet.md "API C TaskQuest.GetQuestIconUIWidgetSet")  [C\_TaskQuest.GetQuestTooltipUIWidgetSet](API_C_TaskQuest.GetQuestTooltipUIWidgetSet.md "API C TaskQuest.GetQuestTooltipUIWidgetSet")  [C\_Texture.GetCraftingReagentQualityChatIcon](API_C_Texture.GetCraftingReagentQualityChatIcon.md "API C Texture.GetCraftingReagentQualityChatIcon")  [C\_TooltipInfo.GetTransmogrifyItem](API_C_TooltipInfo.GetTransmogrifyItem.md "API C TooltipInfo.GetTransmogrifyItem")  [C\_TradeSkillUI.GetReagentRequirementItemIDs](API_C_TradeSkillUI.GetReagentRequirementItemIDs.md "API C TradeSkillUI.GetReagentRequirementItemIDs")  [C\_TradeSkillUI.GetRecipeFixedReagentItemLink](API_C_TradeSkillUI.GetRecipeFixedReagentItemLink.md "API C TradeSkillUI.GetRecipeFixedReagentItemLink")  [C\_TradeSkillUI.GetRecipeQualityReagentItemLink](API_C_TradeSkillUI.GetRecipeQualityReagentItemLink.md "API C TradeSkillUI.GetRecipeQualityReagentItemLink")  [C\_Transmog.ApplyAllPending](API_C_Transmog.ApplyAllPending.md "API C Transmog.ApplyAllPending")  [C\_Transmog.CanTransmogItemWithItem](API_C_Transmog.CanTransmogItemWithItem.md "API C Transmog.CanTransmogItemWithItem")  [C\_Transmog.CanTransmogItem](API_C_Transmog.CanTransmogItem.md "API C Transmog.CanTransmogItem")  [C\_Transmog.ClearAllPending](API_C_Transmog.ClearAllPending.md "API C Transmog.ClearAllPending")  [C\_Transmog.ClearPending](API_C_Transmog.ClearPending.md "API C Transmog.ClearPending")  [C\_Transmog.Close](API_C_Transmog.Close.md "API C Transmog.Close")  [C\_Transmog.GetApplyCost](API_C_Transmog.GetApplyCost.md "API C Transmog.GetApplyCost")  [C\_Transmog.GetApplyWarnings](API_C_Transmog.GetApplyWarnings.md "API C Transmog.GetApplyWarnings")  [C\_Transmog.GetBaseCategory](API_C_Transmog.GetBaseCategory.md "API C Transmog.GetBaseCategory")  [C\_Transmog.GetCreatureDisplayIDForSource](API_C_Transmog.GetCreatureDisplayIDForSource.md "API C Transmog.GetCreatureDisplayIDForSource")  [C\_Transmog.GetPending](API_C_Transmog.GetPending.md "API C Transmog.GetPending")  [C\_Transmog.GetSlotEffectiveCategory](API_C_Transmog.GetSlotEffectiveCategory.md "API C Transmog.GetSlotEffectiveCategory")  [C\_Transmog.GetSlotInfo](API_C_Transmog.GetSlotInfo.md "API C Transmog.GetSlotInfo")  [C\_Transmog.GetSlotUseError](API_C_Transmog.GetSlotUseError.md "API C Transmog.GetSlotUseError")  [C\_Transmog.IsSlotBeingCollapsed](API_C_Transmog.IsSlotBeingCollapsed.md "API C Transmog.IsSlotBeingCollapsed")  [C\_Transmog.IsTransmogEnabled](API_C_Transmog.IsTransmogEnabled.md "API C Transmog.IsTransmogEnabled")  [C\_Transmog.LoadOutfit](API_C_Transmog.LoadOutfit.md "API C Transmog.LoadOutfit")  [C\_Transmog.SetPending](API_C_Transmog.SetPending.md "API C Transmog.SetPending")  [C\_TransmogCollection.DeleteOutfit](API_C_TransmogCollection.DeleteOutfit.md "API C TransmogCollection.DeleteOutfit")  [C\_TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink](API_C_TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink.md "API C TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink")  [C\_TransmogCollection.GetNumMaxOutfits](API_C_TransmogCollection.GetNumMaxOutfits.md "API C TransmogCollection.GetNumMaxOutfits")  [C\_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList](API_C_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList.md "API C TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList")  [C\_TransmogCollection.GetOutfitInfo](API_C_TransmogCollection.GetOutfitInfo.md "API C TransmogCollection.GetOutfitInfo")  [C\_TransmogCollection.GetOutfitItemTransmogInfoList](API_C_TransmogCollection.GetOutfitItemTransmogInfoList.md "API C TransmogCollection.GetOutfitItemTransmogInfoList")  [C\_TransmogCollection.GetOutfits](API_C_TransmogCollection.GetOutfits.md "API C TransmogCollection.GetOutfits")  [C\_TransmogCollection.ModifyOutfit](API_C_TransmogCollection.ModifyOutfit.md "API C TransmogCollection.ModifyOutfit")  [C\_TransmogCollection.NewOutfit](API_C_TransmogCollection.NewOutfit.md "API C TransmogCollection.NewOutfit")  [C\_TransmogCollection.RenameOutfit](API_C_TransmogCollection.RenameOutfit.md "API C TransmogCollection.RenameOutfit")  [CancelEmote](API_CancelEmote.md "API CancelEmote (page does not exist)")  [ChangeActionBarPage](API_ChangeActionBarPage.md "API ChangeActionBarPage")  [CombatLogAddFilter](API_CombatLogAddFilter.md "API CombatLogAddFilter (page does not exist)")  [CombatLogAdvanceEntry](API_CombatLogAdvanceEntry.md "API CombatLogAdvanceEntry")  [CombatLogClearEntries](API_CombatLogClearEntries.md "API CombatLogClearEntries (page does not exist)")  [CombatLogGetCurrentEntry](API_CombatLogGetCurrentEntry.md "API CombatLogGetCurrentEntry")  [CombatLogGetCurrentEventInfo](API_CombatLogGetCurrentEventInfo.md "API CombatLogGetCurrentEventInfo")  [CombatLogGetNumEntries](API_CombatLogGetNumEntries.md "API CombatLogGetNumEntries (page does not exist)")  [CombatLogGetRetentionTime](API_CombatLogGetRetentionTime.md "API CombatLogGetRetentionTime (page does not exist)")  [CombatLogResetFilter](API_CombatLogResetFilter.md "API CombatLogResetFilter (page does not exist)")  [CombatLogSetCurrentEntry](API_CombatLogSetCurrentEntry.md "API CombatLogSetCurrentEntry")  [CombatLogSetRetentionTime](API_CombatLogSetRetentionTime.md "API CombatLogSetRetentionTime (page does not exist)")  [CombatLogShowCurrentEntry](API_CombatLogShowCurrentEntry.md "API CombatLogShowCurrentEntry (page does not exist)")  [CombatLog\_Object\_IsA](API_CombatLog_Object_IsA.md "API CombatLog Object IsA")  [CombatTextSetActiveUnit](API_CombatTextSetActiveUnit.md "API CombatTextSetActiveUnit")  [DeathRecap\_GetEvents](API_DeathRecap_GetEvents.md "API DeathRecap GetEvents")  [DeathRecap\_HasEvents](API_DeathRecap_HasEvents.md "API DeathRecap HasEvents")  [DoEmote](API_DoEmote.md "API DoEmote")  [FindBaseSpellByID](API_FindBaseSpellByID.md "API FindBaseSpellByID")  [FindFlyoutSlotBySpellID](API_FindFlyoutSlotBySpellID.md "API FindFlyoutSlotBySpellID (page does not exist)")  [FindSpellOverrideByID](API_FindSpellOverrideByID.md "API FindSpellOverrideByID")  [GetActionAutocast](API_GetActionAutocast.md "API GetActionAutocast (page does not exist)")  [GetActionBarPage](API_GetActionBarPage.md "API GetActionBarPage")  [GetActionCharges](API_GetActionCharges.md "API GetActionCharges")  [GetActionCooldown](API_GetActionCooldown.md "API GetActionCooldown")  [GetActionCount](API_GetActionCount.md "API GetActionCount")  [GetActionLossOfControlCooldown](API_GetActionLossOfControlCooldown.md "API GetActionLossOfControlCooldown")  [GetActionTexture](API_GetActionTexture.md "API GetActionTexture")  [GetActionText](API_GetActionText.md "API GetActionText")  [GetBattlegroundInfo](API_GetBattlegroundInfo.md "API GetBattlegroundInfo")  [GetBonusBarIndex](API_GetBonusBarIndex.md "API GetBonusBarIndex (page does not exist)")  [GetBonusBarOffset](API_GetBonusBarOffset.md "API GetBonusBarOffset")  [GetCurrentCombatTextEventInfo](API_GetCurrentCombatTextEventInfo.md "API GetCurrentCombatTextEventInfo")  [GetDeathRecapLink](API_GetDeathRecapLink.md "API GetDeathRecapLink")  [GetExtraBarIndex](API_GetExtraBarIndex.md "API GetExtraBarIndex")  [GetMultiCastBarIndex](API_GetMultiCastBarIndex.md "API GetMultiCastBarIndex (page does not exist)")  [GetOverrideBarIndex](API_GetOverrideBarIndex.md "API GetOverrideBarIndex (page does not exist)")  [GetOverrideBarSkin](API_GetOverrideBarSkin.md "API GetOverrideBarSkin (page does not exist)")  [GetTempShapeshiftBarIndex](API_GetTempShapeshiftBarIndex.md "API GetTempShapeshiftBarIndex (page does not exist)")  [GetVehicleBarIndex](API_GetVehicleBarIndex.md "API GetVehicleBarIndex (page does not exist)")  [HasAction](API_HasAction.md "API HasAction")  [HasBonusActionBar](API_HasBonusActionBar.md "API HasBonusActionBar (page does not exist)")  [HasExtraActionBar](API_HasExtraActionBar.md "API HasExtraActionBar")  [HasOverrideActionBar](API_HasOverrideActionBar.md "API HasOverrideActionBar (page does not exist)")  [HasTempShapeshiftActionBar](API_HasTempShapeshiftActionBar.md "API HasTempShapeshiftActionBar (page does not exist)")  [HasVehicleActionBar](API_HasVehicleActionBar.md "API HasVehicleActionBar (page does not exist)")  [IsActionInRange](API_IsActionInRange.md "API IsActionInRange")  [IsAttackAction](API_IsAttackAction.md "API IsAttackAction")  [IsAutoRepeatAction](API_IsAutoRepeatAction.md "API IsAutoRepeatAction")  [IsConsumableAction](API_IsConsumableAction.md "API IsConsumableAction")  [IsConsumableSpell](API_IsConsumableSpell.md "API IsConsumableSpell (page does not exist)")  [IsCurrentAction](API_IsCurrentAction.md "API IsCurrentAction")  [IsEncounterInProgress](API_IsEncounterInProgress.md "API IsEncounterInProgress (page does not exist)")  [IsEncounterLimitingResurrections](API_IsEncounterLimitingResurrections.md "API IsEncounterLimitingResurrections (page does not exist)")  [IsEncounterSuppressingRelease](API_IsEncounterSuppressingRelease.md "API IsEncounterSuppressingRelease (page does not exist)")  [IsEquippedAction](API_IsEquippedAction.md "API IsEquippedAction")  [IsItemAction](API_IsItemAction.md "API IsItemAction (page does not exist)")  [IsPossessBarVisible](API_IsPossessBarVisible.md "API IsPossessBarVisible (page does not exist)")  [IsStackableAction](API_IsStackableAction.md "API IsStackableAction (page does not exist)")  [IsUsableAction](API_IsUsableAction.md "API IsUsableAction")  [SetActionUIButton](API_SetActionUIButton.md "API SetActionUIButton")  [SetPortraitToTexture](API_SetPortraitToTexture.md "API SetPortraitToTexture")  [SetRaidTargetProtected](API_SetRaidTargetProtected.md "API SetRaidTargetProtected (page does not exist)")  [SpellGetVisibilityInfo](API_SpellGetVisibilityInfo.md "API SpellGetVisibilityInfo")  [SpellIsAlwaysShown](API_SpellIsAlwaysShown.md "API SpellIsAlwaysShown (page does not exist)")  [SpellIsPriorityAura](API_SpellIsPriorityAura.md "API SpellIsPriorityAura (page does not exist)")  [SpellIsSelfBuff](API_SpellIsSelfBuff.md "API SpellIsSelfBuff (page does not exist)")  [StripHyperlinks](API_StripHyperlinks.md "API StripHyperlinks") |

|  |
| --- |
| Added [AbbreviateConfig](ScriptObject_AbbreviateConfig.md "ScriptObject AbbreviateConfig")  [ColorCurveObject](ScriptObject_ColorCurveObject.md "ScriptObject ColorCurveObject")  [CurveObject](ScriptObject_CurveObject.md "ScriptObject CurveObject")  [CurveObjectBase](ScriptObject_CurveObjectBase.md "ScriptObject CurveObjectBase")  [DurationObject](ScriptObject_DurationObject.md "ScriptObject DurationObject")  [UnitHealPredictionCalculator](ScriptObject_UnitHealPredictionCalculator.md "ScriptObject UnitHealPredictionCalculator") |

| Added (28) | Removed (0) |
| --- | --- |
| [FrameScriptObject:HasAnySecretAspect](API_FrameScriptObject_HasAnySecretAspect.md "API FrameScriptObject HasAnySecretAspect")  [FrameScriptObject:HasSecretAspect](API_FrameScriptObject_HasSecretAspect.md "API FrameScriptObject HasSecretAspect")  [FrameScriptObject:HasSecretValues](API_FrameScriptObject_HasSecretValues.md "API FrameScriptObject HasSecretValues")  [FrameScriptObject:IsPreventingSecretValues](API_FrameScriptObject_IsPreventingSecretValues.md "API FrameScriptObject IsPreventingSecretValues")  [FrameScriptObject:SetPreventSecretValues](API_FrameScriptObject_SetPreventSecretValues.md "API FrameScriptObject SetPreventSecretValues")  [ScriptRegion:IsAnchoringSecret](API_ScriptRegion_IsAnchoringSecret.md "API ScriptRegion IsAnchoringSecret")  [Region:SetAlphaFromBoolean](API_Region_SetAlphaFromBoolean.md "API Region SetAlphaFromBoolean")  [Region:SetVertexColorFromBoolean](API_Region_SetVertexColorFromBoolean.md "API Region SetVertexColorFromBoolean")  [FontString:GetScaleAnimationMode](API_FontString_GetScaleAnimationMode.md "API FontString GetScaleAnimationMode")  [FontString:SetScaleAnimationMode](API_FontString_SetScaleAnimationMode.md "API FontString SetScaleAnimationMode")  [TextureBase:ResetTexCoord](API_TextureBase_ResetTexCoord.md "API TextureBase ResetTexCoord")  [TextureBase:SetSpriteSheetCell](API_TextureBase_SetSpriteSheetCell.md "API TextureBase SetSpriteSheetCell")  [Frame:IsIgnoringChildrenForBounds](API_Frame_IsIgnoringChildrenForBounds.md "API Frame IsIgnoringChildrenForBounds")  [Frame:RegisterEventCallback](API_Frame_RegisterEventCallback.md "API Frame RegisterEventCallback")  [Frame:RegisterUnitEventCallback](API_Frame_RegisterUnitEventCallback.md "API Frame RegisterUnitEventCallback")  [Frame:SetIgnoringChildrenForBounds](API_Frame_SetIgnoringChildrenForBounds.md "API Frame SetIgnoringChildrenForBounds")  [Model:SetUseGBuffer](API_Model_SetUseGBuffer.md "API Model SetUseGBuffer")  [GameTooltip:GetLeftLine](API_GameTooltip_GetLeftLine.md "API GameTooltip GetLeftLine")  [GameTooltip:GetRightLine](API_GameTooltip_GetRightLine.md "API GameTooltip GetRightLine")  [Cooldown:GetCountdownFontString](API_Cooldown_GetCountdownFontString.md "API Cooldown GetCountdownFontString")  [Cooldown:SetCooldownFromDurationObject](API_Cooldown_SetCooldownFromDurationObject.md "API Cooldown SetCooldownFromDurationObject")  [Cooldown:SetCooldownFromExpirationTime](API_Cooldown_SetCooldownFromExpirationTime.md "API Cooldown SetCooldownFromExpirationTime")  [Cooldown:SetPaused](API_Cooldown_SetPaused.md "API Cooldown SetPaused")  [StatusBar:GetInterpolatedValue](API_StatusBar_GetInterpolatedValue.md "API StatusBar GetInterpolatedValue")  [StatusBar:GetTimerDuration](API_StatusBar_GetTimerDuration.md "API StatusBar GetTimerDuration")  [StatusBar:IsInterpolating](API_StatusBar_IsInterpolating.md "API StatusBar IsInterpolating")  [StatusBar:SetTimerDuration](API_StatusBar_SetTimerDuration.md "API StatusBar SetTimerDuration")  [StatusBar:SetToTargetValue](API_StatusBar_SetToTargetValue.md "API StatusBar SetToTargetValue") |  |

| Added (76) | Removed (8) |
| --- | --- |
| [ADDON\_RESTRICTION\_STATE\_CHANGED](ADDON_RESTRICTION_STATE_CHANGED.md "ADDON RESTRICTION STATE CHANGED")  [BULK\_PURCHASE\_RESULT\_RECEIVED](BULK_PURCHASE_RESULT_RECEIVED.md "BULK PURCHASE RESULT RECEIVED")  [CATALOG\_SHOP\_REFUNDABLE\_DECORS\_UPDATED](CATALOG_SHOP_REFUNDABLE_DECORS_UPDATED.md "CATALOG SHOP REFUNDABLE DECORS UPDATED")  [CATALOG\_SHOP\_VIRTUAL\_CURRENCY\_BALANCE\_UPDATE\_FAILURE](CATALOG_SHOP_VIRTUAL_CURRENCY_BALANCE_UPDATE_FAILURE.md "CATALOG SHOP VIRTUAL CURRENCY BALANCE UPDATE FAILURE")  [CATALOG\_SHOP\_VIRTUAL\_CURRENCY\_BALANCE\_UPDATE](CATALOG_SHOP_VIRTUAL_CURRENCY_BALANCE_UPDATE.md "CATALOG SHOP VIRTUAL CURRENCY BALANCE UPDATE")  [CHAT\_MSG\_ENCOUNTER\_EVENT](CHAT_MSG_ENCOUNTER_EVENT.md "CHAT MSG ENCOUNTER EVENT")  [COMBAT\_LOG\_APPLY\_FILTER\_SETTINGS](COMBAT_LOG_APPLY_FILTER_SETTINGS.md "COMBAT LOG APPLY FILTER SETTINGS")  [COMBAT\_LOG\_ENTRIES\_CLEARED](COMBAT_LOG_ENTRIES_CLEARED.md "COMBAT LOG ENTRIES CLEARED")  [COMBAT\_LOG\_EVENT\_INTERNAL\_UNFILTERED](COMBAT_LOG_EVENT_INTERNAL_UNFILTERED.md "COMBAT LOG EVENT INTERNAL UNFILTERED")  [COMBAT\_LOG\_MESSAGE\_LIMIT\_CHANGED](COMBAT_LOG_MESSAGE_LIMIT_CHANGED.md "COMBAT LOG MESSAGE LIMIT CHANGED")  [COMBAT\_LOG\_MESSAGE](COMBAT_LOG_MESSAGE.md "COMBAT LOG MESSAGE")  [COMBAT\_LOG\_REFILTER\_ENTRIES](COMBAT_LOG_REFILTER_ENTRIES.md "COMBAT LOG REFILTER ENTRIES")  [COMMENTATOR\_COMBAT\_EVENT](COMMENTATOR_COMBAT_EVENT.md "COMMENTATOR COMBAT EVENT")  [DAMAGE\_METER\_COMBAT\_SESSION\_UPDATED](DAMAGE_METER_COMBAT_SESSION_UPDATED.md "DAMAGE METER COMBAT SESSION UPDATED")  [DAMAGE\_METER\_CURRENT\_SESSION\_UPDATED](DAMAGE_METER_CURRENT_SESSION_UPDATED.md "DAMAGE METER CURRENT SESSION UPDATED")  [DAMAGE\_METER\_RESET](DAMAGE_METER_RESET.md "DAMAGE METER RESET")  [ENCOUNTER\_STATE\_CHANGED](ENCOUNTER_STATE_CHANGED.md "ENCOUNTER STATE CHANGED")  [ENCOUNTER\_TIMELINE\_EVENT\_ADDED](ENCOUNTER_TIMELINE_EVENT_ADDED.md "ENCOUNTER TIMELINE EVENT ADDED")  [ENCOUNTER\_TIMELINE\_EVENT\_BLOCK\_STATE\_CHANGED](ENCOUNTER_TIMELINE_EVENT_BLOCK_STATE_CHANGED.md "ENCOUNTER TIMELINE EVENT BLOCK STATE CHANGED")  [ENCOUNTER\_TIMELINE\_EVENT\_HIGHLIGHT](ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT.md "ENCOUNTER TIMELINE EVENT HIGHLIGHT")  [ENCOUNTER\_TIMELINE\_EVENT\_REMOVED](ENCOUNTER_TIMELINE_EVENT_REMOVED.md "ENCOUNTER TIMELINE EVENT REMOVED")  [ENCOUNTER\_TIMELINE\_EVENT\_STATE\_CHANGED](ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED.md "ENCOUNTER TIMELINE EVENT STATE CHANGED")  [ENCOUNTER\_TIMELINE\_EVENT\_TRACK\_CHANGED](ENCOUNTER_TIMELINE_EVENT_TRACK_CHANGED.md "ENCOUNTER TIMELINE EVENT TRACK CHANGED")  [ENCOUNTER\_TIMELINE\_LAYOUT\_UPDATED](ENCOUNTER_TIMELINE_LAYOUT_UPDATED.md "ENCOUNTER TIMELINE LAYOUT UPDATED")  [ENCOUNTER\_TIMELINE\_STATE\_UPDATED](ENCOUNTER_TIMELINE_STATE_UPDATED.md "ENCOUNTER TIMELINE STATE UPDATED")  [ENCOUNTER\_WARNING](ENCOUNTER_WARNING.md "ENCOUNTER WARNING")  [FACTION\_STANDING\_CHANGED](FACTION_STANDING_CHANGED.md "FACTION STANDING CHANGED")  [HOUSE\_EXTERIOR\_TYPE\_UNLOCKED](HOUSE_EXTERIOR_TYPE_UNLOCKED.md "HOUSE EXTERIOR TYPE UNLOCKED")  [HOUSE\_LEVEL\_CHANGED](HOUSE_LEVEL_CHANGED.md "HOUSE LEVEL CHANGED")  [HOUSING\_DECOR\_ADD\_TO\_PREVIEW\_LIST](HOUSING_DECOR_ADD_TO_PREVIEW_LIST.md "HOUSING DECOR ADD TO PREVIEW LIST")  [HOUSING\_DECOR\_FREE\_PLACE\_STATUS\_CHANGED](HOUSING_DECOR_FREE_PLACE_STATUS_CHANGED.md "HOUSING DECOR FREE PLACE STATUS CHANGED")  [HOUSING\_DECOR\_PREVIEW\_LIST\_REMOVE\_FROM\_WORLD](HOUSING_DECOR_PREVIEW_LIST_REMOVE_FROM_WORLD.md "HOUSING DECOR PREVIEW LIST REMOVE FROM WORLD")  [HOUSING\_DECOR\_PREVIEW\_LIST\_UPDATED](HOUSING_DECOR_PREVIEW_LIST_UPDATED.md "HOUSING DECOR PREVIEW LIST UPDATED")  [HOUSING\_DECOR\_PREVIEW\_STATE\_CHANGED](HOUSING_DECOR_PREVIEW_STATE_CHANGED.md "HOUSING DECOR PREVIEW STATE CHANGED")  [HOUSING\_EXPERT\_MODE\_PLACEMENT\_FLAGS\_UPDATED](HOUSING_EXPERT_MODE_PLACEMENT_FLAGS_UPDATED.md "HOUSING EXPERT MODE PLACEMENT FLAGS UPDATED")  [HOUSING\_FIXTURE\_UNLOCKED](HOUSING_FIXTURE_UNLOCKED.md "HOUSING FIXTURE UNLOCKED")  [HOUSING\_REFUND\_LIST\_UPDATED](HOUSING_REFUND_LIST_UPDATED.md "HOUSING REFUND LIST UPDATED")  [HOUSING\_SET\_EXTERIOR\_HOUSE\_SIZE\_RESPONSE](HOUSING_SET_EXTERIOR_HOUSE_SIZE_RESPONSE.md "HOUSING SET EXTERIOR HOUSE SIZE RESPONSE")  [HOUSING\_SET\_EXTERIOR\_HOUSE\_TYPE\_RESPONSE](HOUSING_SET_EXTERIOR_HOUSE_TYPE_RESPONSE.md "HOUSING SET EXTERIOR HOUSE TYPE RESPONSE")  [HOUSING\_SET\_FIXTURE\_RESPONSE](HOUSING_SET_FIXTURE_RESPONSE.md "HOUSING SET FIXTURE RESPONSE")  [INITIATIVE\_ACTIVITY\_LOG\_UPDATED](INITIATIVE_ACTIVITY_LOG_UPDATED.md "INITIATIVE ACTIVITY LOG UPDATED")  [INITIATIVE\_COMPLETED](INITIATIVE_COMPLETED.md "INITIATIVE COMPLETED")  [INITIATIVE\_TASK\_COMPLETED](INITIATIVE_TASK_COMPLETED.md "INITIATIVE TASK COMPLETED")  [INITIATIVE\_TASKS\_TRACKED\_LIST\_CHANGED](INITIATIVE_TASKS_TRACKED_LIST_CHANGED.md "INITIATIVE TASKS TRACKED LIST CHANGED")  [INITIATIVE\_TASKS\_TRACKED\_UPDATED](INITIATIVE_TASKS_TRACKED_UPDATED.md "INITIATIVE TASKS TRACKED UPDATED")  [LEGACY\_LOOT\_RULES\_CHANGED](LEGACY_LOOT_RULES_CHANGED.md "LEGACY LOOT RULES CHANGED")  [NAME\_PLATE\_UNIT\_BEHIND\_CAMERA\_CHANGED](NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED.md "NAME PLATE UNIT BEHIND CAMERA CHANGED")  [NEIGHBORHOOD\_INITIATIVE\_UPDATED](NEIGHBORHOOD_INITIATIVE_UPDATED.md "NEIGHBORHOOD INITIATIVE UPDATED")  [PARTY\_KILL](PARTY_KILL.md "PARTY KILL")  [PLAYER\_TARGET\_DIED](PLAYER_TARGET_DIED.md "PLAYER TARGET DIED")  [REMOVE\_NEIGHBORHOOD\_CHARTER\_SIGNATURE](REMOVE_NEIGHBORHOOD_CHARTER_SIGNATURE.md "REMOVE NEIGHBORHOOD CHARTER SIGNATURE")  [SECURE\_TRANSFER\_CONFIRM\_HOUSING\_PURCHASE](SECURE_TRANSFER_CONFIRM_HOUSING_PURCHASE.md "SECURE TRANSFER CONFIRM HOUSING PURCHASE")  [SECURE\_TRANSFER\_HOUSING\_CURRENCY\_PURCHASE\_CONFIRMATION](SECURE_TRANSFER_HOUSING_CURRENCY_PURCHASE_CONFIRMATION.md "SECURE TRANSFER HOUSING CURRENCY PURCHASE CONFIRMATION")  [SET\_SEEN\_PRODUCTS](SET_SEEN_PRODUCTS.md "SET SEEN PRODUCTS")  [SETTINGS\_LOADED](SETTINGS_LOADED.md "SETTINGS LOADED")  [SETTINGS\_PANEL\_OPEN](SETTINGS_PANEL_OPEN.md "SETTINGS PANEL OPEN")  [SHOW\_JOURNEYS\_UI](SHOW_JOURNEYS_UI.md "SHOW JOURNEYS UI")  [SHOW\_NEW\_PRODUCT\_NOTIFICATION](SHOW_NEW_PRODUCT_NOTIFICATION.md "SHOW NEW PRODUCT NOTIFICATION")  [TOOLTIP\_SHOW\_ITEM\_COMPARISON](TOOLTIP_SHOW_ITEM_COMPARISON.md "TOOLTIP SHOW ITEM COMPARISON")  [TRAINING\_GROUNDS\_ENABLED\_STATUS\_UPDATED](TRAINING_GROUNDS_ENABLED_STATUS_UPDATED.md "TRAINING GROUNDS ENABLED STATUS UPDATED")  [TRANSMOG\_CUSTOM\_SETS\_CHANGED](TRANSMOG_CUSTOM_SETS_CHANGED.md "TRANSMOG CUSTOM SETS CHANGED")  [TRANSMOG\_DISPLAYED\_OUTFIT\_CHANGED](TRANSMOG_DISPLAYED_OUTFIT_CHANGED.md "TRANSMOG DISPLAYED OUTFIT CHANGED")  [TRANSMOG\_OUTFITS\_CHANGED](TRANSMOG_OUTFITS_CHANGED.md "TRANSMOG OUTFITS CHANGED")  [TUTORIAL\_COMBAT\_EVENT](TUTORIAL_COMBAT_EVENT.md "TUTORIAL COMBAT EVENT")  [UNIT\_DIED](UNIT_DIED.md "UNIT DIED")  [UNIT\_LOOT](UNIT_LOOT.md "UNIT LOOT")  [UNIT\_SPELL\_DIMINISH\_CATEGORY\_STATE\_UPDATED](UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED.md "UNIT SPELL DIMINISH CATEGORY STATE UPDATED")  [UNIT\_SPELLCAST\_SENT](UNIT_SPELLCAST_SENT.md "UNIT SPELLCAST SENT")  [UPDATE\_BULLETIN\_BOARD\_MEMBER\_TYPE](UPDATE_BULLETIN_BOARD_MEMBER_TYPE.md "UPDATE BULLETIN BOARD MEMBER TYPE")  [VIEWED\_TRANSMOG\_OUTFIT\_CHANGED](VIEWED_TRANSMOG_OUTFIT_CHANGED.md "VIEWED TRANSMOG OUTFIT CHANGED")  [VIEWED\_TRANSMOG\_OUTFIT\_SECONDARY\_SLOTS\_CHANGED](VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED.md "VIEWED TRANSMOG OUTFIT SECONDARY SLOTS CHANGED")  [VIEWED\_TRANSMOG\_OUTFIT\_SITUATIONS\_CHANGED](VIEWED_TRANSMOG_OUTFIT_SITUATIONS_CHANGED.md "VIEWED TRANSMOG OUTFIT SITUATIONS CHANGED")  [VIEWED\_TRANSMOG\_OUTFIT\_SLOT\_REFRESH](VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH.md "VIEWED TRANSMOG OUTFIT SLOT REFRESH")  [VIEWED\_TRANSMOG\_OUTFIT\_SLOT\_SAVE\_SUCCESS](VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS.md "VIEWED TRANSMOG OUTFIT SLOT SAVE SUCCESS")  [VIEWED\_TRANSMOG\_OUTFIT\_SLOT\_WEAPON\_OPTION\_CHANGED](VIEWED_TRANSMOG_OUTFIT_SLOT_WEAPON_OPTION_CHANGED.md "VIEWED TRANSMOG OUTFIT SLOT WEAPON OPTION CHANGED")  [VOICE\_CHAT\_TTS\_PLAYBACK\_BOOKMARK](VOICE_CHAT_TTS_PLAYBACK_BOOKMARK.md "VOICE CHAT TTS PLAYBACK BOOKMARK") | [HOUSE\_LEVEL\_CHANGED](HOUSE_LEVEL_CHANGED.md "HOUSE LEVEL CHANGED")  [HOUSING\_CATALOG\_SEARCHER\_RELEASED](HOUSING_CATALOG_SEARCHER_RELEASED.md "HOUSING CATALOG SEARCHER RELEASED")  [HOUSING\_DECOR\_NUDGE\_STATUS\_CHANGED](HOUSING_DECOR_NUDGE_STATUS_CHANGED.md "HOUSING DECOR NUDGE STATUS CHANGED")  [LEARNED\_SPELL\_IN\_TAB](LEARNED_SPELL_IN_TAB.md "LEARNED SPELL IN TAB")  [SETTINGS\_LOADED](SETTINGS_LOADED.md "SETTINGS LOADED")  [SHOW\_DELVES\_DISPLAY\_UI](SHOW_DELVES_DISPLAY_UI.md "SHOW DELVES DISPLAY UI")  [TRANSMOG\_OUTFITS\_CHANGED](TRANSMOG_OUTFITS_CHANGED.md "TRANSMOG OUTFITS CHANGED")  [UNIT\_SPELLCAST\_SENT](UNIT_SPELLCAST_SENT.md "UNIT SPELLCAST SENT") |

| Added (137) | Removed (153) |
| --- | --- |
| [addonChatRestrictionsForced](CVar_addonChatRestrictionsForced.md "CVar addonChatRestrictionsForced (page does not exist)")CVar: addonChatRestrictionsForced (Game) Default: `0` If true, force the client into the chat lockdown state. This is provided for addon author testing and will not persist across client restarts.  [alwaysShowRuneIcons](CVar_alwaysShowRuneIcons.md "CVar alwaysShowRuneIcons (page does not exist)")CVar: alwaysShowRuneIcons (None) Default: `0`, Scope: Account Show the rune icons on equipment at all times, as opposed to only when the rune UI is open.  [auctionSortByBuyoutPrice](CVar_auctionSortByBuyoutPrice.md "CVar auctionSortByBuyoutPrice (page does not exist)")CVar: auctionSortByBuyoutPrice (Game) Default: `0`, Scope: Character Sort auction items by buyout price instead of current bid price  [auctionSortByUnitPrice](CVar_auctionSortByUnitPrice.md "CVar auctionSortByUnitPrice (page does not exist)")CVar: auctionSortByUnitPrice (Game) Default: `0`, Scope: Character Sort auction items by unit price instead of total stack price  [CAAEnabled](CVar_CAAEnabled.md "CVar CAAEnabled (page does not exist)")CVar: CAAEnabled (Game) Default: `0`, Scope: Account Enable or disable combat audio alerts  [CAAInterruptCastSuccess](CVar_CAAInterruptCastSuccess.md "CVar CAAInterruptCastSuccess (page does not exist)")CVar: CAAInterruptCastSuccess (Game) Default: `0`, Scope: Account Announce when the target's cast is interrupted  [CAAInterruptCast](CVar_CAAInterruptCast.md "CVar CAAInterruptCast (page does not exist)")CVar: CAAInterruptCast (Game) Default: `0`, Scope: Account Announce when the target starts casting something interruptible  [CAAPartyHealthFrequency](CVar_CAAPartyHealthFrequency.md "CVar CAAPartyHealthFrequency (page does not exist)")CVar: CAAPartyHealthFrequency (Game) Default: `0`, Scope: Account Relative frequency at which party health combat audio alerts are read (-10 to 10). -10 halves the frequency and 10 doubles it  [CAAPartyHealthPercent](CVar_CAAPartyHealthPercent.md "CVar CAAPartyHealthPercent (page does not exist)")CVar: CAAPartyHealthPercent (Game) Default: `0`, Scope: Account Announce party member indices to indicate current health when it's below X percent. Frequency of announcements are affected by remaining health and CAAPartyHealthFrequencySpeed  [CAAPlayerCastFormat](CVar_CAAPlayerCastFormat.md "CVar CAAPlayerCastFormat (page does not exist)")CVar: CAAPlayerCastFormat (Game) Default: `4`, Scope: Account Format string to use when reading the player's casts  [CAAPlayerCastMinTime](CVar_CAAPlayerCastMinTime.md "CVar CAAPlayerCastMinTime (page does not exist)")CVar: CAAPlayerCastMinTime (Game) Default: `1.500000`, Scope: Account The player's casts will only be read out if they have a cast time >= this  [CAAPlayerCastMode](CVar_CAAPlayerCastMode.md "CVar CAAPlayerCastMode (page does not exist)")CVar: CAAPlayerCastMode (Game) Default: `0`, Scope: Account When the player's casts should be announced (0=off, 1=cast start, 2=cast end)  [CAAPlayerCastThrottle](CVar_CAAPlayerCastThrottle.md "CVar CAAPlayerCastThrottle (page does not exist)")CVar: CAAPlayerCastThrottle (Game) Default: `0.000000`, Scope: Account The player's casts will only be read every X seconds at most  [CAAPlayerHealthFormat](CVar_CAAPlayerHealthFormat.md "CVar CAAPlayerHealthFormat (page does not exist)")CVar: CAAPlayerHealthFormat (Game) Default: `1`, Scope: Account Format string to use when reading the player's health  [CAAPlayerHealthPercent](CVar_CAAPlayerHealthPercent.md "CVar CAAPlayerHealthPercent (page does not exist)")CVar: CAAPlayerHealthPercent (Game) Default: `0`, Scope: Account Announce player health every X percent  [CAAPlayerHealthThrottle](CVar_CAAPlayerHealthThrottle.md "CVar CAAPlayerHealthThrottle (page does not exist)")CVar: CAAPlayerHealthThrottle (Game) Default: `0.000000`, Scope: Account The player's health will only be read every X seconds at most  [CAAResource1Formats](CVar_CAAResource1Formats.md "CVar CAAResource1Formats (page does not exist)")CVar: CAAResource1Formats (Game) Scope: Character Stores the format string to use (for each spec) when announcing the player's first resource  [CAAResource1Percents](CVar_CAAResource1Percents.md "CVar CAAResource1Percents (page does not exist)")CVar: CAAResource1Percents (Game) Scope: Character Stores the percentage band sizes to use (for each spec) when announcing the player's first resource  [CAAResource1Throttle](CVar_CAAResource1Throttle.md "CVar CAAResource1Throttle (page does not exist)")CVar: CAAResource1Throttle (Game) Default: `0.000000`, Scope: Character Updates to the player's first resource will only be read every X seconds at most  [CAAResource2Formats](CVar_CAAResource2Formats.md "CVar CAAResource2Formats (page does not exist)")CVar: CAAResource2Formats (Game) Scope: Character Stores the format string to use (for each spec) when announcing the player's second resource  [CAAResource2Percents](CVar_CAAResource2Percents.md "CVar CAAResource2Percents (page does not exist)")CVar: CAAResource2Percents (Game) Scope: Character Stores the percentage band sizes to use (for each spec) when announcing the player's second resource  [CAAResource2Throttle](CVar_CAAResource2Throttle.md "CVar CAAResource2Throttle (page does not exist)")CVar: CAAResource2Throttle (Game) Default: `0.000000`, Scope: Character Updates to the player's second resource will only be read every X seconds at most  [CAASayCombatEnd](CVar_CAASayCombatEnd.md "CVar CAASayCombatEnd (page does not exist)")CVar: CAASayCombatEnd (Game) Default: `1`, Scope: Account Announce when combat ends  [CAASayCombatStart](CVar_CAASayCombatStart.md "CVar CAASayCombatStart (page does not exist)")CVar: CAASayCombatStart (Game) Default: `1`, Scope: Account Announce when combat starts  [CAASayIfTargeted](CVar_CAASayIfTargeted.md "CVar CAASayIfTargeted (page does not exist)")CVar: CAASayIfTargeted (Game) Scope: Character Stores the 'say if targeted' settings for each spec  [CAASayTargetName](CVar_CAASayTargetName.md "CVar CAASayTargetName (page does not exist)")CVar: CAASayTargetName (Game) Default: `1`, Scope: Account Say the target's name when a new target is selected  [CAASpeed](CVar_CAASpeed.md "CVar CAASpeed (page does not exist)")CVar: CAASpeed (Game) Default: `0`, Scope: Account Speed at which combat audio alerts are read (-10 to 10)  [CAATargetCastFormat](CVar_CAATargetCastFormat.md "CVar CAATargetCastFormat (page does not exist)")CVar: CAATargetCastFormat (Game) Default: `0`, Scope: Account Format string to use when reading the target's casts  [CAATargetCastMinTime](CVar_CAATargetCastMinTime.md "CVar CAATargetCastMinTime (page does not exist)")CVar: CAATargetCastMinTime (Game) Default: `1.500000`, Scope: Account The target's casts will only be read out if they have a cast time >= this  [CAATargetCastMode](CVar_CAATargetCastMode.md "CVar CAATargetCastMode (page does not exist)")CVar: CAATargetCastMode (Game) Default: `0`, Scope: Account When the target's casts should be announced (0=off, 1=cast start, 2=cast end)  [CAATargetCastThrottle](CVar_CAATargetCastThrottle.md "CVar CAATargetCastThrottle (page does not exist)")CVar: CAATargetCastThrottle (Game) Default: `0.000000`, Scope: Account The target's casts will only be read every X seconds at most  [CAATargetDeathBehavior](CVar_CAATargetDeathBehavior.md "CVar CAATargetDeathBehavior (page does not exist)")CVar: CAATargetDeathBehavior (Game) Default: `0`, Scope: Account Behavior of announcement when target dies (0=default, 1=target dead)  [CAATargetHealthFormat](CVar_CAATargetHealthFormat.md "CVar CAATargetHealthFormat (page does not exist)")CVar: CAATargetHealthFormat (Game) Default: `3`, Scope: Account Format string to use when reading the target's health  [CAATargetHealthPercent](CVar_CAATargetHealthPercent.md "CVar CAATargetHealthPercent (page does not exist)")CVar: CAATargetHealthPercent (Game) Default: `2`, Scope: Account Announce target health every X percent  [CAATargetHealthThrottle](CVar_CAATargetHealthThrottle.md "CVar CAATargetHealthThrottle (page does not exist)")CVar: CAATargetHealthThrottle (Game) Default: `0.000000`, Scope: Account The target's health will only be read every X seconds at most  [CAAVoice](CVar_CAAVoice.md "CVar CAAVoice (page does not exist)")CVar: CAAVoice (Game) Default: `0`, Scope: Account Voice to use for combat audio alerts  [CAAVolume](CVar_CAAVolume.md "CVar CAAVolume (page does not exist)")CVar: CAAVolume (Game) Default: `100`, Scope: Account Volume of combat audio alerts (0 to 100)  [chatBubblesRaid](CVar_chatBubblesRaid.md "CVar chatBubblesRaid (page does not exist)")CVar: chatBubblesRaid (Game) Default: `0`, Scope: Account Whether to show in-game chat bubbles for raid chat  [combatWarningsEnabled](CVar_combatWarningsEnabled.md "CVar combatWarningsEnabled (page does not exist)")CVar: combatWarningsEnabled (Game) Default: `1`, Scope: Account If set, enables combat warning UI functionality such as the boss timeline or warnings displays  [damageMeterEnabled](CVar_damageMeterEnabled.md "CVar damageMeterEnabled (page does not exist)")CVar: damageMeterEnabled (Game) Default: `0`, Scope: Character If true, show the damage meter UI.  [disableSuggestedLevelActivityFilter](CVar_disableSuggestedLevelActivityFilter.md "CVar disableSuggestedLevelActivityFilter (page does not exist)")CVar: disableSuggestedLevelActivityFilter (Game) Default: `0`, Scope: Account Whether to disable filtering the activity list by the user's level.  [enablePetBattleFloatingCombatText\_v2](CVar_enablePetBattleFloatingCombatText_v2.md "CVar enablePetBattleFloatingCombatText v2 (page does not exist)")CVar: enablePetBattleFloatingCombatText\_v2 (Game) Default: `1` Whether to show floating combat text for pet battles  [encounterTimelineEnabled](CVar_encounterTimelineEnabled.md "CVar encounterTimelineEnabled (page does not exist)")CVar: encounterTimelineEnabled (Game) Default: `1`, Scope: Account If true, enable the encounter timeline UI.  [encounterTimelineHideForOtherRoles](CVar_encounterTimelineHideForOtherRoles.md "CVar encounterTimelineHideForOtherRoles (page does not exist)")CVar: encounterTimelineHideForOtherRoles (Game) Default: `0`, Scope: Account If true, hide encounter timeline events that are relevant for roles other than the player's own group role assignment. Events with no assigned role will always be shown.  [encounterTimelineHideLongCountdowns](CVar_encounterTimelineHideLongCountdowns.md "CVar encounterTimelineHideLongCountdowns (page does not exist)")CVar: encounterTimelineHideLongCountdowns (Game) Default: `0`, Scope: Account If true, hide all long countdowns from the timeline.  [encounterTimelineHideQueuedCountdowns](CVar_encounterTimelineHideQueuedCountdowns.md "CVar encounterTimelineHideQueuedCountdowns (page does not exist)")CVar: encounterTimelineHideQueuedCountdowns (Game) Default: `0`, Scope: Account If true, hide all queued countdowns from the timeline.  [encounterTimelineIconographyEnabled](CVar_encounterTimelineIconographyEnabled.md "CVar encounterTimelineIconographyEnabled (page does not exist)")CVar: encounterTimelineIconographyEnabled (Game) Default: `1`, Scope: Account If true, enable the display of spell support iconography such as role and effect type indicators.  [encounterWarningsDefaultMessageDuration](CVar_encounterWarningsDefaultMessageDuration.md "CVar encounterWarningsDefaultMessageDuration (page does not exist)")CVar: encounterWarningsDefaultMessageDuration (Game) Default: `3500`, Scope: Account Default duration (in milliseconds) applied to encounter warning text messages  [encounterWarningsEnabled](CVar_encounterWarningsEnabled.md "CVar encounterWarningsEnabled (page does not exist)")CVar: encounterWarningsEnabled (Game) Default: `1`, Scope: Account If true, enable the display of encounter warning messages  [encounterWarningsHideIfNotTargetingPlayer](CVar_encounterWarningsHideIfNotTargetingPlayer.md "CVar encounterWarningsHideIfNotTargetingPlayer (page does not exist)")CVar: encounterWarningsHideIfNotTargetingPlayer (Game) Default: `0`, Scope: Account If true, hide messages that aren't actively targeting the player. Messages that have no explicit target will always be shown  [encounterWarningsLevel](CVar_encounterWarningsLevel.md "CVar encounterWarningsLevel (page does not exist)")CVar: encounterWarningsLevel (Game) Default: `0`, Scope: Account Minimum level of encounter warning severities to be shown  [endeavorInitiativesLastPoints](CVar_endeavorInitiativesLastPoints.md "CVar endeavorInitiativesLastPoints (page does not exist)")CVar: endeavorInitiativesLastPoints (Game) Default: `0`, Scope: Account Last seen number of endeavor points in the progress bar  [equipmentManager](CVar_equipmentManager.md "CVar equipmentManager")CVar: equipmentManager (Game) Default: `1`, Scope: Character Enables the equipment management UI  [externalDefensivesEnabled](CVar_externalDefensivesEnabled.md "CVar externalDefensivesEnabled (page does not exist)")CVar: externalDefensivesEnabled (Game) Default: `0`, Scope: Character If true, show the external defensives buff tracker UI.  [floatingCombatTextAuraFade\_v2](CVar_floatingCombatTextAuraFade_v2.md "CVar floatingCombatTextAuraFade v2 (page does not exist)")CVar: floatingCombatTextAuraFade\_v2 (Game) Default: `0`  [floatingCombatTextAuras\_v2](CVar_floatingCombatTextAuras_v2.md "CVar floatingCombatTextAuras v2 (page does not exist)")CVar: floatingCombatTextAuras\_v2 (Game) Default: `0`  [floatingCombatTextCombatDamage\_v2](CVar_floatingCombatTextCombatDamage_v2.md "CVar floatingCombatTextCombatDamage v2 (page does not exist)")CVar: floatingCombatTextCombatDamage\_v2 (Game) Default: `1` Display damage numbers over hostile creatures when damaged  [floatingCombatTextCombatDamageAllAutos\_v2](CVar_floatingCombatTextCombatDamageAllAutos_v2.md "CVar floatingCombatTextCombatDamageAllAutos v2 (page does not exist)")CVar: floatingCombatTextCombatDamageAllAutos\_v2 (Game) Default: `1` Show all auto-attack numbers, rather than hiding non-event numbers  [floatingCombatTextCombatDamageDirectionalOffset\_v2](CVar_floatingCombatTextCombatDamageDirectionalOffset_v2.md "CVar floatingCombatTextCombatDamageDirectionalOffset v2 (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalOffset\_v2 (Game) Default: `1.000000` Amount to offset directional damage numbers when they start  [floatingCombatTextCombatDamageDirectionalScale\_v2](CVar_floatingCombatTextCombatDamageDirectionalScale_v2.md "CVar floatingCombatTextCombatDamageDirectionalScale v2 (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalScale\_v2 (Game) Default: `1.000000` Directional damage numbers movement scale (0 = no directional numbers)  [floatingCombatTextCombatHealing\_v2](CVar_floatingCombatTextCombatHealing_v2.md "CVar floatingCombatTextCombatHealing v2 (page does not exist)")CVar: floatingCombatTextCombatHealing\_v2 (Game) Default: `1` Display amount of healing you did to the target  [floatingCombatTextCombatHealingAbsorbSelf\_v2](CVar_floatingCombatTextCombatHealingAbsorbSelf_v2.md "CVar floatingCombatTextCombatHealingAbsorbSelf v2 (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbSelf\_v2 (Game) Default: `1` Display amount of shield added to yourself.  [floatingCombatTextCombatHealingAbsorbTarget\_v2](CVar_floatingCombatTextCombatHealingAbsorbTarget_v2.md "CVar floatingCombatTextCombatHealingAbsorbTarget v2 (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbTarget\_v2 (Game) Default: `1` Display amount of shield added to the target.  [floatingCombatTextCombatLogPeriodicSpells\_v2](CVar_floatingCombatTextCombatLogPeriodicSpells_v2.md "CVar floatingCombatTextCombatLogPeriodicSpells v2 (page does not exist)")CVar: floatingCombatTextCombatLogPeriodicSpells\_v2 (Game) Default: `1` Display damage caused by periodic effects  [floatingCombatTextCombatState\_v2](CVar_floatingCombatTextCombatState_v2.md "CVar floatingCombatTextCombatState v2 (page does not exist)")CVar: floatingCombatTextCombatState\_v2 (Game) Default: `0`  [floatingCombatTextComboPoints\_v2](CVar_floatingCombatTextComboPoints_v2.md "CVar floatingCombatTextComboPoints v2 (page does not exist)")CVar: floatingCombatTextComboPoints\_v2 (Game) Default: `0`  [floatingCombatTextDamageReduction\_v2](CVar_floatingCombatTextDamageReduction_v2.md "CVar floatingCombatTextDamageReduction v2 (page does not exist)")CVar: floatingCombatTextDamageReduction\_v2 (Game) Default: `0`  [floatingCombatTextDodgeParryMiss\_v2](CVar_floatingCombatTextDodgeParryMiss_v2.md "CVar floatingCombatTextDodgeParryMiss v2 (page does not exist)")CVar: floatingCombatTextDodgeParryMiss\_v2 (Game) Default: `0`  [floatingCombatTextEnergyGains\_v2](CVar_floatingCombatTextEnergyGains_v2.md "CVar floatingCombatTextEnergyGains v2 (page does not exist)")CVar: floatingCombatTextEnergyGains\_v2 (Game) Default: `0`  [floatingCombatTextFloatMode\_v2](CVar_floatingCombatTextFloatMode_v2.md "CVar floatingCombatTextFloatMode v2 (page does not exist)")CVar: floatingCombatTextFloatMode\_v2 (Game) Default: `1` The combat text float mode for the player  [floatingCombatTextFriendlyHealers\_v2](CVar_floatingCombatTextFriendlyHealers_v2.md "CVar floatingCombatTextFriendlyHealers v2 (page does not exist)")CVar: floatingCombatTextFriendlyHealers\_v2 (Game) Default: `0`  [floatingCombatTextHonorGains\_v2](CVar_floatingCombatTextHonorGains_v2.md "CVar floatingCombatTextHonorGains v2 (page does not exist)")CVar: floatingCombatTextHonorGains\_v2 (Game) Default: `0`  [floatingCombatTextLowManaHealth\_v2](CVar_floatingCombatTextLowManaHealth_v2.md "CVar floatingCombatTextLowManaHealth v2 (page does not exist)")CVar: floatingCombatTextLowManaHealth\_v2 (Game) Default: `1`  [floatingCombatTextPeriodicEnergyGains\_v2](CVar_floatingCombatTextPeriodicEnergyGains_v2.md "CVar floatingCombatTextPeriodicEnergyGains v2 (page does not exist)")CVar: floatingCombatTextPeriodicEnergyGains\_v2 (Game) Default: `0`  [floatingCombatTextPetMeleeDamage\_v2](CVar_floatingCombatTextPetMeleeDamage_v2.md "CVar floatingCombatTextPetMeleeDamage v2 (page does not exist)")CVar: floatingCombatTextPetMeleeDamage\_v2 (Game) Default: `1` Display pet melee damage in the world  [floatingCombatTextPetSpellDamage\_v2](CVar_floatingCombatTextPetSpellDamage_v2.md "CVar floatingCombatTextPetSpellDamage v2 (page does not exist)")CVar: floatingCombatTextPetSpellDamage\_v2 (Game) Default: `1` Display pet spell damage in the world  [floatingCombatTextReactives\_v2](CVar_floatingCombatTextReactives_v2.md "CVar floatingCombatTextReactives v2 (page does not exist)")CVar: floatingCombatTextReactives\_v2 (Game) Default: `1`  [floatingCombatTextRepChanges\_v2](CVar_floatingCombatTextRepChanges_v2.md "CVar floatingCombatTextRepChanges v2 (page does not exist)")CVar: floatingCombatTextRepChanges\_v2 (Game) Default: `0`  [lastTransmogCustomSetIDNoSpec](CVar_lastTransmogCustomSetIDNoSpec.md "CVar lastTransmogCustomSetIDNoSpec (page does not exist)")CVar: lastTransmogCustomSetIDNoSpec (Game) Scope: Character SetID of the last applied transmog custom set  [lastTransmogCustomSetIDSpec1](CVar_lastTransmogCustomSetIDSpec1.md "CVar lastTransmogCustomSetIDSpec1 (page does not exist)")CVar: lastTransmogCustomSetIDSpec1 (Game) Scope: Character SetID of the last applied transmog custom set for the 1st spec  [lastTransmogCustomSetIDSpec2](CVar_lastTransmogCustomSetIDSpec2.md "CVar lastTransmogCustomSetIDSpec2 (page does not exist)")CVar: lastTransmogCustomSetIDSpec2 (Game) Scope: Character SetID of the last applied transmog custom set for the 2nd spec  [lastTransmogCustomSetIDSpec3](CVar_lastTransmogCustomSetIDSpec3.md "CVar lastTransmogCustomSetIDSpec3 (page does not exist)")CVar: lastTransmogCustomSetIDSpec3 (Game) Scope: Character SetID of the last applied transmog custom set for the 3rd spec  [lastTransmogCustomSetIDSpec4](CVar_lastTransmogCustomSetIDSpec4.md "CVar lastTransmogCustomSetIDSpec4 (page does not exist)")CVar: lastTransmogCustomSetIDSpec4 (Game) Scope: Character SetID of the last applied transmog custom set for the 4th spec  [lastTransmogOutfitIDNoSpec](CVar_lastTransmogOutfitIDNoSpec.md "CVar lastTransmogOutfitIDNoSpec (page does not exist)")CVar: lastTransmogOutfitIDNoSpec (Game) Scope: Character SetID of the last applied transmog outfit  [lfgListAdvancedFiltersVersion](CVar_lfgListAdvancedFiltersVersion.md "CVar lfgListAdvancedFiltersVersion (page does not exist)")CVar: lfgListAdvancedFiltersVersion (Game) Default: `0`, Scope: Account Version for lfgListAdvancedFilters  [majorFactionRenownMap](CVar_majorFactionRenownMap.md "CVar majorFactionRenownMap (page does not exist)")CVar: majorFactionRenownMap (Game) Scope: Account Serialized mapping of faction ID to last known renown rank/level. Updated when the Renown UI is closed, used to control animations in the Major Faction UI.  [minimapTrackedInfov2](CVar_minimapTrackedInfov2.md "CVar minimapTrackedInfov2 (page does not exist)")CVar: minimapTrackedInfov2  [nameplateAuraScale](CVar_nameplateAuraScale.md "CVar nameplateAuraScale (page does not exist)")CVar: nameplateAuraScale (Game) Default: `1.000000`, Scope: Account Controls the size multiplier for buffs and debuffs on nameplates.  [nameplateDebuffPadding](CVar_nameplateDebuffPadding.md "CVar nameplateDebuffPadding (page does not exist)")CVar: nameplateDebuffPadding (Game) Default: `0`, Scope: Account The padding between the debuff list and the health bar on nameplates.  [nameplateShowCastBars](CVar_nameplateShowCastBars.md "CVar nameplateShowCastBars (page does not exist)")CVar: nameplateShowCastBars (Game) Default: `1`, Scope: Character Show cast bars for unit nameplates.  [nameplateShowClassColor](CVar_nameplateShowClassColor.md "CVar nameplateShowClassColor (page does not exist)")CVar: nameplateShowClassColor (Game) Default: `1` Used to display the class color in enemy nameplate health bars  [nameplateShowFriendlyClassColor](CVar_nameplateShowFriendlyClassColor.md "CVar nameplateShowFriendlyClassColor (page does not exist)")CVar: nameplateShowFriendlyClassColor (Game) Default: `1` Used to display the class color in friendly nameplate health bars  [nameplateShowFriendlyNpcs](CVar_nameplateShowFriendlyNpcs.md "CVar nameplateShowFriendlyNpcs (page does not exist)")CVar: nameplateShowFriendlyNpcs (Game) Default: `0`, Scope: Account Whether nameplates are shown for friendly npcs.  [nameplateShowFriendlyPlayerGuardians](CVar_nameplateShowFriendlyPlayerGuardians.md "CVar nameplateShowFriendlyPlayerGuardians (page does not exist)")CVar: nameplateShowFriendlyPlayerGuardians (Game) Default: `0`, Scope: Account Whether friendly player guardian nameplates are shown.  [nameplateShowFriendlyPlayerMinions](CVar_nameplateShowFriendlyPlayerMinions.md "CVar nameplateShowFriendlyPlayerMinions (page does not exist)")CVar: nameplateShowFriendlyPlayerMinions (Game) Default: `0`, Scope: Account Whether friendly player minion nameplates are shown.  [nameplateShowFriendlyPlayerPets](CVar_nameplateShowFriendlyPlayerPets.md "CVar nameplateShowFriendlyPlayerPets (page does not exist)")CVar: nameplateShowFriendlyPlayerPets (Game) Default: `0`, Scope: Account Whether friendly player pet nameplates are shown.  [nameplateShowFriendlyPlayers](CVar_nameplateShowFriendlyPlayers.md "CVar nameplateShowFriendlyPlayers (page does not exist)")CVar: nameplateShowFriendlyPlayers (Game) Default: `0`, Scope: Account Whether nameplates are shown for friendly players.  [nameplateShowFriendlyPlayerTotems](CVar_nameplateShowFriendlyPlayerTotems.md "CVar nameplateShowFriendlyPlayerTotems (page does not exist)")CVar: nameplateShowFriendlyPlayerTotems (Game) Default: `0`, Scope: Account Whether friendly player totem nameplates are shown.  [nameplateShowOffscreen](CVar_nameplateShowOffscreen.md "CVar nameplateShowOffscreen (page does not exist)")CVar: nameplateShowOffscreen (Game) Default: `0`, Scope: Account When enabled, the nameplate is always shown if owner is in combat with player or player's group member.  [nameplateShowOnlyNameForFriendlyPlayerUnits](CVar_nameplateShowOnlyNameForFriendlyPlayerUnits.md "CVar nameplateShowOnlyNameForFriendlyPlayerUnits (page does not exist)")CVar: nameplateShowOnlyNameForFriendlyPlayerUnits (Game) Default: `0` Used to hide every part of the nameplate but the name for friendly player units.  [nameplateSize](CVar_nameplateSize.md "CVar nameplateSize (page does not exist)")CVar: nameplateSize (Game) Default: `1`, Scope: Account Provides discrete values that are translated into specific horizontal and vertical scales defined in lua for displaying nameplates.  [nameplateStyle](CVar_nameplateStyle.md "CVar nameplateStyle (page does not exist)")CVar: nameplateStyle (Game) Default: `0`, Scope: Account Determines how nameplate contents are displayed.  [petJournalFilterVersion](CVar_petJournalFilterVersion.md "CVar petJournalFilterVersion (page does not exist)")CVar: petJournalFilterVersion (Game) Default: `0`, Scope: Account Current filter version. Will reset all filters to their defaults if out of date.  [raidFramesCenterBigDefensive](CVar_raidFramesCenterBigDefensive.md "CVar raidFramesCenterBigDefensive (page does not exist)")CVar: raidFramesCenterBigDefensive (Game) Default: `1`, Scope: Character Show big defensive raid buffs in the center of the unit frame  [raidFramesDispelIndicatorOverlay](CVar_raidFramesDispelIndicatorOverlay.md "CVar raidFramesDispelIndicatorOverlay (page does not exist)")CVar: raidFramesDispelIndicatorOverlay (Game) Default: `1`, Scope: Character When showing dispel indicators, also show a color gradient overlay  [raidFramesDispelIndicatorType](CVar_raidFramesDispelIndicatorType.md "CVar raidFramesDispelIndicatorType (page does not exist)")CVar: raidFramesDispelIndicatorType (Game) Default: `2`, Scope: Character Choose which dispel icon indicators to show in raid frames  [raidFramesDisplayLargerRoleSpecificDebuffs](CVar_raidFramesDisplayLargerRoleSpecificDebuffs.md "CVar raidFramesDisplayLargerRoleSpecificDebuffs (page does not exist)")CVar: raidFramesDisplayLargerRoleSpecificDebuffs (Game) Default: `1`, Scope: Character Show role-specific debuffs as larger on Raid Frames  [raidFramesHealthBarColor](CVar_raidFramesHealthBarColor.md "CVar raidFramesHealthBarColor (page does not exist)")CVar: raidFramesHealthBarColor (Game) Default: `FF2B9305`, Scope: Character Colors raid frames with a custom color if the user doesn't want class colors, ARGB format  [scriptWarnings](CVar_scriptWarnings.md "CVar scriptWarnings (page does not exist)")CVar: scriptWarnings (Debug) Default: `0`, Scope: Account Whether or not the UI shows Lua warnings  [secretChallengeModeRestrictionsForced](CVar_secretChallengeModeRestrictionsForced.md "CVar secretChallengeModeRestrictionsForced (page does not exist)")CVar: secretChallengeModeRestrictionsForced (Game) Default: `0` If set, APIs guarded by challenge mode and mythic plus restrictions will return secrets.  [secretCombatRestrictionsForced](CVar_secretCombatRestrictionsForced.md "CVar secretCombatRestrictionsForced (page does not exist)")CVar: secretCombatRestrictionsForced (Game) Default: `0` If set, APIs guarded by combat restrictions will return secrets.  [secretEncounterRestrictionsForced](CVar_secretEncounterRestrictionsForced.md "CVar secretEncounterRestrictionsForced (page does not exist)")CVar: secretEncounterRestrictionsForced (Game) Default: `0` If set, APIs guarded by instance encounter restrictions will return secrets.  [secretMapRestrictionsForced](CVar_secretMapRestrictionsForced.md "CVar secretMapRestrictionsForced (page does not exist)")CVar: secretMapRestrictionsForced (Game) Default: `0` If set, APIs guarded by map restrictions will return secrets.  [secretPvPMatchRestrictionsForced](CVar_secretPvPMatchRestrictionsForced.md "CVar secretPvPMatchRestrictionsForced (page does not exist)")CVar: secretPvPMatchRestrictionsForced (Game) Default: `0` If set, APIs guarded by PvP match restrictions will return secrets.  [showAllItemsInTransmog](CVar_showAllItemsInTransmog.md "CVar showAllItemsInTransmog (page does not exist)")CVar: showAllItemsInTransmog (Game) Default: `0` Shows all items in the transmogger regardless of armor restrictions  [showCustomSetDetails](CVar_showCustomSetDetails.md "CVar showCustomSetDetails (page does not exist)")CVar: showCustomSetDetails (Game) Default: `1`, Scope: Character Whether or not to show custom set details when the dressing room is opened in maximized mode, default on  [Sound\_EnableEncounterWarningsSounds](CVar_Sound_EnableEncounterWarningsSounds.md "CVar Sound EnableEncounterWarningsSounds (page does not exist)")CVar: Sound\_EnableEncounterWarningsSounds (Sound) Default: `1` Enable Encounter Warnings Sounds  [Sound\_EncounterWarningsVolume](CVar_Sound_EncounterWarningsVolume.md "CVar Sound EncounterWarningsVolume (page does not exist)")CVar: Sound\_EncounterWarningsVolume (Sound) Default: `1.000000` Encounter Warnings Volume (0.0 to 1.0)  [spellDiminishPVPEnemiesEnabled](CVar_spellDiminishPVPEnemiesEnabled.md "CVar spellDiminishPVPEnemiesEnabled (page does not exist)")CVar: spellDiminishPVPEnemiesEnabled (Game) Default: `1`, Scope: Character Determines if we should show crowd control diminishing returns on enemy unit frames in arenas  [spellDiminishPVPOnlyTriggerableByMe](CVar_spellDiminishPVPOnlyTriggerableByMe.md "CVar spellDiminishPVPOnlyTriggerableByMe (page does not exist)")CVar: spellDiminishPVPOnlyTriggerableByMe (Game) Default: `0`, Scope: Character Determines if we should show crowd control diminishing returns for all categories or only the ones you could cause with your spells  [trackedInitiativeTasks](CVar_trackedInitiativeTasks.md "CVar trackedInitiativeTasks (page does not exist)")CVar: trackedInitiativeTasks (Game) Scope: Character Internal cvar for saving tracked initiative tasks in order  [transmogHideIgnoredSlots](CVar_transmogHideIgnoredSlots.md "CVar transmogHideIgnoredSlots (page does not exist)")CVar: transmogHideIgnoredSlots (Game) Default: `0`, Scope: Account Whether ignored slots display as hidden or unassigned in the transmog frame  [transmogrifySetsFilters](CVar_transmogrifySetsFilters.md "CVar transmogrifySetsFilters (page does not exist)")CVar: transmogrifySetsFilters (Game) Default: `0`, Scope: Account Bitfield for which transmog sets filters are applied in the transmog sets tab  [useCompactPartyFrames](CVar_useCompactPartyFrames.md "CVar useCompactPartyFrames")CVar: useCompactPartyFrames  [WorldTextCritScreenY\_v2](CVar_WorldTextCritScreenY_v2.md "CVar WorldTextCritScreenY v2 (page does not exist)")CVar: WorldTextCritScreenY\_v2 (Game) Default: `0.0275`  [WorldTextGravity\_v2](CVar_WorldTextGravity_v2.md "CVar WorldTextGravity v2 (page does not exist)")CVar: WorldTextGravity\_v2 (Game) Default: `0.500000`  [WorldTextMinAlpha\_v2](CVar_WorldTextMinAlpha_v2.md "CVar WorldTextMinAlpha v2 (page does not exist)")CVar: WorldTextMinAlpha\_v2 (Game) Default: `0.500000`  [WorldTextNonRandomZ\_v2](CVar_WorldTextNonRandomZ_v2.md "CVar WorldTextNonRandomZ v2 (page does not exist)")CVar: WorldTextNonRandomZ\_v2 (Game) Default: `2.5`  [WorldTextRampDuration\_v2](CVar_WorldTextRampDuration_v2.md "CVar WorldTextRampDuration v2 (page does not exist)")CVar: WorldTextRampDuration\_v2 (Game) Default: `1.000000`  [WorldTextRampPow\_v2](CVar_WorldTextRampPow_v2.md "CVar WorldTextRampPow v2 (page does not exist)")CVar: WorldTextRampPow\_v2 (Game) Default: `1.900000`  [WorldTextRampPowCrit\_v2](CVar_WorldTextRampPowCrit_v2.md "CVar WorldTextRampPowCrit v2 (page does not exist)")CVar: WorldTextRampPowCrit\_v2 (Game) Default: `8.000000`  [WorldTextRandomXY\_v2](CVar_WorldTextRandomXY_v2.md "CVar WorldTextRandomXY v2 (page does not exist)")CVar: WorldTextRandomXY\_v2 (Game) Default: `0.0`  [WorldTextRandomZMax\_v2](CVar_WorldTextRandomZMax_v2.md "CVar WorldTextRandomZMax v2 (page does not exist)")CVar: WorldTextRandomZMax\_v2 (Game) Default: `1.5`  [WorldTextRandomZMin\_v2](CVar_WorldTextRandomZMin_v2.md "CVar WorldTextRandomZMin v2 (page does not exist)")CVar: WorldTextRandomZMin\_v2 (Game) Default: `0.8`  [WorldTextScale\_v2](CVar_WorldTextScale_v2.md "CVar WorldTextScale v2 (page does not exist)")CVar: WorldTextScale\_v2 (Game) Default: `1.000000`  [WorldTextScreenY\_v2](CVar_WorldTextScreenY_v2.md "CVar WorldTextScreenY v2 (page does not exist)")CVar: WorldTextScreenY\_v2 (Game) Default: `0.015`  [WorldTextStartPosRandomness\_v2](CVar_WorldTextStartPosRandomness_v2.md "CVar WorldTextStartPosRandomness v2 (page does not exist)")CVar: WorldTextStartPosRandomness\_v2 (Game) Default: `1.0` | [advancedWatchFrame](CVar_advancedWatchFrame.md "CVar advancedWatchFrame")CVar: advancedWatchFrame (Game) Default: `0`, Scope: Account Enables advanced Objectives tracking features  [currencyTokensBackpack1](CVar_currencyTokensBackpack1.md "CVar currencyTokensBackpack1 (page does not exist)")CVar: currencyTokensBackpack1 (Game) Default: `0`, Scope: Character Currency token types shown on backpack.  [currencyTokensBackpack2](CVar_currencyTokensBackpack2.md "CVar currencyTokensBackpack2 (page does not exist)")CVar: currencyTokensBackpack2 (Game) Default: `0`, Scope: Character Currency token types shown on backpack.  [currencyTokensUnused1](CVar_currencyTokensUnused1.md "CVar currencyTokensUnused1 (page does not exist)")CVar: currencyTokensUnused1 (Game) Default: `0`, Scope: Character Currency token types marked as unused.  [currencyTokensUnused2](CVar_currencyTokensUnused2.md "CVar currencyTokensUnused2 (page does not exist)")CVar: currencyTokensUnused2 (Game) Default: `0`, Scope: Character Currency token types marked as unused.  [displayedRAFFriendInfo](CVar_displayedRAFFriendInfo.md "CVar displayedRAFFriendInfo (page does not exist)")CVar: displayedRAFFriendInfo (Game) Default: `0`, Scope: Account Stores whether we already told a recruited person about their new BattleTag friend  [enablePetBattleFloatingCombatText](CVar_enablePetBattleFloatingCombatText.md "CVar enablePetBattleFloatingCombatText (page does not exist)")CVar: enablePetBattleFloatingCombatText (Game) Default: `1`, Scope: Account Whether to show floating combat text for pet battles  [floatingCombatTextAllSpellMechanics](CVar_floatingCombatTextAllSpellMechanics.md "CVar floatingCombatTextAllSpellMechanics (page does not exist)")CVar: floatingCombatTextAllSpellMechanics (Game) Default: `0`, Scope: Account  [floatingCombatTextAuras](CVar_floatingCombatTextAuras.md "CVar floatingCombatTextAuras (page does not exist)")CVar: floatingCombatTextAuras (Game) Default: `0`, Scope: Account  [floatingCombatTextCombatDamageAllAutos](CVar_floatingCombatTextCombatDamageAllAutos.md "CVar floatingCombatTextCombatDamageAllAutos (page does not exist)")CVar: floatingCombatTextCombatDamageAllAutos (Game) Default: `1`, Scope: Account Show all auto-attack numbers, rather than hiding non-event numbers  [floatingCombatTextCombatDamageDirectionalOffset](CVar_floatingCombatTextCombatDamageDirectionalOffset.md "CVar floatingCombatTextCombatDamageDirectionalOffset (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalOffset (Game) Default: `1`, Scope: Account Amount to offset directional damage numbers when they start  [floatingCombatTextCombatDamageDirectionalScale](CVar_floatingCombatTextCombatDamageDirectionalScale.md "CVar floatingCombatTextCombatDamageDirectionalScale (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalScale (Game) Default: `1`, Scope: Account Directional damage numbers movement scale (0 = no directional numbers)  [floatingCombatTextCombatDamageStyle](CVar_floatingCombatTextCombatDamageStyle.md "CVar floatingCombatTextCombatDamageStyle (page does not exist)")CVar: floatingCombatTextCombatDamageStyle (Game) Default: `1`, Scope: Account No longer used  [floatingCombatTextCombatDamage](CVar_floatingCombatTextCombatDamage.md "CVar floatingCombatTextCombatDamage (page does not exist)")CVar: floatingCombatTextCombatDamage (Game) Default: `1`, Scope: Account Display damage numbers over hostile creatures when damaged  [floatingCombatTextCombatHealingAbsorbSelf](CVar_floatingCombatTextCombatHealingAbsorbSelf.md "CVar floatingCombatTextCombatHealingAbsorbSelf (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbSelf (Game) Default: `1`, Scope: Account Shows a message when you gain a shield.  [floatingCombatTextCombatHealingAbsorbTarget](CVar_floatingCombatTextCombatHealingAbsorbTarget.md "CVar floatingCombatTextCombatHealingAbsorbTarget (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbTarget (Game) Default: `1`, Scope: Account Display amount of shield added to the target.  [floatingCombatTextCombatHealing](CVar_floatingCombatTextCombatHealing.md "CVar floatingCombatTextCombatHealing (page does not exist)")CVar: floatingCombatTextCombatHealing (Game) Default: `1`, Scope: Account Display amount of healing you did to the target  [floatingCombatTextCombatLogPeriodicSpells](CVar_floatingCombatTextCombatLogPeriodicSpells.md "CVar floatingCombatTextCombatLogPeriodicSpells (page does not exist)")CVar: floatingCombatTextCombatLogPeriodicSpells (Game) Default: `1`, Scope: Account Display damage caused by periodic effects  [floatingCombatTextCombatState](CVar_floatingCombatTextCombatState.md "CVar floatingCombatTextCombatState (page does not exist)")CVar: floatingCombatTextCombatState (Game) Default: `0`, Scope: Account  [floatingCombatTextComboPoints](CVar_floatingCombatTextComboPoints.md "CVar floatingCombatTextComboPoints (page does not exist)")CVar: floatingCombatTextComboPoints (Game) Default: `0`, Scope: Account  [floatingCombatTextDamageReduction](CVar_floatingCombatTextDamageReduction.md "CVar floatingCombatTextDamageReduction (page does not exist)")CVar: floatingCombatTextDamageReduction (Game) Default: `0`, Scope: Account  [floatingCombatTextDodgeParryMiss](CVar_floatingCombatTextDodgeParryMiss.md "CVar floatingCombatTextDodgeParryMiss (page does not exist)")CVar: floatingCombatTextDodgeParryMiss (Game) Default: `0`, Scope: Account  [floatingCombatTextEnergyGains](CVar_floatingCombatTextEnergyGains.md "CVar floatingCombatTextEnergyGains (page does not exist)")CVar: floatingCombatTextEnergyGains (Game) Default: `0`, Scope: Account  [floatingCombatTextFloatMode](CVar_floatingCombatTextFloatMode.md "CVar floatingCombatTextFloatMode (page does not exist)")CVar: floatingCombatTextFloatMode (Game) Default: `1`, Scope: Account The combat text float mode  [floatingCombatTextFriendlyHealers](CVar_floatingCombatTextFriendlyHealers.md "CVar floatingCombatTextFriendlyHealers (page does not exist)")CVar: floatingCombatTextFriendlyHealers (Game) Default: `0`, Scope: Account  [floatingCombatTextHonorGains](CVar_floatingCombatTextHonorGains.md "CVar floatingCombatTextHonorGains (page does not exist)")CVar: floatingCombatTextHonorGains (Game) Default: `0`, Scope: Account  [floatingCombatTextLowManaHealth](CVar_floatingCombatTextLowManaHealth.md "CVar floatingCombatTextLowManaHealth (page does not exist)")CVar: floatingCombatTextLowManaHealth (Game) Default: `1`, Scope: Account  [floatingCombatTextPeriodicEnergyGains](CVar_floatingCombatTextPeriodicEnergyGains.md "CVar floatingCombatTextPeriodicEnergyGains (page does not exist)")CVar: floatingCombatTextPeriodicEnergyGains (Game) Default: `0`, Scope: Account  [floatingCombatTextPetMeleeDamage](CVar_floatingCombatTextPetMeleeDamage.md "CVar floatingCombatTextPetMeleeDamage (page does not exist)")CVar: floatingCombatTextPetMeleeDamage (Game) Default: `1`, Scope: Account Display pet melee damage in the world  [floatingCombatTextPetSpellDamage](CVar_floatingCombatTextPetSpellDamage.md "CVar floatingCombatTextPetSpellDamage (page does not exist)")CVar: floatingCombatTextPetSpellDamage (Game) Default: `1`, Scope: Account Display pet spell damage in the world  [floatingCombatTextReactives](CVar_floatingCombatTextReactives.md "CVar floatingCombatTextReactives (page does not exist)")CVar: floatingCombatTextReactives (Game) Default: `1`, Scope: Account  [floatingCombatTextRepChanges](CVar_floatingCombatTextRepChanges.md "CVar floatingCombatTextRepChanges (page does not exist)")CVar: floatingCombatTextRepChanges (Game) Default: `0`, Scope: Account  [floatingCombatTextSpellMechanicsOther](CVar_floatingCombatTextSpellMechanicsOther.md "CVar floatingCombatTextSpellMechanicsOther (page does not exist)")CVar: floatingCombatTextSpellMechanicsOther (Game) Default: `0`, Scope: Account  [floatingCombatTextSpellMechanics](CVar_floatingCombatTextSpellMechanics.md "CVar floatingCombatTextSpellMechanics (page does not exist)")CVar: floatingCombatTextSpellMechanics (Game) Default: `0`, Scope: Account  [ForceAllowAero](CVar_ForceAllowAero.md "CVar ForceAllowAero")CVar: ForceAllowAero (Graphics) Default: `0` Force Direct X 12 on Windows 7 to not disable Aero theme. You are opting into crashing in some edge cases  [friendsSmallView](CVar_friendsSmallView.md "CVar friendsSmallView")CVar: friendsSmallView (Game) Default: `0`, Scope: Character Whether to use smaller buttons in the friends list  [friendsViewButtons](CVar_friendsViewButtons.md "CVar friendsViewButtons")CVar: friendsViewButtons (Game) Default: `0`, Scope: Character Whether to show the friends list view buttons  [housingExpertGizmos\_Rotation\_BaseOrbScale](CVar_housingExpertGizmos_Rotation_BaseOrbScale.md "CVar housingExpertGizmos Rotation BaseOrbScale (page does not exist)")CVar: housingExpertGizmos\_Rotation\_BaseOrbScale (Game) Default: `0.080000` Base scale of the orb gizmos before multiplying in distance-based scale  [housingExpertGizmos\_Rotation\_BaseRingScale](CVar_housingExpertGizmos_Rotation_BaseRingScale.md "CVar housingExpertGizmos Rotation BaseRingScale (page does not exist)")CVar: housingExpertGizmos\_Rotation\_BaseRingScale (Game) Default: `0.080000` Base scale of the ring gizmos before multiplying in distance-based scale  [housingExpertGizmos\_Rotation\_DistScaleMax](CVar_housingExpertGizmos_Rotation_DistScaleMax.md "CVar housingExpertGizmos Rotation DistScaleMax (page does not exist)")CVar: housingExpertGizmos\_Rotation\_DistScaleMax (Game) Default: `2.250000` Amount of scale to multiply when we're >= ScaleDistanceMax  [housingExpertGizmos\_Rotation\_DistScaleMin](CVar_housingExpertGizmos_Rotation_DistScaleMin.md "CVar housingExpertGizmos Rotation DistScaleMin (page does not exist)")CVar: housingExpertGizmos\_Rotation\_DistScaleMin (Game) Default: `1.000000` Amount of scale to multiply when we're <= ScaleDistanceMin  [housingExpertGizmos\_Rotation\_HighlightDefault](CVar_housingExpertGizmos_Rotation_HighlightDefault.md "CVar housingExpertGizmos Rotation HighlightDefault (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightDefault (None) Default: `0.800000` Intensity of highlight when not hovered/selected/in use  [housingExpertGizmos\_Rotation\_HighlightDragging](CVar_housingExpertGizmos_Rotation_HighlightDragging.md "CVar housingExpertGizmos Rotation HighlightDragging (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightDragging (None) Default: `1.000000` Intensity of highlight when dragging  [housingExpertGizmos\_Rotation\_HighlightHovered](CVar_housingExpertGizmos_Rotation_HighlightHovered.md "CVar housingExpertGizmos Rotation HighlightHovered (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightHovered (None) Default: `0.900000` Intensity of highlight when hovered  [housingExpertGizmos\_Rotation\_HighlightKeybind](CVar_housingExpertGizmos_Rotation_HighlightKeybind.md "CVar housingExpertGizmos Rotation HighlightKeybind (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightKeybind (None) Default: `1.000000` Intensity of highlight when corresponding keybind being pressed  [housingExpertGizmos\_Rotation\_HighlightSelected](CVar_housingExpertGizmos_Rotation_HighlightSelected.md "CVar housingExpertGizmos Rotation HighlightSelected (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightSelected (None) Default: `1.000000` Intensity of highlight when selected  [housingExpertGizmos\_Rotation\_OrbPosOffset](CVar_housingExpertGizmos_Rotation_OrbPosOffset.md "CVar housingExpertGizmos Rotation OrbPosOffset (page does not exist)")CVar: housingExpertGizmos\_Rotation\_OrbPosOffset (Game) Default: `-0.800000` How much offset from the outer edge of the ring's radius the orb should be offset  [housingExpertGizmos\_Rotation\_ScaleDistanceMax](CVar_housingExpertGizmos_Rotation_ScaleDistanceMax.md "CVar housingExpertGizmos Rotation ScaleDistanceMax (page does not exist)")CVar: housingExpertGizmos\_Rotation\_ScaleDistanceMax (Game) Default: `60.000000` Distance at which we'll multiply control scale by DistScaleMax  [housingExpertGizmos\_Rotation\_ScaleDistanceMin](CVar_housingExpertGizmos_Rotation_ScaleDistanceMin.md "CVar housingExpertGizmos Rotation ScaleDistanceMin (page does not exist)")CVar: housingExpertGizmos\_Rotation\_ScaleDistanceMin (Game) Default: `0.000000` Distance at which we'll multiply control scale by DistScaleMin  [housingExpertGizmos\_Rotation\_SnapDegrees](CVar_housingExpertGizmos_Rotation_SnapDegrees.md "CVar housingExpertGizmos Rotation SnapDegrees (page does not exist)")CVar: housingExpertGizmos\_Rotation\_SnapDegrees (None) Default: `15.000000` Degrees rotation should snap  [housingExpertGizmos\_Rotation\_TextMode](CVar_housingExpertGizmos_Rotation_TextMode.md "CVar housingExpertGizmos Rotation TextMode (page does not exist)")CVar: housingExpertGizmos\_Rotation\_TextMode (None) Default: `1` 1: curr angle 0-360, 2: curr angle up to -/+ 180, 3: curr delta 0-360, 4: curr delta up to -/+ 180  [housingExpertGizmos\_Rotation\_XRayCheckerSize](CVar_housingExpertGizmos_Rotation_XRayCheckerSize.md "CVar housingExpertGizmos Rotation XRayCheckerSize (page does not exist)")CVar: housingExpertGizmos\_Rotation\_XRayCheckerSize (Game) Default: `7` The size in pixels of the checker squares for obscured transform gizmos.  [housingExpertGizmos\_Rotation\_XRayDarkAlpha](CVar_housingExpertGizmos_Rotation_XRayDarkAlpha.md "CVar housingExpertGizmos Rotation XRayDarkAlpha (page does not exist)")CVar: housingExpertGizmos\_Rotation\_XRayDarkAlpha (Game) Default: `0.100000` The alpha of the dark square checker pattern for obscured transform gizmos.  [housingExpertGizmos\_Rotation\_XRayLightAlpha](CVar_housingExpertGizmos_Rotation_XRayLightAlpha.md "CVar housingExpertGizmos Rotation XRayLightAlpha (page does not exist)")CVar: housingExpertGizmos\_Rotation\_XRayLightAlpha (Game) Default: `0.250000` The alpha of the light square checker pattern for obscured transform gizmos.  [housingExpertGizmos\_Translation\_BaseArrowHeadScale](CVar_housingExpertGizmos_Translation_BaseArrowHeadScale.md "CVar housingExpertGizmos Translation BaseArrowHeadScale (page does not exist)")CVar: housingExpertGizmos\_Translation\_BaseArrowHeadScale (Game) Default: `0.250000` Base scale of the arrow head gizmos before multiplying in distance-based scale  [housingExpertGizmos\_Translation\_BaseArrowStemScale](CVar_housingExpertGizmos_Translation_BaseArrowStemScale.md "CVar housingExpertGizmos Translation BaseArrowStemScale (page does not exist)")CVar: housingExpertGizmos\_Translation\_BaseArrowStemScale (Game) Default: `0.300000` Base scale of the arrow stem gizmos before multiplying in distance-based scale  [housingExpertGizmos\_Translation\_BaseCubeScale](CVar_housingExpertGizmos_Translation_BaseCubeScale.md "CVar housingExpertGizmos Translation BaseCubeScale (page does not exist)")CVar: housingExpertGizmos\_Translation\_BaseCubeScale (Game) Default: `0.050000` Base scale of the center cube gizmo before multiplying in distance-based scale  [housingExpertGizmos\_Translation\_DistScaleMax](CVar_housingExpertGizmos_Translation_DistScaleMax.md "CVar housingExpertGizmos Translation DistScaleMax (page does not exist)")CVar: housingExpertGizmos\_Translation\_DistScaleMax (Game) Default: `8.000000` Amount of scale to multiply when we're >= ScaleDistanceMax  [housingExpertGizmos\_Translation\_DistScaleMin](CVar_housingExpertGizmos_Translation_DistScaleMin.md "CVar housingExpertGizmos Translation DistScaleMin (page does not exist)")CVar: housingExpertGizmos\_Translation\_DistScaleMin (Game) Default: `1.000000` Amount of scale to multiply when we're <= ScaleDistanceMin  [housingExpertGizmos\_Translation\_HighlightDefault](CVar_housingExpertGizmos_Translation_HighlightDefault.md "CVar housingExpertGizmos Translation HighlightDefault (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightDefault (Game) Default: `0.800000` Intensity of highlight when not hovered/selected/in use  [housingExpertGizmos\_Translation\_HighlightDragging](CVar_housingExpertGizmos_Translation_HighlightDragging.md "CVar housingExpertGizmos Translation HighlightDragging (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightDragging (Game) Default: `1.000000` Intensity of highlight when dragging  [housingExpertGizmos\_Translation\_HighlightHovered](CVar_housingExpertGizmos_Translation_HighlightHovered.md "CVar housingExpertGizmos Translation HighlightHovered (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightHovered (Game) Default: `0.900000` Intensity of highlight when hovered  [housingExpertGizmos\_Translation\_HighlightKeybind](CVar_housingExpertGizmos_Translation_HighlightKeybind.md "CVar housingExpertGizmos Translation HighlightKeybind (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightKeybind (Game) Default: `1.000000` Intensity of highlight when corresponding keybind being pressed  [housingExpertGizmos\_Translation\_HighlightSelected](CVar_housingExpertGizmos_Translation_HighlightSelected.md "CVar housingExpertGizmos Translation HighlightSelected (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightSelected (Game) Default: `1.000000` Intensity of highlight when selected  [housingExpertGizmos\_Translation\_MaxDistanceFromCamera](CVar_housingExpertGizmos_Translation_MaxDistanceFromCamera.md "CVar housingExpertGizmos Translation MaxDistanceFromCamera (page does not exist)")CVar: housingExpertGizmos\_Translation\_MaxDistanceFromCamera (Game) Default: `1000.000000` Hard maximum distance from the camera, beyond which this control can no longer reasonably render or calculate translation  [housingExpertGizmos\_Translation\_Padding](CVar_housingExpertGizmos_Translation_Padding.md "CVar housingExpertGizmos Translation Padding (page does not exist)")CVar: housingExpertGizmos\_Translation\_Padding (Game) Default: `0.050000` Distance the arrows are offset from the center position  [housingExpertGizmos\_Translation\_ScaleDistanceMax](CVar_housingExpertGizmos_Translation_ScaleDistanceMax.md "CVar housingExpertGizmos Translation ScaleDistanceMax (page does not exist)")CVar: housingExpertGizmos\_Translation\_ScaleDistanceMax (Game) Default: `60.000000` Distance at which we'll multiply control scale by DistScaleMax  [housingExpertGizmos\_Translation\_ScaleDistanceMin](CVar_housingExpertGizmos_Translation_ScaleDistanceMin.md "CVar housingExpertGizmos Translation ScaleDistanceMin (page does not exist)")CVar: housingExpertGizmos\_Translation\_ScaleDistanceMin (Game) Default: `0.000000` Distance at which we'll multiply control scale by DistScaleMin  [housingExpertGizmos\_Translation\_XRayCheckerSize](CVar_housingExpertGizmos_Translation_XRayCheckerSize.md "CVar housingExpertGizmos Translation XRayCheckerSize (page does not exist)")CVar: housingExpertGizmos\_Translation\_XRayCheckerSize (Game) Default: `7` The size in pixels of the checker squares for obscured transform gizmos.  [housingExpertGizmos\_Translation\_XRayDarkAlpha](CVar_housingExpertGizmos_Translation_XRayDarkAlpha.md "CVar housingExpertGizmos Translation XRayDarkAlpha (page does not exist)")CVar: housingExpertGizmos\_Translation\_XRayDarkAlpha (Game) Default: `0.600000` The alpha of the dark square checker pattern for obscured transform gizmos.  [housingExpertGizmos\_Translation\_XRayLightAlpha](CVar_housingExpertGizmos_Translation_XRayLightAlpha.md "CVar housingExpertGizmos Translation XRayLightAlpha (page does not exist)")CVar: housingExpertGizmos\_Translation\_XRayLightAlpha (Game) Default: `0.250000` The alpha of the light square checker pattern for obscured transform gizmos.  [lastRenownForMajorFaction2503](CVar_lastRenownForMajorFaction2503.md "CVar lastRenownForMajorFaction2503 (page does not exist)")CVar: lastRenownForMajorFaction2503 (Game) Default: `0`, Scope: Account Stores the Maruuk Centaur renown when Renown UI is closed  [lastRenownForMajorFaction2507](CVar_lastRenownForMajorFaction2507.md "CVar lastRenownForMajorFaction2507 (page does not exist)")CVar: lastRenownForMajorFaction2507 (Game) Default: `0`, Scope: Account Stores the Dragonscale Expedition renown when Renown UI is closed  [lastRenownForMajorFaction2510](CVar_lastRenownForMajorFaction2510.md "CVar lastRenownForMajorFaction2510 (page does not exist)")CVar: lastRenownForMajorFaction2510 (Game) Default: `0`, Scope: Account Stores the Valdrakken Accord renown when Renown UI is closed  [lastRenownForMajorFaction2511](CVar_lastRenownForMajorFaction2511.md "CVar lastRenownForMajorFaction2511 (page does not exist)")CVar: lastRenownForMajorFaction2511 (Game) Default: `0`, Scope: Account Stores the Iskaara Tuskarr renown when Renown UI is closed  [lastRenownForMajorFaction2564](CVar_lastRenownForMajorFaction2564.md "CVar lastRenownForMajorFaction2564 (page does not exist)")CVar: lastRenownForMajorFaction2564 (Game) Default: `0`, Scope: Account Stores the Loamm Niffen renown when Renown UI is closed  [lastRenownForMajorFaction2570](CVar_lastRenownForMajorFaction2570.md "CVar lastRenownForMajorFaction2570 (page does not exist)")CVar: lastRenownForMajorFaction2570 (Game) Default: `0`, Scope: Account Stores the Hallowfall Arathi renown when Renown UI is closed  [lastRenownForMajorFaction2574](CVar_lastRenownForMajorFaction2574.md "CVar lastRenownForMajorFaction2574 (page does not exist)")CVar: lastRenownForMajorFaction2574 (Game) Default: `0`, Scope: Account Stores the Dream Warden renown when Renown UI is closed  [lastRenownForMajorFaction2590](CVar_lastRenownForMajorFaction2590.md "CVar lastRenownForMajorFaction2590 (page does not exist)")CVar: lastRenownForMajorFaction2590 (Game) Default: `0`, Scope: Account Stores the Council of Dornogal renown when Renown UI is closed  [lastRenownForMajorFaction2593](CVar_lastRenownForMajorFaction2593.md "CVar lastRenownForMajorFaction2593 (page does not exist)")CVar: lastRenownForMajorFaction2593 (Game) Default: `0`, Scope: Account Stores the Keg Leg's Crew renown when Renown UI is closed  [lastRenownForMajorFaction2594](CVar_lastRenownForMajorFaction2594.md "CVar lastRenownForMajorFaction2594 (page does not exist)")CVar: lastRenownForMajorFaction2594 (Game) Default: `0`, Scope: Account Stores the Assembly of the Deeps renown when Renown UI is closed  [lastRenownForMajorFaction2600](CVar_lastRenownForMajorFaction2600.md "CVar lastRenownForMajorFaction2600 (page does not exist)")CVar: lastRenownForMajorFaction2600 (Game) Default: `0`, Scope: Account Stores the Severed Threads renown when Renown UI is closed  [lastRenownForMajorFaction2653](CVar_lastRenownForMajorFaction2653.md "CVar lastRenownForMajorFaction2653 (page does not exist)")CVar: lastRenownForMajorFaction2653 (Game) Default: `0`, Scope: Account Stores the Cartels of Undermine Rewards renown when Renown UI is closed  [lastRenownForMajorFaction2658](CVar_lastRenownForMajorFaction2658.md "CVar lastRenownForMajorFaction2658 (page does not exist)")CVar: lastRenownForMajorFaction2658 (Game) Default: `0`, Scope: Account Stores the K'aresh Trust renown when Renown UI is closed  [lastRenownForMajorFaction2685](CVar_lastRenownForMajorFaction2685.md "CVar lastRenownForMajorFaction2685 (page does not exist)")CVar: lastRenownForMajorFaction2685 (Game) Default: `0`, Scope: Account Stores the Gallagio Loyatly Rewards renown when Renown UI is closed  [lastRenownForMajorFaction2688](CVar_lastRenownForMajorFaction2688.md "CVar lastRenownForMajorFaction2688 (page does not exist)")CVar: lastRenownForMajorFaction2688 (Game) Default: `0`, Scope: Account Stores the Flame's Radiance renown when Renown UI is closed  [lastRenownForMajorFaction2736](CVar_lastRenownForMajorFaction2736.md "CVar lastRenownForMajorFaction2736 (page does not exist)")CVar: lastRenownForMajorFaction2736 (Game) Default: `0`, Scope: Account Stores the Manaforge Vandals renown when Renown UI is closed  [lastTransmogOutfitIDSpec1](CVar_lastTransmogOutfitIDSpec1.md "CVar lastTransmogOutfitIDSpec1 (page does not exist)")CVar: lastTransmogOutfitIDSpec1 (Game) Scope: Character SetID of the last applied transmog outfit for the 1st spec  [lastTransmogOutfitIDSpec2](CVar_lastTransmogOutfitIDSpec2.md "CVar lastTransmogOutfitIDSpec2 (page does not exist)")CVar: lastTransmogOutfitIDSpec2 (Game) Scope: Character SetID of the last applied transmog outfit for the 2nd spec  [lastTransmogOutfitIDSpec3](CVar_lastTransmogOutfitIDSpec3.md "CVar lastTransmogOutfitIDSpec3 (page does not exist)")CVar: lastTransmogOutfitIDSpec3 (Game) Scope: Character SetID of the last applied transmog outfit for the 3rd spec  [lastTransmogOutfitIDSpec4](CVar_lastTransmogOutfitIDSpec4.md "CVar lastTransmogOutfitIDSpec4 (page does not exist)")CVar: lastTransmogOutfitIDSpec4 (Game) Scope: Character SetID of the last applied transmog outfit for the 4th spec  [lfgAutoFill](CVar_lfgAutoFill.md "CVar lfgAutoFill")CVar: lfgAutoFill (Game) Default: `0`, Scope: Account Whether to automatically add party members while looking for a group  [lfgAutoJoin](CVar_lfgAutoJoin.md "CVar lfgAutoJoin")CVar: lfgAutoJoin (Game) Default: `0`, Scope: Account Whether to automatically join a party while looking for a group  [lfGuildComment](CVar_lfGuildComment.md "CVar lfGuildComment")CVar: lfGuildComment (Game) Scope: Character Stores the player's Looking For Guild comment  [lfGuildSettings](CVar_lfGuildSettings.md "CVar lfGuildSettings (page does not exist)")CVar: lfGuildSettings (Game) Default: `1`, Scope: Character Bit field of Looking For Guild player settings  [mapAnimDuration](CVar_mapAnimDuration.md "CVar mapAnimDuration (page does not exist)")CVar: mapAnimDuration (Game) Default: `0.12`, Scope: Account Duration for the alpha animation  [mapAnimMinAlpha](CVar_mapAnimMinAlpha.md "CVar mapAnimMinAlpha (page does not exist)")CVar: mapAnimMinAlpha (Game) Default: `0.35`, Scope: Account Alpha value to animate to when player moves with windowed world map open  [mapAnimStartDelay](CVar_mapAnimStartDelay.md "CVar mapAnimStartDelay (page does not exist)")CVar: mapAnimStartDelay (Game) Default: `0.0`, Scope: Account Start delay for the alpha animation  [minimapAltitudeHintMode](CVar_minimapAltitudeHintMode.md "CVar minimapAltitudeHintMode (page does not exist)")CVar: minimapAltitudeHintMode (Game) Default: `0` Change minimap altitude difference display. 0=none, 1=darken, 2=arrows  [minimapShowArchBlobs](CVar_minimapShowArchBlobs.md "CVar minimapShowArchBlobs (page does not exist)")CVar: minimapShowArchBlobs (Game) Default: `1`, Scope: Character Stores whether to show the quest blobs on the minimap.  [minimapShowQuestBlobs](CVar_minimapShowQuestBlobs.md "CVar minimapShowQuestBlobs (page does not exist)")CVar: minimapShowQuestBlobs (Game) Default: `1`, Scope: Character Stores whether to show the quest blobs on the minimap.  [nameplateClassResourceTopInset](CVar_nameplateClassResourceTopInset.md "CVar nameplateClassResourceTopInset (page does not exist)")CVar: nameplateClassResourceTopInset (Graphics) Default: `.03`, Scope: Character The inset from the top (in screen percent) that nameplates are clamped to when class resources are being displayed on them.  [nameplateGlobalScale](CVar_nameplateGlobalScale.md "CVar nameplateGlobalScale (page does not exist)")CVar: nameplateGlobalScale (Graphics) Default: `1.0`, Scope: Character Applies global scaling to non-self nameplates, this is applied AFTER selected, min, and max scale.  [nameplateHideHealthAndPower](CVar_nameplateHideHealthAndPower.md "CVar nameplateHideHealthAndPower (page does not exist)")CVar: nameplateHideHealthAndPower (Game) Default: `0`, Scope: Character  [nameplateLargeBottomInset](CVar_nameplateLargeBottomInset.md "CVar nameplateLargeBottomInset (page does not exist)")CVar: nameplateLargeBottomInset (Graphics) Default: `0.15`, Scope: Character The inset from the bottom (in screen percent) that large nameplates are clamped to.  [nameplateLargeTopInset](CVar_nameplateLargeTopInset.md "CVar nameplateLargeTopInset (page does not exist)")CVar: nameplateLargeTopInset (Graphics) Default: `0.1`, Scope: Character The inset from the top (in screen percent) that large nameplates are clamped to.  [NamePlateMaximumClassificationScale](CVar_NamePlateMaximumClassificationScale.md "CVar NamePlateMaximumClassificationScale (page does not exist)")CVar: NamePlateMaximumClassificationScale (Game) Default: `1.25`, Scope: Character This is the maximum effective scale of the classification icon for nameplates.  [nameplateMotionSpeed](CVar_nameplateMotionSpeed.md "CVar nameplateMotionSpeed (page does not exist)")CVar: nameplateMotionSpeed (Graphics) Default: `0.025`, Scope: Character Controls the rate at which nameplate animates into their target locations [0.0-1.0]  [nameplateMotion](CVar_nameplateMotion.md "CVar nameplateMotion")CVar: nameplateMotion (Graphics) Default: `0`, Scope: Character Defines the movement/collision model for nameplates  [NameplatePersonalClickThrough](CVar_NameplatePersonalClickThrough.md "CVar NameplatePersonalClickThrough (page does not exist)")CVar: NameplatePersonalClickThrough (Game) Default: `1`, Scope: Character When enabled, the personal nameplate is transparent to mouse clicks.  [NameplatePersonalHideDelayAlpha](CVar_NameplatePersonalHideDelayAlpha.md "CVar NameplatePersonalHideDelayAlpha (page does not exist)")CVar: NameplatePersonalHideDelayAlpha (Game) Default: `0.45`, Scope: Character Determines the alpha of the personal nameplate after no visibility conditions are met (during the period of time specified by NameplatePersonalHideDelaySeconds).  [NameplatePersonalHideDelaySeconds](CVar_NameplatePersonalHideDelaySeconds.md "CVar NameplatePersonalHideDelaySeconds (page does not exist)")CVar: NameplatePersonalHideDelaySeconds (Game) Default: `3.0`, Scope: Character Determines the length of time in seconds that the personal nameplate will be visible after no visibility conditions are met.  [NameplatePersonalShowAlways](CVar_NameplatePersonalShowAlways.md "CVar NameplatePersonalShowAlways (page does not exist)")CVar: NameplatePersonalShowAlways (Game) Default: `0`, Scope: Character Determines if the the personal nameplate is always shown.  [NameplatePersonalShowInCombat](CVar_NameplatePersonalShowInCombat.md "CVar NameplatePersonalShowInCombat (page does not exist)")CVar: NameplatePersonalShowInCombat (Game) Default: `1`, Scope: Character Determines if the the personal nameplate is shown when you enter combat.  [NameplatePersonalShowWithTarget](CVar_NameplatePersonalShowWithTarget.md "CVar NameplatePersonalShowWithTarget (page does not exist)")CVar: NameplatePersonalShowWithTarget (Game) Default: `0`, Scope: Character Determines if the personal nameplate is shown when selecting a target. 0 = targeting has no effect, 1 = show on hostile target, 2 = show on any target  [nameplateResourceOnTarget](CVar_nameplateResourceOnTarget.md "CVar nameplateResourceOnTarget (page does not exist)")CVar: nameplateResourceOnTarget (Game) Default: `0`, Scope: Character Nameplate class resource overlay mode. 0=self, 1=target  [nameplateSelfBottomInset](CVar_nameplateSelfBottomInset.md "CVar nameplateSelfBottomInset (page does not exist)")CVar: nameplateSelfBottomInset (Graphics) Default: `0.2`, Scope: Character The inset from the bottom (in screen percent) that the self nameplate is clamped to.  [nameplateSelfScale](CVar_nameplateSelfScale.md "CVar nameplateSelfScale (page does not exist)")CVar: nameplateSelfScale (Graphics) Default: `1.0`, Scope: Character The scale of the self nameplate.  [nameplateSelfTopInset](CVar_nameplateSelfTopInset.md "CVar nameplateSelfTopInset (page does not exist)")CVar: nameplateSelfTopInset (Graphics) Default: `0.5`, Scope: Character The inset from the top (in screen percent) that the self nameplate is clamped to.  [nameplateShowFriendlyBuffs](CVar_nameplateShowFriendlyBuffs.md "CVar nameplateShowFriendlyBuffs (page does not exist)")CVar: nameplateShowFriendlyBuffs (Game) Default: `0`, Scope: Character  [nameplateShowFriendlyGuardians](CVar_nameplateShowFriendlyGuardians.md "CVar nameplateShowFriendlyGuardians (page does not exist)")CVar: nameplateShowFriendlyGuardians (Game) Default: `0`, Scope: Character  [nameplateShowFriendlyMinions](CVar_nameplateShowFriendlyMinions.md "CVar nameplateShowFriendlyMinions (page does not exist)")CVar: nameplateShowFriendlyMinions (Game) Default: `0`, Scope: Character  [nameplateShowFriendlyNPCs](CVar_nameplateShowFriendlyNPCs.md "CVar nameplateShowFriendlyNPCs (page does not exist)")CVar: nameplateShowFriendlyNPCs (Game) Default: `0`, Scope: Character  [nameplateShowFriendlyPets](CVar_nameplateShowFriendlyPets.md "CVar nameplateShowFriendlyPets (page does not exist)")CVar: nameplateShowFriendlyPets (Game) Default: `0`, Scope: Character  [nameplateShowFriendlyTotems](CVar_nameplateShowFriendlyTotems.md "CVar nameplateShowFriendlyTotems (page does not exist)")CVar: nameplateShowFriendlyTotems (Game) Default: `0`, Scope: Character  [nameplateShowOnlyNames](CVar_nameplateShowOnlyNames.md "CVar nameplateShowOnlyNames (page does not exist)")CVar: nameplateShowOnlyNames (Game) Default: `0` Whether to hide the nameplate bars  [nameplateShowPersonalCooldowns](CVar_nameplateShowPersonalCooldowns.md "CVar nameplateShowPersonalCooldowns (page does not exist)")CVar: nameplateShowPersonalCooldowns (Game) Default: `0`, Scope: Character If set, personal buffs/debuffs will appear above the personal resource display  [removeChatDelay](CVar_removeChatDelay.md "CVar removeChatDelay (page does not exist)")CVar: removeChatDelay (Game) Default: `0`, Scope: Account Remove Chat Hover Delay  [ShowClassColorInFriendlyNameplate](CVar_ShowClassColorInFriendlyNameplate.md "CVar ShowClassColorInFriendlyNameplate (page does not exist)")CVar: ShowClassColorInFriendlyNameplate (Game) Default: `1`, Scope: Character use this to display the class color in friendly nameplate health bars  [ShowNamePlateLoseAggroFlash](CVar_ShowNamePlateLoseAggroFlash.md "CVar ShowNamePlateLoseAggroFlash (page does not exist)")CVar: ShowNamePlateLoseAggroFlash (Game) Default: `1`, Scope: Character When enabled, if you are a tank role and lose aggro, the nameplate with briefly flash.  [showQuestObjectivesOnMap](CVar_showQuestObjectivesOnMap.md "CVar showQuestObjectivesOnMap (page does not exist)")CVar: showQuestObjectivesOnMap (Game) Default: `1`, Scope: Character Shows quest POIs on the main map.  [showTokenFrameHonor](CVar_showTokenFrameHonor.md "CVar showTokenFrameHonor (page does not exist)")CVar: showTokenFrameHonor (Game) Default: `0`, Scope: Character The token UI has shown Honor  [splashScreenBoost](CVar_splashScreenBoost.md "CVar splashScreenBoost (page does not exist)")CVar: splashScreenBoost (Game) Default: `0`, Scope: Character Show boost splash screen id  [splashScreenSeason](CVar_splashScreenSeason.md "CVar splashScreenSeason (page does not exist)")CVar: splashScreenSeason (Game) Default: `1`, Scope: Character Show season splash screen id  [TerrainBlendBakeEnable](CVar_TerrainBlendBakeEnable.md "CVar TerrainBlendBakeEnable (page does not exist)")CVar: TerrainBlendBakeEnable (Graphics) Default: `0` Enable pre-blending terrain layers  [TerrainUnlitShaderEnable](CVar_TerrainUnlitShaderEnable.md "CVar TerrainUnlitShaderEnable (page does not exist)")CVar: TerrainUnlitShaderEnable (Graphics) Default: `0` Enable Unlit terrain shader  [trackQuestSorting](CVar_trackQuestSorting.md "CVar trackQuestSorting (page does not exist)")CVar: trackQuestSorting (Game) Default: `top`, Scope: Account Whether to sort the last tracked quest to the top of the quest tracker or use proximity sorting  [watchFrameBaseAlpha](CVar_watchFrameBaseAlpha.md "CVar watchFrameBaseAlpha (page does not exist)")CVar: watchFrameBaseAlpha (Game) Default: `0`, Scope: Account Objectives frame opacity.  [watchFrameIgnoreCursor](CVar_watchFrameIgnoreCursor.md "CVar watchFrameIgnoreCursor (page does not exist)")CVar: watchFrameIgnoreCursor (Game) Default: `0`, Scope: Account Disables Objectives frame mouseover and title dropdown.  [watchFrameState](CVar_watchFrameState.md "CVar watchFrameState (page does not exist)")CVar: watchFrameState (Game) Default: `0`, Scope: Account Stores Objectives frame locked and collapsed states  [WorldTextCritScreenY](CVar_WorldTextCritScreenY.md "CVar WorldTextCritScreenY (page does not exist)")CVar: WorldTextCritScreenY (Game) Default: `0.0275`, Scope: Account  [WorldTextGravity](CVar_WorldTextGravity.md "CVar WorldTextGravity (page does not exist)")CVar: WorldTextGravity (Game) Default: `0.5`, Scope: Account  [WorldTextMinAlpha](CVar_WorldTextMinAlpha.md "CVar WorldTextMinAlpha (page does not exist)")CVar: WorldTextMinAlpha (Game) Default: `0.5`, Scope: Account  [WorldTextNonRandomZ](CVar_WorldTextNonRandomZ.md "CVar WorldTextNonRandomZ (page does not exist)")CVar: WorldTextNonRandomZ (Game) Default: `2.5`, Scope: Account  [WorldTextRampDuration](CVar_WorldTextRampDuration.md "CVar WorldTextRampDuration (page does not exist)")CVar: WorldTextRampDuration (Game) Default: `1.0`, Scope: Account  [WorldTextRampPowCrit](CVar_WorldTextRampPowCrit.md "CVar WorldTextRampPowCrit (page does not exist)")CVar: WorldTextRampPowCrit (Game) Default: `8.0`, Scope: Account  [WorldTextRampPow](CVar_WorldTextRampPow.md "CVar WorldTextRampPow (page does not exist)")CVar: WorldTextRampPow (Game) Default: `1.9`, Scope: Account  [WorldTextRandomXY](CVar_WorldTextRandomXY.md "CVar WorldTextRandomXY (page does not exist)")CVar: WorldTextRandomXY (Game) Default: `0.0`, Scope: Account  [WorldTextRandomZMax](CVar_WorldTextRandomZMax.md "CVar WorldTextRandomZMax (page does not exist)")CVar: WorldTextRandomZMax (Game) Default: `1.5`, Scope: Account  [WorldTextRandomZMin](CVar_WorldTextRandomZMin.md "CVar WorldTextRandomZMin (page does not exist)")CVar: WorldTextRandomZMin (Game) Default: `0.8`, Scope: Account  [WorldTextScale](CVar_WorldTextScale.md "CVar WorldTextScale (page does not exist)")CVar: WorldTextScale (Game) Default: `1.0`, Scope: Account  [WorldTextScreenY](CVar_WorldTextScreenY.md "CVar WorldTextScreenY (page does not exist)")CVar: WorldTextScreenY (Game) Default: `0.015`, Scope: Account  [WorldTextStartPosRandomness](CVar_WorldTextStartPosRandomness.md "CVar WorldTextStartPosRandomness (page does not exist)")CVar: WorldTextStartPosRandomness (Game) Default: `1.0`, Scope: Account |

|  |
| --- |
| **[Deprecated\_11\_0\_0.lua](https://github.com/Gethe/wow-ui-source/blob/11.0.0/Interface/AddOns/Blizzard_Deprecated/Deprecated_11_0_0.lua)**  [GetSpellInfo](API_GetSpellInfo.md "API GetSpellInfo") → [C\_Spell.GetSpellInfo](API_C_Spell.GetSpellInfo.md "API C Spell.GetSpellInfo")  [GetNumSpellTabs](API_GetNumSpellTabs.md "API GetNumSpellTabs") → [C\_SpellBook.GetNumSpellBookSkillLines](API_C_SpellBook.GetNumSpellBookSkillLines.md "API C SpellBook.GetNumSpellBookSkillLines")  [GetSpellTabInfo](API_GetSpellTabInfo.md "API GetSpellTabInfo") → [C\_SpellBook.GetSpellBookSkillLineInfo](API_C_SpellBook.GetSpellBookSkillLineInfo.md "API C SpellBook.GetSpellBookSkillLineInfo")  [GetSpellCooldown](API_GetSpellCooldown.md "API GetSpellCooldown") → [C\_Spell.GetSpellCooldown](API_C_Spell.GetSpellCooldown.md "API C Spell.GetSpellCooldown")  [GetSpellBookItemName](API_GetSpellBookItemName.md "API GetSpellBookItemName") → [C\_SpellBook.GetSpellBookItemName](API_C_SpellBook.GetSpellBookItemName.md "API C SpellBook.GetSpellBookItemName")  [GetSpellTexture](API_GetSpellTexture.md "API GetSpellTexture") → [C\_Spell.GetSpellTexture](API_C_Spell.GetSpellTexture.md "API C Spell.GetSpellTexture")  [GetSpellCharges](API_GetSpellCharges.md "API GetSpellCharges") → [C\_Spell.GetSpellCharges](API_C_Spell.GetSpellCharges.md "API C Spell.GetSpellCharges")  [GetSpellDescription](API_GetSpellDescription.md "API GetSpellDescription") → [C\_Spell.GetSpellDescription](API_C_Spell.GetSpellDescription.md "API C Spell.GetSpellDescription")  [GetSpellCount](API_GetSpellCount.md "API GetSpellCount") → [C\_Spell.GetSpellCastCount](API_C_Spell.GetSpellCastCount.md "API C Spell.GetSpellCastCount")  [IsUsableSpell](API_IsUsableSpell.md "API IsUsableSpell") → [C\_Spell.IsSpellUsable](API_C_Spell.IsSpellUsable.md "API C Spell.IsSpellUsable")  **[Deprecated\_11\_0\_5.lua](https://github.com/Gethe/wow-ui-source/blob/11.0.5/Interface/AddOns/Blizzard_Deprecated/Deprecated_11_0_5.lua)**  [C\_TaskQuest.GetQuestsForPlayerByMapID](API_C_TaskQuest.GetQuestsForPlayerByMapID.md "API C TaskQuest.GetQuestsForPlayerByMapID") → [C\_TaskQuest.GetQuestsOnMap](API_C_TaskQuest.GetQuestsOnMap.md "API C TaskQuest.GetQuestsOnMap")  [GetMerchantItemInfo](API_GetMerchantItemInfo.md "API GetMerchantItemInfo") → [C\_MerchantFrame.GetItemInfo](API_C_MerchantFrame.GetItemInfo.md "API C MerchantFrame.GetItemInfo")  [C\_ChallengeMode.GetCompletionInfo](API_C_ChallengeMode.GetCompletionInfo.md "API C ChallengeMode.GetCompletionInfo") → [C\_ChallengeMode.GetChallengeCompletionInfo](API_C_ChallengeMode.GetChallengeCompletionInfo.md "API C ChallengeMode.GetChallengeCompletionInfo")  [C\_MythicPlus.IsWeeklyRewardAvailable](API_C_MythicPlus.IsWeeklyRewardAvailable.md "API C MythicPlus.IsWeeklyRewardAvailable")  **[Deprecated\_11\_0\_7.lua](https://github.com/Gethe/wow-ui-source/blob/11.0.7/Interface/AddOns/Blizzard_Deprecated/Deprecated_11_0_7.lua)**  [IsActiveQuestLegendary](API_IsActiveQuestLegendary.md "API IsActiveQuestLegendary (page does not exist)") → [C\_QuestInfoSystem.GetQuestClassification](API_C_QuestInfoSystem.GetQuestClassification.md "API C QuestInfoSystem.GetQuestClassification")  [C\_QuestLog.IsLegendaryQuest](API_C_QuestLog.IsLegendaryQuest.md "API C QuestLog.IsLegendaryQuest") → [C\_QuestInfoSystem.GetQuestClassification](API_C_QuestInfoSystem.GetQuestClassification.md "API C QuestInfoSystem.GetQuestClassification")  [C\_QuestLog.IsQuestRepeatableType](API_C_QuestLog.IsQuestRepeatableType.md "API C QuestLog.IsQuestRepeatableType") → [C\_QuestLog.IsRepeatableQuest](API_C_QuestLog.IsRepeatableQuest.md "API C QuestLog.IsRepeatableQuest")  **[Deprecated\_11\_1\_5.lua](https://github.com/Gethe/wow-ui-source/blob/11.1.5/Interface/AddOns/Blizzard_Deprecated/Deprecated_11_1_5.lua)**  [ConsolePrint](API_ConsolePrint.md "API ConsolePrint (page does not exist)") → [C\_Log.LogMessage](API_C_Log.LogMessage.md "API C Log.LogMessage")  [message](API_message.md "API message") → [SetBasicMessageDialogText](API_SetBasicMessageDialogText.md "API SetBasicMessageDialogText (page does not exist)")  **[Deprecated\_11\_2\_0.lua](https://github.com/Gethe/wow-ui-source/blob/11.2.0/Interface/AddOns/Blizzard_Deprecated/Deprecated_11_2_0.lua)**  [IsSpellOverlayed](API_IsSpellOverlayed.md "API IsSpellOverlayed") → [C\_SpellActivationOverlay.IsSpellOverlayed](API_C_SpellActivationOverlay.IsSpellOverlayed.md "API C SpellActivationOverlay.IsSpellOverlayed")  **[Deprecated\_11\_2\_5.lua](https://github.com/Gethe/wow-ui-source/blob/11.2.5/Interface/AddOns/Blizzard_Deprecated/Deprecated_11_2_5.lua)**  [IsArtifactRelicItem](API_IsArtifactRelicItem.md "API IsArtifactRelicItem (page does not exist)") → [C\_ItemSocketInfo.IsArtifactRelicItem](API_C_ItemSocketInfo.IsArtifactRelicItem.md "API C ItemSocketInfo.IsArtifactRelicItem") |

`120000`

```
C_Housing.RequestHouseFinderNeighborhoodData
  + arg 2: neighborhoodName
C_Item.CanItemTransmogAppearance
  # ret 2: errorCode, Type: number -> TransmogOutfitSlotError
C_Item.GetItemInfo
  + ret 18: itemDescription
C_LFGList.DoesEntryTitleMatchPrebuiltTitle
  + arg 4: generalPlaystyle
C_LFGList.GetPlaystyleString
  + arg 2: generalPlaystyle
C_LFGList.SetEntryTitle
  + arg 4: generalPlaystyle
C_Reputation.GetFactionParagonInfo
  + ret 6: paragonStorageLevel
C_Reputation.IsFactionParagon
  # ret 1: hasParagon -> factionIsParagon
C_SpecializationInfo.GetSpecializationInfo
  + arg 7: classID
C_TooltipInfo.GetRecipeResultItem
  # arg 2: craftingReagents -> reagentInfos
C_TooltipInfo.GetRecipeResultItemForOrder
  # arg 2: craftingReagents -> reagentInfos
C_TradeSkillUI.GetEnchantItems
  + arg 2: craftingReagents
C_TradeSkillUI.GetRecraftRemovalWarnings
  # arg 2: replacedItemIDs -> replacedReagents
C_TradeSkillUI.IsRecraftReagentValid
  # arg 2: itemID -> reagent
C_TradeSkillUI.RecraftLimitCategoryValid
  # arg 1: reagentItemID -> reagent
C_Transmog.GetSlotVisualInfo
  # ret 1: slotVisualInfo
C_TransmogCollection.GetAppearanceSourceInfo
  # ret 1: info
C_UnitAuras.GetUnitAuras
  + arg 4: sortRule
  + arg 5: sortDirection
C_VoiceChat.SpeakText
  + arg 5: overlap
  - arg 3: destination
UnitCastingInfo
  # ret 8: notInterruptible, Nilable: false -> true
  + ret 10: castBarID
UnitChannelInfo
  # arg 1: unitToken -> unit
  # ret 7: notInterruptible, Nilable: false -> true
  + ret 11: castBarID
```

```
TextureBase:SetAtlas
  + arg 5: wrapModeHorizontal
  + arg 6: wrapModeVertical
StatusBar:SetMinMaxValues
  + arg 3: interpolation
StatusBar:SetValue
  + arg 2: interpolation
```

```
VOICE_CHAT_TTS_PLAYBACK_FAILED
  - 3: destination
VOICE_CHAT_TTS_PLAYBACK_FINISHED
  - 1: numConsumers
  - 3: destination
VOICE_CHAT_TTS_PLAYBACK_STARTED
  - 1: numConsumers
  - 3: durationMS
  - 4: destination
```

`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`4`
`1.500000`
`0`
`0.000000`
`1`
`0`
`0.000000`
`0.000000`
`0.000000`
`1`
`1`
`1`
`0`
`0`
`1.500000`
`0`
`0.000000`
`0`
`3`
`2`
`0.000000`
`0`
`100`
`0`
`1`
`0`
`0`
`1`
`1`
`0`
`0`
`0`
`1`
`3500`
`1`
`0`
`0`
`0`
`1`
`0`
`0`
`0`
`1`
`1`
`1.000000`
`1.000000`
`1`
`1`
`1`
`1`
`0`
`0`
`0`
`0`
`0`
`1`
`0`
`0`
`1`
`0`
`1`
`1`
`1`
`0`
`0`
`1.000000`
`0`
`1`
`1`
`1`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`1`
`0`
`0`
`1`
`1`
`2`
`1`
`FF2B9305`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`1`
`1`
`1.000000`
`1`
`0`
`0`
`0`
`0.0275`
`0.500000`
`0.500000`
`2.5`
`1.000000`
`1.900000`
`8.000000`
`0.0`
`1.5`
`0.8`
`1.000000`
`0.015`
`1.0`
`0`
`0`
`0`
`0`
`0`
`0`
`1`
`0`
`0`
`1`
`1`
`1`
`1`
`1`
`1`
`1`
`1`
`1`
`0`
`0`
`0`
`0`
`0`
`1`
`0`
`0`
`1`
`0`
`1`
`1`
`1`
`0`
`0`
`0`
`0`
`0`
`0`
`0.080000`
`0.080000`
`2.250000`
`1.000000`
`0.800000`
`1.000000`
`0.900000`
`1.000000`
`1.000000`
`-0.800000`
`60.000000`
`0.000000`
`15.000000`
`1`
`7`
`0.100000`
`0.250000`
`0.250000`
`0.300000`
`0.050000`
`8.000000`
`1.000000`
`0.800000`
`1.000000`
`0.900000`
`1.000000`
`1.000000`
`1000.000000`
`0.050000`
`60.000000`
`0.000000`
`7`
`0.600000`
`0.250000`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`1`
`0.12`
`0.35`
`0.0`
`0`
`1`
`1`
`.03`
`1.0`
`0`
`0.15`
`0.1`
`1.25`
`0.025`
`0`
`1`
`0.45`
`3.0`
`0`
`1`
`0`
`0`
`0.2`
`1.0`
`0.5`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`0`
`1`
`1`
`1`
`0`
`0`
`1`
`0`
`0`
`top`
`0`
`0`
`0`
`0.0275`
`0.5`
`0.5`
`2.5`
`1.0`
`8.0`
`1.9`
`0.0`
`1.5`
`0.8`
`1.0`
`0.015`
`1.0`

```
Enum.CraftingOrderResult
  + MissingCurrency
  + TooManyCurrencies
Enum.EditModeAccountSetting
  + ShowPersonalResourceDisplay
  + ShowEncounterEvents
  + ShowDamageMeter
  + ShowExternalDefensives
Enum.EditModeSystem
  + PersonalResourceDisplay
  + EncounterEvents
  + DamageMeter
Enum.PlayerInteractionType
  # PlaceholderType79 -> TieredEntrance
Enum.QuestTagType
  # Placeholder_1 -> Prey
Enum.SendAddonMessageResult
  + AddOnMessageLockdown
  + TargetOffline
Enum.SurveyDeliveryMoment
  + MythicPlusCompleted
Enum.TooltipDataLineType
  + SpellPassive
  + SpellDescription
Enum.TooltipDataType
  + Outfit
Enum.TradeskillRecipeType
  - Recraft
Enum.UICursorType
  + Outfit
Enum.UIWidgetVisualizationType
  + PreyHuntProgress
```

```
AdvancedFilterOptions
  + generalPlaystyle1
  + generalPlaystyle2
  + generalPlaystyle3
  + generalPlaystyle4
CatalogShopCategoryInfo
  + showPersistentRefundButton
CatalogShopProductInfo
  +  consumableQuantity
CooldownViewerCooldown
  + cooldownID
  + category
CraftingItemSlotModification
  + itemID -> reagent
CraftingOrderReagentInfo
  # reagent -> reagentInfo
CraftingReagentInfo
  + itemID -> reagent
CraftingReagentSlotSchematic
  + variableQuantities
CraftingResourceReturnInfo
  + itemID -> reagent
ExpansionDisplayInfo
  + glueAmbianceSoundKit
  + glueMusicSoundKit
  + glueCreditsSoundKit
ItemInteractionFrameInfo
  # flags, Type: number -> UIItemInteractionFlags
LfgEntryData
  + generalPlaystyle
LfgListingCreateData
  + generalPlaystyle
LfgSearchResultData
  + generalPlaystyle
MajorFactionData
  + description
  + highlights
  + playerCompanionID
MajorFactionRenownRewardInfo
  + rewardType
NewCraftingOrderInfo
  # reagentItems -> reagentInfos
PrivateAuraIconInfo
  + borderScale
RegularReagentInfo
  + itemID -> reagent
ScheduledEventInfo
  + eventID
  + displayInfo
SpellCooldownInfo
  + timeUntilEndOfStartRecovery
  + isOnGCD
TransmogAppearanceSourceInfoData
  + itemSubClass -> itemSubclass
TransmogSetInfo
  + grantAsPrecedingVariant
```

* [WoW API](World_of_Warcraft_API.md "World of Warcraft API")
* [Lua API](Lua_functions.md "Lua functions")
* [FrameXML API](FrameXML_functions.md "FrameXML functions")

* [Widget API](Widget_API.md "Widget API")
* [Widget scripts](Widget_script_handlers.md "Widget script handlers")
* [XML schema](XML_schema.md "XML schema")
* [Events](Events.md "Events")
* [CVars](Console_variables.md "Console variables")

* [Macro commands](Macro_commands.md "Macro commands")
* [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT")
* [Escape sequences](UI_escape_sequences.md "UI escape sequences")
* [Hyperlinks](Hyperlinks.md "Hyperlinks")
* [API changes](API_change_summaries.md "API change summaries")
* [HOWTOs](HOWTOs.md "HOWTOs")
* [![Discord logo.png](/images/thumb/Discord_logo.png/12px-Discord_logo.png?4d7bc2)](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6)

* Previous patch: [Patch 11.2.7](Patch_11.2.7/API_changes.md "Patch 11.2.7/API changes").
* Next patch: [Patch 12.0.1](Patch_12.0.1/API_changes.md "Patch 12.0.1/API changes").

* [1 Summary](#Summary)
* [2 Resources](#Resources)
* [3 AddOn security changes](#AddOn_security_changes)
  + [3.1 Secret values](#Secret_values)
* [4 Consolidated changes](#Consolidated_changes)
  + [4.1 Global API](#Global_API)
  + [4.2 ScriptObjects](#ScriptObjects)
  + [4.3 Widgets](#Widgets)
  + [4.4 Events](#Events)
  + [4.5 CVars](#CVars)
  + [4.6 Enums](#Enums)
  + [4.7 Structures](#Structures)
* [5 Deprecated 11.x API](#Deprecated_11.x_API)

* [3.1 Secret values](#Secret_values)

* [4.1 Global API](#Global_API)
* [4.2 ScriptObjects](#ScriptObjects)
* [4.3 Widgets](#Widgets)
* [4.4 Events](#Events)
* [4.5 CVars](#CVars)
* [4.6 Enums](#Enums)
* [4.7 Structures](#Structures)

* Addon apocalypse. ![Emoji fatcatfire.png](/images/thumb/Emoji_fatcatfire.png/24px-Emoji_fatcatfire.png?323fa7)

* TOC: `120000`

* Diffs: [wow-ui-source](https://github.com/Gethe/wow-ui-source/compare/11.2.7..12.0.0), [BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources/compare/11.2.7..12.0.0)
* Official patch notes: [Midnight Pre-Expansion Content Update Notes](https://worldofwarcraft.blizzard.com/en-us/news/24244455/midnight-pre-expansion-content-update-notes#item13)
* Official restriction changes: ![Blizz.gif](/images/Blizz.gif?984542) [Planned API changes](Patch_12.0.0/Planned_API_changes.md "Patch 12.0.0/Planned API changes")
* Deprecated APIs:
  + [Deprecated\_BattleNet.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedBattleNet/Deprecated_BattleNet.lua)
  + [Deprecated\_ChatInfo.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedChatInfo/Deprecated_ChatInfo.lua)
  + [Deprecated\_ChatFrame.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedChatInfo/Deprecated_ChatFrame.lua)
  + [Deprecated\_CombatLog.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedCombatLog/Deprecated_CombatLog.lua)
  + [Deprecated\_SpellBook.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedSpellBook/Deprecated_SpellBook.lua)
  + [Deprecated\_InstanceEncounter.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedInstanceEncounter/Deprecated_InstanceEncounter.lua)
  + [Deprecated\_SpellScript.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedSpellScript/Deprecated_SpellScript.lua)

* [Deprecated\_BattleNet.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedBattleNet/Deprecated_BattleNet.lua)
* [Deprecated\_ChatInfo.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedChatInfo/Deprecated_ChatInfo.lua)
* [Deprecated\_ChatFrame.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedChatInfo/Deprecated_ChatFrame.lua)
* [Deprecated\_CombatLog.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedCombatLog/Deprecated_CombatLog.lua)
* [Deprecated\_SpellBook.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedSpellBook/Deprecated_SpellBook.lua)
* [Deprecated\_InstanceEncounter.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedInstanceEncounter/Deprecated_InstanceEncounter.lua)
* [Deprecated\_SpellScript.lua](https://github.com/Gethe/wow-ui-source/blob/12.0.0/Interface/AddOns/Blizzard_DeprecatedSpellScript/Deprecated_SpellScript.lua)

:   11.2.7 (64978) → 12.0.0 (65655) Jan 28 2026

:   [AbbreviateLargeNumbers](API_AbbreviateLargeNumbers.md "API AbbreviateLargeNumbers")
:   [AbbreviateNumbers](API_AbbreviateNumbers.md "API AbbreviateNumbers")
:   [AddSourceLocationExclude](API_AddSourceLocationExclude.md "API AddSourceLocationExclude")
:   [C\_ActionBar.GetActionAutocast](API_C_ActionBar.GetActionAutocast.md "API C ActionBar.GetActionAutocast")
:   [C\_ActionBar.GetActionBarPage](API_C_ActionBar.GetActionBarPage.md "API C ActionBar.GetActionBarPage")
:   [C\_ActionBar.GetActionChargeDuration](API_C_ActionBar.GetActionChargeDuration.md "API C ActionBar.GetActionChargeDuration")
:   [C\_ActionBar.GetActionCharges](API_C_ActionBar.GetActionCharges.md "API C ActionBar.GetActionCharges")
:   [C\_ActionBar.GetActionCooldownDuration](API_C_ActionBar.GetActionCooldownDuration.md "API C ActionBar.GetActionCooldownDuration")
:   [C\_ActionBar.GetActionCooldown](API_C_ActionBar.GetActionCooldown.md "API C ActionBar.GetActionCooldown")
:   [C\_ActionBar.GetActionDisplayCount](API_C_ActionBar.GetActionDisplayCount.md "API C ActionBar.GetActionDisplayCount")
:   [C\_ActionBar.GetActionLossOfControlCooldownDuration](API_C_ActionBar.GetActionLossOfControlCooldownDuration.md "API C ActionBar.GetActionLossOfControlCooldownDuration")
:   [C\_ActionBar.GetActionLossOfControlCooldown](API_C_ActionBar.GetActionLossOfControlCooldown.md "API C ActionBar.GetActionLossOfControlCooldown")
:   [C\_ActionBar.GetActionTexture](API_C_ActionBar.GetActionTexture.md "API C ActionBar.GetActionTexture")
:   [C\_ActionBar.GetActionText](API_C_ActionBar.GetActionText.md "API C ActionBar.GetActionText")
:   [C\_ActionBar.GetActionUseCount](API_C_ActionBar.GetActionUseCount.md "API C ActionBar.GetActionUseCount")
:   [C\_ActionBar.GetBonusBarIndex](API_C_ActionBar.GetBonusBarIndex.md "API C ActionBar.GetBonusBarIndex")
:   [C\_ActionBar.GetBonusBarOffset](API_C_ActionBar.GetBonusBarOffset.md "API C ActionBar.GetBonusBarOffset")
:   [C\_ActionBar.GetExtraBarIndex](API_C_ActionBar.GetExtraBarIndex.md "API C ActionBar.GetExtraBarIndex")
:   [C\_ActionBar.GetMultiCastBarIndex](API_C_ActionBar.GetMultiCastBarIndex.md "API C ActionBar.GetMultiCastBarIndex")
:   [C\_ActionBar.GetOverrideBarIndex](API_C_ActionBar.GetOverrideBarIndex.md "API C ActionBar.GetOverrideBarIndex")
:   [C\_ActionBar.GetOverrideBarSkin](API_C_ActionBar.GetOverrideBarSkin.md "API C ActionBar.GetOverrideBarSkin")
:   [C\_ActionBar.GetProfessionQualityInfo](API_C_ActionBar.GetProfessionQualityInfo.md "API C ActionBar.GetProfessionQualityInfo")
:   [C\_ActionBar.GetTempShapeshiftBarIndex](API_C_ActionBar.GetTempShapeshiftBarIndex.md "API C ActionBar.GetTempShapeshiftBarIndex")
:   [C\_ActionBar.GetVehicleBarIndex](API_C_ActionBar.GetVehicleBarIndex.md "API C ActionBar.GetVehicleBarIndex")
:   [C\_ActionBar.HasAction](API_C_ActionBar.HasAction.md "API C ActionBar.HasAction")
:   [C\_ActionBar.HasBonusActionBar](API_C_ActionBar.HasBonusActionBar.md "API C ActionBar.HasBonusActionBar")
:   [C\_ActionBar.HasExtraActionBar](API_C_ActionBar.HasExtraActionBar.md "API C ActionBar.HasExtraActionBar")
:   [C\_ActionBar.HasOverrideActionBar](API_C_ActionBar.HasOverrideActionBar.md "API C ActionBar.HasOverrideActionBar")
:   [C\_ActionBar.HasRangeRequirements](API_C_ActionBar.HasRangeRequirements.md "API C ActionBar.HasRangeRequirements")
:   [C\_ActionBar.HasTempShapeshiftActionBar](API_C_ActionBar.HasTempShapeshiftActionBar.md "API C ActionBar.HasTempShapeshiftActionBar")
:   [C\_ActionBar.HasVehicleActionBar](API_C_ActionBar.HasVehicleActionBar.md "API C ActionBar.HasVehicleActionBar")
:   [C\_ActionBar.IsActionInRange](API_C_ActionBar.IsActionInRange.md "API C ActionBar.IsActionInRange")
:   [C\_ActionBar.IsAttackAction](API_C_ActionBar.IsAttackAction.md "API C ActionBar.IsAttackAction")
:   [C\_ActionBar.IsAutoRepeatAction](API_C_ActionBar.IsAutoRepeatAction.md "API C ActionBar.IsAutoRepeatAction")
:   [C\_ActionBar.IsConsumableAction](API_C_ActionBar.IsConsumableAction.md "API C ActionBar.IsConsumableAction")
:   [C\_ActionBar.IsCurrentAction](API_C_ActionBar.IsCurrentAction.md "API C ActionBar.IsCurrentAction")
:   [C\_ActionBar.IsEquippedAction](API_C_ActionBar.IsEquippedAction.md "API C ActionBar.IsEquippedAction")
:   [C\_ActionBar.IsEquippedGearOutfitAction](API_C_ActionBar.IsEquippedGearOutfitAction.md "API C ActionBar.IsEquippedGearOutfitAction")
:   [C\_ActionBar.IsItemAction](API_C_ActionBar.IsItemAction.md "API C ActionBar.IsItemAction")
:   [C\_ActionBar.IsPossessBarVisible](API_C_ActionBar.IsPossessBarVisible.md "API C ActionBar.IsPossessBarVisible")
:   [C\_ActionBar.IsStackableAction](API_C_ActionBar.IsStackableAction.md "API C ActionBar.IsStackableAction")
:   [C\_ActionBar.IsUsableAction](API_C_ActionBar.IsUsableAction.md "API C ActionBar.IsUsableAction")
:   [C\_ActionBar.RegisterActionUIButton](API_C_ActionBar.RegisterActionUIButton.md "API C ActionBar.RegisterActionUIButton")
:   [C\_ActionBar.SetActionBarPage](API_C_ActionBar.SetActionBarPage.md "API C ActionBar.SetActionBarPage")
:   [C\_ActionBar.UnregisterActionUIButton](API_C_ActionBar.UnregisterActionUIButton.md "API C ActionBar.UnregisterActionUIButton")
:   [C\_AdventureMap.GetQuestPortraitInfo](API_C_AdventureMap.GetQuestPortraitInfo.md "API C AdventureMap.GetQuestPortraitInfo")
:   [C\_BattleNet.SendGameData](API_C_BattleNet.SendGameData.md "API C BattleNet.SendGameData")
:   [C\_BattleNet.SendWhisper](API_C_BattleNet.SendWhisper.md "API C BattleNet.SendWhisper")
:   [C\_BattleNet.SetCustomMessage](API_C_BattleNet.SetCustomMessage.md "API C BattleNet.SetCustomMessage")
:   [C\_CatalogShop.BulkPurchaseProducts](API_C_CatalogShop.BulkPurchaseProducts.md "API C CatalogShop.BulkPurchaseProducts")
:   [C\_CatalogShop.ConfirmHousingPurchase](API_C_CatalogShop.ConfirmHousingPurchase.md "API C CatalogShop.ConfirmHousingPurchase")
:   [C\_CatalogShop.GetFirstCategoryByProductID](API_C_CatalogShop.GetFirstCategoryByProductID.md "API C CatalogShop.GetFirstCategoryByProductID")
:   [C\_CatalogShop.GetNewProducts](API_C_CatalogShop.GetNewProducts.md "API C CatalogShop.GetNewProducts")
:   [C\_CatalogShop.GetProductIDsForCategory](API_C_CatalogShop.GetProductIDsForCategory.md "API C CatalogShop.GetProductIDsForCategory")
:   [C\_CatalogShop.GetRefundableDecors](API_C_CatalogShop.GetRefundableDecors.md "API C CatalogShop.GetRefundableDecors")
:   [C\_CatalogShop.GetVirtualCurrencyBalance](API_C_CatalogShop.GetVirtualCurrencyBalance.md "API C CatalogShop.GetVirtualCurrencyBalance")
:   [C\_CatalogShop.HasNewProducts](API_C_CatalogShop.HasNewProducts.md "API C CatalogShop.HasNewProducts")
:   [C\_CatalogShop.OpenCatalogShopInteractionFromHouse](API_C_CatalogShop.OpenCatalogShopInteractionFromHouse.md "API C CatalogShop.OpenCatalogShopInteractionFromHouse")
:   [C\_CatalogShop.OpenCatalogShopInteractionFromShop](API_C_CatalogShop.OpenCatalogShopInteractionFromShop.md "API C CatalogShop.OpenCatalogShopInteractionFromShop")
:   [C\_CatalogShop.RefreshRefundableDecors](API_C_CatalogShop.RefreshRefundableDecors.md "API C CatalogShop.RefreshRefundableDecors")
:   [C\_CatalogShop.RefreshVirtualCurrencyBalance](API_C_CatalogShop.RefreshVirtualCurrencyBalance.md "API C CatalogShop.RefreshVirtualCurrencyBalance")
:   [C\_CatalogShop.StartHousingVCPurchaseConfirmation](API_C_CatalogShop.StartHousingVCPurchaseConfirmation.md "API C CatalogShop.StartHousingVCPurchaseConfirmation")
:   [C\_CharacterServices.AssignFCMDistribution](API_C_CharacterServices.AssignFCMDistribution.md "API C CharacterServices.AssignFCMDistribution (page does not exist)")
:   [C\_ChatInfo.CancelEmote](API_C_ChatInfo.CancelEmote.md "API C ChatInfo.CancelEmote")
:   [C\_ChatInfo.InChatMessagingLockdown](API_C_ChatInfo.InChatMessagingLockdown.md "API C ChatInfo.InChatMessagingLockdown")
:   [C\_ChatInfo.PerformEmote](API_C_ChatInfo.PerformEmote.md "API C ChatInfo.PerformEmote")
:   [C\_ColorUtil.ConvertHSLToHSV](API_C_ColorUtil.ConvertHSLToHSV.md "API C ColorUtil.ConvertHSLToHSV")
:   [C\_ColorUtil.ConvertHSVToHSL](API_C_ColorUtil.ConvertHSVToHSL.md "API C ColorUtil.ConvertHSVToHSL")
:   [C\_ColorUtil.ConvertHSVToRGB](API_C_ColorUtil.ConvertHSVToRGB.md "API C ColorUtil.ConvertHSVToRGB")
:   [C\_ColorUtil.ConvertRGBToHSV](API_C_ColorUtil.ConvertRGBToHSV.md "API C ColorUtil.ConvertRGBToHSV")
:   [C\_ColorUtil.GenerateTextColorCode](API_C_ColorUtil.GenerateTextColorCode.md "API C ColorUtil.GenerateTextColorCode")
:   [C\_ColorUtil.WrapTextInColorCode](API_C_ColorUtil.WrapTextInColorCode.md "API C ColorUtil.WrapTextInColorCode")
:   [C\_ColorUtil.WrapTextInColor](API_C_ColorUtil.WrapTextInColor.md "API C ColorUtil.WrapTextInColor")
:   [C\_CombatAudioAlert.GetFormatSetting](API_C_CombatAudioAlert.GetFormatSetting.md "API C CombatAudioAlert.GetFormatSetting")
:   [C\_CombatAudioAlert.GetSpeakerSpeed](API_C_CombatAudioAlert.GetSpeakerSpeed.md "API C CombatAudioAlert.GetSpeakerSpeed")
:   [C\_CombatAudioAlert.GetSpeakerVolume](API_C_CombatAudioAlert.GetSpeakerVolume.md "API C CombatAudioAlert.GetSpeakerVolume")
:   [C\_CombatAudioAlert.GetSpecSetting](API_C_CombatAudioAlert.GetSpecSetting.md "API C CombatAudioAlert.GetSpecSetting")
:   [C\_CombatAudioAlert.GetThrottle](API_C_CombatAudioAlert.GetThrottle.md "API C CombatAudioAlert.GetThrottle")
:   [C\_CombatAudioAlert.IsEnabled](API_C_CombatAudioAlert.IsEnabled.md "API C CombatAudioAlert.IsEnabled")
:   [C\_CombatAudioAlert.SetFormatSetting](API_C_CombatAudioAlert.SetFormatSetting.md "API C CombatAudioAlert.SetFormatSetting")
:   [C\_CombatAudioAlert.SetSpeakerSpeed](API_C_CombatAudioAlert.SetSpeakerSpeed.md "API C CombatAudioAlert.SetSpeakerSpeed")
:   [C\_CombatAudioAlert.SetSpeakerVolume](API_C_CombatAudioAlert.SetSpeakerVolume.md "API C CombatAudioAlert.SetSpeakerVolume")
:   [C\_CombatAudioAlert.SetSpecSetting](API_C_CombatAudioAlert.SetSpecSetting.md "API C CombatAudioAlert.SetSpecSetting")
:   [C\_CombatAudioAlert.SetThrottle](API_C_CombatAudioAlert.SetThrottle.md "API C CombatAudioAlert.SetThrottle")
:   [C\_CombatAudioAlert.SpeakText](API_C_CombatAudioAlert.SpeakText.md "API C CombatAudioAlert.SpeakText")
:   [C\_CombatLog.ApplyFilterSettings](API_C_CombatLog.ApplyFilterSettings.md "API C CombatLog.ApplyFilterSettings")
:   [C\_CombatLog.AreFilteredEventsEnabled](API_C_CombatLog.AreFilteredEventsEnabled.md "API C CombatLog.AreFilteredEventsEnabled")
:   [C\_CombatLog.ClearEntries](API_C_CombatLog.ClearEntries.md "API C CombatLog.ClearEntries")
:   [C\_CombatLog.DoesObjectMatchFilter](API_C_CombatLog.DoesObjectMatchFilter.md "API C CombatLog.DoesObjectMatchFilter")
:   [C\_CombatLog.GetEntryRetentionTime](API_C_CombatLog.GetEntryRetentionTime.md "API C CombatLog.GetEntryRetentionTime")
:   [C\_CombatLog.GetMessageLimit](API_C_CombatLog.GetMessageLimit.md "API C CombatLog.GetMessageLimit")
:   [C\_CombatLog.IsCombatLogRestricted](API_C_CombatLog.IsCombatLogRestricted.md "API C CombatLog.IsCombatLogRestricted")
:   [C\_CombatLog.RefilterEntries](API_C_CombatLog.RefilterEntries.md "API C CombatLog.RefilterEntries")
:   [C\_CombatLog.SetEntryRetentionTime](API_C_CombatLog.SetEntryRetentionTime.md "API C CombatLog.SetEntryRetentionTime")
:   [C\_CombatLog.SetFilteredEventsEnabled](API_C_CombatLog.SetFilteredEventsEnabled.md "API C CombatLog.SetFilteredEventsEnabled")
:   [C\_CombatLog.SetMessageLimit](API_C_CombatLog.SetMessageLimit.md "API C CombatLog.SetMessageLimit")
:   [C\_CombatText.GetActiveUnit](API_C_CombatText.GetActiveUnit.md "API C CombatText.GetActiveUnit")
:   [C\_CombatText.GetCurrentEventInfo](API_C_CombatText.GetCurrentEventInfo.md "API C CombatText.GetCurrentEventInfo")
:   [C\_CombatText.SetActiveUnit](API_C_CombatText.SetActiveUnit.md "API C CombatText.SetActiveUnit")
:   [C\_Commentator.GetCombatEventInfo](API_C_Commentator.GetCombatEventInfo.md "API C Commentator.GetCombatEventInfo")
:   [C\_CooldownViewer.GetValidAlertTypes](API_C_CooldownViewer.GetValidAlertTypes.md "API C CooldownViewer.GetValidAlertTypes")
:   [C\_CreatureInfo.GetCreatureID](API_C_CreatureInfo.GetCreatureID.md "API C CreatureInfo.GetCreatureID")
:   [C\_CurveUtil.CreateColorCurve](API_C_CurveUtil.CreateColorCurve.md "API C CurveUtil.CreateColorCurve")
:   [C\_CurveUtil.CreateCurve](API_C_CurveUtil.CreateCurve.md "API C CurveUtil.CreateCurve")
:   [C\_CurveUtil.EvaluateColorFromBoolean](API_C_CurveUtil.EvaluateColorFromBoolean.md "API C CurveUtil.EvaluateColorFromBoolean")
:   [C\_CurveUtil.EvaluateColorValueFromBoolean](API_C_CurveUtil.EvaluateColorValueFromBoolean.md "API C CurveUtil.EvaluateColorValueFromBoolean")
:   [C\_CurveUtil.EvaluateGameCurve](API_C_CurveUtil.EvaluateGameCurve.md "API C CurveUtil.EvaluateGameCurve")
:   [C\_DamageMeter.GetAvailableCombatSessions](API_C_DamageMeter.GetAvailableCombatSessions.md "API C DamageMeter.GetAvailableCombatSessions")
:   [C\_DamageMeter.GetCombatSessionFromID](API_C_DamageMeter.GetCombatSessionFromID.md "API C DamageMeter.GetCombatSessionFromID")
:   [C\_DamageMeter.GetCombatSessionFromType](API_C_DamageMeter.GetCombatSessionFromType.md "API C DamageMeter.GetCombatSessionFromType")
:   [C\_DamageMeter.GetCombatSessionSourceFromID](API_C_DamageMeter.GetCombatSessionSourceFromID.md "API C DamageMeter.GetCombatSessionSourceFromID")
:   [C\_DamageMeter.GetCombatSessionSourceFromType](API_C_DamageMeter.GetCombatSessionSourceFromType.md "API C DamageMeter.GetCombatSessionSourceFromType")
:   [C\_DamageMeter.IsDamageMeterAvailable](API_C_DamageMeter.IsDamageMeterAvailable.md "API C DamageMeter.IsDamageMeterAvailable")
:   [C\_DamageMeter.ResetAllCombatSessions](API_C_DamageMeter.ResetAllCombatSessions.md "API C DamageMeter.ResetAllCombatSessions")
:   [C\_DeathRecap.GetRecapEvents](API_C_DeathRecap.GetRecapEvents.md "API C DeathRecap.GetRecapEvents")
:   [C\_DeathRecap.GetRecapLink](API_C_DeathRecap.GetRecapLink.md "API C DeathRecap.GetRecapLink")
:   [C\_DeathRecap.HasRecapEvents](API_C_DeathRecap.HasRecapEvents.md "API C DeathRecap.HasRecapEvents")
:   [C\_DelvesUI.GetLockedTextForCompanion](API_C_DelvesUI.GetLockedTextForCompanion.md "API C DelvesUI.GetLockedTextForCompanion")
:   [C\_DelvesUI.IsTraitTreeForCompanion](API_C_DelvesUI.IsTraitTreeForCompanion.md "API C DelvesUI.IsTraitTreeForCompanion")
:   [C\_DurationUtil.CreateDuration](API_C_DurationUtil.CreateDuration.md "API C DurationUtil.CreateDuration")
:   [C\_DurationUtil.GetCurrentTime](API_C_DurationUtil.GetCurrentTime.md "API C DurationUtil.GetCurrentTime")
:   [C\_EncounterTimeline.AddEditModeEvents](API_C_EncounterTimeline.AddEditModeEvents.md "API C EncounterTimeline.AddEditModeEvents")
:   [C\_EncounterTimeline.AddScriptEvent](API_C_EncounterTimeline.AddScriptEvent.md "API C EncounterTimeline.AddScriptEvent")
:   [C\_EncounterTimeline.CancelAllScriptEvents](API_C_EncounterTimeline.CancelAllScriptEvents.md "API C EncounterTimeline.CancelAllScriptEvents")
:   [C\_EncounterTimeline.CancelEditModeEvents](API_C_EncounterTimeline.CancelEditModeEvents.md "API C EncounterTimeline.CancelEditModeEvents")
:   [C\_EncounterTimeline.CancelScriptEvent](API_C_EncounterTimeline.CancelScriptEvent.md "API C EncounterTimeline.CancelScriptEvent")
:   [C\_EncounterTimeline.FinishScriptEvent](API_C_EncounterTimeline.FinishScriptEvent.md "API C EncounterTimeline.FinishScriptEvent")
:   [C\_EncounterTimeline.GetCurrentTime](API_C_EncounterTimeline.GetCurrentTime.md "API C EncounterTimeline.GetCurrentTime")
:   [C\_EncounterTimeline.GetEventCountBySource](API_C_EncounterTimeline.GetEventCountBySource.md "API C EncounterTimeline.GetEventCountBySource")
:   [C\_EncounterTimeline.GetEventInfo](API_C_EncounterTimeline.GetEventInfo.md "API C EncounterTimeline.GetEventInfo")
:   [C\_EncounterTimeline.GetEventList](API_C_EncounterTimeline.GetEventList.md "API C EncounterTimeline.GetEventList")
:   [C\_EncounterTimeline.GetEventState](API_C_EncounterTimeline.GetEventState.md "API C EncounterTimeline.GetEventState")
:   [C\_EncounterTimeline.GetEventTimeElapsed](API_C_EncounterTimeline.GetEventTimeElapsed.md "API C EncounterTimeline.GetEventTimeElapsed")
:   [C\_EncounterTimeline.GetEventTimeRemaining](API_C_EncounterTimeline.GetEventTimeRemaining.md "API C EncounterTimeline.GetEventTimeRemaining")
:   [C\_EncounterTimeline.GetEventTrack](API_C_EncounterTimeline.GetEventTrack.md "API C EncounterTimeline.GetEventTrack")
:   [C\_EncounterTimeline.GetTrackInfo](API_C_EncounterTimeline.GetTrackInfo.md "API C EncounterTimeline.GetTrackInfo")
:   [C\_EncounterTimeline.GetTrackList](API_C_EncounterTimeline.GetTrackList.md "API C EncounterTimeline.GetTrackList")
:   [C\_EncounterTimeline.HasActiveEvents](API_C_EncounterTimeline.HasActiveEvents.md "API C EncounterTimeline.HasActiveEvents")
:   [C\_EncounterTimeline.HasAnyEvents](API_C_EncounterTimeline.HasAnyEvents.md "API C EncounterTimeline.HasAnyEvents")
:   [C\_EncounterTimeline.HasPausedEvents](API_C_EncounterTimeline.HasPausedEvents.md "API C EncounterTimeline.HasPausedEvents")
:   [C\_EncounterTimeline.HasVisibleEvents](API_C_EncounterTimeline.HasVisibleEvents.md "API C EncounterTimeline.HasVisibleEvents")
:   [C\_EncounterTimeline.IsEventBlocked](API_C_EncounterTimeline.IsEventBlocked.md "API C EncounterTimeline.IsEventBlocked")
:   [C\_EncounterTimeline.IsFeatureAvailable](API_C_EncounterTimeline.IsFeatureAvailable.md "API C EncounterTimeline.IsFeatureAvailable")
:   [C\_EncounterTimeline.IsFeatureEnabled](API_C_EncounterTimeline.IsFeatureEnabled.md "API C EncounterTimeline.IsFeatureEnabled")
:   [C\_EncounterTimeline.PauseScriptEvent](API_C_EncounterTimeline.PauseScriptEvent.md "API C EncounterTimeline.PauseScriptEvent")
:   [C\_EncounterTimeline.ResumeScriptEvent](API_C_EncounterTimeline.ResumeScriptEvent.md "API C EncounterTimeline.ResumeScriptEvent")
:   [C\_EncounterTimeline.SetEventIconTextures](API_C_EncounterTimeline.SetEventIconTextures.md "API C EncounterTimeline.SetEventIconTextures")
:   [C\_EncounterWarnings.GetEditModeWarningInfo](API_C_EncounterWarnings.GetEditModeWarningInfo.md "API C EncounterWarnings.GetEditModeWarningInfo")
:   [C\_EncounterWarnings.GetSoundKitForSeverity](API_C_EncounterWarnings.GetSoundKitForSeverity.md "API C EncounterWarnings.GetSoundKitForSeverity")
:   [C\_EncounterWarnings.IsFeatureAvailable](API_C_EncounterWarnings.IsFeatureAvailable.md "API C EncounterWarnings.IsFeatureAvailable")
:   [C\_EncounterWarnings.IsFeatureEnabled](API_C_EncounterWarnings.IsFeatureEnabled.md "API C EncounterWarnings.IsFeatureEnabled")
:   [C\_EncounterWarnings.PlaySound](API_C_EncounterWarnings.PlaySound.md "API C EncounterWarnings.PlaySound")
:   [C\_EventScheduler.CanShowEvents](API_C_EventScheduler.CanShowEvents.md "API C EventScheduler.CanShowEvents")
:   [C\_EventUtils.IsCallbackEvent](API_C_EventUtils.IsCallbackEvent.md "API C EventUtils.IsCallbackEvent")
:   [C\_GameRules.IsPersonalResourceDisplayEnabled](API_C_GameRules.IsPersonalResourceDisplayEnabled.md "API C GameRules.IsPersonalResourceDisplayEnabled")
:   [C\_HouseExterior.GetCurrentHouseExteriorType](API_C_HouseExterior.GetCurrentHouseExteriorType.md "API C HouseExterior.GetCurrentHouseExteriorType")
:   [C\_HouseExterior.GetFixtureDebugInfoForGUID](API_C_HouseExterior.GetFixtureDebugInfoForGUID.md "API C HouseExterior.GetFixtureDebugInfoForGUID (page does not exist)")
:   [C\_HouseExterior.GetHouseExteriorSizeOptions](API_C_HouseExterior.GetHouseExteriorSizeOptions.md "API C HouseExterior.GetHouseExteriorSizeOptions")
:   [C\_HouseExterior.GetHouseExteriorTypeOptions](API_C_HouseExterior.GetHouseExteriorTypeOptions.md "API C HouseExterior.GetHouseExteriorTypeOptions")
:   [C\_HouseExterior.GetHoveredFixtureDebugInfo](API_C_HouseExterior.GetHoveredFixtureDebugInfo.md "API C HouseExterior.GetHoveredFixtureDebugInfo (page does not exist)")
:   [C\_HouseExterior.GetSelectedFixtureDebugInfo](API_C_HouseExterior.GetSelectedFixtureDebugInfo.md "API C HouseExterior.GetSelectedFixtureDebugInfo (page does not exist)")
:   [C\_HouseExterior.SetHouseExteriorSize](API_C_HouseExterior.SetHouseExteriorSize.md "API C HouseExterior.SetHouseExteriorSize")
:   [C\_HouseExterior.SetHouseExteriorType](API_C_HouseExterior.SetHouseExteriorType.md "API C HouseExterior.SetHouseExteriorType")
:   [C\_Housing.IsHousingMarketShopEnabled](API_C_Housing.IsHousingMarketShopEnabled.md "API C Housing.IsHousingMarketShopEnabled")
:   [C\_Housing.OnHouseFinderClickPlot](API_C_Housing.OnHouseFinderClickPlot.md "API C Housing.OnHouseFinderClickPlot")
:   [C\_HousingBasicMode.IsFreePlaceEnabled](API_C_HousingBasicMode.IsFreePlaceEnabled.md "API C HousingBasicMode.IsFreePlaceEnabled")
:   [C\_HousingBasicMode.SetFreePlaceEnabled](API_C_HousingBasicMode.SetFreePlaceEnabled.md "API C HousingBasicMode.SetFreePlaceEnabled")
:   [C\_HousingBasicMode.StartPlacingPreviewDecor](API_C_HousingBasicMode.StartPlacingPreviewDecor.md "API C HousingBasicMode.StartPlacingPreviewDecor")
:   [C\_HousingCatalog.DeletePreviewCartDecor](API_C_HousingCatalog.DeletePreviewCartDecor.md "API C HousingCatalog.DeletePreviewCartDecor")
:   [C\_HousingCatalog.GetBundleInfo](API_C_HousingCatalog.GetBundleInfo.md "API C HousingCatalog.GetBundleInfo")
:   [C\_HousingCatalog.GetCartSizeLimit](API_C_HousingCatalog.GetCartSizeLimit.md "API C HousingCatalog.GetCartSizeLimit")
:   [C\_HousingCatalog.GetCatalogEntryRefundTimeStampByRecordID](API_C_HousingCatalog.GetCatalogEntryRefundTimeStampByRecordID.md "API C HousingCatalog.GetCatalogEntryRefundTimeStampByRecordID")
:   [C\_HousingCatalog.HasFeaturedEntries](API_C_HousingCatalog.HasFeaturedEntries.md "API C HousingCatalog.HasFeaturedEntries")
:   [C\_HousingCatalog.IsPreviewCartItemShown](API_C_HousingCatalog.IsPreviewCartItemShown.md "API C HousingCatalog.IsPreviewCartItemShown")
:   [C\_HousingCatalog.PromotePreviewDecor](API_C_HousingCatalog.PromotePreviewDecor.md "API C HousingCatalog.PromotePreviewDecor")
:   [C\_HousingCatalog.RequestHousingMarketRefundInfo](API_C_HousingCatalog.RequestHousingMarketRefundInfo.md "API C HousingCatalog.RequestHousingMarketRefundInfo")
:   [C\_HousingCatalog.SetPreviewCartItemShown](API_C_HousingCatalog.SetPreviewCartItemShown.md "API C HousingCatalog.SetPreviewCartItemShown")
:   [C\_HousingCustomizeMode.IsHouseExteriorDoorHovered](API_C_HousingCustomizeMode.IsHouseExteriorDoorHovered.md "API C HousingCustomizeMode.IsHouseExteriorDoorHovered")
:   [C\_HousingDecor.EnterPreviewState](API_C_HousingDecor.EnterPreviewState.md "API C HousingDecor.EnterPreviewState")
:   [C\_HousingDecor.ExitPreviewState](API_C_HousingDecor.ExitPreviewState.md "API C HousingDecor.ExitPreviewState")
:   [C\_HousingDecor.GetNumPreviewDecor](API_C_HousingDecor.GetNumPreviewDecor.md "API C HousingDecor.GetNumPreviewDecor")
:   [C\_HousingDecor.IsModeDisabledForPreviewState](API_C_HousingDecor.IsModeDisabledForPreviewState.md "API C HousingDecor.IsModeDisabledForPreviewState")
:   [C\_HousingDecor.IsPreviewState](API_C_HousingDecor.IsPreviewState.md "API C HousingDecor.IsPreviewState")
:   [C\_InstanceEncounter.IsEncounterInProgress](API_C_InstanceEncounter.IsEncounterInProgress.md "API C InstanceEncounter.IsEncounterInProgress")
:   [C\_InstanceEncounter.IsEncounterLimitingResurrections](API_C_InstanceEncounter.IsEncounterLimitingResurrections.md "API C InstanceEncounter.IsEncounterLimitingResurrections")
:   [C\_InstanceEncounter.IsEncounterSuppressingRelease](API_C_InstanceEncounter.IsEncounterSuppressingRelease.md "API C InstanceEncounter.IsEncounterSuppressingRelease")
:   [C\_InstanceEncounter.ShouldShowTimelineForEncounter](API_C_InstanceEncounter.ShouldShowTimelineForEncounter.md "API C InstanceEncounter.ShouldShowTimelineForEncounter")
:   [C\_Item.IsItemBindToAccount](API_C_Item.IsItemBindToAccount.md "API C Item.IsItemBindToAccount")
:   [C\_LimitedInput.LimitedInputAllowed](API_C_LimitedInput.LimitedInputAllowed.md "API C LimitedInput.LimitedInputAllowed")
:   [C\_MajorFactions.ShouldDisplayMajorFactionAsJourney](API_C_MajorFactions.ShouldDisplayMajorFactionAsJourney.md "API C MajorFactions.ShouldDisplayMajorFactionAsJourney")
:   [C\_MajorFactions.ShouldUseJourneyRewardTrack](API_C_MajorFactions.ShouldUseJourneyRewardTrack.md "API C MajorFactions.ShouldUseJourneyRewardTrack")
:   [C\_NamePlate.GetNamePlateSize](API_C_NamePlate.GetNamePlateSize.md "API C NamePlate.GetNamePlateSize")
:   [C\_NamePlate.SetNamePlateSize](API_C_NamePlate.SetNamePlateSize.md "API C NamePlate.SetNamePlateSize")
:   [C\_NamePlateManager.GetNamePlateHitTestInsets](API_C_NamePlateManager.GetNamePlateHitTestInsets.md "API C NamePlateManager.GetNamePlateHitTestInsets")
:   [C\_NamePlateManager.IsNamePlateUnitBehindCamera](API_C_NamePlateManager.IsNamePlateUnitBehindCamera.md "API C NamePlateManager.IsNamePlateUnitBehindCamera")
:   [C\_NamePlateManager.SetNamePlateHitTestFrame](API_C_NamePlateManager.SetNamePlateHitTestFrame.md "API C NamePlateManager.SetNamePlateHitTestFrame")
:   [C\_NamePlateManager.SetNamePlateHitTestInsets](API_C_NamePlateManager.SetNamePlateHitTestInsets.md "API C NamePlateManager.SetNamePlateHitTestInsets")
:   [C\_NamePlateManager.SetNamePlateSimplified](API_C_NamePlateManager.SetNamePlateSimplified.md "API C NamePlateManager.SetNamePlateSimplified")
:   [C\_NeighborhoodInitiative.AddTrackedInitiativeTask](API_C_NeighborhoodInitiative.AddTrackedInitiativeTask.md "API C NeighborhoodInitiative.AddTrackedInitiativeTask")
:   [C\_NeighborhoodInitiative.GetActiveNeighborhood](API_C_NeighborhoodInitiative.GetActiveNeighborhood.md "API C NeighborhoodInitiative.GetActiveNeighborhood")
:   [C\_NeighborhoodInitiative.GetInitiativeActivityLogInfo](API_C_NeighborhoodInitiative.GetInitiativeActivityLogInfo.md "API C NeighborhoodInitiative.GetInitiativeActivityLogInfo")
:   [C\_NeighborhoodInitiative.GetInitiativeTaskChatLink](API_C_NeighborhoodInitiative.GetInitiativeTaskChatLink.md "API C NeighborhoodInitiative.GetInitiativeTaskChatLink")
:   [C\_NeighborhoodInitiative.GetInitiativeTaskInfo](API_C_NeighborhoodInitiative.GetInitiativeTaskInfo.md "API C NeighborhoodInitiative.GetInitiativeTaskInfo")
:   [C\_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo](API_C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo.md "API C NeighborhoodInitiative.GetNeighborhoodInitiativeInfo")
:   [C\_NeighborhoodInitiative.GetRequiredLevel](API_C_NeighborhoodInitiative.GetRequiredLevel.md "API C NeighborhoodInitiative.GetRequiredLevel")
:   [C\_NeighborhoodInitiative.GetTrackedInitiativeTasks](API_C_NeighborhoodInitiative.GetTrackedInitiativeTasks.md "API C NeighborhoodInitiative.GetTrackedInitiativeTasks")
:   [C\_NeighborhoodInitiative.IsInitiativeEnabled](API_C_NeighborhoodInitiative.IsInitiativeEnabled.md "API C NeighborhoodInitiative.IsInitiativeEnabled")
:   [C\_NeighborhoodInitiative.IsPlayerInNeighborhoodGroup](API_C_NeighborhoodInitiative.IsPlayerInNeighborhoodGroup.md "API C NeighborhoodInitiative.IsPlayerInNeighborhoodGroup")
:   [C\_NeighborhoodInitiative.IsViewingActiveNeighborhood](API_C_NeighborhoodInitiative.IsViewingActiveNeighborhood.md "API C NeighborhoodInitiative.IsViewingActiveNeighborhood")
:   [C\_NeighborhoodInitiative.PlayerHasInitiativeAccess](API_C_NeighborhoodInitiative.PlayerHasInitiativeAccess.md "API C NeighborhoodInitiative.PlayerHasInitiativeAccess")
:   [C\_NeighborhoodInitiative.PlayerMeetsRequiredLevel](API_C_NeighborhoodInitiative.PlayerMeetsRequiredLevel.md "API C NeighborhoodInitiative.PlayerMeetsRequiredLevel")
:   [C\_NeighborhoodInitiative.RemoveTrackedInitiativeTask](API_C_NeighborhoodInitiative.RemoveTrackedInitiativeTask.md "API C NeighborhoodInitiative.RemoveTrackedInitiativeTask")
:   [C\_NeighborhoodInitiative.RequestInitiativeActivityLog](API_C_NeighborhoodInitiative.RequestInitiativeActivityLog.md "API C NeighborhoodInitiative.RequestInitiativeActivityLog")
:   [C\_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo](API_C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo.md "API C NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo")
:   [C\_NeighborhoodInitiative.SetActiveNeighborhood](API_C_NeighborhoodInitiative.SetActiveNeighborhood.md "API C NeighborhoodInitiative.SetActiveNeighborhood")
:   [C\_NeighborhoodInitiative.SetViewingNeighborhood](API_C_NeighborhoodInitiative.SetViewingNeighborhood.md "API C NeighborhoodInitiative.SetViewingNeighborhood")
:   [C\_Ping.IsPingSystemEnabled](API_C_Ping.IsPingSystemEnabled.md "API C Ping.IsPingSystemEnabled")
:   [C\_PvP.AreTrainingGroundsEnabled](API_C_PvP.AreTrainingGroundsEnabled.md "API C PvP.AreTrainingGroundsEnabled")
:   [C\_PvP.CanPlayerUseTrainingGroundsUI](API_C_PvP.CanPlayerUseTrainingGroundsUI.md "API C PvP.CanPlayerUseTrainingGroundsUI")
:   [C\_PvP.GetBattlegroundInfo](API_C_PvP.GetBattlegroundInfo.md "API C PvP.GetBattlegroundInfo")
:   [C\_PvP.GetRandomTrainingGroundRewards](API_C_PvP.GetRandomTrainingGroundRewards.md "API C PvP.GetRandomTrainingGroundRewards")
:   [C\_PvP.GetTrainingGrounds](API_C_PvP.GetTrainingGrounds.md "API C PvP.GetTrainingGrounds")
:   [C\_PvP.HasMatchStarted](API_C_PvP.HasMatchStarted.md "API C PvP.HasMatchStarted")
:   [C\_PvP.HasRandomTrainingGroundWinToday](API_C_PvP.HasRandomTrainingGroundWinToday.md "API C PvP.HasRandomTrainingGroundWinToday")
:   [C\_PvP.JoinRandomTrainingGround](API_C_PvP.JoinRandomTrainingGround.md "API C PvP.JoinRandomTrainingGround")
:   [C\_PvP.JoinTrainingGround](API_C_PvP.JoinTrainingGround.md "API C PvP.JoinTrainingGround")
:   [C\_QuestInfoSystem.GetQuestLogRewardFavor](API_C_QuestInfoSystem.GetQuestLogRewardFavor.md "API C QuestInfoSystem.GetQuestLogRewardFavor")
:   [C\_QuestLog.GetActivePreyQuest](API_C_QuestLog.GetActivePreyQuest.md "API C QuestLog.GetActivePreyQuest")
:   [C\_Reputation.IsFactionParagonForCurrentPlayer](API_C_Reputation.IsFactionParagonForCurrentPlayer.md "API C Reputation.IsFactionParagonForCurrentPlayer")
:   [C\_RestrictedActions.CheckAllowProtectedFunctions](API_C_RestrictedActions.CheckAllowProtectedFunctions.md "API C RestrictedActions.CheckAllowProtectedFunctions")
:   [C\_RestrictedActions.GetAddOnRestrictionState](API_C_RestrictedActions.GetAddOnRestrictionState.md "API C RestrictedActions.GetAddOnRestrictionState")
:   [C\_RestrictedActions.IsAddOnRestrictionActive](API_C_RestrictedActions.IsAddOnRestrictionActive.md "API C RestrictedActions.IsAddOnRestrictionActive")
:   [C\_Secrets.GetPowerTypeSecrecy](API_C_Secrets.GetPowerTypeSecrecy.md "API C Secrets.GetPowerTypeSecrecy")
:   [C\_Secrets.GetSpellAuraSecrecy](API_C_Secrets.GetSpellAuraSecrecy.md "API C Secrets.GetSpellAuraSecrecy")
:   [C\_Secrets.GetSpellCastSecrecy](API_C_Secrets.GetSpellCastSecrecy.md "API C Secrets.GetSpellCastSecrecy")
:   [C\_Secrets.GetSpellCooldownSecrecy](API_C_Secrets.GetSpellCooldownSecrecy.md "API C Secrets.GetSpellCooldownSecrecy")
:   [C\_Secrets.HasSecretRestrictions](API_C_Secrets.HasSecretRestrictions.md "API C Secrets.HasSecretRestrictions")
:   [C\_Secrets.ShouldActionCooldownBeSecret](API_C_Secrets.ShouldActionCooldownBeSecret.md "API C Secrets.ShouldActionCooldownBeSecret")
:   [C\_Secrets.ShouldAurasBeSecret](API_C_Secrets.ShouldAurasBeSecret.md "API C Secrets.ShouldAurasBeSecret")
:   [C\_Secrets.ShouldCooldownsBeSecret](API_C_Secrets.ShouldCooldownsBeSecret.md "API C Secrets.ShouldCooldownsBeSecret")
:   [C\_Secrets.ShouldSpellAuraBeSecret](API_C_Secrets.ShouldSpellAuraBeSecret.md "API C Secrets.ShouldSpellAuraBeSecret")
:   [C\_Secrets.ShouldSpellBookItemCooldownBeSecret](API_C_Secrets.ShouldSpellBookItemCooldownBeSecret.md "API C Secrets.ShouldSpellBookItemCooldownBeSecret")
:   [C\_Secrets.ShouldSpellCooldownBeSecret](API_C_Secrets.ShouldSpellCooldownBeSecret.md "API C Secrets.ShouldSpellCooldownBeSecret")
:   [C\_Secrets.ShouldTotemSlotBeSecret](API_C_Secrets.ShouldTotemSlotBeSecret.md "API C Secrets.ShouldTotemSlotBeSecret")
:   [C\_Secrets.ShouldTotemSpellBeSecret](API_C_Secrets.ShouldTotemSpellBeSecret.md "API C Secrets.ShouldTotemSpellBeSecret")
:   [C\_Secrets.ShouldUnitAuraIndexBeSecret](API_C_Secrets.ShouldUnitAuraIndexBeSecret.md "API C Secrets.ShouldUnitAuraIndexBeSecret")
:   [C\_Secrets.ShouldUnitAuraInstanceBeSecret](API_C_Secrets.ShouldUnitAuraInstanceBeSecret.md "API C Secrets.ShouldUnitAuraInstanceBeSecret")
:   [C\_Secrets.ShouldUnitAuraSlotBeSecret](API_C_Secrets.ShouldUnitAuraSlotBeSecret.md "API C Secrets.ShouldUnitAuraSlotBeSecret")
:   [C\_Secrets.ShouldUnitComparisonBeSecret](API_C_Secrets.ShouldUnitComparisonBeSecret.md "API C Secrets.ShouldUnitComparisonBeSecret")
:   [C\_Secrets.ShouldUnitHealthMaxBeSecret](API_C_Secrets.ShouldUnitHealthMaxBeSecret.md "API C Secrets.ShouldUnitHealthMaxBeSecret")
:   [C\_Secrets.ShouldUnitIdentityBeSecret](API_C_Secrets.ShouldUnitIdentityBeSecret.md "API C Secrets.ShouldUnitIdentityBeSecret")
:   [C\_Secrets.ShouldUnitPowerBeSecret](API_C_Secrets.ShouldUnitPowerBeSecret.md "API C Secrets.ShouldUnitPowerBeSecret")
:   [C\_Secrets.ShouldUnitPowerMaxBeSecret](API_C_Secrets.ShouldUnitPowerMaxBeSecret.md "API C Secrets.ShouldUnitPowerMaxBeSecret")
:   [C\_Secrets.ShouldUnitSpellCastBeSecret](API_C_Secrets.ShouldUnitSpellCastBeSecret.md "API C Secrets.ShouldUnitSpellCastBeSecret")
:   [C\_Secrets.ShouldUnitSpellCastingBeSecret](API_C_Secrets.ShouldUnitSpellCastingBeSecret.md "API C Secrets.ShouldUnitSpellCastingBeSecret")
:   [C\_SettingsUtil.NotifySettingsLoaded](API_C_SettingsUtil.NotifySettingsLoaded.md "API C SettingsUtil.NotifySettingsLoaded")
:   [C\_SettingsUtil.OpenSettingsPanel](API_C_SettingsUtil.OpenSettingsPanel.md "API C SettingsUtil.OpenSettingsPanel")
:   [C\_Sound.PlaySound](API_C_Sound.PlaySound.md "API C Sound.PlaySound")
:   [C\_Spell.GetSpellChargeDuration](API_C_Spell.GetSpellChargeDuration.md "API C Spell.GetSpellChargeDuration")
:   [C\_Spell.GetSpellCooldownDuration](API_C_Spell.GetSpellCooldownDuration.md "API C Spell.GetSpellCooldownDuration")
:   [C\_Spell.GetSpellDisplayCount](API_C_Spell.GetSpellDisplayCount.md "API C Spell.GetSpellDisplayCount")
:   [C\_Spell.GetSpellLossOfControlCooldownDuration](API_C_Spell.GetSpellLossOfControlCooldownDuration.md "API C Spell.GetSpellLossOfControlCooldownDuration")
:   [C\_Spell.GetSpellMaxCumulativeAuraApplications](API_C_Spell.GetSpellMaxCumulativeAuraApplications.md "API C Spell.GetSpellMaxCumulativeAuraApplications")
:   [C\_Spell.GetVisibilityInfo](API_C_Spell.GetVisibilityInfo.md "API C Spell.GetVisibilityInfo")
:   [C\_Spell.IsConsumableSpell](API_C_Spell.IsConsumableSpell.md "API C Spell.IsConsumableSpell")
:   [C\_Spell.IsExternalDefensive](API_C_Spell.IsExternalDefensive.md "API C Spell.IsExternalDefensive")
:   [C\_Spell.IsPriorityAura](API_C_Spell.IsPriorityAura.md "API C Spell.IsPriorityAura")
:   [C\_Spell.IsSelfBuff](API_C_Spell.IsSelfBuff.md "API C Spell.IsSelfBuff")
:   [C\_Spell.IsSpellCrowdControl](API_C_Spell.IsSpellCrowdControl.md "API C Spell.IsSpellCrowdControl")
:   [C\_Spell.IsSpellImportant](API_C_Spell.IsSpellImportant.md "API C Spell.IsSpellImportant")
:   [C\_SpellBook.FindBaseSpellByID](API_C_SpellBook.FindBaseSpellByID.md "API C SpellBook.FindBaseSpellByID")
:   [C\_SpellBook.FindFlyoutSlotBySpellID](API_C_SpellBook.FindFlyoutSlotBySpellID.md "API C SpellBook.FindFlyoutSlotBySpellID")
:   [C\_SpellBook.FindSpellOverrideByID](API_C_SpellBook.FindSpellOverrideByID.md "API C SpellBook.FindSpellOverrideByID")
:   [C\_SpellBook.GetSpellBookItemChargeDuration](API_C_SpellBook.GetSpellBookItemChargeDuration.md "API C SpellBook.GetSpellBookItemChargeDuration")
:   [C\_SpellBook.GetSpellBookItemCooldownDuration](API_C_SpellBook.GetSpellBookItemCooldownDuration.md "API C SpellBook.GetSpellBookItemCooldownDuration")
:   [C\_SpellBook.GetSpellBookItemLossOfControlCooldownDuration](API_C_SpellBook.GetSpellBookItemLossOfControlCooldownDuration.md "API C SpellBook.GetSpellBookItemLossOfControlCooldownDuration")
:   [C\_SpellDiminish.GetAllSpellDiminishCategories](API_C_SpellDiminish.GetAllSpellDiminishCategories.md "API C SpellDiminish.GetAllSpellDiminishCategories")
:   [C\_SpellDiminish.GetSpellDiminishCategoryInfo](API_C_SpellDiminish.GetSpellDiminishCategoryInfo.md "API C SpellDiminish.GetSpellDiminishCategoryInfo")
:   [C\_SpellDiminish.IsSystemSupported](API_C_SpellDiminish.IsSystemSupported.md "API C SpellDiminish.IsSystemSupported")
:   [C\_SpellDiminish.ShouldTrackSpellDiminishCategory](API_C_SpellDiminish.ShouldTrackSpellDiminishCategory.md "API C SpellDiminish.ShouldTrackSpellDiminishCategory")
:   [C\_StableInfo.IsBonusPetSlotAvailable](API_C_StableInfo.IsBonusPetSlotAvailable.md "API C StableInfo.IsBonusPetSlotAvailable")
:   [C\_StringUtil.EscapeLuaFormatString](API_C_StringUtil.EscapeLuaFormatString.md "API C StringUtil.EscapeLuaFormatString")
:   [C\_StringUtil.EscapeLuaPatterns](API_C_StringUtil.EscapeLuaPatterns.md "API C StringUtil.EscapeLuaPatterns")
:   [C\_StringUtil.EscapeQuotedCodes](API_C_StringUtil.EscapeQuotedCodes.md "API C StringUtil.EscapeQuotedCodes")
:   [C\_StringUtil.FloorToNearestString](API_C_StringUtil.FloorToNearestString.md "API C StringUtil.FloorToNearestString")
:   [C\_StringUtil.RemoveContiguousSpaces](API_C_StringUtil.RemoveContiguousSpaces.md "API C StringUtil.RemoveContiguousSpaces")
:   [C\_StringUtil.RoundToNearestString](API_C_StringUtil.RoundToNearestString.md "API C StringUtil.RoundToNearestString")
:   [C\_StringUtil.StripHyperlinks](API_C_StringUtil.StripHyperlinks.md "API C StringUtil.StripHyperlinks")
:   [C\_StringUtil.TruncateWhenZero](API_C_StringUtil.TruncateWhenZero.md "API C StringUtil.TruncateWhenZero")
:   [C\_StringUtil.WrapString](API_C_StringUtil.WrapString.md "API C StringUtil.WrapString")
:   [C\_TaskQuest.GetQuestUIWidgetSetByType](API_C_TaskQuest.GetQuestUIWidgetSetByType.md "API C TaskQuest.GetQuestUIWidgetSetByType")
:   [C\_TooltipComparison.CompareItem](API_C_TooltipComparison.CompareItem.md "API C TooltipComparison.CompareItem")
:   [C\_TooltipInfo.GetOutfit](API_C_TooltipInfo.GetOutfit.md "API C TooltipInfo.GetOutfit")
:   [C\_TooltipInfo.GetUnitAuraByAuraInstanceID](API_C_TooltipInfo.GetUnitAuraByAuraInstanceID.md "API C TooltipInfo.GetUnitAuraByAuraInstanceID")
:   [C\_TradeSkillUI.GetDependentReagents](API_C_TradeSkillUI.GetDependentReagents.md "API C TradeSkillUI.GetDependentReagents")
:   [C\_TradeSkillUI.GetItemCraftedQualityInfo](API_C_TradeSkillUI.GetItemCraftedQualityInfo.md "API C TradeSkillUI.GetItemCraftedQualityInfo")
:   [C\_TradeSkillUI.GetItemReagentQualityInfo](API_C_TradeSkillUI.GetItemReagentQualityInfo.md "API C TradeSkillUI.GetItemReagentQualityInfo")
:   [C\_TradeSkillUI.GetRecipeItemQualityInfo](API_C_TradeSkillUI.GetRecipeItemQualityInfo.md "API C TradeSkillUI.GetRecipeItemQualityInfo")
:   [C\_TradeSkillUI.GetRecipeQualityReagentLink](API_C_TradeSkillUI.GetRecipeQualityReagentLink.md "API C TradeSkillUI.GetRecipeQualityReagentLink")
:   [C\_TransmogCollection.DeleteCustomSet](API_C_TransmogCollection.DeleteCustomSet.md "API C TransmogCollection.DeleteCustomSet")
:   [C\_TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList](API_C_TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList.md "API C TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList")
:   [C\_TransmogCollection.GetCustomSetInfo](API_C_TransmogCollection.GetCustomSetInfo.md "API C TransmogCollection.GetCustomSetInfo")
:   [C\_TransmogCollection.GetCustomSetItemTransmogInfoList](API_C_TransmogCollection.GetCustomSetItemTransmogInfoList.md "API C TransmogCollection.GetCustomSetItemTransmogInfoList")
:   [C\_TransmogCollection.GetCustomSets](API_C_TransmogCollection.GetCustomSets.md "API C TransmogCollection.GetCustomSets")
:   [C\_TransmogCollection.GetItemTransmogInfoListFromCustomSetHyperlink](API_C_TransmogCollection.GetItemTransmogInfoListFromCustomSetHyperlink.md "API C TransmogCollection.GetItemTransmogInfoListFromCustomSetHyperlink")
:   [C\_TransmogCollection.GetNumMaxCustomSets](API_C_TransmogCollection.GetNumMaxCustomSets.md "API C TransmogCollection.GetNumMaxCustomSets")
:   [C\_TransmogCollection.IsValidCustomSetName](API_C_TransmogCollection.IsValidCustomSetName.md "API C TransmogCollection.IsValidCustomSetName")
:   [C\_TransmogCollection.IsValidTransmogSource](API_C_TransmogCollection.IsValidTransmogSource.md "API C TransmogCollection.IsValidTransmogSource")
:   [C\_TransmogCollection.ModifyCustomSet](API_C_TransmogCollection.ModifyCustomSet.md "API C TransmogCollection.ModifyCustomSet")
:   [C\_TransmogCollection.NewCustomSet](API_C_TransmogCollection.NewCustomSet.md "API C TransmogCollection.NewCustomSet")
:   [C\_TransmogCollection.RenameCustomSet](API_C_TransmogCollection.RenameCustomSet.md "API C TransmogCollection.RenameCustomSet")
:   [C\_TransmogOutfitInfo.AddNewOutfit](API_C_TransmogOutfitInfo.AddNewOutfit.md "API C TransmogOutfitInfo.AddNewOutfit")
:   [C\_TransmogOutfitInfo.ChangeDisplayedOutfit](API_C_TransmogOutfitInfo.ChangeDisplayedOutfit.md "API C TransmogOutfitInfo.ChangeDisplayedOutfit")
:   [C\_TransmogOutfitInfo.ChangeViewedOutfit](API_C_TransmogOutfitInfo.ChangeViewedOutfit.md "API C TransmogOutfitInfo.ChangeViewedOutfit")
:   [C\_TransmogOutfitInfo.ClearAllPendingSituations](API_C_TransmogOutfitInfo.ClearAllPendingSituations.md "API C TransmogOutfitInfo.ClearAllPendingSituations")
:   [C\_TransmogOutfitInfo.ClearAllPendingTransmogs](API_C_TransmogOutfitInfo.ClearAllPendingTransmogs.md "API C TransmogOutfitInfo.ClearAllPendingTransmogs")
:   [C\_TransmogOutfitInfo.ClearDisplayedOutfit](API_C_TransmogOutfitInfo.ClearDisplayedOutfit.md "API C TransmogOutfitInfo.ClearDisplayedOutfit")
:   [C\_TransmogOutfitInfo.CommitAndApplyAllPending](API_C_TransmogOutfitInfo.CommitAndApplyAllPending.md "API C TransmogOutfitInfo.CommitAndApplyAllPending")
:   [C\_TransmogOutfitInfo.CommitOutfitInfo](API_C_TransmogOutfitInfo.CommitOutfitInfo.md "API C TransmogOutfitInfo.CommitOutfitInfo")
:   [C\_TransmogOutfitInfo.CommitPendingSituations](API_C_TransmogOutfitInfo.CommitPendingSituations.md "API C TransmogOutfitInfo.CommitPendingSituations")
:   [C\_TransmogOutfitInfo.GetActiveOutfitID](API_C_TransmogOutfitInfo.GetActiveOutfitID.md "API C TransmogOutfitInfo.GetActiveOutfitID")
:   [C\_TransmogOutfitInfo.GetAllSlotLocationInfo](API_C_TransmogOutfitInfo.GetAllSlotLocationInfo.md "API C TransmogOutfitInfo.GetAllSlotLocationInfo")
:   [C\_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption](API_C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption.md "API C TransmogOutfitInfo.GetCollectionInfoForSlotAndOption")
:   [C\_TransmogOutfitInfo.GetCurrentlyViewedOutfitID](API_C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID.md "API C TransmogOutfitInfo.GetCurrentlyViewedOutfitID")
:   [C\_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot](API_C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot.md "API C TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot")
:   [C\_TransmogOutfitInfo.GetIllusionDefaultIMAIDForCollectionType](API_C_TransmogOutfitInfo.GetIllusionDefaultIMAIDForCollectionType.md "API C TransmogOutfitInfo.GetIllusionDefaultIMAIDForCollectionType")
:   [C\_TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory](API_C_TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory.md "API C TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory")
:   [C\_TransmogOutfitInfo.GetLinkedSlotInfo](API_C_TransmogOutfitInfo.GetLinkedSlotInfo.md "API C TransmogOutfitInfo.GetLinkedSlotInfo")
:   [C\_TransmogOutfitInfo.GetMaxNumberOfTotalOutfitsForSource](API_C_TransmogOutfitInfo.GetMaxNumberOfTotalOutfitsForSource.md "API C TransmogOutfitInfo.GetMaxNumberOfTotalOutfitsForSource")
:   [C\_TransmogOutfitInfo.GetMaxNumberOfUsableOutfits](API_C_TransmogOutfitInfo.GetMaxNumberOfUsableOutfits.md "API C TransmogOutfitInfo.GetMaxNumberOfUsableOutfits")
:   [C\_TransmogOutfitInfo.GetNextOutfitCost](API_C_TransmogOutfitInfo.GetNextOutfitCost.md "API C TransmogOutfitInfo.GetNextOutfitCost")
:   [C\_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource](API_C_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource.md "API C TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource")
:   [C\_TransmogOutfitInfo.GetOutfitInfo](API_C_TransmogOutfitInfo.GetOutfitInfo.md "API C TransmogOutfitInfo.GetOutfitInfo")
:   [C\_TransmogOutfitInfo.GetOutfitSituationsEnabled](API_C_TransmogOutfitInfo.GetOutfitSituationsEnabled.md "API C TransmogOutfitInfo.GetOutfitSituationsEnabled")
:   [C\_TransmogOutfitInfo.GetOutfitSituation](API_C_TransmogOutfitInfo.GetOutfitSituation.md "API C TransmogOutfitInfo.GetOutfitSituation")
:   [C\_TransmogOutfitInfo.GetOutfitsInfo](API_C_TransmogOutfitInfo.GetOutfitsInfo.md "API C TransmogOutfitInfo.GetOutfitsInfo")
:   [C\_TransmogOutfitInfo.GetPendingTransmogCost](API_C_TransmogOutfitInfo.GetPendingTransmogCost.md "API C TransmogOutfitInfo.GetPendingTransmogCost")
:   [C\_TransmogOutfitInfo.GetSecondarySlotState](API_C_TransmogOutfitInfo.GetSecondarySlotState.md "API C TransmogOutfitInfo.GetSecondarySlotState")
:   [C\_TransmogOutfitInfo.GetSetSourcesForSlot](API_C_TransmogOutfitInfo.GetSetSourcesForSlot.md "API C TransmogOutfitInfo.GetSetSourcesForSlot")
:   [C\_TransmogOutfitInfo.GetSlotGroupInfo](API_C_TransmogOutfitInfo.GetSlotGroupInfo.md "API C TransmogOutfitInfo.GetSlotGroupInfo")
:   [C\_TransmogOutfitInfo.GetSourceIDsForSlot](API_C_TransmogOutfitInfo.GetSourceIDsForSlot.md "API C TransmogOutfitInfo.GetSourceIDsForSlot")
:   [C\_TransmogOutfitInfo.GetTransmogOutfitSlotForInventoryType](API_C_TransmogOutfitInfo.GetTransmogOutfitSlotForInventoryType.md "API C TransmogOutfitInfo.GetTransmogOutfitSlotForInventoryType")
:   [C\_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot](API_C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot.md "API C TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot")
:   [C\_TransmogOutfitInfo.GetUISituationCategoriesAndOptions](API_C_TransmogOutfitInfo.GetUISituationCategoriesAndOptions.md "API C TransmogOutfitInfo.GetUISituationCategoriesAndOptions")
:   [C\_TransmogOutfitInfo.GetUnassignedAtlasForSlot](API_C_TransmogOutfitInfo.GetUnassignedAtlasForSlot.md "API C TransmogOutfitInfo.GetUnassignedAtlasForSlot")
:   [C\_TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot](API_C_TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot.md "API C TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot")
:   [C\_TransmogOutfitInfo.GetViewedOutfitSlotInfo](API_C_TransmogOutfitInfo.GetViewedOutfitSlotInfo.md "API C TransmogOutfitInfo.GetViewedOutfitSlotInfo")
:   [C\_TransmogOutfitInfo.GetWeaponOptionsForSlot](API_C_TransmogOutfitInfo.GetWeaponOptionsForSlot.md "API C TransmogOutfitInfo.GetWeaponOptionsForSlot")
:   [C\_TransmogOutfitInfo.HasPendingOutfitSituations](API_C_TransmogOutfitInfo.HasPendingOutfitSituations.md "API C TransmogOutfitInfo.HasPendingOutfitSituations")
:   [C\_TransmogOutfitInfo.HasPendingOutfitTransmogs](API_C_TransmogOutfitInfo.HasPendingOutfitTransmogs.md "API C TransmogOutfitInfo.HasPendingOutfitTransmogs")
:   [C\_TransmogOutfitInfo.IsEquippedGearOutfitDisplayed](API_C_TransmogOutfitInfo.IsEquippedGearOutfitDisplayed.md "API C TransmogOutfitInfo.IsEquippedGearOutfitDisplayed")
:   [C\_TransmogOutfitInfo.IsEquippedGearOutfitLocked](API_C_TransmogOutfitInfo.IsEquippedGearOutfitLocked.md "API C TransmogOutfitInfo.IsEquippedGearOutfitLocked")
:   [C\_TransmogOutfitInfo.IsLockedOutfit](API_C_TransmogOutfitInfo.IsLockedOutfit.md "API C TransmogOutfitInfo.IsLockedOutfit")
:   [C\_TransmogOutfitInfo.IsSlotWeaponSlot](API_C_TransmogOutfitInfo.IsSlotWeaponSlot.md "API C TransmogOutfitInfo.IsSlotWeaponSlot")
:   [C\_TransmogOutfitInfo.IsValidTransmogOutfitName](API_C_TransmogOutfitInfo.IsValidTransmogOutfitName.md "API C TransmogOutfitInfo.IsValidTransmogOutfitName")
:   [C\_TransmogOutfitInfo.PickupOutfit](API_C_TransmogOutfitInfo.PickupOutfit.md "API C TransmogOutfitInfo.PickupOutfit")
:   [C\_TransmogOutfitInfo.ResetOutfitSituations](API_C_TransmogOutfitInfo.ResetOutfitSituations.md "API C TransmogOutfitInfo.ResetOutfitSituations")
:   [C\_TransmogOutfitInfo.RevertPendingTransmog](API_C_TransmogOutfitInfo.RevertPendingTransmog.md "API C TransmogOutfitInfo.RevertPendingTransmog")
:   [C\_TransmogOutfitInfo.SetOutfitSituationsEnabled](API_C_TransmogOutfitInfo.SetOutfitSituationsEnabled.md "API C TransmogOutfitInfo.SetOutfitSituationsEnabled")
:   [C\_TransmogOutfitInfo.SetOutfitToCustomSet](API_C_TransmogOutfitInfo.SetOutfitToCustomSet.md "API C TransmogOutfitInfo.SetOutfitToCustomSet")
:   [C\_TransmogOutfitInfo.SetOutfitToSet](API_C_TransmogOutfitInfo.SetOutfitToSet.md "API C TransmogOutfitInfo.SetOutfitToSet")
:   [C\_TransmogOutfitInfo.SetPendingTransmog](API_C_TransmogOutfitInfo.SetPendingTransmog.md "API C TransmogOutfitInfo.SetPendingTransmog")
:   [C\_TransmogOutfitInfo.SetSecondarySlotState](API_C_TransmogOutfitInfo.SetSecondarySlotState.md "API C TransmogOutfitInfo.SetSecondarySlotState")
:   [C\_TransmogOutfitInfo.SetViewedWeaponOptionForSlot](API_C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot.md "API C TransmogOutfitInfo.SetViewedWeaponOptionForSlot")
:   [C\_TransmogOutfitInfo.SlotHasSecondary](API_C_TransmogOutfitInfo.SlotHasSecondary.md "API C TransmogOutfitInfo.SlotHasSecondary")
:   [C\_TransmogOutfitInfo.UpdatePendingSituation](API_C_TransmogOutfitInfo.UpdatePendingSituation.md "API C TransmogOutfitInfo.UpdatePendingSituation")
:   [C\_TransmogSets.GetAvailableSets](API_C_TransmogSets.GetAvailableSets.md "API C TransmogSets.GetAvailableSets")
:   [C\_TransmogSets.GetSetsFilter](API_C_TransmogSets.GetSetsFilter.md "API C TransmogSets.GetSetsFilter")
:   [C\_TransmogSets.IsUsingDefaultSetsFilters](API_C_TransmogSets.IsUsingDefaultSetsFilters.md "API C TransmogSets.IsUsingDefaultSetsFilters")
:   [C\_TransmogSets.SetDefaultSetsFilters](API_C_TransmogSets.SetDefaultSetsFilters.md "API C TransmogSets.SetDefaultSetsFilters")
:   [C\_TransmogSets.SetSetsFilter](API_C_TransmogSets.SetSetsFilter.md "API C TransmogSets.SetSetsFilter")
:   [C\_Tutorial.GetCombatEventInfo](API_C_Tutorial.GetCombatEventInfo.md "API C Tutorial.GetCombatEventInfo")
:   [C\_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo](API_C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo.md "API C UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo")
:   [C\_UnitAuras.AuraIsBigDefensive](API_C_UnitAuras.AuraIsBigDefensive.md "API C UnitAuras.AuraIsBigDefensive")
:   [C\_UnitAuras.DoesAuraHaveExpirationTime](API_C_UnitAuras.DoesAuraHaveExpirationTime.md "API C UnitAuras.DoesAuraHaveExpirationTime")
:   [C\_UnitAuras.GetAuraApplicationDisplayCount](API_C_UnitAuras.GetAuraApplicationDisplayCount.md "API C UnitAuras.GetAuraApplicationDisplayCount")
:   [C\_UnitAuras.GetAuraBaseDuration](API_C_UnitAuras.GetAuraBaseDuration.md "API C UnitAuras.GetAuraBaseDuration")
:   [C\_UnitAuras.GetAuraDispelTypeColor](API_C_UnitAuras.GetAuraDispelTypeColor.md "API C UnitAuras.GetAuraDispelTypeColor")
:   [C\_UnitAuras.GetAuraDuration](API_C_UnitAuras.GetAuraDuration.md "API C UnitAuras.GetAuraDuration")
:   [C\_UnitAuras.GetRefreshExtendedDuration](API_C_UnitAuras.GetRefreshExtendedDuration.md "API C UnitAuras.GetRefreshExtendedDuration")
:   [C\_UnitAuras.GetUnitAuraInstanceIDs](API_C_UnitAuras.GetUnitAuraInstanceIDs.md "API C UnitAuras.GetUnitAuraInstanceIDs")
:   [C\_UnitAuras.TriggerPrivateAuraShowDispelType](API_C_UnitAuras.TriggerPrivateAuraShowDispelType.md "API C UnitAuras.TriggerPrivateAuraShowDispelType")
:   [C\_WeeklyRewards.GetSortedProgressForActivity](API_C_WeeklyRewards.GetSortedProgressForActivity.md "API C WeeklyRewards.GetSortedProgressForActivity")
:   [CreateAbbreviateConfig](API_CreateAbbreviateConfig.md "API CreateAbbreviateConfig")
:   [CreateUnitHealPredictionCalculator](API_CreateUnitHealPredictionCalculator.md "API CreateUnitHealPredictionCalculator")
:   [GetCollapsingStarCost](API_GetCollapsingStarCost.md "API GetCollapsingStarCost")
:   [IsRaidMarkerSystemEnabled](API_IsRaidMarkerSystemEnabled.md "API IsRaidMarkerSystemEnabled")
:   [RegisterEventCallback](API_RegisterEventCallback.md "API RegisterEventCallback")
:   [RegisterUnitEventCallback](API_RegisterUnitEventCallback.md "API RegisterUnitEventCallback")
:   [SetCursorPosition](API_SetCursorPosition.md "API SetCursorPosition")
:   [SetTableSecurityOption](API_SetTableSecurityOption.md "API SetTableSecurityOption")
:   [ShowCloak](API_ShowCloak.md "API ShowCloak")
:   [ShowHelm](API_ShowHelm.md "API ShowHelm")
:   [ShowingCloak](API_ShowingCloak.md "API ShowingCloak")
:   [ShowingHelm](API_ShowingHelm.md "API ShowingHelm")
:   [SimulateMouseClick](API_SimulateMouseClick.md "API SimulateMouseClick")
:   [SimulateMouseDown](API_SimulateMouseDown.md "API SimulateMouseDown")
:   [SimulateMouseUp](API_SimulateMouseUp.md "API SimulateMouseUp")
:   [SimulateMouseWheel](API_SimulateMouseWheel.md "API SimulateMouseWheel")
:   [UnitCastingDuration](API_UnitCastingDuration.md "API UnitCastingDuration")
:   [UnitChannelDuration](API_UnitChannelDuration.md "API UnitChannelDuration")
:   [UnitClassFromGUID](API_UnitClassFromGUID.md "API UnitClassFromGUID")
:   [UnitCreatureID](API_UnitCreatureID.md "API UnitCreatureID")
:   [UnitEmpoweredChannelDuration](API_UnitEmpoweredChannelDuration.md "API UnitEmpoweredChannelDuration")
:   [UnitEmpoweredStageDurations](API_UnitEmpoweredStageDurations.md "API UnitEmpoweredStageDurations")
:   [UnitEmpoweredStagePercentages](API_UnitEmpoweredStagePercentages.md "API UnitEmpoweredStagePercentages")
:   [UnitGetDetailedHealPrediction](API_UnitGetDetailedHealPrediction.md "API UnitGetDetailedHealPrediction")
:   [UnitHealthMissing](API_UnitHealthMissing.md "API UnitHealthMissing")
:   [UnitHealthPercent](API_UnitHealthPercent.md "API UnitHealthPercent")
:   [UnitIsHumanPlayer](API_UnitIsHumanPlayer.md "API UnitIsHumanPlayer")
:   [UnitIsLieutenant](API_UnitIsLieutenant.md "API UnitIsLieutenant")
:   [UnitIsMinion](API_UnitIsMinion.md "API UnitIsMinion")
:   [UnitIsNPCAsPlayer](API_UnitIsNPCAsPlayer.md "API UnitIsNPCAsPlayer")
:   [UnitIsSpellTarget](API_UnitIsSpellTarget.md "API UnitIsSpellTarget")
:   [UnitNameFromGUID](API_UnitNameFromGUID.md "API UnitNameFromGUID")
:   [UnitPowerMissing](API_UnitPowerMissing.md "API UnitPowerMissing")
:   [UnitPowerPercent](API_UnitPowerPercent.md "API UnitPowerPercent")
:   [UnitSexBase](API_UnitSexBase.md "API UnitSexBase")
:   [UnitShouldDisplaySpellTargetName](API_UnitShouldDisplaySpellTargetName.md "API UnitShouldDisplaySpellTargetName")
:   [UnitSpellTargetClass](API_UnitSpellTargetClass.md "API UnitSpellTargetClass")
:   [UnitSpellTargetName](API_UnitSpellTargetName.md "API UnitSpellTargetName")
:   [UnitThreatLeadSituation](API_UnitThreatLeadSituation.md "API UnitThreatLeadSituation")
:   [UnregisterEventCallback](API_UnregisterEventCallback.md "API UnregisterEventCallback")
:   [UnregisterUnitEventCallback](API_UnregisterUnitEventCallback.md "API UnregisterUnitEventCallback")
:   [canaccessallvalues](API_canaccessallvalues.md "API canaccessallvalues")
:   [canaccesssecrets](API_canaccesssecrets.md "API canaccesssecrets")
:   [canaccesstable](API_canaccesstable.md "API canaccesstable")
:   [canaccessvalue](API_canaccessvalue.md "API canaccessvalue")
:   [dropsecretaccess](API_dropsecretaccess.md "API dropsecretaccess")
:   [hasanysecretvalues](API_hasanysecretvalues.md "API hasanysecretvalues")
:   [issecrettable](API_issecrettable.md "API issecrettable")
:   [issecretvalue](API_issecretvalue.md "API issecretvalue")
:   [mapvalues](API_mapvalues.md "API mapvalues")
:   [scrubsecretvalues](API_scrubsecretvalues.md "API scrubsecretvalues")
:   [secretwrap](API_secretwrap.md "API secretwrap")
:   [securecallmethod](API_securecallmethod.md "API securecallmethod")
:   [string.concat](API_string.concat.md "API string.concat")

:   [ActionHasRange](API_ActionHasRange.md "API ActionHasRange")
:   [BNSendGameData](API_BNSendGameData.md "API BNSendGameData")
:   [BNSendWhisper](API_BNSendWhisper.md "API BNSendWhisper")
:   [BNSetCustomMessage](API_BNSetCustomMessage.md "API BNSetCustomMessage")
:   [C\_CatalogShop.OpenCatalogShopInteraction](API_C_CatalogShop.OpenCatalogShopInteraction.md "API C CatalogShop.OpenCatalogShopInteraction")
:   [C\_EventUtils.NotifySettingsLoaded](API_C_EventUtils.NotifySettingsLoaded.md "API C EventUtils.NotifySettingsLoaded")
:   [C\_HouseExterior.GetCurrentHouseExteriorTypeName](API_C_HouseExterior.GetCurrentHouseExteriorTypeName.md "API C HouseExterior.GetCurrentHouseExteriorTypeName")
:   [C\_HousingBasicMode.IsNudgeEnabled](API_C_HousingBasicMode.IsNudgeEnabled.md "API C HousingBasicMode.IsNudgeEnabled")
:   [C\_HousingBasicMode.SetNudgeEnabled](API_C_HousingBasicMode.SetNudgeEnabled.md "API C HousingBasicMode.SetNudgeEnabled")
:   [C\_HousingDecor.GetMaxDecorPlaced](API_C_HousingDecor.GetMaxDecorPlaced.md "API C HousingDecor.GetMaxDecorPlaced")
:   [C\_NamePlate.GetNamePlateEnemyClickThrough](API_C_NamePlate.GetNamePlateEnemyClickThrough.md "API C NamePlate.GetNamePlateEnemyClickThrough (page does not exist)")
:   [C\_NamePlate.GetNamePlateEnemyPreferredClickInsets](API_C_NamePlate.GetNamePlateEnemyPreferredClickInsets.md "API C NamePlate.GetNamePlateEnemyPreferredClickInsets (page does not exist)")
:   [C\_NamePlate.GetNamePlateEnemySize](API_C_NamePlate.GetNamePlateEnemySize.md "API C NamePlate.GetNamePlateEnemySize (page does not exist)")
:   [C\_NamePlate.GetNamePlateFriendlyClickThrough](API_C_NamePlate.GetNamePlateFriendlyClickThrough.md "API C NamePlate.GetNamePlateFriendlyClickThrough (page does not exist)")
:   [C\_NamePlate.GetNamePlateFriendlyPreferredClickInsets](API_C_NamePlate.GetNamePlateFriendlyPreferredClickInsets.md "API C NamePlate.GetNamePlateFriendlyPreferredClickInsets (page does not exist)")
:   [C\_NamePlate.GetNamePlateFriendlySize](API_C_NamePlate.GetNamePlateFriendlySize.md "API C NamePlate.GetNamePlateFriendlySize (page does not exist)")
:   [C\_NamePlate.GetNamePlateSelfClickThrough](API_C_NamePlate.GetNamePlateSelfClickThrough.md "API C NamePlate.GetNamePlateSelfClickThrough (page does not exist)")
:   [C\_NamePlate.GetNamePlateSelfPreferredClickInsets](API_C_NamePlate.GetNamePlateSelfPreferredClickInsets.md "API C NamePlate.GetNamePlateSelfPreferredClickInsets (page does not exist)")
:   [C\_NamePlate.GetNamePlateSelfSize](API_C_NamePlate.GetNamePlateSelfSize.md "API C NamePlate.GetNamePlateSelfSize (page does not exist)")
:   [C\_NamePlate.GetNumNamePlateMotionTypes](API_C_NamePlate.GetNumNamePlateMotionTypes.md "API C NamePlate.GetNumNamePlateMotionTypes (page does not exist)")
:   [C\_NamePlate.SetNamePlateEnemyClickThrough](API_C_NamePlate.SetNamePlateEnemyClickThrough.md "API C NamePlate.SetNamePlateEnemyClickThrough")
:   [C\_NamePlate.SetNamePlateEnemyPreferredClickInsets](API_C_NamePlate.SetNamePlateEnemyPreferredClickInsets.md "API C NamePlate.SetNamePlateEnemyPreferredClickInsets")
:   [C\_NamePlate.SetNamePlateEnemySize](API_C_NamePlate.SetNamePlateEnemySize.md "API C NamePlate.SetNamePlateEnemySize")
:   [C\_NamePlate.SetNamePlateFriendlyClickThrough](API_C_NamePlate.SetNamePlateFriendlyClickThrough.md "API C NamePlate.SetNamePlateFriendlyClickThrough")
:   [C\_NamePlate.SetNamePlateFriendlyPreferredClickInsets](API_C_NamePlate.SetNamePlateFriendlyPreferredClickInsets.md "API C NamePlate.SetNamePlateFriendlyPreferredClickInsets")
:   [C\_NamePlate.SetNamePlateFriendlySize](API_C_NamePlate.SetNamePlateFriendlySize.md "API C NamePlate.SetNamePlateFriendlySize")
:   [C\_NamePlate.SetNamePlateSelfClickThrough](API_C_NamePlate.SetNamePlateSelfClickThrough.md "API C NamePlate.SetNamePlateSelfClickThrough")
:   [C\_NamePlate.SetNamePlateSelfPreferredClickInsets](API_C_NamePlate.SetNamePlateSelfPreferredClickInsets.md "API C NamePlate.SetNamePlateSelfPreferredClickInsets")
:   [C\_NamePlate.SetNamePlateSelfSize](API_C_NamePlate.SetNamePlateSelfSize.md "API C NamePlate.SetNamePlateSelfSize")
:   [C\_PlayerInfo.CanPlayerUseEventScheduler](API_C_PlayerInfo.CanPlayerUseEventScheduler.md "API C PlayerInfo.CanPlayerUseEventScheduler")
:   [C\_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer](API_C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer.md "API C PlayerInfo.IsExpansionLandingPageUnlockedForPlayer")
:   [C\_PvP.CanDisplayDamage](API_C_PvP.CanDisplayDamage.md "API C PvP.CanDisplayDamage")
:   [C\_PvP.CanDisplayHealing](API_C_PvP.CanDisplayHealing.md "API C PvP.CanDisplayHealing")
:   [C\_PvP.CanDisplayKillingBlows](API_C_PvP.CanDisplayKillingBlows.md "API C PvP.CanDisplayKillingBlows")
:   [C\_StorePublic.IsDisabledByParentalControls](API_C_StorePublic.IsDisabledByParentalControls.md "API C StorePublic.IsDisabledByParentalControls")
:   [C\_TaskQuest.GetQuestIconUIWidgetSet](API_C_TaskQuest.GetQuestIconUIWidgetSet.md "API C TaskQuest.GetQuestIconUIWidgetSet")
:   [C\_TaskQuest.GetQuestTooltipUIWidgetSet](API_C_TaskQuest.GetQuestTooltipUIWidgetSet.md "API C TaskQuest.GetQuestTooltipUIWidgetSet")
:   [C\_Texture.GetCraftingReagentQualityChatIcon](API_C_Texture.GetCraftingReagentQualityChatIcon.md "API C Texture.GetCraftingReagentQualityChatIcon")
:   [C\_TooltipInfo.GetTransmogrifyItem](API_C_TooltipInfo.GetTransmogrifyItem.md "API C TooltipInfo.GetTransmogrifyItem")
:   [C\_TradeSkillUI.GetReagentRequirementItemIDs](API_C_TradeSkillUI.GetReagentRequirementItemIDs.md "API C TradeSkillUI.GetReagentRequirementItemIDs")
:   [C\_TradeSkillUI.GetRecipeFixedReagentItemLink](API_C_TradeSkillUI.GetRecipeFixedReagentItemLink.md "API C TradeSkillUI.GetRecipeFixedReagentItemLink")
:   [C\_TradeSkillUI.GetRecipeQualityReagentItemLink](API_C_TradeSkillUI.GetRecipeQualityReagentItemLink.md "API C TradeSkillUI.GetRecipeQualityReagentItemLink")
:   [C\_Transmog.ApplyAllPending](API_C_Transmog.ApplyAllPending.md "API C Transmog.ApplyAllPending")
:   [C\_Transmog.CanTransmogItemWithItem](API_C_Transmog.CanTransmogItemWithItem.md "API C Transmog.CanTransmogItemWithItem")
:   [C\_Transmog.CanTransmogItem](API_C_Transmog.CanTransmogItem.md "API C Transmog.CanTransmogItem")
:   [C\_Transmog.ClearAllPending](API_C_Transmog.ClearAllPending.md "API C Transmog.ClearAllPending")
:   [C\_Transmog.ClearPending](API_C_Transmog.ClearPending.md "API C Transmog.ClearPending")
:   [C\_Transmog.Close](API_C_Transmog.Close.md "API C Transmog.Close")
:   [C\_Transmog.GetApplyCost](API_C_Transmog.GetApplyCost.md "API C Transmog.GetApplyCost")
:   [C\_Transmog.GetApplyWarnings](API_C_Transmog.GetApplyWarnings.md "API C Transmog.GetApplyWarnings")
:   [C\_Transmog.GetBaseCategory](API_C_Transmog.GetBaseCategory.md "API C Transmog.GetBaseCategory")
:   [C\_Transmog.GetCreatureDisplayIDForSource](API_C_Transmog.GetCreatureDisplayIDForSource.md "API C Transmog.GetCreatureDisplayIDForSource")
:   [C\_Transmog.GetPending](API_C_Transmog.GetPending.md "API C Transmog.GetPending")
:   [C\_Transmog.GetSlotEffectiveCategory](API_C_Transmog.GetSlotEffectiveCategory.md "API C Transmog.GetSlotEffectiveCategory")
:   [C\_Transmog.GetSlotInfo](API_C_Transmog.GetSlotInfo.md "API C Transmog.GetSlotInfo")
:   [C\_Transmog.GetSlotUseError](API_C_Transmog.GetSlotUseError.md "API C Transmog.GetSlotUseError")
:   [C\_Transmog.IsSlotBeingCollapsed](API_C_Transmog.IsSlotBeingCollapsed.md "API C Transmog.IsSlotBeingCollapsed")
:   [C\_Transmog.IsTransmogEnabled](API_C_Transmog.IsTransmogEnabled.md "API C Transmog.IsTransmogEnabled")
:   [C\_Transmog.LoadOutfit](API_C_Transmog.LoadOutfit.md "API C Transmog.LoadOutfit")
:   [C\_Transmog.SetPending](API_C_Transmog.SetPending.md "API C Transmog.SetPending")
:   [C\_TransmogCollection.DeleteOutfit](API_C_TransmogCollection.DeleteOutfit.md "API C TransmogCollection.DeleteOutfit")
:   [C\_TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink](API_C_TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink.md "API C TransmogCollection.GetItemTransmogInfoListFromOutfitHyperlink")
:   [C\_TransmogCollection.GetNumMaxOutfits](API_C_TransmogCollection.GetNumMaxOutfits.md "API C TransmogCollection.GetNumMaxOutfits")
:   [C\_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList](API_C_TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList.md "API C TransmogCollection.GetOutfitHyperlinkFromItemTransmogInfoList")
:   [C\_TransmogCollection.GetOutfitInfo](API_C_TransmogCollection.GetOutfitInfo.md "API C TransmogCollection.GetOutfitInfo")
:   [C\_TransmogCollection.GetOutfitItemTransmogInfoList](API_C_TransmogCollection.GetOutfitItemTransmogInfoList.md "API C TransmogCollection.GetOutfitItemTransmogInfoList")
:   [C\_TransmogCollection.GetOutfits](API_C_TransmogCollection.GetOutfits.md "API C TransmogCollection.GetOutfits")
:   [C\_TransmogCollection.ModifyOutfit](API_C_TransmogCollection.ModifyOutfit.md "API C TransmogCollection.ModifyOutfit")
:   [C\_TransmogCollection.NewOutfit](API_C_TransmogCollection.NewOutfit.md "API C TransmogCollection.NewOutfit")
:   [C\_TransmogCollection.RenameOutfit](API_C_TransmogCollection.RenameOutfit.md "API C TransmogCollection.RenameOutfit")
:   [CancelEmote](API_CancelEmote.md "API CancelEmote (page does not exist)")
:   [ChangeActionBarPage](API_ChangeActionBarPage.md "API ChangeActionBarPage")
:   [CombatLogAddFilter](API_CombatLogAddFilter.md "API CombatLogAddFilter (page does not exist)")
:   [CombatLogAdvanceEntry](API_CombatLogAdvanceEntry.md "API CombatLogAdvanceEntry")
:   [CombatLogClearEntries](API_CombatLogClearEntries.md "API CombatLogClearEntries (page does not exist)")
:   [CombatLogGetCurrentEntry](API_CombatLogGetCurrentEntry.md "API CombatLogGetCurrentEntry")
:   [CombatLogGetCurrentEventInfo](API_CombatLogGetCurrentEventInfo.md "API CombatLogGetCurrentEventInfo")
:   [CombatLogGetNumEntries](API_CombatLogGetNumEntries.md "API CombatLogGetNumEntries (page does not exist)")
:   [CombatLogGetRetentionTime](API_CombatLogGetRetentionTime.md "API CombatLogGetRetentionTime (page does not exist)")
:   [CombatLogResetFilter](API_CombatLogResetFilter.md "API CombatLogResetFilter (page does not exist)")
:   [CombatLogSetCurrentEntry](API_CombatLogSetCurrentEntry.md "API CombatLogSetCurrentEntry")
:   [CombatLogSetRetentionTime](API_CombatLogSetRetentionTime.md "API CombatLogSetRetentionTime (page does not exist)")
:   [CombatLogShowCurrentEntry](API_CombatLogShowCurrentEntry.md "API CombatLogShowCurrentEntry (page does not exist)")
:   [CombatLog\_Object\_IsA](API_CombatLog_Object_IsA.md "API CombatLog Object IsA")
:   [CombatTextSetActiveUnit](API_CombatTextSetActiveUnit.md "API CombatTextSetActiveUnit")
:   [DeathRecap\_GetEvents](API_DeathRecap_GetEvents.md "API DeathRecap GetEvents")
:   [DeathRecap\_HasEvents](API_DeathRecap_HasEvents.md "API DeathRecap HasEvents")
:   [DoEmote](API_DoEmote.md "API DoEmote")
:   [FindBaseSpellByID](API_FindBaseSpellByID.md "API FindBaseSpellByID")
:   [FindFlyoutSlotBySpellID](API_FindFlyoutSlotBySpellID.md "API FindFlyoutSlotBySpellID (page does not exist)")
:   [FindSpellOverrideByID](API_FindSpellOverrideByID.md "API FindSpellOverrideByID")
:   [GetActionAutocast](API_GetActionAutocast.md "API GetActionAutocast (page does not exist)")
:   [GetActionBarPage](API_GetActionBarPage.md "API GetActionBarPage")
:   [GetActionCharges](API_GetActionCharges.md "API GetActionCharges")
:   [GetActionCooldown](API_GetActionCooldown.md "API GetActionCooldown")
:   [GetActionCount](API_GetActionCount.md "API GetActionCount")
:   [GetActionLossOfControlCooldown](API_GetActionLossOfControlCooldown.md "API GetActionLossOfControlCooldown")
:   [GetActionTexture](API_GetActionTexture.md "API GetActionTexture")
:   [GetActionText](API_GetActionText.md "API GetActionText")
:   [GetBattlegroundInfo](API_GetBattlegroundInfo.md "API GetBattlegroundInfo")
:   [GetBonusBarIndex](API_GetBonusBarIndex.md "API GetBonusBarIndex (page does not exist)")
:   [GetBonusBarOffset](API_GetBonusBarOffset.md "API GetBonusBarOffset")
:   [GetCurrentCombatTextEventInfo](API_GetCurrentCombatTextEventInfo.md "API GetCurrentCombatTextEventInfo")
:   [GetDeathRecapLink](API_GetDeathRecapLink.md "API GetDeathRecapLink")
:   [GetExtraBarIndex](API_GetExtraBarIndex.md "API GetExtraBarIndex")
:   [GetMultiCastBarIndex](API_GetMultiCastBarIndex.md "API GetMultiCastBarIndex (page does not exist)")
:   [GetOverrideBarIndex](API_GetOverrideBarIndex.md "API GetOverrideBarIndex (page does not exist)")
:   [GetOverrideBarSkin](API_GetOverrideBarSkin.md "API GetOverrideBarSkin (page does not exist)")
:   [GetTempShapeshiftBarIndex](API_GetTempShapeshiftBarIndex.md "API GetTempShapeshiftBarIndex (page does not exist)")
:   [GetVehicleBarIndex](API_GetVehicleBarIndex.md "API GetVehicleBarIndex (page does not exist)")
:   [HasAction](API_HasAction.md "API HasAction")
:   [HasBonusActionBar](API_HasBonusActionBar.md "API HasBonusActionBar (page does not exist)")
:   [HasExtraActionBar](API_HasExtraActionBar.md "API HasExtraActionBar")
:   [HasOverrideActionBar](API_HasOverrideActionBar.md "API HasOverrideActionBar (page does not exist)")
:   [HasTempShapeshiftActionBar](API_HasTempShapeshiftActionBar.md "API HasTempShapeshiftActionBar (page does not exist)")
:   [HasVehicleActionBar](API_HasVehicleActionBar.md "API HasVehicleActionBar (page does not exist)")
:   [IsActionInRange](API_IsActionInRange.md "API IsActionInRange")
:   [IsAttackAction](API_IsAttackAction.md "API IsAttackAction")
:   [IsAutoRepeatAction](API_IsAutoRepeatAction.md "API IsAutoRepeatAction")
:   [IsConsumableAction](API_IsConsumableAction.md "API IsConsumableAction")
:   [IsConsumableSpell](API_IsConsumableSpell.md "API IsConsumableSpell (page does not exist)")
:   [IsCurrentAction](API_IsCurrentAction.md "API IsCurrentAction")
:   [IsEncounterInProgress](API_IsEncounterInProgress.md "API IsEncounterInProgress (page does not exist)")
:   [IsEncounterLimitingResurrections](API_IsEncounterLimitingResurrections.md "API IsEncounterLimitingResurrections (page does not exist)")
:   [IsEncounterSuppressingRelease](API_IsEncounterSuppressingRelease.md "API IsEncounterSuppressingRelease (page does not exist)")
:   [IsEquippedAction](API_IsEquippedAction.md "API IsEquippedAction")
:   [IsItemAction](API_IsItemAction.md "API IsItemAction (page does not exist)")
:   [IsPossessBarVisible](API_IsPossessBarVisible.md "API IsPossessBarVisible (page does not exist)")
:   [IsStackableAction](API_IsStackableAction.md "API IsStackableAction (page does not exist)")
:   [IsUsableAction](API_IsUsableAction.md "API IsUsableAction")
:   [SetActionUIButton](API_SetActionUIButton.md "API SetActionUIButton")
:   [SetPortraitToTexture](API_SetPortraitToTexture.md "API SetPortraitToTexture")
:   [SetRaidTargetProtected](API_SetRaidTargetProtected.md "API SetRaidTargetProtected (page does not exist)")
:   [SpellGetVisibilityInfo](API_SpellGetVisibilityInfo.md "API SpellGetVisibilityInfo")
:   [SpellIsAlwaysShown](API_SpellIsAlwaysShown.md "API SpellIsAlwaysShown (page does not exist)")
:   [SpellIsPriorityAura](API_SpellIsPriorityAura.md "API SpellIsPriorityAura (page does not exist)")
:   [SpellIsSelfBuff](API_SpellIsSelfBuff.md "API SpellIsSelfBuff (page does not exist)")
:   [StripHyperlinks](API_StripHyperlinks.md "API StripHyperlinks")

:   [AbbreviateConfig](ScriptObject_AbbreviateConfig.md "ScriptObject AbbreviateConfig")
:   [ColorCurveObject](ScriptObject_ColorCurveObject.md "ScriptObject ColorCurveObject")
:   [CurveObject](ScriptObject_CurveObject.md "ScriptObject CurveObject")
:   [CurveObjectBase](ScriptObject_CurveObjectBase.md "ScriptObject CurveObjectBase")
:   [DurationObject](ScriptObject_DurationObject.md "ScriptObject DurationObject")
:   [UnitHealPredictionCalculator](ScriptObject_UnitHealPredictionCalculator.md "ScriptObject UnitHealPredictionCalculator")

:   [FrameScriptObject:HasAnySecretAspect](API_FrameScriptObject_HasAnySecretAspect.md "API FrameScriptObject HasAnySecretAspect")
:   [FrameScriptObject:HasSecretAspect](API_FrameScriptObject_HasSecretAspect.md "API FrameScriptObject HasSecretAspect")
:   [FrameScriptObject:HasSecretValues](API_FrameScriptObject_HasSecretValues.md "API FrameScriptObject HasSecretValues")
:   [FrameScriptObject:IsPreventingSecretValues](API_FrameScriptObject_IsPreventingSecretValues.md "API FrameScriptObject IsPreventingSecretValues")
:   [FrameScriptObject:SetPreventSecretValues](API_FrameScriptObject_SetPreventSecretValues.md "API FrameScriptObject SetPreventSecretValues")
:   [ScriptRegion:IsAnchoringSecret](API_ScriptRegion_IsAnchoringSecret.md "API ScriptRegion IsAnchoringSecret")
:   [Region:SetAlphaFromBoolean](API_Region_SetAlphaFromBoolean.md "API Region SetAlphaFromBoolean")
:   [Region:SetVertexColorFromBoolean](API_Region_SetVertexColorFromBoolean.md "API Region SetVertexColorFromBoolean")
:   [FontString:GetScaleAnimationMode](API_FontString_GetScaleAnimationMode.md "API FontString GetScaleAnimationMode")
:   [FontString:SetScaleAnimationMode](API_FontString_SetScaleAnimationMode.md "API FontString SetScaleAnimationMode")
:   [TextureBase:ResetTexCoord](API_TextureBase_ResetTexCoord.md "API TextureBase ResetTexCoord")
:   [TextureBase:SetSpriteSheetCell](API_TextureBase_SetSpriteSheetCell.md "API TextureBase SetSpriteSheetCell")
:   [Frame:IsIgnoringChildrenForBounds](API_Frame_IsIgnoringChildrenForBounds.md "API Frame IsIgnoringChildrenForBounds")
:   [Frame:RegisterEventCallback](API_Frame_RegisterEventCallback.md "API Frame RegisterEventCallback")
:   [Frame:RegisterUnitEventCallback](API_Frame_RegisterUnitEventCallback.md "API Frame RegisterUnitEventCallback")
:   [Frame:SetIgnoringChildrenForBounds](API_Frame_SetIgnoringChildrenForBounds.md "API Frame SetIgnoringChildrenForBounds")
:   [Model:SetUseGBuffer](API_Model_SetUseGBuffer.md "API Model SetUseGBuffer")
:   [GameTooltip:GetLeftLine](API_GameTooltip_GetLeftLine.md "API GameTooltip GetLeftLine")
:   [GameTooltip:GetRightLine](API_GameTooltip_GetRightLine.md "API GameTooltip GetRightLine")
:   [Cooldown:GetCountdownFontString](API_Cooldown_GetCountdownFontString.md "API Cooldown GetCountdownFontString")
:   [Cooldown:SetCooldownFromDurationObject](API_Cooldown_SetCooldownFromDurationObject.md "API Cooldown SetCooldownFromDurationObject")
:   [Cooldown:SetCooldownFromExpirationTime](API_Cooldown_SetCooldownFromExpirationTime.md "API Cooldown SetCooldownFromExpirationTime")
:   [Cooldown:SetPaused](API_Cooldown_SetPaused.md "API Cooldown SetPaused")
:   [StatusBar:GetInterpolatedValue](API_StatusBar_GetInterpolatedValue.md "API StatusBar GetInterpolatedValue")
:   [StatusBar:GetTimerDuration](API_StatusBar_GetTimerDuration.md "API StatusBar GetTimerDuration")
:   [StatusBar:IsInterpolating](API_StatusBar_IsInterpolating.md "API StatusBar IsInterpolating")
:   [StatusBar:SetTimerDuration](API_StatusBar_SetTimerDuration.md "API StatusBar SetTimerDuration")
:   [StatusBar:SetToTargetValue](API_StatusBar_SetToTargetValue.md "API StatusBar SetToTargetValue")

:   [ADDON\_RESTRICTION\_STATE\_CHANGED](ADDON_RESTRICTION_STATE_CHANGED.md "ADDON RESTRICTION STATE CHANGED")
:   [BULK\_PURCHASE\_RESULT\_RECEIVED](BULK_PURCHASE_RESULT_RECEIVED.md "BULK PURCHASE RESULT RECEIVED")
:   [CATALOG\_SHOP\_REFUNDABLE\_DECORS\_UPDATED](CATALOG_SHOP_REFUNDABLE_DECORS_UPDATED.md "CATALOG SHOP REFUNDABLE DECORS UPDATED")
:   [CATALOG\_SHOP\_VIRTUAL\_CURRENCY\_BALANCE\_UPDATE\_FAILURE](CATALOG_SHOP_VIRTUAL_CURRENCY_BALANCE_UPDATE_FAILURE.md "CATALOG SHOP VIRTUAL CURRENCY BALANCE UPDATE FAILURE")
:   [CATALOG\_SHOP\_VIRTUAL\_CURRENCY\_BALANCE\_UPDATE](CATALOG_SHOP_VIRTUAL_CURRENCY_BALANCE_UPDATE.md "CATALOG SHOP VIRTUAL CURRENCY BALANCE UPDATE")
:   [CHAT\_MSG\_ENCOUNTER\_EVENT](CHAT_MSG_ENCOUNTER_EVENT.md "CHAT MSG ENCOUNTER EVENT")
:   [COMBAT\_LOG\_APPLY\_FILTER\_SETTINGS](COMBAT_LOG_APPLY_FILTER_SETTINGS.md "COMBAT LOG APPLY FILTER SETTINGS")
:   [COMBAT\_LOG\_ENTRIES\_CLEARED](COMBAT_LOG_ENTRIES_CLEARED.md "COMBAT LOG ENTRIES CLEARED")
:   [COMBAT\_LOG\_EVENT\_INTERNAL\_UNFILTERED](COMBAT_LOG_EVENT_INTERNAL_UNFILTERED.md "COMBAT LOG EVENT INTERNAL UNFILTERED")
:   [COMBAT\_LOG\_MESSAGE\_LIMIT\_CHANGED](COMBAT_LOG_MESSAGE_LIMIT_CHANGED.md "COMBAT LOG MESSAGE LIMIT CHANGED")
:   [COMBAT\_LOG\_MESSAGE](COMBAT_LOG_MESSAGE.md "COMBAT LOG MESSAGE")
:   [COMBAT\_LOG\_REFILTER\_ENTRIES](COMBAT_LOG_REFILTER_ENTRIES.md "COMBAT LOG REFILTER ENTRIES")
:   [COMMENTATOR\_COMBAT\_EVENT](COMMENTATOR_COMBAT_EVENT.md "COMMENTATOR COMBAT EVENT")
:   [DAMAGE\_METER\_COMBAT\_SESSION\_UPDATED](DAMAGE_METER_COMBAT_SESSION_UPDATED.md "DAMAGE METER COMBAT SESSION UPDATED")
:   [DAMAGE\_METER\_CURRENT\_SESSION\_UPDATED](DAMAGE_METER_CURRENT_SESSION_UPDATED.md "DAMAGE METER CURRENT SESSION UPDATED")
:   [DAMAGE\_METER\_RESET](DAMAGE_METER_RESET.md "DAMAGE METER RESET")
:   [ENCOUNTER\_STATE\_CHANGED](ENCOUNTER_STATE_CHANGED.md "ENCOUNTER STATE CHANGED")
:   [ENCOUNTER\_TIMELINE\_EVENT\_ADDED](ENCOUNTER_TIMELINE_EVENT_ADDED.md "ENCOUNTER TIMELINE EVENT ADDED")
:   [ENCOUNTER\_TIMELINE\_EVENT\_BLOCK\_STATE\_CHANGED](ENCOUNTER_TIMELINE_EVENT_BLOCK_STATE_CHANGED.md "ENCOUNTER TIMELINE EVENT BLOCK STATE CHANGED")
:   [ENCOUNTER\_TIMELINE\_EVENT\_HIGHLIGHT](ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT.md "ENCOUNTER TIMELINE EVENT HIGHLIGHT")
:   [ENCOUNTER\_TIMELINE\_EVENT\_REMOVED](ENCOUNTER_TIMELINE_EVENT_REMOVED.md "ENCOUNTER TIMELINE EVENT REMOVED")
:   [ENCOUNTER\_TIMELINE\_EVENT\_STATE\_CHANGED](ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED.md "ENCOUNTER TIMELINE EVENT STATE CHANGED")
:   [ENCOUNTER\_TIMELINE\_EVENT\_TRACK\_CHANGED](ENCOUNTER_TIMELINE_EVENT_TRACK_CHANGED.md "ENCOUNTER TIMELINE EVENT TRACK CHANGED")
:   [ENCOUNTER\_TIMELINE\_LAYOUT\_UPDATED](ENCOUNTER_TIMELINE_LAYOUT_UPDATED.md "ENCOUNTER TIMELINE LAYOUT UPDATED")
:   [ENCOUNTER\_TIMELINE\_STATE\_UPDATED](ENCOUNTER_TIMELINE_STATE_UPDATED.md "ENCOUNTER TIMELINE STATE UPDATED")
:   [ENCOUNTER\_WARNING](ENCOUNTER_WARNING.md "ENCOUNTER WARNING")
:   [FACTION\_STANDING\_CHANGED](FACTION_STANDING_CHANGED.md "FACTION STANDING CHANGED")
:   [HOUSE\_EXTERIOR\_TYPE\_UNLOCKED](HOUSE_EXTERIOR_TYPE_UNLOCKED.md "HOUSE EXTERIOR TYPE UNLOCKED")
:   [HOUSE\_LEVEL\_CHANGED](HOUSE_LEVEL_CHANGED.md "HOUSE LEVEL CHANGED")
:   [HOUSING\_DECOR\_ADD\_TO\_PREVIEW\_LIST](HOUSING_DECOR_ADD_TO_PREVIEW_LIST.md "HOUSING DECOR ADD TO PREVIEW LIST")
:   [HOUSING\_DECOR\_FREE\_PLACE\_STATUS\_CHANGED](HOUSING_DECOR_FREE_PLACE_STATUS_CHANGED.md "HOUSING DECOR FREE PLACE STATUS CHANGED")
:   [HOUSING\_DECOR\_PREVIEW\_LIST\_REMOVE\_FROM\_WORLD](HOUSING_DECOR_PREVIEW_LIST_REMOVE_FROM_WORLD.md "HOUSING DECOR PREVIEW LIST REMOVE FROM WORLD")
:   [HOUSING\_DECOR\_PREVIEW\_LIST\_UPDATED](HOUSING_DECOR_PREVIEW_LIST_UPDATED.md "HOUSING DECOR PREVIEW LIST UPDATED")
:   [HOUSING\_DECOR\_PREVIEW\_STATE\_CHANGED](HOUSING_DECOR_PREVIEW_STATE_CHANGED.md "HOUSING DECOR PREVIEW STATE CHANGED")
:   [HOUSING\_EXPERT\_MODE\_PLACEMENT\_FLAGS\_UPDATED](HOUSING_EXPERT_MODE_PLACEMENT_FLAGS_UPDATED.md "HOUSING EXPERT MODE PLACEMENT FLAGS UPDATED")
:   [HOUSING\_FIXTURE\_UNLOCKED](HOUSING_FIXTURE_UNLOCKED.md "HOUSING FIXTURE UNLOCKED")
:   [HOUSING\_REFUND\_LIST\_UPDATED](HOUSING_REFUND_LIST_UPDATED.md "HOUSING REFUND LIST UPDATED")
:   [HOUSING\_SET\_EXTERIOR\_HOUSE\_SIZE\_RESPONSE](HOUSING_SET_EXTERIOR_HOUSE_SIZE_RESPONSE.md "HOUSING SET EXTERIOR HOUSE SIZE RESPONSE")
:   [HOUSING\_SET\_EXTERIOR\_HOUSE\_TYPE\_RESPONSE](HOUSING_SET_EXTERIOR_HOUSE_TYPE_RESPONSE.md "HOUSING SET EXTERIOR HOUSE TYPE RESPONSE")
:   [HOUSING\_SET\_FIXTURE\_RESPONSE](HOUSING_SET_FIXTURE_RESPONSE.md "HOUSING SET FIXTURE RESPONSE")
:   [INITIATIVE\_ACTIVITY\_LOG\_UPDATED](INITIATIVE_ACTIVITY_LOG_UPDATED.md "INITIATIVE ACTIVITY LOG UPDATED")
:   [INITIATIVE\_COMPLETED](INITIATIVE_COMPLETED.md "INITIATIVE COMPLETED")
:   [INITIATIVE\_TASK\_COMPLETED](INITIATIVE_TASK_COMPLETED.md "INITIATIVE TASK COMPLETED")
:   [INITIATIVE\_TASKS\_TRACKED\_LIST\_CHANGED](INITIATIVE_TASKS_TRACKED_LIST_CHANGED.md "INITIATIVE TASKS TRACKED LIST CHANGED")
:   [INITIATIVE\_TASKS\_TRACKED\_UPDATED](INITIATIVE_TASKS_TRACKED_UPDATED.md "INITIATIVE TASKS TRACKED UPDATED")
:   [LEGACY\_LOOT\_RULES\_CHANGED](LEGACY_LOOT_RULES_CHANGED.md "LEGACY LOOT RULES CHANGED")
:   [NAME\_PLATE\_UNIT\_BEHIND\_CAMERA\_CHANGED](NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED.md "NAME PLATE UNIT BEHIND CAMERA CHANGED")
:   [NEIGHBORHOOD\_INITIATIVE\_UPDATED](NEIGHBORHOOD_INITIATIVE_UPDATED.md "NEIGHBORHOOD INITIATIVE UPDATED")
:   [PARTY\_KILL](PARTY_KILL.md "PARTY KILL")
:   [PLAYER\_TARGET\_DIED](PLAYER_TARGET_DIED.md "PLAYER TARGET DIED")
:   [REMOVE\_NEIGHBORHOOD\_CHARTER\_SIGNATURE](REMOVE_NEIGHBORHOOD_CHARTER_SIGNATURE.md "REMOVE NEIGHBORHOOD CHARTER SIGNATURE")
:   [SECURE\_TRANSFER\_CONFIRM\_HOUSING\_PURCHASE](SECURE_TRANSFER_CONFIRM_HOUSING_PURCHASE.md "SECURE TRANSFER CONFIRM HOUSING PURCHASE")
:   [SECURE\_TRANSFER\_HOUSING\_CURRENCY\_PURCHASE\_CONFIRMATION](SECURE_TRANSFER_HOUSING_CURRENCY_PURCHASE_CONFIRMATION.md "SECURE TRANSFER HOUSING CURRENCY PURCHASE CONFIRMATION")
:   [SET\_SEEN\_PRODUCTS](SET_SEEN_PRODUCTS.md "SET SEEN PRODUCTS")
:   [SETTINGS\_LOADED](SETTINGS_LOADED.md "SETTINGS LOADED")
:   [SETTINGS\_PANEL\_OPEN](SETTINGS_PANEL_OPEN.md "SETTINGS PANEL OPEN")
:   [SHOW\_JOURNEYS\_UI](SHOW_JOURNEYS_UI.md "SHOW JOURNEYS UI")
:   [SHOW\_NEW\_PRODUCT\_NOTIFICATION](SHOW_NEW_PRODUCT_NOTIFICATION.md "SHOW NEW PRODUCT NOTIFICATION")
:   [TOOLTIP\_SHOW\_ITEM\_COMPARISON](TOOLTIP_SHOW_ITEM_COMPARISON.md "TOOLTIP SHOW ITEM COMPARISON")
:   [TRAINING\_GROUNDS\_ENABLED\_STATUS\_UPDATED](TRAINING_GROUNDS_ENABLED_STATUS_UPDATED.md "TRAINING GROUNDS ENABLED STATUS UPDATED")
:   [TRANSMOG\_CUSTOM\_SETS\_CHANGED](TRANSMOG_CUSTOM_SETS_CHANGED.md "TRANSMOG CUSTOM SETS CHANGED")
:   [TRANSMOG\_DISPLAYED\_OUTFIT\_CHANGED](TRANSMOG_DISPLAYED_OUTFIT_CHANGED.md "TRANSMOG DISPLAYED OUTFIT CHANGED")
:   [TRANSMOG\_OUTFITS\_CHANGED](TRANSMOG_OUTFITS_CHANGED.md "TRANSMOG OUTFITS CHANGED")
:   [TUTORIAL\_COMBAT\_EVENT](TUTORIAL_COMBAT_EVENT.md "TUTORIAL COMBAT EVENT")
:   [UNIT\_DIED](UNIT_DIED.md "UNIT DIED")
:   [UNIT\_LOOT](UNIT_LOOT.md "UNIT LOOT")
:   [UNIT\_SPELL\_DIMINISH\_CATEGORY\_STATE\_UPDATED](UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED.md "UNIT SPELL DIMINISH CATEGORY STATE UPDATED")
:   [UNIT\_SPELLCAST\_SENT](UNIT_SPELLCAST_SENT.md "UNIT SPELLCAST SENT")
:   [UPDATE\_BULLETIN\_BOARD\_MEMBER\_TYPE](UPDATE_BULLETIN_BOARD_MEMBER_TYPE.md "UPDATE BULLETIN BOARD MEMBER TYPE")
:   [VIEWED\_TRANSMOG\_OUTFIT\_CHANGED](VIEWED_TRANSMOG_OUTFIT_CHANGED.md "VIEWED TRANSMOG OUTFIT CHANGED")
:   [VIEWED\_TRANSMOG\_OUTFIT\_SECONDARY\_SLOTS\_CHANGED](VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED.md "VIEWED TRANSMOG OUTFIT SECONDARY SLOTS CHANGED")
:   [VIEWED\_TRANSMOG\_OUTFIT\_SITUATIONS\_CHANGED](VIEWED_TRANSMOG_OUTFIT_SITUATIONS_CHANGED.md "VIEWED TRANSMOG OUTFIT SITUATIONS CHANGED")
:   [VIEWED\_TRANSMOG\_OUTFIT\_SLOT\_REFRESH](VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH.md "VIEWED TRANSMOG OUTFIT SLOT REFRESH")
:   [VIEWED\_TRANSMOG\_OUTFIT\_SLOT\_SAVE\_SUCCESS](VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS.md "VIEWED TRANSMOG OUTFIT SLOT SAVE SUCCESS")
:   [VIEWED\_TRANSMOG\_OUTFIT\_SLOT\_WEAPON\_OPTION\_CHANGED](VIEWED_TRANSMOG_OUTFIT_SLOT_WEAPON_OPTION_CHANGED.md "VIEWED TRANSMOG OUTFIT SLOT WEAPON OPTION CHANGED")
:   [VOICE\_CHAT\_TTS\_PLAYBACK\_BOOKMARK](VOICE_CHAT_TTS_PLAYBACK_BOOKMARK.md "VOICE CHAT TTS PLAYBACK BOOKMARK")

:   [HOUSE\_LEVEL\_CHANGED](HOUSE_LEVEL_CHANGED.md "HOUSE LEVEL CHANGED")
:   [HOUSING\_CATALOG\_SEARCHER\_RELEASED](HOUSING_CATALOG_SEARCHER_RELEASED.md "HOUSING CATALOG SEARCHER RELEASED")
:   [HOUSING\_DECOR\_NUDGE\_STATUS\_CHANGED](HOUSING_DECOR_NUDGE_STATUS_CHANGED.md "HOUSING DECOR NUDGE STATUS CHANGED")
:   [LEARNED\_SPELL\_IN\_TAB](LEARNED_SPELL_IN_TAB.md "LEARNED SPELL IN TAB")
:   [SETTINGS\_LOADED](SETTINGS_LOADED.md "SETTINGS LOADED")
:   [SHOW\_DELVES\_DISPLAY\_UI](SHOW_DELVES_DISPLAY_UI.md "SHOW DELVES DISPLAY UI")
:   [TRANSMOG\_OUTFITS\_CHANGED](TRANSMOG_OUTFITS_CHANGED.md "TRANSMOG OUTFITS CHANGED")
:   [UNIT\_SPELLCAST\_SENT](UNIT_SPELLCAST_SENT.md "UNIT SPELLCAST SENT")

:   [addonChatRestrictionsForced](CVar_addonChatRestrictionsForced.md "CVar addonChatRestrictionsForced (page does not exist)")CVar: addonChatRestrictionsForced (Game)  
    Default: `0`  
    If true, force the client into the chat lockdown state. This is provided for addon author testing and will not persist across client restarts.
:   [alwaysShowRuneIcons](CVar_alwaysShowRuneIcons.md "CVar alwaysShowRuneIcons (page does not exist)")CVar: alwaysShowRuneIcons (None)  
    Default: `0`, Scope: Account  
    Show the rune icons on equipment at all times, as opposed to only when the rune UI is open.
:   [auctionSortByBuyoutPrice](CVar_auctionSortByBuyoutPrice.md "CVar auctionSortByBuyoutPrice (page does not exist)")CVar: auctionSortByBuyoutPrice (Game)  
    Default: `0`, Scope: Character  
    Sort auction items by buyout price instead of current bid price
:   [auctionSortByUnitPrice](CVar_auctionSortByUnitPrice.md "CVar auctionSortByUnitPrice (page does not exist)")CVar: auctionSortByUnitPrice (Game)  
    Default: `0`, Scope: Character  
    Sort auction items by unit price instead of total stack price
:   [CAAEnabled](CVar_CAAEnabled.md "CVar CAAEnabled (page does not exist)")CVar: CAAEnabled (Game)  
    Default: `0`, Scope: Account  
    Enable or disable combat audio alerts
:   [CAAInterruptCastSuccess](CVar_CAAInterruptCastSuccess.md "CVar CAAInterruptCastSuccess (page does not exist)")CVar: CAAInterruptCastSuccess (Game)  
    Default: `0`, Scope: Account  
    Announce when the target's cast is interrupted
:   [CAAInterruptCast](CVar_CAAInterruptCast.md "CVar CAAInterruptCast (page does not exist)")CVar: CAAInterruptCast (Game)  
    Default: `0`, Scope: Account  
    Announce when the target starts casting something interruptible
:   [CAAPartyHealthFrequency](CVar_CAAPartyHealthFrequency.md "CVar CAAPartyHealthFrequency (page does not exist)")CVar: CAAPartyHealthFrequency (Game)  
    Default: `0`, Scope: Account  
    Relative frequency at which party health combat audio alerts are read (-10 to 10). -10 halves the frequency and 10 doubles it
:   [CAAPartyHealthPercent](CVar_CAAPartyHealthPercent.md "CVar CAAPartyHealthPercent (page does not exist)")CVar: CAAPartyHealthPercent (Game)  
    Default: `0`, Scope: Account  
    Announce party member indices to indicate current health when it's below X percent. Frequency of announcements are affected by remaining health and CAAPartyHealthFrequencySpeed
:   [CAAPlayerCastFormat](CVar_CAAPlayerCastFormat.md "CVar CAAPlayerCastFormat (page does not exist)")CVar: CAAPlayerCastFormat (Game)  
    Default: `4`, Scope: Account  
    Format string to use when reading the player's casts
:   [CAAPlayerCastMinTime](CVar_CAAPlayerCastMinTime.md "CVar CAAPlayerCastMinTime (page does not exist)")CVar: CAAPlayerCastMinTime (Game)  
    Default: `1.500000`, Scope: Account  
    The player's casts will only be read out if they have a cast time >= this
:   [CAAPlayerCastMode](CVar_CAAPlayerCastMode.md "CVar CAAPlayerCastMode (page does not exist)")CVar: CAAPlayerCastMode (Game)  
    Default: `0`, Scope: Account  
    When the player's casts should be announced (0=off, 1=cast start, 2=cast end)
:   [CAAPlayerCastThrottle](CVar_CAAPlayerCastThrottle.md "CVar CAAPlayerCastThrottle (page does not exist)")CVar: CAAPlayerCastThrottle (Game)  
    Default: `0.000000`, Scope: Account  
    The player's casts will only be read every X seconds at most
:   [CAAPlayerHealthFormat](CVar_CAAPlayerHealthFormat.md "CVar CAAPlayerHealthFormat (page does not exist)")CVar: CAAPlayerHealthFormat (Game)  
    Default: `1`, Scope: Account  
    Format string to use when reading the player's health
:   [CAAPlayerHealthPercent](CVar_CAAPlayerHealthPercent.md "CVar CAAPlayerHealthPercent (page does not exist)")CVar: CAAPlayerHealthPercent (Game)  
    Default: `0`, Scope: Account  
    Announce player health every X percent
:   [CAAPlayerHealthThrottle](CVar_CAAPlayerHealthThrottle.md "CVar CAAPlayerHealthThrottle (page does not exist)")CVar: CAAPlayerHealthThrottle (Game)  
    Default: `0.000000`, Scope: Account  
    The player's health will only be read every X seconds at most
:   [CAAResource1Formats](CVar_CAAResource1Formats.md "CVar CAAResource1Formats (page does not exist)")CVar: CAAResource1Formats (Game)  
    Scope: Character  
    Stores the format string to use (for each spec) when announcing the player's first resource
:   [CAAResource1Percents](CVar_CAAResource1Percents.md "CVar CAAResource1Percents (page does not exist)")CVar: CAAResource1Percents (Game)  
    Scope: Character  
    Stores the percentage band sizes to use (for each spec) when announcing the player's first resource
:   [CAAResource1Throttle](CVar_CAAResource1Throttle.md "CVar CAAResource1Throttle (page does not exist)")CVar: CAAResource1Throttle (Game)  
    Default: `0.000000`, Scope: Character  
    Updates to the player's first resource will only be read every X seconds at most
:   [CAAResource2Formats](CVar_CAAResource2Formats.md "CVar CAAResource2Formats (page does not exist)")CVar: CAAResource2Formats (Game)  
    Scope: Character  
    Stores the format string to use (for each spec) when announcing the player's second resource
:   [CAAResource2Percents](CVar_CAAResource2Percents.md "CVar CAAResource2Percents (page does not exist)")CVar: CAAResource2Percents (Game)  
    Scope: Character  
    Stores the percentage band sizes to use (for each spec) when announcing the player's second resource
:   [CAAResource2Throttle](CVar_CAAResource2Throttle.md "CVar CAAResource2Throttle (page does not exist)")CVar: CAAResource2Throttle (Game)  
    Default: `0.000000`, Scope: Character  
    Updates to the player's second resource will only be read every X seconds at most
:   [CAASayCombatEnd](CVar_CAASayCombatEnd.md "CVar CAASayCombatEnd (page does not exist)")CVar: CAASayCombatEnd (Game)  
    Default: `1`, Scope: Account  
    Announce when combat ends
:   [CAASayCombatStart](CVar_CAASayCombatStart.md "CVar CAASayCombatStart (page does not exist)")CVar: CAASayCombatStart (Game)  
    Default: `1`, Scope: Account  
    Announce when combat starts
:   [CAASayIfTargeted](CVar_CAASayIfTargeted.md "CVar CAASayIfTargeted (page does not exist)")CVar: CAASayIfTargeted (Game)  
    Scope: Character  
    Stores the 'say if targeted' settings for each spec
:   [CAASayTargetName](CVar_CAASayTargetName.md "CVar CAASayTargetName (page does not exist)")CVar: CAASayTargetName (Game)  
    Default: `1`, Scope: Account  
    Say the target's name when a new target is selected
:   [CAASpeed](CVar_CAASpeed.md "CVar CAASpeed (page does not exist)")CVar: CAASpeed (Game)  
    Default: `0`, Scope: Account  
    Speed at which combat audio alerts are read (-10 to 10)
:   [CAATargetCastFormat](CVar_CAATargetCastFormat.md "CVar CAATargetCastFormat (page does not exist)")CVar: CAATargetCastFormat (Game)  
    Default: `0`, Scope: Account  
    Format string to use when reading the target's casts
:   [CAATargetCastMinTime](CVar_CAATargetCastMinTime.md "CVar CAATargetCastMinTime (page does not exist)")CVar: CAATargetCastMinTime (Game)  
    Default: `1.500000`, Scope: Account  
    The target's casts will only be read out if they have a cast time >= this
:   [CAATargetCastMode](CVar_CAATargetCastMode.md "CVar CAATargetCastMode (page does not exist)")CVar: CAATargetCastMode (Game)  
    Default: `0`, Scope: Account  
    When the target's casts should be announced (0=off, 1=cast start, 2=cast end)
:   [CAATargetCastThrottle](CVar_CAATargetCastThrottle.md "CVar CAATargetCastThrottle (page does not exist)")CVar: CAATargetCastThrottle (Game)  
    Default: `0.000000`, Scope: Account  
    The target's casts will only be read every X seconds at most
:   [CAATargetDeathBehavior](CVar_CAATargetDeathBehavior.md "CVar CAATargetDeathBehavior (page does not exist)")CVar: CAATargetDeathBehavior (Game)  
    Default: `0`, Scope: Account  
    Behavior of announcement when target dies (0=default, 1=target dead)
:   [CAATargetHealthFormat](CVar_CAATargetHealthFormat.md "CVar CAATargetHealthFormat (page does not exist)")CVar: CAATargetHealthFormat (Game)  
    Default: `3`, Scope: Account  
    Format string to use when reading the target's health
:   [CAATargetHealthPercent](CVar_CAATargetHealthPercent.md "CVar CAATargetHealthPercent (page does not exist)")CVar: CAATargetHealthPercent (Game)  
    Default: `2`, Scope: Account  
    Announce target health every X percent
:   [CAATargetHealthThrottle](CVar_CAATargetHealthThrottle.md "CVar CAATargetHealthThrottle (page does not exist)")CVar: CAATargetHealthThrottle (Game)  
    Default: `0.000000`, Scope: Account  
    The target's health will only be read every X seconds at most
:   [CAAVoice](CVar_CAAVoice.md "CVar CAAVoice (page does not exist)")CVar: CAAVoice (Game)  
    Default: `0`, Scope: Account  
    Voice to use for combat audio alerts
:   [CAAVolume](CVar_CAAVolume.md "CVar CAAVolume (page does not exist)")CVar: CAAVolume (Game)  
    Default: `100`, Scope: Account  
    Volume of combat audio alerts (0 to 100)
:   [chatBubblesRaid](CVar_chatBubblesRaid.md "CVar chatBubblesRaid (page does not exist)")CVar: chatBubblesRaid (Game)  
    Default: `0`, Scope: Account  
    Whether to show in-game chat bubbles for raid chat
:   [combatWarningsEnabled](CVar_combatWarningsEnabled.md "CVar combatWarningsEnabled (page does not exist)")CVar: combatWarningsEnabled (Game)  
    Default: `1`, Scope: Account  
    If set, enables combat warning UI functionality such as the boss timeline or warnings displays
:   [damageMeterEnabled](CVar_damageMeterEnabled.md "CVar damageMeterEnabled (page does not exist)")CVar: damageMeterEnabled (Game)  
    Default: `0`, Scope: Character  
    If true, show the damage meter UI.
:   [disableSuggestedLevelActivityFilter](CVar_disableSuggestedLevelActivityFilter.md "CVar disableSuggestedLevelActivityFilter (page does not exist)")CVar: disableSuggestedLevelActivityFilter (Game)  
    Default: `0`, Scope: Account  
    Whether to disable filtering the activity list by the user's level.
:   [enablePetBattleFloatingCombatText\_v2](CVar_enablePetBattleFloatingCombatText_v2.md "CVar enablePetBattleFloatingCombatText v2 (page does not exist)")CVar: enablePetBattleFloatingCombatText\_v2 (Game)  
    Default: `1`  
    Whether to show floating combat text for pet battles
:   [encounterTimelineEnabled](CVar_encounterTimelineEnabled.md "CVar encounterTimelineEnabled (page does not exist)")CVar: encounterTimelineEnabled (Game)  
    Default: `1`, Scope: Account  
    If true, enable the encounter timeline UI.
:   [encounterTimelineHideForOtherRoles](CVar_encounterTimelineHideForOtherRoles.md "CVar encounterTimelineHideForOtherRoles (page does not exist)")CVar: encounterTimelineHideForOtherRoles (Game)  
    Default: `0`, Scope: Account  
    If true, hide encounter timeline events that are relevant for roles other than the player's own group role assignment. Events with no assigned role will always be shown.
:   [encounterTimelineHideLongCountdowns](CVar_encounterTimelineHideLongCountdowns.md "CVar encounterTimelineHideLongCountdowns (page does not exist)")CVar: encounterTimelineHideLongCountdowns (Game)  
    Default: `0`, Scope: Account  
    If true, hide all long countdowns from the timeline.
:   [encounterTimelineHideQueuedCountdowns](CVar_encounterTimelineHideQueuedCountdowns.md "CVar encounterTimelineHideQueuedCountdowns (page does not exist)")CVar: encounterTimelineHideQueuedCountdowns (Game)  
    Default: `0`, Scope: Account  
    If true, hide all queued countdowns from the timeline.
:   [encounterTimelineIconographyEnabled](CVar_encounterTimelineIconographyEnabled.md "CVar encounterTimelineIconographyEnabled (page does not exist)")CVar: encounterTimelineIconographyEnabled (Game)  
    Default: `1`, Scope: Account  
    If true, enable the display of spell support iconography such as role and effect type indicators.
:   [encounterWarningsDefaultMessageDuration](CVar_encounterWarningsDefaultMessageDuration.md "CVar encounterWarningsDefaultMessageDuration (page does not exist)")CVar: encounterWarningsDefaultMessageDuration (Game)  
    Default: `3500`, Scope: Account  
    Default duration (in milliseconds) applied to encounter warning text messages
:   [encounterWarningsEnabled](CVar_encounterWarningsEnabled.md "CVar encounterWarningsEnabled (page does not exist)")CVar: encounterWarningsEnabled (Game)  
    Default: `1`, Scope: Account  
    If true, enable the display of encounter warning messages
:   [encounterWarningsHideIfNotTargetingPlayer](CVar_encounterWarningsHideIfNotTargetingPlayer.md "CVar encounterWarningsHideIfNotTargetingPlayer (page does not exist)")CVar: encounterWarningsHideIfNotTargetingPlayer (Game)  
    Default: `0`, Scope: Account  
    If true, hide messages that aren't actively targeting the player. Messages that have no explicit target will always be shown
:   [encounterWarningsLevel](CVar_encounterWarningsLevel.md "CVar encounterWarningsLevel (page does not exist)")CVar: encounterWarningsLevel (Game)  
    Default: `0`, Scope: Account  
    Minimum level of encounter warning severities to be shown
:   [endeavorInitiativesLastPoints](CVar_endeavorInitiativesLastPoints.md "CVar endeavorInitiativesLastPoints (page does not exist)")CVar: endeavorInitiativesLastPoints (Game)  
    Default: `0`, Scope: Account  
    Last seen number of endeavor points in the progress bar
:   [equipmentManager](CVar_equipmentManager.md "CVar equipmentManager")CVar: equipmentManager (Game)  
    Default: `1`, Scope: Character  
    Enables the equipment management UI
:   [externalDefensivesEnabled](CVar_externalDefensivesEnabled.md "CVar externalDefensivesEnabled (page does not exist)")CVar: externalDefensivesEnabled (Game)  
    Default: `0`, Scope: Character  
    If true, show the external defensives buff tracker UI.
:   [floatingCombatTextAuraFade\_v2](CVar_floatingCombatTextAuraFade_v2.md "CVar floatingCombatTextAuraFade v2 (page does not exist)")CVar: floatingCombatTextAuraFade\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextAuras\_v2](CVar_floatingCombatTextAuras_v2.md "CVar floatingCombatTextAuras v2 (page does not exist)")CVar: floatingCombatTextAuras\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextCombatDamage\_v2](CVar_floatingCombatTextCombatDamage_v2.md "CVar floatingCombatTextCombatDamage v2 (page does not exist)")CVar: floatingCombatTextCombatDamage\_v2 (Game)  
    Default: `1`  
    Display damage numbers over hostile creatures when damaged
:   [floatingCombatTextCombatDamageAllAutos\_v2](CVar_floatingCombatTextCombatDamageAllAutos_v2.md "CVar floatingCombatTextCombatDamageAllAutos v2 (page does not exist)")CVar: floatingCombatTextCombatDamageAllAutos\_v2 (Game)  
    Default: `1`  
    Show all auto-attack numbers, rather than hiding non-event numbers
:   [floatingCombatTextCombatDamageDirectionalOffset\_v2](CVar_floatingCombatTextCombatDamageDirectionalOffset_v2.md "CVar floatingCombatTextCombatDamageDirectionalOffset v2 (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalOffset\_v2 (Game)  
    Default: `1.000000`  
    Amount to offset directional damage numbers when they start
:   [floatingCombatTextCombatDamageDirectionalScale\_v2](CVar_floatingCombatTextCombatDamageDirectionalScale_v2.md "CVar floatingCombatTextCombatDamageDirectionalScale v2 (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalScale\_v2 (Game)  
    Default: `1.000000`  
    Directional damage numbers movement scale (0 = no directional numbers)
:   [floatingCombatTextCombatHealing\_v2](CVar_floatingCombatTextCombatHealing_v2.md "CVar floatingCombatTextCombatHealing v2 (page does not exist)")CVar: floatingCombatTextCombatHealing\_v2 (Game)  
    Default: `1`  
    Display amount of healing you did to the target
:   [floatingCombatTextCombatHealingAbsorbSelf\_v2](CVar_floatingCombatTextCombatHealingAbsorbSelf_v2.md "CVar floatingCombatTextCombatHealingAbsorbSelf v2 (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbSelf\_v2 (Game)  
    Default: `1`  
    Display amount of shield added to yourself.
:   [floatingCombatTextCombatHealingAbsorbTarget\_v2](CVar_floatingCombatTextCombatHealingAbsorbTarget_v2.md "CVar floatingCombatTextCombatHealingAbsorbTarget v2 (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbTarget\_v2 (Game)  
    Default: `1`  
    Display amount of shield added to the target.
:   [floatingCombatTextCombatLogPeriodicSpells\_v2](CVar_floatingCombatTextCombatLogPeriodicSpells_v2.md "CVar floatingCombatTextCombatLogPeriodicSpells v2 (page does not exist)")CVar: floatingCombatTextCombatLogPeriodicSpells\_v2 (Game)  
    Default: `1`  
    Display damage caused by periodic effects
:   [floatingCombatTextCombatState\_v2](CVar_floatingCombatTextCombatState_v2.md "CVar floatingCombatTextCombatState v2 (page does not exist)")CVar: floatingCombatTextCombatState\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextComboPoints\_v2](CVar_floatingCombatTextComboPoints_v2.md "CVar floatingCombatTextComboPoints v2 (page does not exist)")CVar: floatingCombatTextComboPoints\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextDamageReduction\_v2](CVar_floatingCombatTextDamageReduction_v2.md "CVar floatingCombatTextDamageReduction v2 (page does not exist)")CVar: floatingCombatTextDamageReduction\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextDodgeParryMiss\_v2](CVar_floatingCombatTextDodgeParryMiss_v2.md "CVar floatingCombatTextDodgeParryMiss v2 (page does not exist)")CVar: floatingCombatTextDodgeParryMiss\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextEnergyGains\_v2](CVar_floatingCombatTextEnergyGains_v2.md "CVar floatingCombatTextEnergyGains v2 (page does not exist)")CVar: floatingCombatTextEnergyGains\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextFloatMode\_v2](CVar_floatingCombatTextFloatMode_v2.md "CVar floatingCombatTextFloatMode v2 (page does not exist)")CVar: floatingCombatTextFloatMode\_v2 (Game)  
    Default: `1`  
    The combat text float mode for the player
:   [floatingCombatTextFriendlyHealers\_v2](CVar_floatingCombatTextFriendlyHealers_v2.md "CVar floatingCombatTextFriendlyHealers v2 (page does not exist)")CVar: floatingCombatTextFriendlyHealers\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextHonorGains\_v2](CVar_floatingCombatTextHonorGains_v2.md "CVar floatingCombatTextHonorGains v2 (page does not exist)")CVar: floatingCombatTextHonorGains\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextLowManaHealth\_v2](CVar_floatingCombatTextLowManaHealth_v2.md "CVar floatingCombatTextLowManaHealth v2 (page does not exist)")CVar: floatingCombatTextLowManaHealth\_v2 (Game)  
    Default: `1`
:   [floatingCombatTextPeriodicEnergyGains\_v2](CVar_floatingCombatTextPeriodicEnergyGains_v2.md "CVar floatingCombatTextPeriodicEnergyGains v2 (page does not exist)")CVar: floatingCombatTextPeriodicEnergyGains\_v2 (Game)  
    Default: `0`
:   [floatingCombatTextPetMeleeDamage\_v2](CVar_floatingCombatTextPetMeleeDamage_v2.md "CVar floatingCombatTextPetMeleeDamage v2 (page does not exist)")CVar: floatingCombatTextPetMeleeDamage\_v2 (Game)  
    Default: `1`  
    Display pet melee damage in the world
:   [floatingCombatTextPetSpellDamage\_v2](CVar_floatingCombatTextPetSpellDamage_v2.md "CVar floatingCombatTextPetSpellDamage v2 (page does not exist)")CVar: floatingCombatTextPetSpellDamage\_v2 (Game)  
    Default: `1`  
    Display pet spell damage in the world
:   [floatingCombatTextReactives\_v2](CVar_floatingCombatTextReactives_v2.md "CVar floatingCombatTextReactives v2 (page does not exist)")CVar: floatingCombatTextReactives\_v2 (Game)  
    Default: `1`
:   [floatingCombatTextRepChanges\_v2](CVar_floatingCombatTextRepChanges_v2.md "CVar floatingCombatTextRepChanges v2 (page does not exist)")CVar: floatingCombatTextRepChanges\_v2 (Game)  
    Default: `0`
:   [lastTransmogCustomSetIDNoSpec](CVar_lastTransmogCustomSetIDNoSpec.md "CVar lastTransmogCustomSetIDNoSpec (page does not exist)")CVar: lastTransmogCustomSetIDNoSpec (Game)  
    Scope: Character  
    SetID of the last applied transmog custom set
:   [lastTransmogCustomSetIDSpec1](CVar_lastTransmogCustomSetIDSpec1.md "CVar lastTransmogCustomSetIDSpec1 (page does not exist)")CVar: lastTransmogCustomSetIDSpec1 (Game)  
    Scope: Character  
    SetID of the last applied transmog custom set for the 1st spec
:   [lastTransmogCustomSetIDSpec2](CVar_lastTransmogCustomSetIDSpec2.md "CVar lastTransmogCustomSetIDSpec2 (page does not exist)")CVar: lastTransmogCustomSetIDSpec2 (Game)  
    Scope: Character  
    SetID of the last applied transmog custom set for the 2nd spec
:   [lastTransmogCustomSetIDSpec3](CVar_lastTransmogCustomSetIDSpec3.md "CVar lastTransmogCustomSetIDSpec3 (page does not exist)")CVar: lastTransmogCustomSetIDSpec3 (Game)  
    Scope: Character  
    SetID of the last applied transmog custom set for the 3rd spec
:   [lastTransmogCustomSetIDSpec4](CVar_lastTransmogCustomSetIDSpec4.md "CVar lastTransmogCustomSetIDSpec4 (page does not exist)")CVar: lastTransmogCustomSetIDSpec4 (Game)  
    Scope: Character  
    SetID of the last applied transmog custom set for the 4th spec
:   [lastTransmogOutfitIDNoSpec](CVar_lastTransmogOutfitIDNoSpec.md "CVar lastTransmogOutfitIDNoSpec (page does not exist)")CVar: lastTransmogOutfitIDNoSpec (Game)  
    Scope: Character  
    SetID of the last applied transmog outfit
:   [lfgListAdvancedFiltersVersion](CVar_lfgListAdvancedFiltersVersion.md "CVar lfgListAdvancedFiltersVersion (page does not exist)")CVar: lfgListAdvancedFiltersVersion (Game)  
    Default: `0`, Scope: Account  
    Version for lfgListAdvancedFilters
:   [majorFactionRenownMap](CVar_majorFactionRenownMap.md "CVar majorFactionRenownMap (page does not exist)")CVar: majorFactionRenownMap (Game)  
    Scope: Account  
    Serialized mapping of faction ID to last known renown rank/level. Updated when the Renown UI is closed, used to control animations in the Major Faction UI.
:   [minimapTrackedInfov2](CVar_minimapTrackedInfov2.md "CVar minimapTrackedInfov2 (page does not exist)")CVar: minimapTrackedInfov2
:   [nameplateAuraScale](CVar_nameplateAuraScale.md "CVar nameplateAuraScale (page does not exist)")CVar: nameplateAuraScale (Game)  
    Default: `1.000000`, Scope: Account  
    Controls the size multiplier for buffs and debuffs on nameplates.
:   [nameplateDebuffPadding](CVar_nameplateDebuffPadding.md "CVar nameplateDebuffPadding (page does not exist)")CVar: nameplateDebuffPadding (Game)  
    Default: `0`, Scope: Account  
    The padding between the debuff list and the health bar on nameplates.
:   [nameplateShowCastBars](CVar_nameplateShowCastBars.md "CVar nameplateShowCastBars (page does not exist)")CVar: nameplateShowCastBars (Game)  
    Default: `1`, Scope: Character  
    Show cast bars for unit nameplates.
:   [nameplateShowClassColor](CVar_nameplateShowClassColor.md "CVar nameplateShowClassColor (page does not exist)")CVar: nameplateShowClassColor (Game)  
    Default: `1`  
    Used to display the class color in enemy nameplate health bars
:   [nameplateShowFriendlyClassColor](CVar_nameplateShowFriendlyClassColor.md "CVar nameplateShowFriendlyClassColor (page does not exist)")CVar: nameplateShowFriendlyClassColor (Game)  
    Default: `1`  
    Used to display the class color in friendly nameplate health bars
:   [nameplateShowFriendlyNpcs](CVar_nameplateShowFriendlyNpcs.md "CVar nameplateShowFriendlyNpcs (page does not exist)")CVar: nameplateShowFriendlyNpcs (Game)  
    Default: `0`, Scope: Account  
    Whether nameplates are shown for friendly npcs.
:   [nameplateShowFriendlyPlayerGuardians](CVar_nameplateShowFriendlyPlayerGuardians.md "CVar nameplateShowFriendlyPlayerGuardians (page does not exist)")CVar: nameplateShowFriendlyPlayerGuardians (Game)  
    Default: `0`, Scope: Account  
    Whether friendly player guardian nameplates are shown.
:   [nameplateShowFriendlyPlayerMinions](CVar_nameplateShowFriendlyPlayerMinions.md "CVar nameplateShowFriendlyPlayerMinions (page does not exist)")CVar: nameplateShowFriendlyPlayerMinions (Game)  
    Default: `0`, Scope: Account  
    Whether friendly player minion nameplates are shown.
:   [nameplateShowFriendlyPlayerPets](CVar_nameplateShowFriendlyPlayerPets.md "CVar nameplateShowFriendlyPlayerPets (page does not exist)")CVar: nameplateShowFriendlyPlayerPets (Game)  
    Default: `0`, Scope: Account  
    Whether friendly player pet nameplates are shown.
:   [nameplateShowFriendlyPlayers](CVar_nameplateShowFriendlyPlayers.md "CVar nameplateShowFriendlyPlayers (page does not exist)")CVar: nameplateShowFriendlyPlayers (Game)  
    Default: `0`, Scope: Account  
    Whether nameplates are shown for friendly players.
:   [nameplateShowFriendlyPlayerTotems](CVar_nameplateShowFriendlyPlayerTotems.md "CVar nameplateShowFriendlyPlayerTotems (page does not exist)")CVar: nameplateShowFriendlyPlayerTotems (Game)  
    Default: `0`, Scope: Account  
    Whether friendly player totem nameplates are shown.
:   [nameplateShowOffscreen](CVar_nameplateShowOffscreen.md "CVar nameplateShowOffscreen (page does not exist)")CVar: nameplateShowOffscreen (Game)  
    Default: `0`, Scope: Account  
    When enabled, the nameplate is always shown if owner is in combat with player or player's group member.
:   [nameplateShowOnlyNameForFriendlyPlayerUnits](CVar_nameplateShowOnlyNameForFriendlyPlayerUnits.md "CVar nameplateShowOnlyNameForFriendlyPlayerUnits (page does not exist)")CVar: nameplateShowOnlyNameForFriendlyPlayerUnits (Game)  
    Default: `0`  
    Used to hide every part of the nameplate but the name for friendly player units.
:   [nameplateSize](CVar_nameplateSize.md "CVar nameplateSize (page does not exist)")CVar: nameplateSize (Game)  
    Default: `1`, Scope: Account  
    Provides discrete values that are translated into specific horizontal and vertical scales defined in lua for displaying nameplates.
:   [nameplateStyle](CVar_nameplateStyle.md "CVar nameplateStyle (page does not exist)")CVar: nameplateStyle (Game)  
    Default: `0`, Scope: Account  
    Determines how nameplate contents are displayed.
:   [petJournalFilterVersion](CVar_petJournalFilterVersion.md "CVar petJournalFilterVersion (page does not exist)")CVar: petJournalFilterVersion (Game)  
    Default: `0`, Scope: Account  
    Current filter version. Will reset all filters to their defaults if out of date.
:   [raidFramesCenterBigDefensive](CVar_raidFramesCenterBigDefensive.md "CVar raidFramesCenterBigDefensive (page does not exist)")CVar: raidFramesCenterBigDefensive (Game)  
    Default: `1`, Scope: Character  
    Show big defensive raid buffs in the center of the unit frame
:   [raidFramesDispelIndicatorOverlay](CVar_raidFramesDispelIndicatorOverlay.md "CVar raidFramesDispelIndicatorOverlay (page does not exist)")CVar: raidFramesDispelIndicatorOverlay (Game)  
    Default: `1`, Scope: Character  
    When showing dispel indicators, also show a color gradient overlay
:   [raidFramesDispelIndicatorType](CVar_raidFramesDispelIndicatorType.md "CVar raidFramesDispelIndicatorType (page does not exist)")CVar: raidFramesDispelIndicatorType (Game)  
    Default: `2`, Scope: Character  
    Choose which dispel icon indicators to show in raid frames
:   [raidFramesDisplayLargerRoleSpecificDebuffs](CVar_raidFramesDisplayLargerRoleSpecificDebuffs.md "CVar raidFramesDisplayLargerRoleSpecificDebuffs (page does not exist)")CVar: raidFramesDisplayLargerRoleSpecificDebuffs (Game)  
    Default: `1`, Scope: Character  
    Show role-specific debuffs as larger on Raid Frames
:   [raidFramesHealthBarColor](CVar_raidFramesHealthBarColor.md "CVar raidFramesHealthBarColor (page does not exist)")CVar: raidFramesHealthBarColor (Game)  
    Default: `FF2B9305`, Scope: Character  
    Colors raid frames with a custom color if the user doesn't want class colors, ARGB format
:   [scriptWarnings](CVar_scriptWarnings.md "CVar scriptWarnings (page does not exist)")CVar: scriptWarnings (Debug)  
    Default: `0`, Scope: Account  
    Whether or not the UI shows Lua warnings
:   [secretChallengeModeRestrictionsForced](CVar_secretChallengeModeRestrictionsForced.md "CVar secretChallengeModeRestrictionsForced (page does not exist)")CVar: secretChallengeModeRestrictionsForced (Game)  
    Default: `0`  
    If set, APIs guarded by challenge mode and mythic plus restrictions will return secrets.
:   [secretCombatRestrictionsForced](CVar_secretCombatRestrictionsForced.md "CVar secretCombatRestrictionsForced (page does not exist)")CVar: secretCombatRestrictionsForced (Game)  
    Default: `0`  
    If set, APIs guarded by combat restrictions will return secrets.
:   [secretEncounterRestrictionsForced](CVar_secretEncounterRestrictionsForced.md "CVar secretEncounterRestrictionsForced (page does not exist)")CVar: secretEncounterRestrictionsForced (Game)  
    Default: `0`  
    If set, APIs guarded by instance encounter restrictions will return secrets.
:   [secretMapRestrictionsForced](CVar_secretMapRestrictionsForced.md "CVar secretMapRestrictionsForced (page does not exist)")CVar: secretMapRestrictionsForced (Game)  
    Default: `0`  
    If set, APIs guarded by map restrictions will return secrets.
:   [secretPvPMatchRestrictionsForced](CVar_secretPvPMatchRestrictionsForced.md "CVar secretPvPMatchRestrictionsForced (page does not exist)")CVar: secretPvPMatchRestrictionsForced (Game)  
    Default: `0`  
    If set, APIs guarded by PvP match restrictions will return secrets.
:   [showAllItemsInTransmog](CVar_showAllItemsInTransmog.md "CVar showAllItemsInTransmog (page does not exist)")CVar: showAllItemsInTransmog (Game)  
    Default: `0`  
    Shows all items in the transmogger regardless of armor restrictions
:   [showCustomSetDetails](CVar_showCustomSetDetails.md "CVar showCustomSetDetails (page does not exist)")CVar: showCustomSetDetails (Game)  
    Default: `1`, Scope: Character  
    Whether or not to show custom set details when the dressing room is opened in maximized mode, default on
:   [Sound\_EnableEncounterWarningsSounds](CVar_Sound_EnableEncounterWarningsSounds.md "CVar Sound EnableEncounterWarningsSounds (page does not exist)")CVar: Sound\_EnableEncounterWarningsSounds (Sound)  
    Default: `1`  
    Enable Encounter Warnings Sounds
:   [Sound\_EncounterWarningsVolume](CVar_Sound_EncounterWarningsVolume.md "CVar Sound EncounterWarningsVolume (page does not exist)")CVar: Sound\_EncounterWarningsVolume (Sound)  
    Default: `1.000000`  
    Encounter Warnings Volume (0.0 to 1.0)
:   [spellDiminishPVPEnemiesEnabled](CVar_spellDiminishPVPEnemiesEnabled.md "CVar spellDiminishPVPEnemiesEnabled (page does not exist)")CVar: spellDiminishPVPEnemiesEnabled (Game)  
    Default: `1`, Scope: Character  
    Determines if we should show crowd control diminishing returns on enemy unit frames in arenas
:   [spellDiminishPVPOnlyTriggerableByMe](CVar_spellDiminishPVPOnlyTriggerableByMe.md "CVar spellDiminishPVPOnlyTriggerableByMe (page does not exist)")CVar: spellDiminishPVPOnlyTriggerableByMe (Game)  
    Default: `0`, Scope: Character  
    Determines if we should show crowd control diminishing returns for all categories or only the ones you could cause with your spells
:   [trackedInitiativeTasks](CVar_trackedInitiativeTasks.md "CVar trackedInitiativeTasks (page does not exist)")CVar: trackedInitiativeTasks (Game)  
    Scope: Character  
    Internal cvar for saving tracked initiative tasks in order
:   [transmogHideIgnoredSlots](CVar_transmogHideIgnoredSlots.md "CVar transmogHideIgnoredSlots (page does not exist)")CVar: transmogHideIgnoredSlots (Game)  
    Default: `0`, Scope: Account  
    Whether ignored slots display as hidden or unassigned in the transmog frame
:   [transmogrifySetsFilters](CVar_transmogrifySetsFilters.md "CVar transmogrifySetsFilters (page does not exist)")CVar: transmogrifySetsFilters (Game)  
    Default: `0`, Scope: Account  
    Bitfield for which transmog sets filters are applied in the transmog sets tab
:   [useCompactPartyFrames](CVar_useCompactPartyFrames.md "CVar useCompactPartyFrames")CVar: useCompactPartyFrames
:   [WorldTextCritScreenY\_v2](CVar_WorldTextCritScreenY_v2.md "CVar WorldTextCritScreenY v2 (page does not exist)")CVar: WorldTextCritScreenY\_v2 (Game)  
    Default: `0.0275`
:   [WorldTextGravity\_v2](CVar_WorldTextGravity_v2.md "CVar WorldTextGravity v2 (page does not exist)")CVar: WorldTextGravity\_v2 (Game)  
    Default: `0.500000`
:   [WorldTextMinAlpha\_v2](CVar_WorldTextMinAlpha_v2.md "CVar WorldTextMinAlpha v2 (page does not exist)")CVar: WorldTextMinAlpha\_v2 (Game)  
    Default: `0.500000`
:   [WorldTextNonRandomZ\_v2](CVar_WorldTextNonRandomZ_v2.md "CVar WorldTextNonRandomZ v2 (page does not exist)")CVar: WorldTextNonRandomZ\_v2 (Game)  
    Default: `2.5`
:   [WorldTextRampDuration\_v2](CVar_WorldTextRampDuration_v2.md "CVar WorldTextRampDuration v2 (page does not exist)")CVar: WorldTextRampDuration\_v2 (Game)  
    Default: `1.000000`
:   [WorldTextRampPow\_v2](CVar_WorldTextRampPow_v2.md "CVar WorldTextRampPow v2 (page does not exist)")CVar: WorldTextRampPow\_v2 (Game)  
    Default: `1.900000`
:   [WorldTextRampPowCrit\_v2](CVar_WorldTextRampPowCrit_v2.md "CVar WorldTextRampPowCrit v2 (page does not exist)")CVar: WorldTextRampPowCrit\_v2 (Game)  
    Default: `8.000000`
:   [WorldTextRandomXY\_v2](CVar_WorldTextRandomXY_v2.md "CVar WorldTextRandomXY v2 (page does not exist)")CVar: WorldTextRandomXY\_v2 (Game)  
    Default: `0.0`
:   [WorldTextRandomZMax\_v2](CVar_WorldTextRandomZMax_v2.md "CVar WorldTextRandomZMax v2 (page does not exist)")CVar: WorldTextRandomZMax\_v2 (Game)  
    Default: `1.5`
:   [WorldTextRandomZMin\_v2](CVar_WorldTextRandomZMin_v2.md "CVar WorldTextRandomZMin v2 (page does not exist)")CVar: WorldTextRandomZMin\_v2 (Game)  
    Default: `0.8`
:   [WorldTextScale\_v2](CVar_WorldTextScale_v2.md "CVar WorldTextScale v2 (page does not exist)")CVar: WorldTextScale\_v2 (Game)  
    Default: `1.000000`
:   [WorldTextScreenY\_v2](CVar_WorldTextScreenY_v2.md "CVar WorldTextScreenY v2 (page does not exist)")CVar: WorldTextScreenY\_v2 (Game)  
    Default: `0.015`
:   [WorldTextStartPosRandomness\_v2](CVar_WorldTextStartPosRandomness_v2.md "CVar WorldTextStartPosRandomness v2 (page does not exist)")CVar: WorldTextStartPosRandomness\_v2 (Game)  
    Default: `1.0`

:   [advancedWatchFrame](CVar_advancedWatchFrame.md "CVar advancedWatchFrame")CVar: advancedWatchFrame (Game)  
    Default: `0`, Scope: Account  
    Enables advanced Objectives tracking features
:   [currencyTokensBackpack1](CVar_currencyTokensBackpack1.md "CVar currencyTokensBackpack1 (page does not exist)")CVar: currencyTokensBackpack1 (Game)  
    Default: `0`, Scope: Character  
    Currency token types shown on backpack.
:   [currencyTokensBackpack2](CVar_currencyTokensBackpack2.md "CVar currencyTokensBackpack2 (page does not exist)")CVar: currencyTokensBackpack2 (Game)  
    Default: `0`, Scope: Character  
    Currency token types shown on backpack.
:   [currencyTokensUnused1](CVar_currencyTokensUnused1.md "CVar currencyTokensUnused1 (page does not exist)")CVar: currencyTokensUnused1 (Game)  
    Default: `0`, Scope: Character  
    Currency token types marked as unused.
:   [currencyTokensUnused2](CVar_currencyTokensUnused2.md "CVar currencyTokensUnused2 (page does not exist)")CVar: currencyTokensUnused2 (Game)  
    Default: `0`, Scope: Character  
    Currency token types marked as unused.
:   [displayedRAFFriendInfo](CVar_displayedRAFFriendInfo.md "CVar displayedRAFFriendInfo (page does not exist)")CVar: displayedRAFFriendInfo (Game)  
    Default: `0`, Scope: Account  
    Stores whether we already told a recruited person about their new BattleTag friend
:   [enablePetBattleFloatingCombatText](CVar_enablePetBattleFloatingCombatText.md "CVar enablePetBattleFloatingCombatText (page does not exist)")CVar: enablePetBattleFloatingCombatText (Game)  
    Default: `1`, Scope: Account  
    Whether to show floating combat text for pet battles
:   [floatingCombatTextAllSpellMechanics](CVar_floatingCombatTextAllSpellMechanics.md "CVar floatingCombatTextAllSpellMechanics (page does not exist)")CVar: floatingCombatTextAllSpellMechanics (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextAuras](CVar_floatingCombatTextAuras.md "CVar floatingCombatTextAuras (page does not exist)")CVar: floatingCombatTextAuras (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextCombatDamageAllAutos](CVar_floatingCombatTextCombatDamageAllAutos.md "CVar floatingCombatTextCombatDamageAllAutos (page does not exist)")CVar: floatingCombatTextCombatDamageAllAutos (Game)  
    Default: `1`, Scope: Account  
    Show all auto-attack numbers, rather than hiding non-event numbers
:   [floatingCombatTextCombatDamageDirectionalOffset](CVar_floatingCombatTextCombatDamageDirectionalOffset.md "CVar floatingCombatTextCombatDamageDirectionalOffset (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalOffset (Game)  
    Default: `1`, Scope: Account  
    Amount to offset directional damage numbers when they start
:   [floatingCombatTextCombatDamageDirectionalScale](CVar_floatingCombatTextCombatDamageDirectionalScale.md "CVar floatingCombatTextCombatDamageDirectionalScale (page does not exist)")CVar: floatingCombatTextCombatDamageDirectionalScale (Game)  
    Default: `1`, Scope: Account  
    Directional damage numbers movement scale (0 = no directional numbers)
:   [floatingCombatTextCombatDamageStyle](CVar_floatingCombatTextCombatDamageStyle.md "CVar floatingCombatTextCombatDamageStyle (page does not exist)")CVar: floatingCombatTextCombatDamageStyle (Game)  
    Default: `1`, Scope: Account  
    No longer used
:   [floatingCombatTextCombatDamage](CVar_floatingCombatTextCombatDamage.md "CVar floatingCombatTextCombatDamage (page does not exist)")CVar: floatingCombatTextCombatDamage (Game)  
    Default: `1`, Scope: Account  
    Display damage numbers over hostile creatures when damaged
:   [floatingCombatTextCombatHealingAbsorbSelf](CVar_floatingCombatTextCombatHealingAbsorbSelf.md "CVar floatingCombatTextCombatHealingAbsorbSelf (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbSelf (Game)  
    Default: `1`, Scope: Account  
    Shows a message when you gain a shield.
:   [floatingCombatTextCombatHealingAbsorbTarget](CVar_floatingCombatTextCombatHealingAbsorbTarget.md "CVar floatingCombatTextCombatHealingAbsorbTarget (page does not exist)")CVar: floatingCombatTextCombatHealingAbsorbTarget (Game)  
    Default: `1`, Scope: Account  
    Display amount of shield added to the target.
:   [floatingCombatTextCombatHealing](CVar_floatingCombatTextCombatHealing.md "CVar floatingCombatTextCombatHealing (page does not exist)")CVar: floatingCombatTextCombatHealing (Game)  
    Default: `1`, Scope: Account  
    Display amount of healing you did to the target
:   [floatingCombatTextCombatLogPeriodicSpells](CVar_floatingCombatTextCombatLogPeriodicSpells.md "CVar floatingCombatTextCombatLogPeriodicSpells (page does not exist)")CVar: floatingCombatTextCombatLogPeriodicSpells (Game)  
    Default: `1`, Scope: Account  
    Display damage caused by periodic effects
:   [floatingCombatTextCombatState](CVar_floatingCombatTextCombatState.md "CVar floatingCombatTextCombatState (page does not exist)")CVar: floatingCombatTextCombatState (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextComboPoints](CVar_floatingCombatTextComboPoints.md "CVar floatingCombatTextComboPoints (page does not exist)")CVar: floatingCombatTextComboPoints (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextDamageReduction](CVar_floatingCombatTextDamageReduction.md "CVar floatingCombatTextDamageReduction (page does not exist)")CVar: floatingCombatTextDamageReduction (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextDodgeParryMiss](CVar_floatingCombatTextDodgeParryMiss.md "CVar floatingCombatTextDodgeParryMiss (page does not exist)")CVar: floatingCombatTextDodgeParryMiss (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextEnergyGains](CVar_floatingCombatTextEnergyGains.md "CVar floatingCombatTextEnergyGains (page does not exist)")CVar: floatingCombatTextEnergyGains (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextFloatMode](CVar_floatingCombatTextFloatMode.md "CVar floatingCombatTextFloatMode (page does not exist)")CVar: floatingCombatTextFloatMode (Game)  
    Default: `1`, Scope: Account  
    The combat text float mode
:   [floatingCombatTextFriendlyHealers](CVar_floatingCombatTextFriendlyHealers.md "CVar floatingCombatTextFriendlyHealers (page does not exist)")CVar: floatingCombatTextFriendlyHealers (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextHonorGains](CVar_floatingCombatTextHonorGains.md "CVar floatingCombatTextHonorGains (page does not exist)")CVar: floatingCombatTextHonorGains (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextLowManaHealth](CVar_floatingCombatTextLowManaHealth.md "CVar floatingCombatTextLowManaHealth (page does not exist)")CVar: floatingCombatTextLowManaHealth (Game)  
    Default: `1`, Scope: Account
:   [floatingCombatTextPeriodicEnergyGains](CVar_floatingCombatTextPeriodicEnergyGains.md "CVar floatingCombatTextPeriodicEnergyGains (page does not exist)")CVar: floatingCombatTextPeriodicEnergyGains (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextPetMeleeDamage](CVar_floatingCombatTextPetMeleeDamage.md "CVar floatingCombatTextPetMeleeDamage (page does not exist)")CVar: floatingCombatTextPetMeleeDamage (Game)  
    Default: `1`, Scope: Account  
    Display pet melee damage in the world
:   [floatingCombatTextPetSpellDamage](CVar_floatingCombatTextPetSpellDamage.md "CVar floatingCombatTextPetSpellDamage (page does not exist)")CVar: floatingCombatTextPetSpellDamage (Game)  
    Default: `1`, Scope: Account  
    Display pet spell damage in the world
:   [floatingCombatTextReactives](CVar_floatingCombatTextReactives.md "CVar floatingCombatTextReactives (page does not exist)")CVar: floatingCombatTextReactives (Game)  
    Default: `1`, Scope: Account
:   [floatingCombatTextRepChanges](CVar_floatingCombatTextRepChanges.md "CVar floatingCombatTextRepChanges (page does not exist)")CVar: floatingCombatTextRepChanges (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextSpellMechanicsOther](CVar_floatingCombatTextSpellMechanicsOther.md "CVar floatingCombatTextSpellMechanicsOther (page does not exist)")CVar: floatingCombatTextSpellMechanicsOther (Game)  
    Default: `0`, Scope: Account
:   [floatingCombatTextSpellMechanics](CVar_floatingCombatTextSpellMechanics.md "CVar floatingCombatTextSpellMechanics (page does not exist)")CVar: floatingCombatTextSpellMechanics (Game)  
    Default: `0`, Scope: Account
:   [ForceAllowAero](CVar_ForceAllowAero.md "CVar ForceAllowAero")CVar: ForceAllowAero (Graphics)  
    Default: `0`  
    Force Direct X 12 on Windows 7 to not disable Aero theme. You are opting into crashing in some edge cases
:   [friendsSmallView](CVar_friendsSmallView.md "CVar friendsSmallView")CVar: friendsSmallView (Game)  
    Default: `0`, Scope: Character  
    Whether to use smaller buttons in the friends list
:   [friendsViewButtons](CVar_friendsViewButtons.md "CVar friendsViewButtons")CVar: friendsViewButtons (Game)  
    Default: `0`, Scope: Character  
    Whether to show the friends list view buttons
:   [housingExpertGizmos\_Rotation\_BaseOrbScale](CVar_housingExpertGizmos_Rotation_BaseOrbScale.md "CVar housingExpertGizmos Rotation BaseOrbScale (page does not exist)")CVar: housingExpertGizmos\_Rotation\_BaseOrbScale (Game)  
    Default: `0.080000`  
    Base scale of the orb gizmos before multiplying in distance-based scale
:   [housingExpertGizmos\_Rotation\_BaseRingScale](CVar_housingExpertGizmos_Rotation_BaseRingScale.md "CVar housingExpertGizmos Rotation BaseRingScale (page does not exist)")CVar: housingExpertGizmos\_Rotation\_BaseRingScale (Game)  
    Default: `0.080000`  
    Base scale of the ring gizmos before multiplying in distance-based scale
:   [housingExpertGizmos\_Rotation\_DistScaleMax](CVar_housingExpertGizmos_Rotation_DistScaleMax.md "CVar housingExpertGizmos Rotation DistScaleMax (page does not exist)")CVar: housingExpertGizmos\_Rotation\_DistScaleMax (Game)  
    Default: `2.250000`  
    Amount of scale to multiply when we're >= ScaleDistanceMax
:   [housingExpertGizmos\_Rotation\_DistScaleMin](CVar_housingExpertGizmos_Rotation_DistScaleMin.md "CVar housingExpertGizmos Rotation DistScaleMin (page does not exist)")CVar: housingExpertGizmos\_Rotation\_DistScaleMin (Game)  
    Default: `1.000000`  
    Amount of scale to multiply when we're <= ScaleDistanceMin
:   [housingExpertGizmos\_Rotation\_HighlightDefault](CVar_housingExpertGizmos_Rotation_HighlightDefault.md "CVar housingExpertGizmos Rotation HighlightDefault (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightDefault (None)  
    Default: `0.800000`  
    Intensity of highlight when not hovered/selected/in use
:   [housingExpertGizmos\_Rotation\_HighlightDragging](CVar_housingExpertGizmos_Rotation_HighlightDragging.md "CVar housingExpertGizmos Rotation HighlightDragging (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightDragging (None)  
    Default: `1.000000`  
    Intensity of highlight when dragging
:   [housingExpertGizmos\_Rotation\_HighlightHovered](CVar_housingExpertGizmos_Rotation_HighlightHovered.md "CVar housingExpertGizmos Rotation HighlightHovered (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightHovered (None)  
    Default: `0.900000`  
    Intensity of highlight when hovered
:   [housingExpertGizmos\_Rotation\_HighlightKeybind](CVar_housingExpertGizmos_Rotation_HighlightKeybind.md "CVar housingExpertGizmos Rotation HighlightKeybind (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightKeybind (None)  
    Default: `1.000000`  
    Intensity of highlight when corresponding keybind being pressed
:   [housingExpertGizmos\_Rotation\_HighlightSelected](CVar_housingExpertGizmos_Rotation_HighlightSelected.md "CVar housingExpertGizmos Rotation HighlightSelected (page does not exist)")CVar: housingExpertGizmos\_Rotation\_HighlightSelected (None)  
    Default: `1.000000`  
    Intensity of highlight when selected
:   [housingExpertGizmos\_Rotation\_OrbPosOffset](CVar_housingExpertGizmos_Rotation_OrbPosOffset.md "CVar housingExpertGizmos Rotation OrbPosOffset (page does not exist)")CVar: housingExpertGizmos\_Rotation\_OrbPosOffset (Game)  
    Default: `-0.800000`  
    How much offset from the outer edge of the ring's radius the orb should be offset
:   [housingExpertGizmos\_Rotation\_ScaleDistanceMax](CVar_housingExpertGizmos_Rotation_ScaleDistanceMax.md "CVar housingExpertGizmos Rotation ScaleDistanceMax (page does not exist)")CVar: housingExpertGizmos\_Rotation\_ScaleDistanceMax (Game)  
    Default: `60.000000`  
    Distance at which we'll multiply control scale by DistScaleMax
:   [housingExpertGizmos\_Rotation\_ScaleDistanceMin](CVar_housingExpertGizmos_Rotation_ScaleDistanceMin.md "CVar housingExpertGizmos Rotation ScaleDistanceMin (page does not exist)")CVar: housingExpertGizmos\_Rotation\_ScaleDistanceMin (Game)  
    Default: `0.000000`  
    Distance at which we'll multiply control scale by DistScaleMin
:   [housingExpertGizmos\_Rotation\_SnapDegrees](CVar_housingExpertGizmos_Rotation_SnapDegrees.md "CVar housingExpertGizmos Rotation SnapDegrees (page does not exist)")CVar: housingExpertGizmos\_Rotation\_SnapDegrees (None)  
    Default: `15.000000`  
    Degrees rotation should snap
:   [housingExpertGizmos\_Rotation\_TextMode](CVar_housingExpertGizmos_Rotation_TextMode.md "CVar housingExpertGizmos Rotation TextMode (page does not exist)")CVar: housingExpertGizmos\_Rotation\_TextMode (None)  
    Default: `1`  
    1: curr angle 0-360, 2: curr angle up to -/+ 180, 3: curr delta 0-360, 4: curr delta up to -/+ 180
:   [housingExpertGizmos\_Rotation\_XRayCheckerSize](CVar_housingExpertGizmos_Rotation_XRayCheckerSize.md "CVar housingExpertGizmos Rotation XRayCheckerSize (page does not exist)")CVar: housingExpertGizmos\_Rotation\_XRayCheckerSize (Game)  
    Default: `7`  
    The size in pixels of the checker squares for obscured transform gizmos.
:   [housingExpertGizmos\_Rotation\_XRayDarkAlpha](CVar_housingExpertGizmos_Rotation_XRayDarkAlpha.md "CVar housingExpertGizmos Rotation XRayDarkAlpha (page does not exist)")CVar: housingExpertGizmos\_Rotation\_XRayDarkAlpha (Game)  
    Default: `0.100000`  
    The alpha of the dark square checker pattern for obscured transform gizmos.
:   [housingExpertGizmos\_Rotation\_XRayLightAlpha](CVar_housingExpertGizmos_Rotation_XRayLightAlpha.md "CVar housingExpertGizmos Rotation XRayLightAlpha (page does not exist)")CVar: housingExpertGizmos\_Rotation\_XRayLightAlpha (Game)  
    Default: `0.250000`  
    The alpha of the light square checker pattern for obscured transform gizmos.
:   [housingExpertGizmos\_Translation\_BaseArrowHeadScale](CVar_housingExpertGizmos_Translation_BaseArrowHeadScale.md "CVar housingExpertGizmos Translation BaseArrowHeadScale (page does not exist)")CVar: housingExpertGizmos\_Translation\_BaseArrowHeadScale (Game)  
    Default: `0.250000`  
    Base scale of the arrow head gizmos before multiplying in distance-based scale
:   [housingExpertGizmos\_Translation\_BaseArrowStemScale](CVar_housingExpertGizmos_Translation_BaseArrowStemScale.md "CVar housingExpertGizmos Translation BaseArrowStemScale (page does not exist)")CVar: housingExpertGizmos\_Translation\_BaseArrowStemScale (Game)  
    Default: `0.300000`  
    Base scale of the arrow stem gizmos before multiplying in distance-based scale
:   [housingExpertGizmos\_Translation\_BaseCubeScale](CVar_housingExpertGizmos_Translation_BaseCubeScale.md "CVar housingExpertGizmos Translation BaseCubeScale (page does not exist)")CVar: housingExpertGizmos\_Translation\_BaseCubeScale (Game)  
    Default: `0.050000`  
    Base scale of the center cube gizmo before multiplying in distance-based scale
:   [housingExpertGizmos\_Translation\_DistScaleMax](CVar_housingExpertGizmos_Translation_DistScaleMax.md "CVar housingExpertGizmos Translation DistScaleMax (page does not exist)")CVar: housingExpertGizmos\_Translation\_DistScaleMax (Game)  
    Default: `8.000000`  
    Amount of scale to multiply when we're >= ScaleDistanceMax
:   [housingExpertGizmos\_Translation\_DistScaleMin](CVar_housingExpertGizmos_Translation_DistScaleMin.md "CVar housingExpertGizmos Translation DistScaleMin (page does not exist)")CVar: housingExpertGizmos\_Translation\_DistScaleMin (Game)  
    Default: `1.000000`  
    Amount of scale to multiply when we're <= ScaleDistanceMin
:   [housingExpertGizmos\_Translation\_HighlightDefault](CVar_housingExpertGizmos_Translation_HighlightDefault.md "CVar housingExpertGizmos Translation HighlightDefault (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightDefault (Game)  
    Default: `0.800000`  
    Intensity of highlight when not hovered/selected/in use
:   [housingExpertGizmos\_Translation\_HighlightDragging](CVar_housingExpertGizmos_Translation_HighlightDragging.md "CVar housingExpertGizmos Translation HighlightDragging (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightDragging (Game)  
    Default: `1.000000`  
    Intensity of highlight when dragging
:   [housingExpertGizmos\_Translation\_HighlightHovered](CVar_housingExpertGizmos_Translation_HighlightHovered.md "CVar housingExpertGizmos Translation HighlightHovered (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightHovered (Game)  
    Default: `0.900000`  
    Intensity of highlight when hovered
:   [housingExpertGizmos\_Translation\_HighlightKeybind](CVar_housingExpertGizmos_Translation_HighlightKeybind.md "CVar housingExpertGizmos Translation HighlightKeybind (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightKeybind (Game)  
    Default: `1.000000`  
    Intensity of highlight when corresponding keybind being pressed
:   [housingExpertGizmos\_Translation\_HighlightSelected](CVar_housingExpertGizmos_Translation_HighlightSelected.md "CVar housingExpertGizmos Translation HighlightSelected (page does not exist)")CVar: housingExpertGizmos\_Translation\_HighlightSelected (Game)  
    Default: `1.000000`  
    Intensity of highlight when selected
:   [housingExpertGizmos\_Translation\_MaxDistanceFromCamera](CVar_housingExpertGizmos_Translation_MaxDistanceFromCamera.md "CVar housingExpertGizmos Translation MaxDistanceFromCamera (page does not exist)")CVar: housingExpertGizmos\_Translation\_MaxDistanceFromCamera (Game)  
    Default: `1000.000000`  
    Hard maximum distance from the camera, beyond which this control can no longer reasonably render or calculate translation
:   [housingExpertGizmos\_Translation\_Padding](CVar_housingExpertGizmos_Translation_Padding.md "CVar housingExpertGizmos Translation Padding (page does not exist)")CVar: housingExpertGizmos\_Translation\_Padding (Game)  
    Default: `0.050000`  
    Distance the arrows are offset from the center position
:   [housingExpertGizmos\_Translation\_ScaleDistanceMax](CVar_housingExpertGizmos_Translation_ScaleDistanceMax.md "CVar housingExpertGizmos Translation ScaleDistanceMax (page does not exist)")CVar: housingExpertGizmos\_Translation\_ScaleDistanceMax (Game)  
    Default: `60.000000`  
    Distance at which we'll multiply control scale by DistScaleMax
:   [housingExpertGizmos\_Translation\_ScaleDistanceMin](CVar_housingExpertGizmos_Translation_ScaleDistanceMin.md "CVar housingExpertGizmos Translation ScaleDistanceMin (page does not exist)")CVar: housingExpertGizmos\_Translation\_ScaleDistanceMin (Game)  
    Default: `0.000000`  
    Distance at which we'll multiply control scale by DistScaleMin
:   [housingExpertGizmos\_Translation\_XRayCheckerSize](CVar_housingExpertGizmos_Translation_XRayCheckerSize.md "CVar housingExpertGizmos Translation XRayCheckerSize (page does not exist)")CVar: housingExpertGizmos\_Translation\_XRayCheckerSize (Game)  
    Default: `7`  
    The size in pixels of the checker squares for obscured transform gizmos.
:   [housingExpertGizmos\_Translation\_XRayDarkAlpha](CVar_housingExpertGizmos_Translation_XRayDarkAlpha.md "CVar housingExpertGizmos Translation XRayDarkAlpha (page does not exist)")CVar: housingExpertGizmos\_Translation\_XRayDarkAlpha (Game)  
    Default: `0.600000`  
    The alpha of the dark square checker pattern for obscured transform gizmos.
:   [housingExpertGizmos\_Translation\_XRayLightAlpha](CVar_housingExpertGizmos_Translation_XRayLightAlpha.md "CVar housingExpertGizmos Translation XRayLightAlpha (page does not exist)")CVar: housingExpertGizmos\_Translation\_XRayLightAlpha (Game)  
    Default: `0.250000`  
    The alpha of the light square checker pattern for obscured transform gizmos.
:   [lastRenownForMajorFaction2503](CVar_lastRenownForMajorFaction2503.md "CVar lastRenownForMajorFaction2503 (page does not exist)")CVar: lastRenownForMajorFaction2503 (Game)  
    Default: `0`, Scope: Account  
    Stores the Maruuk Centaur renown when Renown UI is closed
:   [lastRenownForMajorFaction2507](CVar_lastRenownForMajorFaction2507.md "CVar lastRenownForMajorFaction2507 (page does not exist)")CVar: lastRenownForMajorFaction2507 (Game)  
    Default: `0`, Scope: Account  
    Stores the Dragonscale Expedition renown when Renown UI is closed
:   [lastRenownForMajorFaction2510](CVar_lastRenownForMajorFaction2510.md "CVar lastRenownForMajorFaction2510 (page does not exist)")CVar: lastRenownForMajorFaction2510 (Game)  
    Default: `0`, Scope: Account  
    Stores the Valdrakken Accord renown when Renown UI is closed
:   [lastRenownForMajorFaction2511](CVar_lastRenownForMajorFaction2511.md "CVar lastRenownForMajorFaction2511 (page does not exist)")CVar: lastRenownForMajorFaction2511 (Game)  
    Default: `0`, Scope: Account  
    Stores the Iskaara Tuskarr renown when Renown UI is closed
:   [lastRenownForMajorFaction2564](CVar_lastRenownForMajorFaction2564.md "CVar lastRenownForMajorFaction2564 (page does not exist)")CVar: lastRenownForMajorFaction2564 (Game)  
    Default: `0`, Scope: Account  
    Stores the Loamm Niffen renown when Renown UI is closed
:   [lastRenownForMajorFaction2570](CVar_lastRenownForMajorFaction2570.md "CVar lastRenownForMajorFaction2570 (page does not exist)")CVar: lastRenownForMajorFaction2570 (Game)  
    Default: `0`, Scope: Account  
    Stores the Hallowfall Arathi renown when Renown UI is closed
:   [lastRenownForMajorFaction2574](CVar_lastRenownForMajorFaction2574.md "CVar lastRenownForMajorFaction2574 (page does not exist)")CVar: lastRenownForMajorFaction2574 (Game)  
    Default: `0`, Scope: Account  
    Stores the Dream Warden renown when Renown UI is closed
:   [lastRenownForMajorFaction2590](CVar_lastRenownForMajorFaction2590.md "CVar lastRenownForMajorFaction2590 (page does not exist)")CVar: lastRenownForMajorFaction2590 (Game)  
    Default: `0`, Scope: Account  
    Stores the Council of Dornogal renown when Renown UI is closed
:   [lastRenownForMajorFaction2593](CVar_lastRenownForMajorFaction2593.md "CVar lastRenownForMajorFaction2593 (page does not exist)")CVar: lastRenownForMajorFaction2593 (Game)  
    Default: `0`, Scope: Account  
    Stores the Keg Leg's Crew renown when Renown UI is closed
:   [lastRenownForMajorFaction2594](CVar_lastRenownForMajorFaction2594.md "CVar lastRenownForMajorFaction2594 (page does not exist)")CVar: lastRenownForMajorFaction2594 (Game)  
    Default: `0`, Scope: Account  
    Stores the Assembly of the Deeps renown when Renown UI is closed
:   [lastRenownForMajorFaction2600](CVar_lastRenownForMajorFaction2600.md "CVar lastRenownForMajorFaction2600 (page does not exist)")CVar: lastRenownForMajorFaction2600 (Game)  
    Default: `0`, Scope: Account  
    Stores the Severed Threads renown when Renown UI is closed
:   [lastRenownForMajorFaction2653](CVar_lastRenownForMajorFaction2653.md "CVar lastRenownForMajorFaction2653 (page does not exist)")CVar: lastRenownForMajorFaction2653 (Game)  
    Default: `0`, Scope: Account  
    Stores the Cartels of Undermine Rewards renown when Renown UI is closed
:   [lastRenownForMajorFaction2658](CVar_lastRenownForMajorFaction2658.md "CVar lastRenownForMajorFaction2658 (page does not exist)")CVar: lastRenownForMajorFaction2658 (Game)  
    Default: `0`, Scope: Account  
    Stores the K'aresh Trust renown when Renown UI is closed
:   [lastRenownForMajorFaction2685](CVar_lastRenownForMajorFaction2685.md "CVar lastRenownForMajorFaction2685 (page does not exist)")CVar: lastRenownForMajorFaction2685 (Game)  
    Default: `0`, Scope: Account  
    Stores the Gallagio Loyatly Rewards renown when Renown UI is closed
:   [lastRenownForMajorFaction2688](CVar_lastRenownForMajorFaction2688.md "CVar lastRenownForMajorFaction2688 (page does not exist)")CVar: lastRenownForMajorFaction2688 (Game)  
    Default: `0`, Scope: Account  
    Stores the Flame's Radiance renown when Renown UI is closed
:   [lastRenownForMajorFaction2736](CVar_lastRenownForMajorFaction2736.md "CVar lastRenownForMajorFaction2736 (page does not exist)")CVar: lastRenownForMajorFaction2736 (Game)  
    Default: `0`, Scope: Account  
    Stores the Manaforge Vandals renown when Renown UI is closed
:   [lastTransmogOutfitIDSpec1](CVar_lastTransmogOutfitIDSpec1.md "CVar lastTransmogOutfitIDSpec1 (page does not exist)")CVar: lastTransmogOutfitIDSpec1 (Game)  
    Scope: Character  
    SetID of the last applied transmog outfit for the 1st spec
:   [lastTransmogOutfitIDSpec2](CVar_lastTransmogOutfitIDSpec2.md "CVar lastTransmogOutfitIDSpec2 (page does not exist)")CVar: lastTransmogOutfitIDSpec2 (Game)  
    Scope: Character  
    SetID of the last applied transmog outfit for the 2nd spec
:   [lastTransmogOutfitIDSpec3](CVar_lastTransmogOutfitIDSpec3.md "CVar lastTransmogOutfitIDSpec3 (page does not exist)")CVar: lastTransmogOutfitIDSpec3 (Game)  
    Scope: Character  
    SetID of the last applied transmog outfit for the 3rd spec
:   [lastTransmogOutfitIDSpec4](CVar_lastTransmogOutfitIDSpec4.md "CVar lastTransmogOutfitIDSpec4 (page does not exist)")CVar: lastTransmogOutfitIDSpec4 (Game)  
    Scope: Character  
    SetID of the last applied transmog outfit for the 4th spec
:   [lfgAutoFill](CVar_lfgAutoFill.md "CVar lfgAutoFill")CVar: lfgAutoFill (Game)  
    Default: `0`, Scope: Account  
    Whether to automatically add party members while looking for a group
:   [lfgAutoJoin](CVar_lfgAutoJoin.md "CVar lfgAutoJoin")CVar: lfgAutoJoin (Game)  
    Default: `0`, Scope: Account  
    Whether to automatically join a party while looking for a group
:   [lfGuildComment](CVar_lfGuildComment.md "CVar lfGuildComment")CVar: lfGuildComment (Game)  
    Scope: Character  
    Stores the player's Looking For Guild comment
:   [lfGuildSettings](CVar_lfGuildSettings.md "CVar lfGuildSettings (page does not exist)")CVar: lfGuildSettings (Game)  
    Default: `1`, Scope: Character  
    Bit field of Looking For Guild player settings
:   [mapAnimDuration](CVar_mapAnimDuration.md "CVar mapAnimDuration (page does not exist)")CVar: mapAnimDuration (Game)  
    Default: `0.12`, Scope: Account  
    Duration for the alpha animation
:   [mapAnimMinAlpha](CVar_mapAnimMinAlpha.md "CVar mapAnimMinAlpha (page does not exist)")CVar: mapAnimMinAlpha (Game)  
    Default: `0.35`, Scope: Account  
    Alpha value to animate to when player moves with windowed world map open
:   [mapAnimStartDelay](CVar_mapAnimStartDelay.md "CVar mapAnimStartDelay (page does not exist)")CVar: mapAnimStartDelay (Game)  
    Default: `0.0`, Scope: Account  
    Start delay for the alpha animation
:   [minimapAltitudeHintMode](CVar_minimapAltitudeHintMode.md "CVar minimapAltitudeHintMode (page does not exist)")CVar: minimapAltitudeHintMode (Game)  
    Default: `0`  
    Change minimap altitude difference display. 0=none, 1=darken, 2=arrows
:   [minimapShowArchBlobs](CVar_minimapShowArchBlobs.md "CVar minimapShowArchBlobs (page does not exist)")CVar: minimapShowArchBlobs (Game)  
    Default: `1`, Scope: Character  
    Stores whether to show the quest blobs on the minimap.
:   [minimapShowQuestBlobs](CVar_minimapShowQuestBlobs.md "CVar minimapShowQuestBlobs (page does not exist)")CVar: minimapShowQuestBlobs (Game)  
    Default: `1`, Scope: Character  
    Stores whether to show the quest blobs on the minimap.
:   [nameplateClassResourceTopInset](CVar_nameplateClassResourceTopInset.md "CVar nameplateClassResourceTopInset (page does not exist)")CVar: nameplateClassResourceTopInset (Graphics)  
    Default: `.03`, Scope: Character  
    The inset from the top (in screen percent) that nameplates are clamped to when class resources are being displayed on them.
:   [nameplateGlobalScale](CVar_nameplateGlobalScale.md "CVar nameplateGlobalScale (page does not exist)")CVar: nameplateGlobalScale (Graphics)  
    Default: `1.0`, Scope: Character  
    Applies global scaling to non-self nameplates, this is applied AFTER selected, min, and max scale.
:   [nameplateHideHealthAndPower](CVar_nameplateHideHealthAndPower.md "CVar nameplateHideHealthAndPower (page does not exist)")CVar: nameplateHideHealthAndPower (Game)  
    Default: `0`, Scope: Character
:   [nameplateLargeBottomInset](CVar_nameplateLargeBottomInset.md "CVar nameplateLargeBottomInset (page does not exist)")CVar: nameplateLargeBottomInset (Graphics)  
    Default: `0.15`, Scope: Character  
    The inset from the bottom (in screen percent) that large nameplates are clamped to.
:   [nameplateLargeTopInset](CVar_nameplateLargeTopInset.md "CVar nameplateLargeTopInset (page does not exist)")CVar: nameplateLargeTopInset (Graphics)  
    Default: `0.1`, Scope: Character  
    The inset from the top (in screen percent) that large nameplates are clamped to.
:   [NamePlateMaximumClassificationScale](CVar_NamePlateMaximumClassificationScale.md "CVar NamePlateMaximumClassificationScale (page does not exist)")CVar: NamePlateMaximumClassificationScale (Game)  
    Default: `1.25`, Scope: Character  
    This is the maximum effective scale of the classification icon for nameplates.
:   [nameplateMotionSpeed](CVar_nameplateMotionSpeed.md "CVar nameplateMotionSpeed (page does not exist)")CVar: nameplateMotionSpeed (Graphics)  
    Default: `0.025`, Scope: Character  
    Controls the rate at which nameplate animates into their target locations [0.0-1.0]
:   [nameplateMotion](CVar_nameplateMotion.md "CVar nameplateMotion")CVar: nameplateMotion (Graphics)  
    Default: `0`, Scope: Character  
    Defines the movement/collision model for nameplates
:   [NameplatePersonalClickThrough](CVar_NameplatePersonalClickThrough.md "CVar NameplatePersonalClickThrough (page does not exist)")CVar: NameplatePersonalClickThrough (Game)  
    Default: `1`, Scope: Character  
    When enabled, the personal nameplate is transparent to mouse clicks.
:   [NameplatePersonalHideDelayAlpha](CVar_NameplatePersonalHideDelayAlpha.md "CVar NameplatePersonalHideDelayAlpha (page does not exist)")CVar: NameplatePersonalHideDelayAlpha (Game)  
    Default: `0.45`, Scope: Character  
    Determines the alpha of the personal nameplate after no visibility conditions are met (during the period of time specified by NameplatePersonalHideDelaySeconds).
:   [NameplatePersonalHideDelaySeconds](CVar_NameplatePersonalHideDelaySeconds.md "CVar NameplatePersonalHideDelaySeconds (page does not exist)")CVar: NameplatePersonalHideDelaySeconds (Game)  
    Default: `3.0`, Scope: Character  
    Determines the length of time in seconds that the personal nameplate will be visible after no visibility conditions are met.
:   [NameplatePersonalShowAlways](CVar_NameplatePersonalShowAlways.md "CVar NameplatePersonalShowAlways (page does not exist)")CVar: NameplatePersonalShowAlways (Game)  
    Default: `0`, Scope: Character  
    Determines if the the personal nameplate is always shown.
:   [NameplatePersonalShowInCombat](CVar_NameplatePersonalShowInCombat.md "CVar NameplatePersonalShowInCombat (page does not exist)")CVar: NameplatePersonalShowInCombat (Game)  
    Default: `1`, Scope: Character  
    Determines if the the personal nameplate is shown when you enter combat.
:   [NameplatePersonalShowWithTarget](CVar_NameplatePersonalShowWithTarget.md "CVar NameplatePersonalShowWithTarget (page does not exist)")CVar: NameplatePersonalShowWithTarget (Game)  
    Default: `0`, Scope: Character  
    Determines if the personal nameplate is shown when selecting a target. 0 = targeting has no effect, 1 = show on hostile target, 2 = show on any target
:   [nameplateResourceOnTarget](CVar_nameplateResourceOnTarget.md "CVar nameplateResourceOnTarget (page does not exist)")CVar: nameplateResourceOnTarget (Game)  
    Default: `0`, Scope: Character  
    Nameplate class resource overlay mode. 0=self, 1=target
:   [nameplateSelfBottomInset](CVar_nameplateSelfBottomInset.md "CVar nameplateSelfBottomInset (page does not exist)")CVar: nameplateSelfBottomInset (Graphics)  
    Default: `0.2`, Scope: Character  
    The inset from the bottom (in screen percent) that the self nameplate is clamped to.
:   [nameplateSelfScale](CVar_nameplateSelfScale.md "CVar nameplateSelfScale (page does not exist)")CVar: nameplateSelfScale (Graphics)  
    Default: `1.0`, Scope: Character  
    The scale of the self nameplate.
:   [nameplateSelfTopInset](CVar_nameplateSelfTopInset.md "CVar nameplateSelfTopInset (page does not exist)")CVar: nameplateSelfTopInset (Graphics)  
    Default: `0.5`, Scope: Character  
    The inset from the top (in screen percent) that the self nameplate is clamped to.
:   [nameplateShowFriendlyBuffs](CVar_nameplateShowFriendlyBuffs.md "CVar nameplateShowFriendlyBuffs (page does not exist)")CVar: nameplateShowFriendlyBuffs (Game)  
    Default: `0`, Scope: Character
:   [nameplateShowFriendlyGuardians](CVar_nameplateShowFriendlyGuardians.md "CVar nameplateShowFriendlyGuardians (page does not exist)")CVar: nameplateShowFriendlyGuardians (Game)  
    Default: `0`, Scope: Character
:   [nameplateShowFriendlyMinions](CVar_nameplateShowFriendlyMinions.md "CVar nameplateShowFriendlyMinions (page does not exist)")CVar: nameplateShowFriendlyMinions (Game)  
    Default: `0`, Scope: Character
:   [nameplateShowFriendlyNPCs](CVar_nameplateShowFriendlyNPCs.md "CVar nameplateShowFriendlyNPCs (page does not exist)")CVar: nameplateShowFriendlyNPCs (Game)  
    Default: `0`, Scope: Character
:   [nameplateShowFriendlyPets](CVar_nameplateShowFriendlyPets.md "CVar nameplateShowFriendlyPets (page does not exist)")CVar: nameplateShowFriendlyPets (Game)  
    Default: `0`, Scope: Character
:   [nameplateShowFriendlyTotems](CVar_nameplateShowFriendlyTotems.md "CVar nameplateShowFriendlyTotems (page does not exist)")CVar: nameplateShowFriendlyTotems (Game)  
    Default: `0`, Scope: Character
:   [nameplateShowOnlyNames](CVar_nameplateShowOnlyNames.md "CVar nameplateShowOnlyNames (page does not exist)")CVar: nameplateShowOnlyNames (Game)  
    Default: `0`  
    Whether to hide the nameplate bars
:   [nameplateShowPersonalCooldowns](CVar_nameplateShowPersonalCooldowns.md "CVar nameplateShowPersonalCooldowns (page does not exist)")CVar: nameplateShowPersonalCooldowns (Game)  
    Default: `0`, Scope: Character  
    If set, personal buffs/debuffs will appear above the personal resource display
:   [removeChatDelay](CVar_removeChatDelay.md "CVar removeChatDelay (page does not exist)")CVar: removeChatDelay (Game)  
    Default: `0`, Scope: Account  
    Remove Chat Hover Delay
:   [ShowClassColorInFriendlyNameplate](CVar_ShowClassColorInFriendlyNameplate.md "CVar ShowClassColorInFriendlyNameplate (page does not exist)")CVar: ShowClassColorInFriendlyNameplate (Game)  
    Default: `1`, Scope: Character  
    use this to display the class color in friendly nameplate health bars
:   [ShowNamePlateLoseAggroFlash](CVar_ShowNamePlateLoseAggroFlash.md "CVar ShowNamePlateLoseAggroFlash (page does not exist)")CVar: ShowNamePlateLoseAggroFlash (Game)  
    Default: `1`, Scope: Character  
    When enabled, if you are a tank role and lose aggro, the nameplate with briefly flash.
:   [showQuestObjectivesOnMap](CVar_showQuestObjectivesOnMap.md "CVar showQuestObjectivesOnMap (page does not exist)")CVar: showQuestObjectivesOnMap (Game)  
    Default: `1`, Scope: Character  
    Shows quest POIs on the main map.
:   [showTokenFrameHonor](CVar_showTokenFrameHonor.md "CVar showTokenFrameHonor (page does not exist)")CVar: showTokenFrameHonor (Game)  
    Default: `0`, Scope: Character  
    The token UI has shown Honor
:   [splashScreenBoost](CVar_splashScreenBoost.md "CVar splashScreenBoost (page does not exist)")CVar: splashScreenBoost (Game)  
    Default: `0`, Scope: Character  
    Show boost splash screen id
:   [splashScreenSeason](CVar_splashScreenSeason.md "CVar splashScreenSeason (page does not exist)")CVar: splashScreenSeason (Game)  
    Default: `1`, Scope: Character  
    Show season splash screen id
:   [TerrainBlendBakeEnable](CVar_TerrainBlendBakeEnable.md "CVar TerrainBlendBakeEnable (page does not exist)")CVar: TerrainBlendBakeEnable (Graphics)  
    Default: `0`  
    Enable pre-blending terrain layers
:   [TerrainUnlitShaderEnable](CVar_TerrainUnlitShaderEnable.md "CVar TerrainUnlitShaderEnable (page does not exist)")CVar: TerrainUnlitShaderEnable (Graphics)  
    Default: `0`  
    Enable Unlit terrain shader
:   [trackQuestSorting](CVar_trackQuestSorting.md "CVar trackQuestSorting (page does not exist)")CVar: trackQuestSorting (Game)  
    Default: `top`, Scope: Account  
    Whether to sort the last tracked quest to the top of the quest tracker or use proximity sorting
:   [watchFrameBaseAlpha](CVar_watchFrameBaseAlpha.md "CVar watchFrameBaseAlpha (page does not exist)")CVar: watchFrameBaseAlpha (Game)  
    Default: `0`, Scope: Account  
    Objectives frame opacity.
:   [watchFrameIgnoreCursor](CVar_watchFrameIgnoreCursor.md "CVar watchFrameIgnoreCursor (page does not exist)")CVar: watchFrameIgnoreCursor (Game)  
    Default: `0`, Scope: Account  
    Disables Objectives frame mouseover and title dropdown.
:   [watchFrameState](CVar_watchFrameState.md "CVar watchFrameState (page does not exist)")CVar: watchFrameState (Game)  
    Default: `0`, Scope: Account  
    Stores Objectives frame locked and collapsed states
:   [WorldTextCritScreenY](CVar_WorldTextCritScreenY.md "CVar WorldTextCritScreenY (page does not exist)")CVar: WorldTextCritScreenY (Game)  
    Default: `0.0275`, Scope: Account
:   [WorldTextGravity](CVar_WorldTextGravity.md "CVar WorldTextGravity (page does not exist)")CVar: WorldTextGravity (Game)  
    Default: `0.5`, Scope: Account
:   [WorldTextMinAlpha](CVar_WorldTextMinAlpha.md "CVar WorldTextMinAlpha (page does not exist)")CVar: WorldTextMinAlpha (Game)  
    Default: `0.5`, Scope: Account
:   [WorldTextNonRandomZ](CVar_WorldTextNonRandomZ.md "CVar WorldTextNonRandomZ (page does not exist)")CVar: WorldTextNonRandomZ (Game)  
    Default: `2.5`, Scope: Account
:   [WorldTextRampDuration](CVar_WorldTextRampDuration.md "CVar WorldTextRampDuration (page does not exist)")CVar: WorldTextRampDuration (Game)  
    Default: `1.0`, Scope: Account
:   [WorldTextRampPowCrit](CVar_WorldTextRampPowCrit.md "CVar WorldTextRampPowCrit (page does not exist)")CVar: WorldTextRampPowCrit (Game)  
    Default: `8.0`, Scope: Account
:   [WorldTextRampPow](CVar_WorldTextRampPow.md "CVar WorldTextRampPow (page does not exist)")CVar: WorldTextRampPow (Game)  
    Default: `1.9`, Scope: Account
:   [WorldTextRandomXY](CVar_WorldTextRandomXY.md "CVar WorldTextRandomXY (page does not exist)")CVar: WorldTextRandomXY (Game)  
    Default: `0.0`, Scope: Account
:   [WorldTextRandomZMax](CVar_WorldTextRandomZMax.md "CVar WorldTextRandomZMax (page does not exist)")CVar: WorldTextRandomZMax (Game)  
    Default: `1.5`, Scope: Account
:   [WorldTextRandomZMin](CVar_WorldTextRandomZMin.md "CVar WorldTextRandomZMin (page does not exist)")CVar: WorldTextRandomZMin (Game)  
    Default: `0.8`, Scope: Account
:   [WorldTextScale](CVar_WorldTextScale.md "CVar WorldTextScale (page does not exist)")CVar: WorldTextScale (Game)  
    Default: `1.0`, Scope: Account
:   [WorldTextScreenY](CVar_WorldTextScreenY.md "CVar WorldTextScreenY (page does not exist)")CVar: WorldTextScreenY (Game)  
    Default: `0.015`, Scope: Account
:   [WorldTextStartPosRandomness](CVar_WorldTextStartPosRandomness.md "CVar WorldTextStartPosRandomness (page does not exist)")CVar: WorldTextStartPosRandomness (Game)  
    Default: `1.0`, Scope: Account

:   [GetSpellInfo](API_GetSpellInfo.md "API GetSpellInfo") → [C\_Spell.GetSpellInfo](API_C_Spell.GetSpellInfo.md "API C Spell.GetSpellInfo")
:   [GetNumSpellTabs](API_GetNumSpellTabs.md "API GetNumSpellTabs") → [C\_SpellBook.GetNumSpellBookSkillLines](API_C_SpellBook.GetNumSpellBookSkillLines.md "API C SpellBook.GetNumSpellBookSkillLines")
:   [GetSpellTabInfo](API_GetSpellTabInfo.md "API GetSpellTabInfo") → [C\_SpellBook.GetSpellBookSkillLineInfo](API_C_SpellBook.GetSpellBookSkillLineInfo.md "API C SpellBook.GetSpellBookSkillLineInfo")
:   [GetSpellCooldown](API_GetSpellCooldown.md "API GetSpellCooldown") → [C\_Spell.GetSpellCooldown](API_C_Spell.GetSpellCooldown.md "API C Spell.GetSpellCooldown")
:   [GetSpellBookItemName](API_GetSpellBookItemName.md "API GetSpellBookItemName") → [C\_SpellBook.GetSpellBookItemName](API_C_SpellBook.GetSpellBookItemName.md "API C SpellBook.GetSpellBookItemName")
:   [GetSpellTexture](API_GetSpellTexture.md "API GetSpellTexture") → [C\_Spell.GetSpellTexture](API_C_Spell.GetSpellTexture.md "API C Spell.GetSpellTexture")
:   [GetSpellCharges](API_GetSpellCharges.md "API GetSpellCharges") → [C\_Spell.GetSpellCharges](API_C_Spell.GetSpellCharges.md "API C Spell.GetSpellCharges")
:   [GetSpellDescription](API_GetSpellDescription.md "API GetSpellDescription") → [C\_Spell.GetSpellDescription](API_C_Spell.GetSpellDescription.md "API C Spell.GetSpellDescription")
:   [GetSpellCount](API_GetSpellCount.md "API GetSpellCount") → [C\_Spell.GetSpellCastCount](API_C_Spell.GetSpellCastCount.md "API C Spell.GetSpellCastCount")
:   [IsUsableSpell](API_IsUsableSpell.md "API IsUsableSpell") → [C\_Spell.IsSpellUsable](API_C_Spell.IsSpellUsable.md "API C Spell.IsSpellUsable")

:   [C\_TaskQuest.GetQuestsForPlayerByMapID](API_C_TaskQuest.GetQuestsForPlayerByMapID.md "API C TaskQuest.GetQuestsForPlayerByMapID") → [C\_TaskQuest.GetQuestsOnMap](API_C_TaskQuest.GetQuestsOnMap.md "API C TaskQuest.GetQuestsOnMap")
:   [GetMerchantItemInfo](API_GetMerchantItemInfo.md "API GetMerchantItemInfo") → [C\_MerchantFrame.GetItemInfo](API_C_MerchantFrame.GetItemInfo.md "API C MerchantFrame.GetItemInfo")
:   [C\_ChallengeMode.GetCompletionInfo](API_C_ChallengeMode.GetCompletionInfo.md "API C ChallengeMode.GetCompletionInfo") → [C\_ChallengeMode.GetChallengeCompletionInfo](API_C_ChallengeMode.GetChallengeCompletionInfo.md "API C ChallengeMode.GetChallengeCompletionInfo")
:   [C\_MythicPlus.IsWeeklyRewardAvailable](API_C_MythicPlus.IsWeeklyRewardAvailable.md "API C MythicPlus.IsWeeklyRewardAvailable")

:   [IsActiveQuestLegendary](API_IsActiveQuestLegendary.md "API IsActiveQuestLegendary (page does not exist)") → [C\_QuestInfoSystem.GetQuestClassification](API_C_QuestInfoSystem.GetQuestClassification.md "API C QuestInfoSystem.GetQuestClassification")
:   [C\_QuestLog.IsLegendaryQuest](API_C_QuestLog.IsLegendaryQuest.md "API C QuestLog.IsLegendaryQuest") → [C\_QuestInfoSystem.GetQuestClassification](API_C_QuestInfoSystem.GetQuestClassification.md "API C QuestInfoSystem.GetQuestClassification")
:   [C\_QuestLog.IsQuestRepeatableType](API_C_QuestLog.IsQuestRepeatableType.md "API C QuestLog.IsQuestRepeatableType") → [C\_QuestLog.IsRepeatableQuest](API_C_QuestLog.IsRepeatableQuest.md "API C QuestLog.IsRepeatableQuest")

:   [ConsolePrint](API_ConsolePrint.md "API ConsolePrint (page does not exist)") → [C\_Log.LogMessage](API_C_Log.LogMessage.md "API C Log.LogMessage")
:   [message](API_message.md "API message") → [SetBasicMessageDialogText](API_SetBasicMessageDialogText.md "API SetBasicMessageDialogText (page does not exist)")

:   [IsSpellOverlayed](API_IsSpellOverlayed.md "API IsSpellOverlayed") → [C\_SpellActivationOverlay.IsSpellOverlayed](API_C_SpellActivationOverlay.IsSpellOverlayed.md "API C SpellActivationOverlay.IsSpellOverlayed")

:   [IsArtifactRelicItem](API_IsArtifactRelicItem.md "API IsArtifactRelicItem (page does not exist)") → [C\_ItemSocketInfo.IsArtifactRelicItem](API_C_ItemSocketInfo.IsArtifactRelicItem.md "API C ItemSocketInfo.IsArtifactRelicItem")

API changes have been introduced with an aim to limit the ability for addons to perform complex logic and decision making based off combat information.

The changes are not intended to prevent "look and feel" customization of UI elements. As part of this, Blizzard have avoided outright restricting many APIs and moving frames into the secure environment but instead have introduced new technology termed as Secret Values.

These API functions were deprecated in the 11.x patches from the previous expansion and have been removed.