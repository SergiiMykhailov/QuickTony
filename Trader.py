import BTCTradeUA
import PlatformsState
from kuna import kuna

import time
import datetime
import sys
import os
import uuid

class Trader(object):
    


    __btcTradeUAProvider = BTCTradeUA.BtcTradeUA()
    __kunaProvider = kuna.KunaAPI()
    __deals = [] # TODO: Replace by storing all pending deals in database



    def __init__(self, btcTradeUAPublicKey, btcTradeUAPrivateKey, kunaPublicKey, kunaPrivateKey):
        self.__btcTradeUAProvider = BTCTradeUA.BtcTradeUA(public_key = btcTradeUAPublicKey, \
                                                          private_key = btcTradeUAPrivateKey)
        self.__kunaProvider = kuna.KunaAPI(kunaPublicKey, kunaPrivateKey)



    def run(self):
        while True:
            try:
                self.__handlePlatformsState()
            except:
                e = sys.exc_info()[0]
                print("Exception handled: ", e)

            time.sleep(10)



    def __handlePlatformsState(self):
        if self.__updatePlatformsState() == False:
            return        

        self.__storePrices()
        self.__buyAndSellAssetIfPossible()
        self.__handlePendingDeals()


    
    def __updatePlatformsState(self):
        print(">>> BEGIN RETRIEVING TRADING DATA")
        
        kunaOrdersBook = self.__kunaProvider.get_order_book('btcuah')
        kunaBuyOrders = kunaOrdersBook['bids']
        kunaSellOrders = kunaOrdersBook['asks']
        kunaAccountInfo = self.__kunaProvider.get_user_account_info()

        btcTradeUABalanceItems = self.__btcTradeUAProvider.balance()
        btcTradeUABuyOrders = self.__btcTradeUAProvider.buy_list()
        btcTradeUASellOrders = self.__btcTradeUAProvider.sell_list()
        
        print("<<< END RETRIEVING TRADING DATA")        

        self.__platformsState = PlatformsState.PlatformsState(btcTradeUABuyOrders, \
                                                              btcTradeUASellOrders, \
                                                              btcTradeUABalanceItems, \
                                                              kunaBuyOrders, \
                                                              kunaSellOrders, \
                                                              kunaAccountInfo)

        if (len(self.__platformsState.btcTradeBuyOrders) == 0 or 
            len(self.__platformsState.btcTradeSellOrders) == 0 or 
            len(self.__platformsState.kunaBuyOrders) == 0 or 
            len(self.__platformsState.kunaSellOrders) == 0):
            return False

        return True

        

    def __openFileForDailyRecords(self, suffixWithExtension):
        currentDate = datetime.datetime.now()
        currentDayString = currentDate.strftime("%Y-%m-%d")
        logFileDir = os.path.join(os.getcwd(), "log")
        os.makedirs(logFileDir, exist_ok = True)

        fileName = currentDayString + "_" + suffixWithExtension
        filePath = os.path.join(logFileDir, fileName)

        result = open(filePath, 'a')
        return result



    def __storePrices(self):
        topBtcTradeBuyPrice = self.__platformsState.topBtcTradeBuyPrice()
        topBtcTradeSellPrice = self.__platformsState.topBtcTradeSellPrice()
        topKunaBuyPrice = self.__platformsState.topKunaBuyPrice()
        topKunaSellPrice = self.__platformsState.topKunaSellPrice()

        btcToKunaRatio = self.__platformsState.btcTradeToKunaBuySellRatio()
        kunaToBtcRatio = self.__platformsState.kunaToBtcTradeBuySellRatio()

        with self.__openFileForDailyRecords("prices.csv") as pricesFile:
            textToAppend = "{0:.2f}".format(topBtcTradeBuyPrice) + "," + \
                           "{0:.2f}".format(topBtcTradeSellPrice) + "," + \
                           "{0:.2f}".format(topKunaBuyPrice) + "," + \
                           "{0:.2f}".format(topKunaSellPrice) + "," + \
                           "{0:.2f}".format(btcToKunaRatio) + "," + \
                           "{0:.2f}".format(kunaToBtcRatio) + "\n"

            pricesFile.write(textToAppend)



    def __buyAndSellAssetIfPossible(self):
        btcTradeToKunaRatio = self.__platformsState.btcTradeToKunaBuySellRatio()
        kunaToBtcTradeRatio = self.__platformsState.kunaToBtcTradeBuySellRatio()

        deal = None

        if btcTradeToKunaRatio > Trader.MIN_BUY_SELL_RATIO:
            deal = self.__buyAtBtcTradeSellAtKuna()                 
        elif kunaToBtcTradeRatio > Trader.MIN_BUY_SELL_RATIO:
            deal = self.__buyAtKunaSellAtBtcTrade()
            
        if deal is not None:
            self.__storeDeal(deal, 'forwardDeals.csv')
            self.__deals.append(deal)



    def __storeDeal(self, deal, fileName):
        with self.__openFileForDailyRecords(fileName) as forwardDealsFile:
            textToAppend = str(deal.id) + "," + \
                           str(deal.fromBtcTradeToKuna) + "," + \
                           "{0:.4f}".format(deal.initialCryptoAmount) + "," + \
                           "{0:.2f}".format(deal.profitInPercents) + "," + \
                           "{0:.2f}".format(deal.profitFiat) + "\n"

            pricesFile.write(textToAppend)
        return



    def __handlePendingDeals(self):
        completedDealsIndices = []

        for dealIndex in range(len(self.__deals)):
            if self.__handlePendingDeal(deal) == True:
                completedDealsIndices.insert(0, dealIndex)

        # Indices are stored using descending order
        for indexToRemove in completedDealsIndices:
            del self.__deals[indexToRemove]

        


    def __handlePendingDeal(self, deal):
        reverseDeal = None

        if deal.fromBtcTradeToKuna == True:
            # Originally we bought at BTCTrade and sold at KUNA
            # Check if we can return assets to original platforms
            # with appropriate loss
            kunaToBtcTradeRatio = self.__platformsState.kunaToBtcTradeBuySellRatio()

            if kunaToBtcTradeRatio > Trader.MIN_RETURN_RATIO:
                reverseDeal = self.__buyAtKunaSellAtBtcTrade(deal.cryptoAmountToReturn)

        else:
            # Originally we bought at KUNA and sold at BTCTrade
            # Check if we can return assets to original platforms
            # with appropriate loss
            btcTradeToKunaRatio = self.__platformsState.btcTradeToKunaBuySellRatio()

            if btcTradeToKunaRatio > Trader.MIN_RETURN_RATIO:
                reverseDeal = self.__buyAtBtcTradeSellAtKuna(deal.cryptoAmountToReturn)

        if reverseDeal is not None:
            deal.cryptoAmountToReturn -= reverseDeal.initialCryptoAmount
            
            # Make connection between forward deal and return deal
            reverseDeal.id = deal.id
            self.__storeDeal(reverseDeal, 'reverseDeals.csv')

            if deal.cryptoAmountToReturn <= 0.0:
                # We have returned all funds which we used in forward deal
                return True 

        return False 



    def __buyAtBtcTradeSellAtKuna(self, preferredCryptoAmount = 1000000000):
        kunaTopBuyOrderCryptoAmount = self.__platformsState.kunaTopBuyOrderCryptoAmount()
        kunaAvailableCryptoAmount = self.__platformsState.kunaAvailableCryptoAmount()
        btcTradeTopSellOrderFiatAmount = self.__platformsState.btcTradeTopSellOrderFiatAmount()
        btcTradeAvailableFiatAmount = self.__platformsState.btcTradeAvailableFiatAmount()

        # Calculate how much we should buy depending of 
        # how much funds we have at the moment
        # and how much is available for buying 
        # and how much can be sold at the opposite site
        buyFunds = min(btcTradeTopSellOrderFiatAmount, btcTradeAvailableFiatAmount)
        buyPrice = self.__platformsState.topBtcTradeSellPrice()
        
        dealCryptoAmount = buyFunds / buyPrice
        sellFunds = min(kunaAvailableCryptoAmount, kunaTopBuyOrderCryptoAmount)
        sellFunds = min(sellFunds, preferredCryptoAmount)
        dealCryptoAmount = min(dealCryptoAmount, sellFunds)       

        if dealCryptoAmount > Trader.BTC_TRADE_MIN_ORDER_AMOUNT:
            # Buy at the top selling (ASK) price at BTCTradeUA and 
            # sell at the top buying (BID) price at KUNA
            sellPrice = self.__platformsState.topKunaBuyPrice()  
            self.__btcTradeUAProvider.buy(buyPrice, dealCryptoAmount)           
            self.__kunaProvider.put_order('sell', dealCryptoAmount, 'btcuah', sellPrice) 
            
            deal = Trader.RoundtripDeal()
            deal.fromBtcTradeToKuna = True
            deal.initialCryptoAmount = dealCryptoAmount
            deal.cryptoAmountToReturn = dealCryptoAmount
            deal.profitAbsolute = dealCryptoAmount * (buyPrice - sellPrice)
            deal.profitFiat = (buyPrice - sellPrice) / buyPrice * 100

            return deal

        return None



    def __buyAtKunaSellAtBtcTrade(self, preferredCryptoAmount = 1000000000):
        kunaTopSellOrderFiatAmount = self.__platformsState.kunaTopSellOrderFiatAmount()
        kunaAvailableFiatAmount = self.__platformsState.kunaAvailableFiatAmount()
        btcTradeTopBuyOrderCryptoAmount = self.__platformsState.btcTradeTopBuyOrderCryptoAmount()
        btcTradeAvailableCryptoAmount = self.__platformsState.btcTradeAvailableCryptoAmount()

        # Calculate how much we should buy depending of 
        # how much funds we have at the moment
        # and how much is available for buying 
        # and how much can be sold at the opposite site
        buyFunds = min(kunaTopSellOrderFiatAmount, kunaAvailableFiatAmount)
        buyPrice = self.__platformsState.topKunaSellPrice()

        dealCryptoAmount = buyFunds / buyPrice
        sellFunds = min(btcTradeTopBuyOrderCryptoAmount, btcTradeAvailableCryptoAmount)
        sellFunds = min(sellFunds, preferredCryptoAmount)
        dealCryptoAmount = min(dealCryptoAmount, sellFunds)

        if dealCryptoAmount > Trader.BTC_TRADE_MIN_ORDER_AMOUNT:
            # Buy at the top selling (ASK) price at KUNA and 
            # sell at the top buying (BID) price at BTCTrade
            sellPrice = self.__platformsState.topBtcTradeBuyPrice()
            self.__kunaProvider.put_order('buy', dealCryptoAmount, 'btcuah', buyPrice) 
            self.__btcTradeUAProvider.sell(sellPrice, dealCryptoAmount) 
                    
            deal = Trader.RoundtripDeal()
            deal.fromBtcTradeToKuna = False
            deal.initialCryptoAmount = dealCryptoAmount
            deal.cryptoAmountToReturn = dealCryptoAmount
            deal.profitFiat = dealCryptoAmount * (buyPrice - sellPrice)
            deal.profitInPercents = (buyPrice - sellPrice) / buyPrice * 100

            return deal

        return None



    # Constants
    MIN_BUY_SELL_RATIO = 2.5
    MIN_RETURN_RATIO = -1.0
    BTC_TRADE_MIN_ORDER_AMOUNT = 0.001

    # Nested types
    class RoundtripDeal:
        id = uuid.uuid1()
        fromBtcTradeToKuna = True
        initialCryptoAmount = 0.0
        cryptoAmountToReturn = 0.0
        profitInPercents = 0.0
        profitFiat = 0.0
        accumulatedLoss = 0.0