from . import TradingPlatform
from .Storage import Storage

import time
import datetime
import sys
import os
import uuid

class Trader(object):
    
    def __init__(self, \
                 platform1:TradingPlatform.TradingPlatform, \
                 platform2:TradingPlatform.TradingPlatform):
        self.__platform1 = platform1
        self.__platform2 = platform2

        self.__storage = Storage(platform1.getName(), platform2.getName())



    def run(self):
        while True:
            try:
                self.__handlePlatformsState()
                self.__storage.recordTimestamp()
            except:
                e = sys.exc_info()[0]
                print("Exception handled: ", e)

            time.sleep(10)



    def __handlePlatformsState(self):
        print("--- LOOP STARTED")

        if self.__updatePlatformsState() == False:
            return        

        self.__storePrices()
        print("    >>> PERFORMING BUY/SELL OPERATIONS")
        self.__buyAndSellAssetIfPossible()
        print("    <<< PERFORMING BUY/SELL OPERATIONS")
        print("    >>> TRYING TO RETURN BOUGHT ASSETS")
        self.__handlePendingDeals()
        print("    <<< TRYING TO RETURN BOUGHT ASSETS")
        print("--- LOOP COMPLETED")


    
    def __updatePlatformsState(self):
        print("    >>> BEGIN RETRIEVING TRADING DATA")
        
        startTime = time.time()
        self.__platform1State = self.__platform1.getState()
        endTime = time.time()
        platform1Duration = endTime - startTime

        startTime = endTime
        self.__platform2State = self.__platform2.getState()
        endTime = time.time()
        platform2Duration = endTime - startTime

        print("    <<< END RETRIEVING TRADING DATA: Platform 1 - " \
              + "{0:.2f}".format(platform1Duration) \
              + " (sec), Platform 2 - " + "{0:.2f}".format(platform2Duration) + " (sec)")

        

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
        platform1TopBuyOrder = self.__platform1State.getTopBuyOrder()
        platform1TopSellOrder = self.__platform1State.getTopSellOrder()
        platform2TopBuyOrder = self.__platform2State.getTopBuyOrder()
        platform2TopSellOrder = self.__platform2State.getTopSellOrder()

        platform1ToPlatform2Ratio = self.__getRatio(self.__platform1State, self.__platform2State)
        platform2ToPlatform1Ratio = self.__getRatio(self.__platform2State, self.__platform1State)

        with self.__openFileForDailyRecords("prices.csv") as pricesFile:
            textToAppend = "{0:.2f}".format(platform1TopBuyOrder.price / self.__platform1State.fiatCurrencyRate) + "," + \
                           "{0:.2f}".format(platform1TopSellOrder.price / self.__platform1State.fiatCurrencyRate) + "," + \
                           "{0:.2f}".format(platform2TopBuyOrder.price / self.__platform2State.fiatCurrencyRate) + "," + \
                           "{0:.2f}".format(platform2TopSellOrder.price / self.__platform2State.fiatCurrencyRate) + "," + \
                           "{0:.2f}".format(platform1ToPlatform2Ratio) + "," + \
                           "{0:.2f}".format(platform2ToPlatform1Ratio) + "\n"

            pricesFile.write(textToAppend)



    def __getRatio(self, platformToBuyState, platformToSellState):
        topSellOrder = platformToBuyState.getTopSellOrder()
        topBuyOrder = platformToSellState.getTopBuyOrder()

        if topSellOrder is not None and topBuyOrder is not None:
            buyPriceConverted = topSellOrder.price / platformToBuyState.fiatCurrencyRate
            sellPriceConverted = topBuyOrder.price / platformToSellState.fiatCurrencyRate
            ratio = (sellPriceConverted - buyPriceConverted) / buyPriceConverted * 100

            return ratio

        return None



    def __buyAndSellAssetIfPossible(self):
        platform1ToPlatform2Ratio = self.__getRatio(self.__platform1State, self.__platform2State)
        platform2ToPlatform1Ratio = self.__getRatio(self.__platform2State, self.__platform1State)

        deal = None

        if platform1ToPlatform2Ratio is not None and platform1ToPlatform2Ratio > Trader.MIN_BUY_SELL_RATIO:
            deal = self.__performBuySell(self.__platform1, \
                                         self.__platform1State, \
                                         self.__platform2, \
                                         self.__platform2State)
            if deal is not None:
                deal.fromPlatform1ToPlatform2 = True           
        elif platform2ToPlatform1Ratio is not None and platform2ToPlatform1Ratio > Trader.MIN_BUY_SELL_RATIO:
            deal = self.__performBuySell(self.__platform2, \
                                         self.__platform2State, \
                                         self.__platform1, \
                                         self.__platform1State) 
            if deal is not None:
                deal.fromPlatform1ToPlatform2 = False 
            
        if deal is not None:
            self.__storeDeal(deal, True, 'forwardDeals.csv')
            self.__deals.append(deal)



    def __storeDeal(self, deal, isForward, fileName):
        with self.__openFileForDailyRecords(fileName) as forwardDealsFile:
            textToAppend = str(deal.id) + "," + \
                           str(deal.fromPlatform1ToPlatform2) + "," + \
                           "{0:.4f}".format(deal.initialCryptoAmount) + "," + \
                           "{0:.2f}".format(deal.profitInPercents) + "," + \
                           "{0:.2f}".format(deal.profitFiat) + "\n"

            forwardDealsFile.write(textToAppend)

        self.__storage.storeDeal(isForward, \
                                 deal.fromPlatform1ToPlatform2, \
                                 deal.initialCryptoAmount, \
                                 deal.buyPrice, \
                                 deal.sellPrice)



    def __handlePendingDeals(self):
        completedDealsIndices = []

        for dealIndex in range(len(self.__deals)):
            deal = self.__deals[dealIndex]
            if self.__handlePendingDeal(deal) == True:
                completedDealsIndices.insert(0, dealIndex)

        # Indices are stored using descending order
        for indexToRemove in completedDealsIndices:
            del self.__deals[indexToRemove]



    def __shouldPerformReverseOperation(self, deal, reverseRatio) -> bool:
        result = deal.profitInPercents + reverseRatio - Trader.AFFORDABLE_LOSS > 0.0
        return result

        

    def __handlePendingDeal(self, deal):
        reverseDeal = None

        sourcePlatformState = self.__platform2State
        sourcePlatform = self.__platform2
        destinationPlatformState = self.__platform1State
        destinationPlatform = self.__platform1

        if deal.fromPlatform1ToPlatform2 == False:
            sourcePlatformState = self.__platform1State
            sourcePlatform = self.__platform1
            destinationPlatformState = self.__platform2State
            destinationPlatform = self.__platform2

        ratio = self.__getRatio(sourcePlatformState, destinationPlatformState)

        if self.__shouldPerformReverseOperation(deal, ratio):
            reverseDeal = self.__performBuySell(sourcePlatform, \
                                                sourcePlatformState, \
                                                destinationPlatform, \
                                                destinationPlatformState, \
                                                deal.cryptoAmountToReturn)

        if reverseDeal is not None:
            deal.cryptoAmountToReturn -= reverseDeal.initialCryptoAmount
            
            # Make connection between forward deal and return deal
            reverseDeal.id = deal.id
            self.__storeDeal(reverseDeal, False, 'reverseDeals.csv')

            if deal.cryptoAmountToReturn <= 0.0:
                # We have returned all funds which we used in forward deal
                return True 

        return False 



    def __performBuySell(self, \
                         platformToBuy, \
                         platformToBuyState, \
                         platformToSell, \
                         platformToSellState, \
                         preferredCryptoAmount = 1000000000):
        platformToBuyTopSellOrder = platformToBuyState.getTopSellOrder()
        platformToBuyAvailableFiatAmount = platformToBuyState.getAvailableFiatAmount() / platformToBuyState.fiatCurrencyRate
        platformToSellTopBuyOrder = platformToSellState.getTopBuyOrder()
        platformToSellAvailableCryptoAmount = platformToSellState.getAvailableCryptoAmount()

        # Calculate how much we should buy depending of 
        # how much funds we have at the moment
        # and how much is available for buying 
        # and how much can be sold at the opposite site
        buyFunds = min(platformToBuyTopSellOrder.getFiatAmount() / platformToBuyState.fiatCurrencyRate, platformToBuyAvailableFiatAmount)
        buyPrice = platformToBuyTopSellOrder.price / platformToBuyState.fiatCurrencyRate

        dealCryptoAmount = buyFunds / buyPrice
        sellFunds = min(platformToSellAvailableCryptoAmount, platformToSellTopBuyOrder.cryptoAmount)
        sellFunds = min(sellFunds, preferredCryptoAmount)
        dealCryptoAmount = min(dealCryptoAmount, sellFunds)       

        minOrderCryptoAmount = max(platformToBuy.minOrderCryptoAmount, platformToSell.minOrderCryptoAmount)

        if dealCryptoAmount > minOrderCryptoAmount:
            # Buy at the top selling (ASK) price at platform 1 
            # sell at the top buying (BID) price at platform 2
            sellPrice = platformToSellTopBuyOrder.price 
            platformToSell.sell(sellPrice, dealCryptoAmount)
            buyPriceConverted = buyPrice * platformToBuyState.fiatCurrencyRate
            platformToBuy.buy(buyPriceConverted, dealCryptoAmount) 
            
            deal = Trader.RoundtripDeal()
            deal.initialCryptoAmount = dealCryptoAmount
            deal.cryptoAmountToReturn = dealCryptoAmount
            deal.profitAbsolute = dealCryptoAmount * (sellPrice / platformToSellState.fiatCurrencyRate - buyPrice)
            deal.profitInPercents = self.__getRatio(platformToBuyState, platformToSellState)
            deal.buyPrice = platformToBuyTopSellOrder.price / platformToBuyState.fiatCurrencyRate
            deal.sellPrice = platformToSellTopBuyOrder.price / platformToSellState.fiatCurrencyRate

            return deal

        print("!!! NOT ENOUGH FUNDS TO PERFORM FORWARD OPERATION")

        return None



    # Internal fields

    __deals = [] # TODO: Replace by storing all pending deals in database


    # Constants
    MIN_BUY_SELL_RATIO = 2.5
    AFFORDABLE_LOSS = 1.6 # We want to pick at least 1% of NET income (0.6% goes for trading platforms fee)

    # Nested types
    class RoundtripDeal:
        id = uuid.uuid1()
        fromPlatform1ToPlatform2 = True
        initialCryptoAmount = 0.0
        cryptoAmountToReturn = 0.0
        profitInPercents = 0.0
        profitFiat = 0.0
        accumulatedLoss = 0.0
        buyPrice = 0.0
        sellPrice = 0.0