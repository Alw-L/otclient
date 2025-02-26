/*
* Copyright (c) 2010-2020 OTClient <https://github.com/edubart/otclient>
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

#include "protocolgame.h"

#include <framework/core/eventdispatcher.h>
#include "effect.h"
#include "game.h"
#include "item.h"
#include "localplayer.h"
#include "luavaluecasts.h"
#include "map.h"
#include "missile.h"
#include "statictext.h"
#include "thingtypemanager.h"
#include "tile.h"
#include "framework/net/inputmessage.h"

void ProtocolGame::parseMessage(const InputMessagePtr& msg)
{
    int opcode = -1;
    int prevOpcode = -1;

    try {
        while(!msg->eof()) {
            opcode = msg->getU8();

            // must be > so extended will be enabled before GameStart.
            if(!g_game.getFeature(Otc::GameLoginPending)) {
                if(!m_gameInitialized && opcode > Proto::GameServerFirstGameOpcode) {
                    g_game.processGameStart();
                    m_gameInitialized = true;
                }
            }

            // try to parse in lua first
            const int readPos = msg->getReadPos();
            if(callLuaField<bool>("onOpcode", opcode, msg))
                continue;
            msg->setReadPos(readPos);
            // restore read pos

            switch(opcode) {
            case Proto::GameServerLoginOrPendingState:
                if(g_game.getFeature(Otc::GameLoginPending))
                    parsePendingGame(msg);
                else
                    parseLogin(msg);
                break;
            case Proto::GameServerGMActions:
                parseGMActions(msg);
                break;
            case Proto::GameServerUpdateNeeded:
                parseUpdateNeeded(msg);
                break;
            case Proto::GameServerLoginError:
                parseLoginError(msg);
                break;
            case Proto::GameServerLoginAdvice:
                parseLoginAdvice(msg);
                break;
            case Proto::GameServerLoginWait:
                parseLoginWait(msg);
                break;
            case Proto::GameServerLoginToken:
                parseLoginToken(msg);
                break;
            case Proto::GameServerPing:
            case Proto::GameServerPingBack:
                if(((opcode == Proto::GameServerPing) && (g_game.getFeature(Otc::GameClientPing))) ||
                   ((opcode == Proto::GameServerPingBack) && !g_game.getFeature(Otc::GameClientPing)))
                    parsePingBack(msg);
                else
                    parsePing(msg);
                break;
            case Proto::GameServerChallenge:
                parseChallenge(msg);
                break;
            case Proto::GameServerDeath:
                parseDeath(msg);
                break;
            case Proto::GameServerFullMap:
                parseMapDescription(msg);
                break;
            case Proto::GameServerMapTopRow:
                parseMapMoveNorth(msg);
                break;
            case Proto::GameServerMapRightRow:
                parseMapMoveEast(msg);
                break;
            case Proto::GameServerMapBottomRow:
                parseMapMoveSouth(msg);
                break;
            case Proto::GameServerMapLeftRow:
                parseMapMoveWest(msg);
                break;
            case Proto::GameServerUpdateTile:
                parseUpdateTile(msg);
                break;
            case Proto::GameServerCreateOnMap:
                parseTileAddThing(msg);
                break;
            case Proto::GameServerChangeOnMap:
                parseTileTransformThing(msg);
                break;
            case Proto::GameServerDeleteOnMap:
                parseTileRemoveThing(msg);
                break;
            case Proto::GameServerMoveCreature:
                parseCreatureMove(msg);
                break;
            case Proto::GameServerOpenContainer:
                parseOpenContainer(msg);
                break;
            case Proto::GameServerCloseContainer:
                parseCloseContainer(msg);
                break;
            case Proto::GameServerCreateContainer:
                parseContainerAddItem(msg);
                break;
            case Proto::GameServerChangeInContainer:
                parseContainerUpdateItem(msg);
                break;
            case Proto::GameServerDeleteInContainer:
                parseContainerRemoveItem(msg);
                break;
            case Proto::GameServerSetInventory:
                parseAddInventoryItem(msg);
                break;
            case Proto::GameServerDeleteInventory:
                parseRemoveInventoryItem(msg);
                break;
            case Proto::GameServerOpenNpcTrade:
                parseOpenNpcTrade(msg);
                break;
            case Proto::GameServerPlayerGoods:
                parsePlayerGoods(msg);
                break;
            case Proto::GameServerCloseNpcTrade:
                parseCloseNpcTrade(msg);
                break;
            case Proto::GameServerOwnTrade:
                parseOwnTrade(msg);
                break;
            case Proto::GameServerCounterTrade:
                parseCounterTrade(msg);
                break;
            case Proto::GameServerCloseTrade:
                parseCloseTrade(msg);
                break;
            case Proto::GameServerAmbient:
                parseWorldLight(msg);
                break;
            case Proto::GameServerGraphicalEffect:
                parseMagicEffect(msg);
                break;
            case Proto::GameServerTextEffect:
                parseAnimatedText(msg);
                break;
            case Proto::GameServerMissleEffect:
                parseDistanceMissile(msg);
                break;
            case Proto::GameServerMarkCreature:
                parseCreatureMark(msg);
                break;
            case Proto::GameServerTrappers:
                parseTrappers(msg);
                break;
            case Proto::GameServerCreatureHealth:
                parseCreatureHealth(msg);
                break;
            case Proto::GameServerCreatureLight:
                parseCreatureLight(msg);
                break;
            case Proto::GameServerCreatureOutfit:
                parseCreatureOutfit(msg);
                break;
            case Proto::GameServerCreatureSpeed:
                parseCreatureSpeed(msg);
                break;
            case Proto::GameServerCreatureSkull:
                parseCreatureSkulls(msg);
                break;
            case Proto::GameServerCreatureParty:
                parseCreatureShields(msg);
                break;
            case Proto::GameServerCreatureUnpass:
                parseCreatureUnpass(msg);
                break;
            case Proto::GameServerEditText:
                parseEditText(msg);
                break;
            case Proto::GameServerEditList:
                parseEditList(msg);
                break;
                // PROTOCOL>=1038
            case Proto::GameServerPremiumTrigger:
                parsePremiumTrigger(msg);
                break;
            case Proto::GameServerPlayerData:
                parsePlayerStats(msg);
                break;
            case Proto::GameServerPlayerSkills:
                parsePlayerSkills(msg);
                break;
            case Proto::GameServerPlayerState:
                parsePlayerState(msg);
                break;
            case Proto::GameServerClearTarget:
                parsePlayerCancelAttack(msg);
                break;
            case Proto::GameServerPlayerModes:
                parsePlayerModes(msg);
                break;
            case Proto::GameServerTalk:
                parseTalk(msg);
                break;
            case Proto::GameServerChannels:
                parseChannelList(msg);
                break;
            case Proto::GameServerOpenChannel:
                parseOpenChannel(msg);
                break;
            case Proto::GameServerOpenPrivateChannel:
                parseOpenPrivateChannel(msg);
                break;
            case Proto::GameServerRuleViolationChannel:
                parseRuleViolationChannel(msg);
                break;
            case Proto::GameServerRuleViolationRemove:
                parseRuleViolationRemove(msg);
                break;
            case Proto::GameServerRuleViolationCancel:
                parseRuleViolationCancel(msg);
                break;
            case Proto::GameServerRuleViolationLock:
                parseRuleViolationLock(msg);
                break;
            case Proto::GameServerOpenOwnChannel:
                parseOpenOwnPrivateChannel(msg);
                break;
            case Proto::GameServerCloseChannel:
                parseCloseChannel(msg);
                break;
            case Proto::GameServerTextMessage:
                parseTextMessage(msg);
                break;
            case Proto::GameServerCancelWalk:
                parseCancelWalk(msg);
                break;
            case Proto::GameServerWalkWait:
                parseWalkWait(msg);
                break;
            case Proto::GameServerFloorChangeUp:
                parseFloorChangeUp(msg);
                break;
            case Proto::GameServerFloorChangeDown:
                parseFloorChangeDown(msg);
                break;
            case Proto::GameServerChooseOutfit:
                parseOpenOutfitWindow(msg);
                break;
            case Proto::GameServerVipAdd:
                parseVipAdd(msg);
                break;
            case Proto::GameServerVipState:
                parseVipState(msg);
                break;
            case Proto::GameServerVipLogout:
                parseVipLogout(msg);
                break;
            case Proto::GameServerTutorialHint:
                parseTutorialHint(msg);
                break;
            case Proto::GameServerAutomapFlag:
                parseAutomapFlag(msg);
                break;
            case Proto::GameServerQuestLog:
                parseQuestLog(msg);
                break;
            case Proto::GameServerQuestLine:
                parseQuestLine(msg);
                break;
                // PROTOCOL>=870
            case Proto::GameServerSpellDelay:
                parseSpellCooldown(msg);
                break;
            case Proto::GameServerSpellGroupDelay:
                parseSpellGroupCooldown(msg);
                break;
            case Proto::GameServerMultiUseDelay:
                parseMultiUseCooldown(msg);
                break;
                // PROTOCOL>=910
            case Proto::GameServerChannelEvent:
                parseChannelEvent(msg);
                break;
            case Proto::GameServerItemInfo:
                parseItemInfo(msg);
                break;
            case Proto::GameServerPlayerInventory:
                parsePlayerInventory(msg);
                break;
                // PROTOCOL>=950
            case Proto::GameServerPlayerDataBasic:
                parsePlayerInfo(msg);
                break;
                // PROTOCOL>=970
            case Proto::GameServerModalDialog:
                parseModalDialog(msg);
                break;
                // PROTOCOL>=980
            case Proto::GameServerLoginSuccess:
                parseLogin(msg);
                break;
            case Proto::GameServerEnterGame:
                parseEnterGame(msg);
                break;
            case Proto::GameServerPlayerHelpers:
                parsePlayerHelpers(msg);
                break;
                // PROTOCOL>=1000
            case Proto::GameServerCreatureMarks:
                parseCreaturesMark(msg);
                break;
            case Proto::GameServerCreatureType:
                parseCreatureType(msg);
                break;
                // PROTOCOL>=1055
            case Proto::GameServerBlessings:
                parseBlessings(msg);
                break;
            case Proto::GameServerUnjustifiedStats:
                parseUnjustifiedStats(msg);
                break;
            case Proto::GameServerPvpSituations:
                parsePvpSituations(msg);
                break;
            case Proto::GameServerPreset:
                parsePreset(msg);
                break;
                // PROTOCOL>=1080
            case Proto::GameServerCoinBalanceUpdating:
                parseCoinBalanceUpdating(msg);
                break;
            case Proto::GameServerCoinBalance:
                parseCoinBalance(msg);
                break;
            case Proto::GameServerRequestPurchaseData:
                parseRequestPurchaseData(msg);
                break;
            case Proto::GameServerStoreCompletePurchase:
                parseCompleteStorePurchase(msg);
                break;
            case Proto::GameServerStoreOffers:
                parseStoreOffers(msg);
                break;
            case Proto::GameServerStoreTransactionHistory:
                parseStoreTransactionHistory(msg);
                break;
            case Proto::GameServerStoreError:
                parseStoreError(msg);
                break;
            case Proto::GameServerStore:
                parseStore(msg);
                break;
                // PROTOCOL>=1097
            case Proto::GameServerStoreButtonIndicators:
                parseStoreButtonIndicators(msg);
                break;
            case Proto::GameServerSetStoreDeepLink:
                parseSetStoreDeepLink(msg);
                break;
                // otclient ONLY
            case Proto::GameServerExtendedOpcode:
                parseExtendedOpcode(msg);
                break;
            case Proto::GameServerChangeMapAwareRange:
                parseChangeMapAwareRange(msg);
                break;
            default:
                stdext::throw_exception(stdext::format("unhandled opcode %d", static_cast<int>(opcode)));
                break;
            }
            prevOpcode = opcode;
        }
    } catch(stdext::exception& e) {
        g_logger.error(stdext::format("ProtocolGame parse message exception (%d bytes unread, last opcode is %d, prev opcode is %d): %s",
                                      msg->getUnreadSize(), opcode, prevOpcode, e.what()));
    }
}

void ProtocolGame::parseLogin(const InputMessagePtr& msg)
{
    const uint playerId = msg->getU32();
    const int serverBeat = msg->getU16();

    if(g_game.getFeature(Otc::GameNewSpeedLaw)) {
        Creature::speedA = msg->getDouble();
        Creature::speedB = msg->getDouble();
        Creature::speedC = msg->getDouble();
    }

    const bool canReportBugs = msg->getU8();

    if(g_game.getClientVersion() >= 1054)
        msg->getU8(); // can change pvp frame option

    if(g_game.getClientVersion() >= 1058) {
        const int expertModeEnabled = msg->getU8();
        g_game.setExpertPvpMode(expertModeEnabled);
    }

    if(g_game.getFeature(Otc::GameIngameStore)) {
        // URL to ingame store images
        msg->getString();

        // premium coin package size
        // e.g you can only buy packs of 25, 50, 75, .. coins in the market
        msg->getU16();
    }

    m_localPlayer->setId(playerId);
    g_game.setServerBeat(serverBeat);
    g_game.setCanReportBugs(canReportBugs);

    g_game.processLogin();
}

void ProtocolGame::parsePendingGame(const InputMessagePtr&)
{
    //set player to pending game state
    g_game.processPendingGame();
}

void ProtocolGame::parseEnterGame(const InputMessagePtr&)
{
    //set player to entered game state
    g_game.processEnterGame();

    if(!m_gameInitialized) {
        g_game.processGameStart();
        m_gameInitialized = true;
    }
}

void ProtocolGame::parseStoreButtonIndicators(const InputMessagePtr& msg)
{
    msg->getU8(); // unknown
    msg->getU8(); // unknown
}

void ProtocolGame::parseSetStoreDeepLink(const InputMessagePtr& msg)
{
    msg->getU8(); // currentlyFeaturedServiceType
}

void ProtocolGame::parseBlessings(const InputMessagePtr& msg)
{
    const uint16 blessings = msg->getU16();
    m_localPlayer->setBlessings(blessings);
}

void ProtocolGame::parsePreset(const InputMessagePtr& msg)
{
    msg->getU32(); // preset
}

void ProtocolGame::parseRequestPurchaseData(const InputMessagePtr& msg)
{
    msg->getU32(); // transactionId
    msg->getU8(); // productType
}

void ProtocolGame::parseStore(const InputMessagePtr& msg)
{
    parseCoinBalance(msg);

    const int categories = msg->getU16();
    for(int i = 0; i < categories; ++i) {
        std::string category = msg->getString();
        std::string description = msg->getString();

        if(g_game.getFeature(Otc::GameIngameStoreHighlights))
            msg->getU8(); // highlightState

        std::vector<std::string> icons;
        const int iconCount = msg->getU8();
        for(int j = 0; j < iconCount; ++j) {
            std::string icon = msg->getString();
            icons.push_back(icon);
        }

        // If this is a valid category name then
        // the category we just parsed is a child of that
        msg->getString();
    }
}

void ProtocolGame::parseCoinBalance(const InputMessagePtr& msg)
{
    const bool update = msg->getU8() == 1;
    if(update) {
        // amount of coins that can be used to buy prodcuts
        // in the ingame store
        msg->getU32(); // coins

        // amount of coins that can be sold in market
        // or be transfered to another player
        msg->getU32(); // transferableCoins
    }
}

void ProtocolGame::parseCoinBalanceUpdating(const InputMessagePtr& msg)
{
    // coin balance can be updating and might not be accurate
    msg->getU8(); // == 1; // isUpdating
}

void ProtocolGame::parseCompleteStorePurchase(const InputMessagePtr& msg)
{
    // not used
    msg->getU8();

    const std::string message = msg->getString();
    const int coins = msg->getU32();
    const int transferableCoins = msg->getU32();

    g_logger.info(stdext::format("Purchase Complete: %s\nAvailable coins: %d (transferable: %d)", message, coins, transferableCoins));
}

void ProtocolGame::parseStoreTransactionHistory(const InputMessagePtr& msg)
{
    int currentPage;
    if(g_game.getClientVersion() <= 1096) {
        currentPage = msg->getU16();
        msg->getU8(); // hasNextPage (bool)
    } else {
        currentPage = msg->getU32();
        msg->getU32(); // pageCount
    }

    const int entries = msg->getU8();
    for(int i = 0; i < entries; ++i) {
        int time = msg->getU16();
        int productType = msg->getU8();
        int coinChange = msg->getU32();
        std::string productName = msg->getString();
        g_logger.error(stdext::format("Time %i, type %i, change %i, product name %s", time, productType, coinChange, productName));
    }
}

void ProtocolGame::parseStoreOffers(const InputMessagePtr& msg)
{
    msg->getString(); // categoryName

    const int offers = msg->getU16();
    for(int i = 0; i < offers; ++i) {
        msg->getU32(); // offerId
        msg->getString(); // offerName
        msg->getString(); // offerDescription

        msg->getU32(); // price
        const int highlightState = msg->getU8();
        if(highlightState == 2 && g_game.getFeature(Otc::GameIngameStoreHighlights) && g_game.getClientVersion() >= 1097) {
            msg->getU32(); // saleValidUntilTimestamp
            msg->getU32(); // basePrice
        }

        const int disabledState = msg->getU8();
        if(g_game.getFeature(Otc::GameIngameStoreHighlights) && disabledState == 1) {
            msg->getString(); // disabledReason
        }

        std::vector<std::string> icons;
        const int iconCount = msg->getU8();
        for(int j = 0; j < iconCount; ++j) {
            std::string icon = msg->getString();
            icons.push_back(icon);
        }

        const int subOffers = msg->getU16();
        for(int j = 0; j < subOffers; ++j) {
            msg->getString(); // name
            msg->getString(); // description

            const int subIcons = msg->getU8();
            for(int k = 0; k < subIcons; k++) {
                msg->getString(); // icon
            }
            msg->getString(); // serviceType
        }
    }
}

void ProtocolGame::parseStoreError(const InputMessagePtr& msg)
{
    const int errorType = msg->getU8();
    const std::string message = msg->getString();
    g_logger.error(stdext::format("Store Error: %s [%i]", message, errorType));
}

void ProtocolGame::parseUnjustifiedStats(const InputMessagePtr& msg)
{
    UnjustifiedPoints unjustifiedPoints;
    unjustifiedPoints.killsDay = msg->getU8();
    unjustifiedPoints.killsDayRemaining = msg->getU8();
    unjustifiedPoints.killsWeek = msg->getU8();
    unjustifiedPoints.killsWeekRemaining = msg->getU8();
    unjustifiedPoints.killsMonth = msg->getU8();
    unjustifiedPoints.killsMonthRemaining = msg->getU8();
    unjustifiedPoints.skullTime = msg->getU8();

    g_game.setUnjustifiedPoints(unjustifiedPoints);
}

void ProtocolGame::parsePvpSituations(const InputMessagePtr& msg)
{
    const uint8 openPvpSituations = msg->getU8();

    g_game.setOpenPvpSituations(openPvpSituations);
}

void ProtocolGame::parsePlayerHelpers(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const int helpers = msg->getU16();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(creature)
        g_game.processPlayerHelpers(helpers);
    else
        g_logger.traceError(stdext::format("could not get creature with id %d", id));
}

void ProtocolGame::parseGMActions(const InputMessagePtr& msg)
{
    std::vector<uint8> actions;

    int numViolationReasons;

    if(g_game.getClientVersion() >= 850)
        numViolationReasons = 20;
    else if(g_game.getClientVersion() >= 840)
        numViolationReasons = 23;
    else
        numViolationReasons = 32;

    for(int i = 0; i < numViolationReasons; ++i)
        actions.push_back(msg->getU8());
    g_game.processGMActions(actions);
}

void ProtocolGame::parseUpdateNeeded(const InputMessagePtr& msg)
{
    const std::string signature = msg->getString();
    g_game.processUpdateNeeded(signature);
}

void ProtocolGame::parseLoginError(const InputMessagePtr& msg)
{
    const std::string error = msg->getString();

    g_game.processLoginError(error);
}

void ProtocolGame::parseLoginAdvice(const InputMessagePtr& msg)
{
    const std::string message = msg->getString();

    g_game.processLoginAdvice(message);
}

void ProtocolGame::parseLoginWait(const InputMessagePtr& msg)
{
    const std::string message = msg->getString();
    const int time = msg->getU8();

    g_game.processLoginWait(message, time);
}

void ProtocolGame::parseLoginToken(const InputMessagePtr& msg)
{
    const bool unknown = msg->getU8() == 0;
    g_game.processLoginToken(unknown);
}

void ProtocolGame::parsePing(const InputMessagePtr& msg)
{
    const int ping = msg->getU8();
    g_game.processPing(ping);
}

void ProtocolGame::parsePingBack(const InputMessagePtr&)
{
    g_game.processPingBack();
}

void ProtocolGame::parseChallenge(const InputMessagePtr& msg)
{
    const uint timestamp = msg->getU32();
    const uint8 random = msg->getU8();

    sendLoginPacket(timestamp, random);
}

void ProtocolGame::parseDeath(const InputMessagePtr& msg)
{
    int penality = 100;
    int deathType = Otc::DeathRegular;

    if(g_game.getFeature(Otc::GameDeathType))
        deathType = msg->getU8();

    if(g_game.getFeature(Otc::GamePenalityOnDeath) && deathType == Otc::DeathRegular)
        penality = msg->getU8();

    g_game.processDeath(deathType, penality);
}

void ProtocolGame::parseMapDescription(const InputMessagePtr& msg)
{
    const Position pos = getPosition(msg);

    if(!m_mapKnown)
        m_localPlayer->setPosition(pos);

    g_map.setCentralPosition(pos);

    AwareRange range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, range.horizontal(), range.vertical());

    if(!m_mapKnown) {
        g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapKnown"); });
        m_mapKnown = true;
    }

    g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapDescription"); });
}

void ProtocolGame::parseMapMoveNorth(const InputMessagePtr& msg)
{
    Position pos;
    if(g_game.getFeature(Otc::GameMapMovePosition))
        pos = getPosition(msg);
    else
        pos = g_map.getCentralPosition();
    --pos.y;

    AwareRange range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, range.horizontal(), 1);
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseMapMoveEast(const InputMessagePtr& msg)
{
    Position pos;
    if(g_game.getFeature(Otc::GameMapMovePosition))
        pos = getPosition(msg);
    else
        pos = g_map.getCentralPosition();
    ++pos.x;

    AwareRange range = g_map.getAwareRange();
    setMapDescription(msg, pos.x + range.right, pos.y - range.top, pos.z, 1, range.vertical());
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseMapMoveSouth(const InputMessagePtr& msg)
{
    Position pos;
    if(g_game.getFeature(Otc::GameMapMovePosition))
        pos = getPosition(msg);
    else
        pos = g_map.getCentralPosition();

    ++pos.y;

    AwareRange range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y + range.bottom, pos.z, range.horizontal(), 1);
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseMapMoveWest(const InputMessagePtr& msg)
{
    Position pos;
    if(g_game.getFeature(Otc::GameMapMovePosition))
        pos = getPosition(msg);
    else
        pos = g_map.getCentralPosition();
    --pos.x;

    AwareRange range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, 1, range.vertical());
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseUpdateTile(const InputMessagePtr& msg)
{
    const Position tilePos = getPosition(msg);
    setTileDescription(msg, tilePos);
}

void ProtocolGame::parseTileAddThing(const InputMessagePtr& msg)
{
    const Position pos = getPosition(msg);
    int stackPos = -1;

    if(g_game.getClientVersion() >= 841)
        stackPos = msg->getU8();

    const ThingPtr thing = getThing(msg);
    g_map.addThing(thing, pos, stackPos);
}

void ProtocolGame::parseTileTransformThing(const InputMessagePtr& msg)
{
    const ThingPtr thing = getMappedThing(msg);
    const ThingPtr newThing = getThing(msg);

    if(!thing) {
        g_logger.traceError("no thing");
        return;
    }

    const Position pos = thing->getPosition();
    const int stackpos = thing->getStackPos();

    if(!g_map.removeThing(thing)) {
        g_logger.traceError("unable to remove thing");
        return;
    }

    g_map.addThing(newThing, pos, stackpos);
}

void ProtocolGame::parseTileRemoveThing(const InputMessagePtr& msg)
{
    const ThingPtr thing = getMappedThing(msg);
    if(!thing) {
        g_logger.traceError("no thing");
        return;
    }

    if(!g_map.removeThing(thing))
        g_logger.traceError("unable to remove thing");
}

void ProtocolGame::parseCreatureMove(const InputMessagePtr& msg)
{
    const ThingPtr thing = getMappedThing(msg);
    const Position newPos = getPosition(msg);

    if(!thing || !thing->isCreature()) {
        g_logger.traceError("no creature found to move");
        return;
    }

    if(!g_map.removeThing(thing)) {
        g_logger.traceError("unable to remove creature");
        return;
    }

    const CreaturePtr creature = thing->static_self_cast<Creature>();
    creature->allowAppearWalk();

    g_map.addThing(thing, newPos, -1);
}

void ProtocolGame::parseOpenContainer(const InputMessagePtr& msg)
{
    const int containerId = msg->getU8();
    const ItemPtr containerItem = getItem(msg);
    const std::string name = msg->getString();
    const int capacity = msg->getU8();
    const bool hasParent = msg->getU8() != 0;

    bool isUnlocked = true;
    bool hasPages = false;
    int containerSize = 0;
    int firstIndex = 0;

    if(g_game.getFeature(Otc::GameContainerPagination)) {
        isUnlocked = msg->getU8() != 0; // drag and drop
        hasPages = msg->getU8() != 0; // pagination
        containerSize = msg->getU16(); // container size
        firstIndex = msg->getU16(); // first index
    }

    const int itemCount = msg->getU8();

    std::vector<ItemPtr> items(itemCount);
    for(int i = 0; i < itemCount; ++i)
        items[i] = getItem(msg);

    g_game.processOpenContainer(containerId, containerItem, name, capacity, hasParent, items, isUnlocked, hasPages, containerSize, firstIndex);
}

void ProtocolGame::parseCloseContainer(const InputMessagePtr& msg)
{
    const int containerId = msg->getU8();
    g_game.processCloseContainer(containerId);
}

void ProtocolGame::parseContainerAddItem(const InputMessagePtr& msg)
{
    const int containerId = msg->getU8();
    int slot = 0;
    if(g_game.getFeature(Otc::GameContainerPagination)) {
        slot = msg->getU16(); // slot
    }
    const ItemPtr item = getItem(msg);
    g_game.processContainerAddItem(containerId, item, slot);
}

void ProtocolGame::parseContainerUpdateItem(const InputMessagePtr& msg)
{
    const int containerId = msg->getU8();
    int slot;
    if(g_game.getFeature(Otc::GameContainerPagination)) {
        slot = msg->getU16();
    } else {
        slot = msg->getU8();
    }
    const ItemPtr item = getItem(msg);
    g_game.processContainerUpdateItem(containerId, slot, item);
}

void ProtocolGame::parseContainerRemoveItem(const InputMessagePtr& msg)
{
    const int containerId = msg->getU8();
    int slot;
    ItemPtr lastItem;
    if(g_game.getFeature(Otc::GameContainerPagination)) {
        slot = msg->getU16();

        const int itemId = msg->getU16();
        if(itemId != 0)
            lastItem = getItem(msg, itemId);
    } else {
        slot = msg->getU8();
    }
    g_game.processContainerRemoveItem(containerId, slot, lastItem);
}

void ProtocolGame::parseAddInventoryItem(const InputMessagePtr& msg)
{
    const int slot = msg->getU8();
    const ItemPtr item = getItem(msg);
    g_game.processInventoryChange(slot, item);
}

void ProtocolGame::parseRemoveInventoryItem(const InputMessagePtr& msg)
{
    const int slot = msg->getU8();
    g_game.processInventoryChange(slot, ItemPtr());
}

void ProtocolGame::parseOpenNpcTrade(const InputMessagePtr& msg)
{
    std::vector<std::tuple<ItemPtr, std::string, int, int, int>> items;

    if(g_game.getFeature(Otc::GameNameOnNpcTrade))
        std::string npcName = msg->getString();

    int listCount;

    if(g_game.getClientVersion() >= 900)
        listCount = msg->getU16();
    else
        listCount = msg->getU8();

    for(int i = 0; i < listCount; ++i) {
        const uint16 itemId = msg->getU16();
        const uint8 count = msg->getU8();

        ItemPtr item = Item::create(itemId);
        item->setCountOrSubType(count);

        std::string name = msg->getString();
        int weight = msg->getU32();
        int buyPrice = msg->getU32();
        int sellPrice = msg->getU32();
        items.emplace_back(item, name, weight, buyPrice, sellPrice);
    }

    g_game.processOpenNpcTrade(items);
}

void ProtocolGame::parsePlayerGoods(const InputMessagePtr& msg)
{
    std::vector<std::tuple<ItemPtr, int>> goods;

    int money;
    if(g_game.getClientVersion() >= 973)
        money = msg->getU64();
    else
        money = msg->getU32();

    const int size = msg->getU8();
    for(int i = 0; i < size; ++i) {
        const int itemId = msg->getU16();
        int amount;

        if(g_game.getFeature(Otc::GameDoubleShopSellAmount))
            amount = msg->getU16();
        else
            amount = msg->getU8();

        goods.emplace_back(Item::create(itemId), amount);
    }

    g_game.processPlayerGoods(money, goods);
}

void ProtocolGame::parseCloseNpcTrade(const InputMessagePtr&)
{
    g_game.processCloseNpcTrade();
}

void ProtocolGame::parseOwnTrade(const InputMessagePtr& msg)
{
    const std::string name = g_game.formatCreatureName(msg->getString());
    const int count = msg->getU8();

    std::vector<ItemPtr> items(count);
    for(int i = 0; i < count; ++i)
        items[i] = getItem(msg);

    g_game.processOwnTrade(name, items);
}

void ProtocolGame::parseCounterTrade(const InputMessagePtr& msg)
{
    const std::string name = g_game.formatCreatureName(msg->getString());
    const int count = msg->getU8();

    std::vector<ItemPtr> items(count);
    for(int i = 0; i < count; ++i)
        items[i] = getItem(msg);

    g_game.processCounterTrade(name, items);
}

void ProtocolGame::parseCloseTrade(const InputMessagePtr&)
{
    g_game.processCloseTrade();
}

void ProtocolGame::parseWorldLight(const InputMessagePtr& msg)
{
    Light light;
    light.intensity = msg->getU8();
    light.color = msg->getU8();

    g_map.setLight(light);
}

void ProtocolGame::parseMagicEffect(const InputMessagePtr& msg)
{
    const Position pos = getPosition(msg);
    int effectId;
    if(g_game.getFeature(Otc::GameMagicEffectU16))
        effectId = msg->getU16();
    else
        effectId = msg->getU8();

    if(!g_things.isValidDatId(effectId, ThingCategoryEffect)) {
        g_logger.traceError(stdext::format("invalid effect id %d", effectId));
        return;
    }

    const auto effect = EffectPtr(new Effect());
    effect->setId(effectId);
    g_map.addThing(effect, pos);
}

void ProtocolGame::parseAnimatedText(const InputMessagePtr& msg)
{
    const Position position = getPosition(msg);
    const int color = msg->getU8();
    const std::string text = msg->getString();
    
    const auto animatedText = AnimatedTextPtr(new AnimatedText);
    animatedText->setColor(color);
    animatedText->setText(text);
    g_map.addThing(animatedText, position);
}

void ProtocolGame::parseDistanceMissile(const InputMessagePtr& msg)
{
    const Position fromPos = getPosition(msg);
    const Position toPos = getPosition(msg);
    const int shotId = msg->getU8();

    if(!g_things.isValidDatId(shotId, ThingCategoryMissile)) {
        g_logger.traceError(stdext::format("invalid missile id %d", shotId));
        return;
    }

    const auto missile = MissilePtr(new Missile());
    missile->setId(shotId);
    missile->setPath(fromPos, toPos);
    g_map.addThing(missile, fromPos);
}

void ProtocolGame::parseCreatureMark(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const int color = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(creature)
        creature->addTimedSquare(color);
    else
        g_logger.traceError("could not get creature");
}

void ProtocolGame::parseTrappers(const InputMessagePtr& msg)
{
    const int numTrappers = msg->getU8();

    if(numTrappers > 8)
        g_logger.traceError("too many trappers");

    for(int i = 0; i < numTrappers; ++i) {
        const uint id = msg->getU32();
        CreaturePtr creature = g_map.getCreatureById(id);
        if(creature) {
            //TODO: set creature as trapper
        } else
            g_logger.traceError("could not get creature");
    }
}

void ProtocolGame::parseCreatureHealth(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const int healthPercent = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(creature) creature->setHealthPercent(healthPercent);
}

void ProtocolGame::parseCreatureLight(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();

    Light light;
    light.intensity = msg->getU8();
    light.color = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setLight(light);
}

void ProtocolGame::parseCreatureOutfit(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const Outfit outfit = getOutfit(msg);

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setOutfit(outfit);
}

void ProtocolGame::parseCreatureSpeed(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();

    int baseSpeed = -1;
    if(g_game.getClientVersion() >= 1059)
        baseSpeed = msg->getU16();

    const int speed = msg->getU16();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(!creature) return;

    creature->setSpeed(speed);
    if(baseSpeed != -1)
        creature->setBaseSpeed(baseSpeed);
}

void ProtocolGame::parseCreatureSkulls(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const int skull = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setSkull(skull);
}

void ProtocolGame::parseCreatureShields(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const int shield = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setShield(shield);
}

void ProtocolGame::parseCreatureUnpass(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    const bool unpass = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setPassable(!unpass);
}

void ProtocolGame::parseEditText(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();

    int itemId;
    if(g_game.getClientVersion() >= 1010) {
        // TODO: processEditText with ItemPtr as parameter
        const ItemPtr item = getItem(msg);
        itemId = item->getId();
    } else
        itemId = msg->getU16();

    const int maxLength = msg->getU16();
    const std::string text = msg->getString();

    const std::string writer = msg->getString();
    std::string date = "";
    if(g_game.getFeature(Otc::GameWritableDate))
        date = msg->getString();

    g_game.processEditText(id, itemId, maxLength, text, writer, date);
}

void ProtocolGame::parseEditList(const InputMessagePtr& msg)
{
    const int doorId = msg->getU8();
    const uint id = msg->getU32();
    const std::string& text = msg->getString();

    g_game.processEditList(id, doorId, text);
}

void ProtocolGame::parsePremiumTrigger(const InputMessagePtr& msg)
{
    const int triggerCount = msg->getU8();
    std::vector<int> triggers;

    for(int i = 0; i < triggerCount; ++i) {
        triggers.push_back(msg->getU8());
    }

    if(g_game.getClientVersion() <= 1096) {
        msg->getU8(); // == 1; // something
    }
}

void ProtocolGame::parsePlayerInfo(const InputMessagePtr& msg)
{
    const bool premium = msg->getU8(); // premium
    if(g_game.getFeature(Otc::GamePremiumExpiration))
        msg->getU32(); // premium expiration used for premium advertisement
    const int vocation = msg->getU8(); // vocation

    const int spellCount = msg->getU16();
    std::vector<int> spells;
    for(int i = 0; i < spellCount; ++i)
        spells.push_back(msg->getU8()); // spell id

    m_localPlayer->setPremium(premium);
    m_localPlayer->setVocation(vocation);
    m_localPlayer->setSpells(spells);
}

void ProtocolGame::parsePlayerStats(const InputMessagePtr& msg)
{
    double health;
    double maxHealth;

    if(g_game.getFeature(Otc::GameDoubleHealth)) {
        health = msg->getU32();
        maxHealth = msg->getU32();
    } else {
        health = msg->getU16();
        maxHealth = msg->getU16();
    }

    double freeCapacity;
    if(g_game.getFeature(Otc::GameDoubleFreeCapacity))
        freeCapacity = msg->getU32() / 100.0;
    else
        freeCapacity = msg->getU16() / 100.0;

    double totalCapacity = 0;
    if(g_game.getFeature(Otc::GameTotalCapacity))
        totalCapacity = msg->getU32() / 100.0;

    double experience;
    if(g_game.getFeature(Otc::GameDoubleExperience))
        experience = msg->getU64();
    else
        experience = msg->getU32();

    const double level = msg->getU16();
    const double levelPercent = msg->getU8();

    if(g_game.getFeature(Otc::GameExperienceBonus)) {
        if(g_game.getClientVersion() <= 1096) {
            msg->getDouble(); // experienceBonus
        } else {
            msg->getU16(); // baseXpGain
            msg->getU16(); // voucherAddend
            msg->getU16(); // grindingAddend
            msg->getU16(); // storeBoostAddend
            msg->getU16(); // huntingBoostFactor
        }
    }

    double mana;
    double maxMana;

    if(g_game.getFeature(Otc::GameDoubleHealth)) {
        mana = msg->getU32();
        maxMana = msg->getU32();
    } else {
        mana = msg->getU16();
        maxMana = msg->getU16();
    }

    const double magicLevel = msg->getU8();

    double baseMagicLevel;
    if(g_game.getFeature(Otc::GameSkillsBase))
        baseMagicLevel = msg->getU8();
    else
        baseMagicLevel = magicLevel;

    const double magicLevelPercent = msg->getU8();
    const double soul = msg->getU8();
    double stamina = 0;
    if(g_game.getFeature(Otc::GamePlayerStamina))
        stamina = msg->getU16();

    double baseSpeed = 0;
    if(g_game.getFeature(Otc::GameSkillsBase))
        baseSpeed = msg->getU16();

    double regeneration = 0;
    if(g_game.getFeature(Otc::GamePlayerRegenerationTime))
        regeneration = msg->getU16();

    double training = 0;
    if(g_game.getFeature(Otc::GameOfflineTrainingTime)) {
        training = msg->getU16();
        if(g_game.getClientVersion() >= 1097) {
            msg->getU16(); // remainingStoreXpBoostSeconds
            msg->getU8(); // canBuyMoreStoreXpBoosts
        }
    }

    m_localPlayer->setHealth(health, maxHealth);
    m_localPlayer->setFreeCapacity(freeCapacity);
    m_localPlayer->setTotalCapacity(totalCapacity);
    m_localPlayer->setExperience(experience);
    m_localPlayer->setLevel(level, levelPercent);
    m_localPlayer->setMana(mana, maxMana);
    m_localPlayer->setMagicLevel(magicLevel, magicLevelPercent);
    m_localPlayer->setBaseMagicLevel(baseMagicLevel);
    m_localPlayer->setStamina(stamina);
    m_localPlayer->setSoul(soul);
    m_localPlayer->setBaseSpeed(baseSpeed);
    m_localPlayer->setRegenerationTime(regeneration);
    m_localPlayer->setOfflineTrainingTime(training);
}

void ProtocolGame::parsePlayerSkills(const InputMessagePtr& msg)
{
    int lastSkill = Otc::Fishing + 1;
    if(g_game.getFeature(Otc::GameAdditionalSkills))
        lastSkill = Otc::LastSkill;

    for(int skill = 0; skill < lastSkill; ++skill) {
        int level;

        if(g_game.getFeature(Otc::GameDoubleSkills))
            level = msg->getU16();
        else
            level = msg->getU8();

        int baseLevel;
        if(g_game.getFeature(Otc::GameSkillsBase))
            if(g_game.getFeature(Otc::GameBaseSkillU16))
                baseLevel = msg->getU16();
            else
                baseLevel = msg->getU8();
        else
            baseLevel = level;

        int levelPercent = 0;
        // Critical, Life Leech and Mana Leech have no level percent
        if(skill <= Otc::Fishing)
            levelPercent = msg->getU8();

        m_localPlayer->setSkill(static_cast<Otc::Skill>(skill), level, levelPercent);
        m_localPlayer->setBaseSkill(static_cast<Otc::Skill>(skill), baseLevel);
    }
}

void ProtocolGame::parsePlayerState(const InputMessagePtr& msg)
{
    int states;
    if(g_game.getFeature(Otc::GamePlayerStateU16))
        states = msg->getU16();
    else
        states = msg->getU8();

    m_localPlayer->setStates(states);
}

void ProtocolGame::parsePlayerCancelAttack(const InputMessagePtr& msg)
{
    uint seq = 0;
    if(g_game.getFeature(Otc::GameAttackSeq))
        seq = msg->getU32();

    g_game.processAttackCancel(seq);
}

void ProtocolGame::parsePlayerModes(const InputMessagePtr& msg)
{
    int fightMode = msg->getU8();
    int chaseMode = msg->getU8();
    const bool safeMode = msg->getU8();

    int pvpMode = 0;
    if(g_game.getFeature(Otc::GamePVPMode))
        pvpMode = msg->getU8();

    g_game.processPlayerModes(static_cast<Otc::FightModes>(fightMode), static_cast<Otc::ChaseModes>(chaseMode), safeMode, static_cast<Otc::PVPModes>(pvpMode));
}

void ProtocolGame::parseSpellCooldown(const InputMessagePtr& msg)
{
    const int spellId = msg->getU8();
    const int delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onSpellCooldown", spellId, delay);
}

void ProtocolGame::parseSpellGroupCooldown(const InputMessagePtr& msg)
{
    const int groupId = msg->getU8();
    const int delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onSpellGroupCooldown", groupId, delay);
}

void ProtocolGame::parseMultiUseCooldown(const InputMessagePtr& msg)
{
    const int delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onMultiUseCooldown", delay);
}

void ProtocolGame::parseTalk(const InputMessagePtr& msg)
{
    if(g_game.getFeature(Otc::GameMessageStatements))
        msg->getU32(); // channel statement guid

    const std::string name = g_game.formatCreatureName(msg->getString());

    int level = 0;
    if(g_game.getFeature(Otc::GameMessageLevel))
        level = msg->getU16();

    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(msg->getU8());
    int channelId = 0;
    Position pos;

    switch(mode) {
    case Otc::MessageSay:
    case Otc::MessageWhisper:
    case Otc::MessageYell:
    case Otc::MessageMonsterSay:
    case Otc::MessageMonsterYell:
    case Otc::MessageNpcTo:
    case Otc::MessageBarkLow:
    case Otc::MessageBarkLoud:
    case Otc::MessageSpell:
    case Otc::MessageNpcFromStartBlock:
        pos = getPosition(msg);
        break;
    case Otc::MessageChannel:
    case Otc::MessageChannelManagement:
    case Otc::MessageChannelHighlight:
    case Otc::MessageGamemasterChannel:
        channelId = msg->getU16();
        break;
    case Otc::MessageNpcFrom:
    case Otc::MessagePrivateFrom:
    case Otc::MessageGamemasterBroadcast:
    case Otc::MessageGamemasterPrivateFrom:
    case Otc::MessageRVRAnswer:
    case Otc::MessageRVRContinue:
        break;
    case Otc::MessageRVRChannel:
        msg->getU32();
        break;
    default:
        stdext::throw_exception(stdext::format("unknown message mode %d", mode));
        break;
    }

    const std::string text = msg->getString();

    g_game.processTalk(name, level, mode, text, channelId, pos);
}

void ProtocolGame::parseChannelList(const InputMessagePtr& msg)
{
    const int count = msg->getU8();
    std::vector<std::tuple<int, std::string> > channelList;
    for(int i = 0; i < count; ++i) {
        int id = msg->getU16();
        std::string name = msg->getString();
        channelList.emplace_back(id, name);
    }

    g_game.processChannelList(channelList);
}

void ProtocolGame::parseOpenChannel(const InputMessagePtr& msg)
{
    const int channelId = msg->getU16();
    const std::string name = msg->getString();

    if(g_game.getFeature(Otc::GameChannelPlayerList)) {
        const int joinedPlayers = msg->getU16();
        for(int i = 0; i < joinedPlayers; ++i)
            g_game.formatCreatureName(msg->getString()); // player name
        const int invitedPlayers = msg->getU16();
        for(int i = 0; i < invitedPlayers; ++i)
            g_game.formatCreatureName(msg->getString()); // player name
    }

    g_game.processOpenChannel(channelId, name);
}

void ProtocolGame::parseOpenPrivateChannel(const InputMessagePtr& msg)
{
    const std::string name = g_game.formatCreatureName(msg->getString());

    g_game.processOpenPrivateChannel(name);
}

void ProtocolGame::parseOpenOwnPrivateChannel(const InputMessagePtr& msg)
{
    const int channelId = msg->getU16();
    const std::string name = msg->getString();

    g_game.processOpenOwnPrivateChannel(channelId, name);
}

void ProtocolGame::parseCloseChannel(const InputMessagePtr& msg)
{
    const int channelId = msg->getU16();

    g_game.processCloseChannel(channelId);
}

void ProtocolGame::parseRuleViolationChannel(const InputMessagePtr& msg)
{
    const int channelId = msg->getU16();

    g_game.processRuleViolationChannel(channelId);
}

void ProtocolGame::parseRuleViolationRemove(const InputMessagePtr& msg)
{
    const std::string name = msg->getString();

    g_game.processRuleViolationRemove(name);
}

void ProtocolGame::parseRuleViolationCancel(const InputMessagePtr& msg)
{
    const std::string name = msg->getString();
    g_game.processRuleViolationCancel(name);
}

void ProtocolGame::parseRuleViolationLock(const InputMessagePtr&)
{
    g_game.processRuleViolationLock();
}

void ProtocolGame::parseTextMessage(const InputMessagePtr& msg)
{
    const int code = msg->getU8();
    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(code);
    std::string text;

    switch(mode) {
    case Otc::MessageChannelManagement:
    {
        msg->getU16(); // channelId
        text = msg->getString();
        break;
    }
    case Otc::MessageGuild:
    case Otc::MessagePartyManagement:
    case Otc::MessageParty:
    {
        msg->getU16(); // channelId
        text = msg->getString();
        break;
    }
    case Otc::MessageDamageDealed:
    case Otc::MessageDamageReceived:
    case Otc::MessageDamageOthers:
    {
        const Position pos = getPosition(msg);
        uint value[2];
        int color[2];

        // physical damage
        value[0] = msg->getU32();
        color[0] = msg->getU8();

        // magic damage
        value[1] = msg->getU32();
        color[1] = msg->getU8();
        text = msg->getString();

        for(int i = 0; i < 2; ++i) {
            if(value[i] == 0)
                continue;
            auto animatedText = AnimatedTextPtr(new AnimatedText);
            animatedText->setColor(color[i]);
            animatedText->setText(std::to_string(value[i]));
            g_map.addThing(animatedText, pos);
        }
        break;
    }
    case Otc::MessageHeal:
    case Otc::MessageMana:
    case Otc::MessageExp:
    case Otc::MessageHealOthers:
    case Otc::MessageExpOthers:
    {
        const Position pos = getPosition(msg);
        const uint value = msg->getU32();
        const int color = msg->getU8();
        text = msg->getString();

        const auto animatedText = AnimatedTextPtr(new AnimatedText);
        animatedText->setColor(color);
        animatedText->setText(std::to_string(value));
        g_map.addThing(animatedText, pos);
        break;
    }
    case Otc::MessageInvalid:
        stdext::throw_exception(stdext::format("unknown message mode %d", mode));
        break;
    default:
        text = msg->getString();
        break;
    }

    g_game.processTextMessage(mode, text);
}

void ProtocolGame::parseCancelWalk(const InputMessagePtr& msg)
{
    const auto direction = static_cast<Otc::Direction>(msg->getU8());

    g_game.processWalkCancel(direction);
}

void ProtocolGame::parseWalkWait(const InputMessagePtr& msg)
{
    const int millis = msg->getU16();
    m_localPlayer->lockWalk(millis);
}

void ProtocolGame::parseFloorChangeUp(const InputMessagePtr& msg)
{
    Position pos;
    if(g_game.getFeature(Otc::GameMapMovePosition))
        pos = getPosition(msg);
    else
        pos = g_map.getCentralPosition();
    AwareRange range = g_map.getAwareRange();
    --pos.z;

    int skip = 0;
    if(pos.z == SEA_FLOOR)
        for(int i = SEA_FLOOR - AWARE_UNDEGROUND_FLOOR_RANGE; i >= 0; --i)
            skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, i, range.horizontal(), range.vertical(), 8 - i, skip);
    else if(pos.z > SEA_FLOOR)
        skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, pos.z - AWARE_UNDEGROUND_FLOOR_RANGE, range.horizontal(), range.vertical(), 3, skip);

    ++pos.x;
    ++pos.y;
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseFloorChangeDown(const InputMessagePtr& msg)
{
    Position pos;
    if(g_game.getFeature(Otc::GameMapMovePosition))
        pos = getPosition(msg);
    else
        pos = g_map.getCentralPosition();
    AwareRange range = g_map.getAwareRange();
    ++pos.z;

    int skip = 0;
    if(pos.z == UNDERGROUND_FLOOR) {
        int j, i;
        for(i = pos.z, j = -1; i <= pos.z + AWARE_UNDEGROUND_FLOOR_RANGE; ++i, --j)
            skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, i, range.horizontal(), range.vertical(), j, skip);
    } else if(pos.z > UNDERGROUND_FLOOR && pos.z < MAX_Z - 1)
        skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, pos.z + AWARE_UNDEGROUND_FLOOR_RANGE, range.horizontal(), range.vertical(), -3, skip);

    --pos.x;
    --pos.y;
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseOpenOutfitWindow(const InputMessagePtr& msg)
{
    const Outfit currentOutfit = getOutfit(msg);
    std::vector<std::tuple<int, std::string, int> > outfitList;

    if(g_game.getFeature(Otc::GameNewOutfitProtocol)) {
        const int outfitCount = msg->getU8();
        for(int i = 0; i < outfitCount; ++i) {
            int outfitId = msg->getU16();
            std::string outfitName = msg->getString();
            int outfitAddons = msg->getU8();

            outfitList.emplace_back(outfitId, outfitName, outfitAddons);
        }
    } else {
        int outfitStart, outfitEnd;
        if(g_game.getFeature(Otc::GameLooktypeU16)) {
            outfitStart = msg->getU16();
            outfitEnd = msg->getU16();
        } else {
            outfitStart = msg->getU8();
            outfitEnd = msg->getU8();
        }

        for(int i = outfitStart; i <= outfitEnd; ++i)
            outfitList.emplace_back(i, "", 0);
    }

    std::vector<std::tuple<int, std::string> > mountList;
    if(g_game.getFeature(Otc::GamePlayerMounts)) {
        const int mountCount = msg->getU8();
        for(int i = 0; i < mountCount; ++i) {
            int mountId = msg->getU16(); // mount type
            std::string mountName = msg->getString(); // mount name

            mountList.emplace_back(mountId, mountName);
        }
    }

    g_game.processOpenOutfitWindow(currentOutfit, outfitList, mountList);
}

void ProtocolGame::parseVipAdd(const InputMessagePtr& msg)
{
    uint iconId = 0;
    std::string desc = "";
    bool notifyLogin = false;

    const uint id = msg->getU32();
    const std::string name = g_game.formatCreatureName(msg->getString());
    if(g_game.getFeature(Otc::GameAdditionalVipInfo)) {
        desc = msg->getString();
        iconId = msg->getU32();
        notifyLogin = msg->getU8();
    }
    const uint status = msg->getU8();

    g_game.processVipAdd(id, name, status, desc, iconId, notifyLogin);
}

void ProtocolGame::parseVipState(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    if(g_game.getFeature(Otc::GameLoginPending)) {
        const uint status = msg->getU8();
        g_game.processVipStateChange(id, status);
    } else {
        g_game.processVipStateChange(id, 1);
    }
}

void ProtocolGame::parseVipLogout(const InputMessagePtr& msg)
{
    const uint id = msg->getU32();
    g_game.processVipStateChange(id, 0);
}

void ProtocolGame::parseTutorialHint(const InputMessagePtr& msg)
{
    const int id = msg->getU8();
    g_game.processTutorialHint(id);
}

void ProtocolGame::parseAutomapFlag(const InputMessagePtr& msg)
{
    const Position pos = getPosition(msg);
    const int icon = msg->getU8();
    const std::string description = msg->getString();

    bool remove = false;
    if(g_game.getFeature(Otc::GameMinimapRemove))
        remove = msg->getU8() != 0;

    if(!remove)
        g_game.processAddAutomapFlag(pos, icon, description);
    else
        g_game.processRemoveAutomapFlag(pos, icon, description);
}

void ProtocolGame::parseQuestLog(const InputMessagePtr& msg)
{
    std::vector<std::tuple<int, std::string, bool> > questList;
    const int questsCount = msg->getU16();
    for(int i = 0; i < questsCount; ++i) {
        int id = msg->getU16();
        std::string name = msg->getString();
        bool completed = msg->getU8();
        questList.emplace_back(id, name, completed);
    }

    g_game.processQuestLog(questList);
}

void ProtocolGame::parseQuestLine(const InputMessagePtr& msg)
{
    std::vector<std::tuple<std::string, std::string>> questMissions;
    const int questId = msg->getU16();
    const int missionCount = msg->getU8();
    for(int i = 0; i < missionCount; ++i) {
        std::string missionName = msg->getString();
        std::string missionDescrition = msg->getString();
        questMissions.emplace_back(missionName, missionDescrition);
    }

    g_game.processQuestLine(questId, questMissions);
}

void ProtocolGame::parseChannelEvent(const InputMessagePtr& msg)
{
    const uint16 channelId = msg->getU16();
    const std::string name = g_game.formatCreatureName(msg->getString());
    const uint8 type = msg->getU8();

    g_lua.callGlobalField("g_game", "onChannelEvent", channelId, name, type);
}

void ProtocolGame::parseItemInfo(const InputMessagePtr& msg)
{
    std::vector<std::tuple<ItemPtr, std::string>> list;
    const int size = msg->getU8();
    for(int i = 0; i < size; ++i) {
        ItemPtr item(new Item);
        item->setId(msg->getU16());
        item->setCountOrSubType(msg->getU8());

        std::string desc = msg->getString();
        list.emplace_back(item, desc);
    }

    g_lua.callGlobalField("g_game", "onItemInfo", list);
}

void ProtocolGame::parsePlayerInventory(const InputMessagePtr& msg)
{
    const int size = msg->getU16();
    for(int i = 0; i < size; ++i) {
        msg->getU16(); // id
        msg->getU8(); // subtype
        msg->getU16(); // count
    }
}

void ProtocolGame::parseModalDialog(const InputMessagePtr& msg)
{
    const uint32 windowId = msg->getU32();
    const std::string title = msg->getString();
    const std::string message = msg->getString();

    const int sizeButtons = msg->getU8();
    std::vector<std::tuple<int, std::string> > buttonList;
    for(int i = 0; i < sizeButtons; ++i) {
        std::string value = msg->getString();
        int buttonId = msg->getU8();
        buttonList.emplace_back(buttonId, value);
    }

    const int sizeChoices = msg->getU8();
    std::vector<std::tuple<int, std::string> > choiceList;
    for(int i = 0; i < sizeChoices; ++i) {
        std::string value = msg->getString();
        int choideId = msg->getU8();
        choiceList.emplace_back(choideId, value);
    }

    int enterButton, escapeButton;
    if(g_game.getClientVersion() > 970) {
        escapeButton = msg->getU8();
        enterButton = msg->getU8();
    } else {
        enterButton = msg->getU8();
        escapeButton = msg->getU8();
    }

    const bool priority = msg->getU8() == 0x01;

    g_game.processModalDialog(windowId, title, message, buttonList, enterButton, escapeButton, choiceList, priority);
}

void ProtocolGame::parseExtendedOpcode(const InputMessagePtr& msg)
{
    const int opcode = msg->getU8();
    const std::string buffer = msg->getString();

    if(opcode == 0)
        m_enableSendExtendedOpcode = true;
    else if(opcode == 2)
        parsePingBack(msg);
    else
        callLuaField("onExtendedOpcode", opcode, buffer);
}

void ProtocolGame::parseChangeMapAwareRange(const InputMessagePtr& msg)
{
    const int xrange = msg->getU8();
    const int yrange = msg->getU8();

    AwareRange range;
    range.left = xrange / 2 - (xrange + 1) % 2;
    range.right = xrange / 2;
    range.top = yrange / 2 - (yrange + 1) % 2;
    range.bottom = yrange / 2;

    g_map.setAwareRange(range);
    g_lua.callGlobalField("g_game", "onMapChangeAwareRange", xrange, yrange);
}

void ProtocolGame::parseCreaturesMark(const InputMessagePtr& msg)
{
    int len;
    if(g_game.getClientVersion() >= 1035) {
        len = 1;
    } else {
        len = msg->getU8();
    }

    for(int i = 0; i < len; ++i) {
        const uint32 id = msg->getU32();
        const bool isPermanent = msg->getU8() != 1;
        const uint8 markType = msg->getU8();

        CreaturePtr creature = g_map.getCreatureById(id);
        if(creature) {
            if(isPermanent) {
                if(markType == 0xff)
                    creature->hideStaticSquare();
                else
                    creature->showStaticSquare(Color::from8bit(markType));
            } else
                creature->addTimedSquare(markType);
        } else
            g_logger.traceError("could not get creature");
    }
}

void ProtocolGame::parseCreatureType(const InputMessagePtr& msg)
{
    const uint32 id = msg->getU32();
    const uint8 type = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if(creature)
        creature->setType(type);
    else
        g_logger.traceError("could not get creature");
}

void ProtocolGame::setMapDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height)
{
    int startz, endz, zstep;

    if(z > SEA_FLOOR) {
        startz = z - AWARE_UNDEGROUND_FLOOR_RANGE;
        endz = std::min<int>(z + AWARE_UNDEGROUND_FLOOR_RANGE, static_cast<int>(MAX_Z));
        zstep = 1;
    } else {
        startz = SEA_FLOOR;
        endz = 0;
        zstep = -1;
    }

    int skip = 0;
    for(int nz = startz; nz != endz + zstep; nz += zstep)
        skip = setFloorDescription(msg, x, y, nz, width, height, z - nz, skip);
}

int ProtocolGame::setFloorDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height, int offset, int skip)
{
    for(int nx = 0; nx < width; ++nx) {
        for(int ny = 0; ny < height; ++ny) {
            Position tilePos(x + nx + offset, y + ny + offset, z);
            if(skip == 0)
                skip = setTileDescription(msg, tilePos);
            else {
                g_map.cleanTile(tilePos);
                --skip;
            }
        }
    }
    return skip;
}

int ProtocolGame::setTileDescription(const InputMessagePtr& msg, Position position)
{
    g_map.cleanTile(position);

    bool gotEffect = false;
    for(int stackPos = 0; stackPos < 256; ++stackPos) {
        if(msg->peekU16() >= 0xff00)
            return msg->getU16() & 0xff;

        if(g_game.getFeature(Otc::GameEnvironmentEffect) && !gotEffect) {
            msg->getU16(); // environment effect
            gotEffect = true;
            continue;
        }

        if(stackPos > 10)
            g_logger.traceError(stdext::format("too many things, pos=%s, stackpos=%d", stdext::to_string(position), stackPos));

        ThingPtr thing = getThing(msg);
        g_map.addThing(thing, position, stackPos);
    }

    return 0;
}
Outfit ProtocolGame::getOutfit(const InputMessagePtr& msg)
{
    Outfit outfit;

    int lookType;
    if(g_game.getFeature(Otc::GameLooktypeU16))
        lookType = msg->getU16();
    else
        lookType = msg->getU8();

    if(lookType != 0) {
        outfit.setCategory(ThingCategoryCreature);
        const int head = msg->getU8();
        const int body = msg->getU8();
        const int legs = msg->getU8();
        const int feet = msg->getU8();
        int addons = 0;
        if(g_game.getFeature(Otc::GamePlayerAddons))
            addons = msg->getU8();

        if(!g_things.isValidDatId(lookType, ThingCategoryCreature)) {
            g_logger.traceError(stdext::format("invalid outfit looktype %d", lookType));
            lookType = 0;
        }

        outfit.setId(lookType);
        outfit.setHead(head);
        outfit.setBody(body);
        outfit.setLegs(legs);
        outfit.setFeet(feet);
        outfit.setAddons(addons);
    } else {
        int lookTypeEx = msg->getU16();
        if(lookTypeEx == 0) {
            outfit.setCategory(ThingCategoryEffect);
            outfit.setAuxId(13); // invisible effect id
        } else {
            if(!g_things.isValidDatId(lookTypeEx, ThingCategoryItem)) {
                g_logger.traceError(stdext::format("invalid outfit looktypeex %d", lookTypeEx));
                lookTypeEx = 0;
            }
            outfit.setCategory(ThingCategoryItem);
            outfit.setAuxId(lookTypeEx);
        }
    }

    if(g_game.getFeature(Otc::GamePlayerMounts)) {
        const int mount = msg->getU16();
        outfit.setMount(mount);
    }

    return outfit;
}

ThingPtr ProtocolGame::getThing(const InputMessagePtr& msg)
{
    ThingPtr thing;

    const int id = msg->getU16();

    if(id == 0)
        stdext::throw_exception("invalid thing id");
    else if(id == Proto::UnknownCreature || id == Proto::OutdatedCreature || id == Proto::Creature)
        thing = getCreature(msg, id);
    else if(id == Proto::StaticText) // otclient only
        thing = getStaticText(msg, id);
    else // item
        thing = getItem(msg, id);

    return thing;
}

ThingPtr ProtocolGame::getMappedThing(const InputMessagePtr& msg)
{
    ThingPtr thing;
    const uint16 x = msg->getU16();

    if(x != 0xffff) {
        Position pos;
        pos.x = x;
        pos.y = msg->getU16();
        pos.z = msg->getU8();
        const uint8 stackpos = msg->getU8();
        assert(stackpos != UINT8_MAX);
        thing = g_map.getThing(pos, stackpos);
        if(!thing)
            g_logger.traceError(stdext::format("no thing at pos:%s, stackpos:%d", stdext::to_string(pos), stackpos));
    } else {
        const uint32 id = msg->getU32();
        thing = g_map.getCreatureById(id);
        if(!thing)
            g_logger.traceError(stdext::format("no creature with id %u", id));
    }

    return thing;
}

CreaturePtr ProtocolGame::getCreature(const InputMessagePtr& msg, int type)
{
    if(type == 0)
        type = msg->getU16();

    CreaturePtr creature;
    const bool known = type != Proto::UnknownCreature;
    if(type == Proto::OutdatedCreature || type == Proto::UnknownCreature) {
        if(known) {
            const uint id = msg->getU32();
            creature = g_map.getCreatureById(id);
            if(!creature)
                g_logger.traceError("server said that a creature is known, but it's not");

            // Is necessary reset camera?
            // if(creature->isLocalPlayer()) g_map.resetLastCamera();
        } else {
            const uint removeId = msg->getU32();
            g_map.removeCreatureById(removeId);

            const uint id = msg->getU32();

            int creatureType;
            if(g_game.getClientVersion() >= 910)
                creatureType = msg->getU8();
            else {
                if(id >= Proto::PlayerStartId && id < Proto::PlayerEndId)
                    creatureType = Proto::CreatureTypePlayer;
                else if(id >= Proto::MonsterStartId && id < Proto::MonsterEndId)
                    creatureType = Proto::CreatureTypeMonster;
                else
                    creatureType = Proto::CreatureTypeNpc;
            }

            const std::string name = g_game.formatCreatureName(msg->getString());

            if(id == m_localPlayer->getId())
                creature = m_localPlayer;
            else if(creatureType == Proto::CreatureTypePlayer) {
                // fixes a bug server side bug where GameInit is not sent and local player id is unknown
                if(m_localPlayer->getId() == 0 && name == m_localPlayer->getName())
                    creature = m_localPlayer;
                else
                    creature = PlayerPtr(new Player);
            } else if(creatureType == Proto::CreatureTypeMonster)
                creature = MonsterPtr(new Monster);
            else if(creatureType == Proto::CreatureTypeNpc)
                creature = NpcPtr(new Npc);
            else
                g_logger.traceError("creature type is invalid");

            if(creature) {
                creature->setId(id);
                creature->setName(name);

                g_map.addCreature(creature);
            }
        }

        const int healthPercent = msg->getU8();
        const auto direction = static_cast<Otc::Direction>(msg->getU8());
        const Outfit outfit = getOutfit(msg);

        Light light;
        light.intensity = msg->getU8();
        light.color = msg->getU8();

        const int speed = msg->getU16();
        const int skull = msg->getU8();
        const int shield = msg->getU8();

        // emblem is sent only when the creature is not known
        int8 emblem = -1;
        int8 creatureType = -1;
        int8 icon = -1;
        bool unpass = true;

        if(g_game.getFeature(Otc::GameCreatureEmblems) && !known)
            emblem = msg->getU8();

        if(g_game.getFeature(Otc::GameThingMarks)) {
            creatureType = msg->getU8();
        }

        if(g_game.getFeature(Otc::GameCreatureIcons)) {
            icon = msg->getU8();
        }

        if(g_game.getFeature(Otc::GameThingMarks)) {
            const uint8 mark = msg->getU8(); // mark
            msg->getU16(); // helpers

            if(creature) {
                if(mark == 0xff)
                    creature->hideStaticSquare();
                else
                    creature->showStaticSquare(Color::from8bit(mark));
            }
        }

        if(g_game.getClientVersion() >= 854)
            unpass = msg->getU8();

        if(creature) {
            creature->setHealthPercent(healthPercent);
            creature->turn(direction);
            creature->setOutfit(outfit);
            creature->setSpeed(speed);
            creature->setSkull(skull);
            creature->setShield(shield);
            creature->setPassable(!unpass);
            creature->setLight(light);

            if(emblem != -1)
                creature->setEmblem(emblem);

            if(creatureType != -1)
                creature->setType(creatureType);

            if(icon != -1)
                creature->setIcon(icon);

            if(creature == m_localPlayer && !m_localPlayer->isKnown())
                m_localPlayer->setKnown(true);
        }
    } else if(type == Proto::Creature) {
        const uint id = msg->getU32();
        creature = g_map.getCreatureById(id);

        if(!creature)
            g_logger.traceError("invalid creature");

        const auto direction = static_cast<Otc::Direction>(msg->getU8());
        if(creature)
            creature->turn(direction);

        if(g_game.getClientVersion() >= 953) {
            const bool unpass = msg->getU8();

            if(creature)
                creature->setPassable(!unpass);
        }
    } else {
        stdext::throw_exception("invalid creature opcode");
    }

    return creature;
}

ItemPtr ProtocolGame::getItem(const InputMessagePtr& msg, int id)
{
    if(id == 0)
        id = msg->getU16();

    ItemPtr item = Item::create(id);
    if(item->getId() == 0)
        stdext::throw_exception(stdext::format("unable to create item with invalid id %d", id));

    if(g_game.getFeature(Otc::GameThingMarks)) {
        msg->getU8(); // mark
    }

    if(item->isStackable() || item->isFluidContainer() || item->isSplash() || item->isChargeable())
        item->setCountOrSubType(msg->getU8());

    if(g_game.getFeature(Otc::GameItemAnimationPhase)) {
        if(item->getAnimationPhases() > 1) {
            // 0x00 => automatic phase
            // 0xFE => random phase
            // 0xFF => async phase
            msg->getU8();
            //item->setPhase(msg->getU8());
        }
    }

    return item;
}

StaticTextPtr ProtocolGame::getStaticText(const InputMessagePtr& msg, int)
{
    const int colorByte = msg->getU8();
    const Color color = Color::from8bit(colorByte);
    const std::string fontName = msg->getString();
    const std::string text = msg->getString();
    auto staticText = StaticTextPtr(new StaticText);
    staticText->setText(text);
    staticText->setFont(fontName);
    staticText->setColor(color);
    return staticText;
}

Position ProtocolGame::getPosition(const InputMessagePtr& msg)
{
    const uint16 x = msg->getU16();
    const uint16 y = msg->getU16();
    const uint8 z = msg->getU8();

    return { x, y, z };
}
