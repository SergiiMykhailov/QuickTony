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



    def run(self):
        while True:
            try:
                self.__storage = Storage(self.__platform1.getName(), \
                                         self.__platform2.getName())
                self.__handlePlatformsState()
                self.__storage.recordTimestamp()
            except:
                e = sys.exc_info()[0]
                print("Exception handled: ", e)

            time.sleep(10)



    def __handlePlatformsState(self):
        if self.__updatePlatformsState() == False:
            return        

        self.__storePrices()

        if self.__buyAndSellAssetIfPossible() == True:
            return
        
        if self.__performReverseDealIfPossible(True) == True:
            return

        if self.__performReverseDealIfPossible(False) == True:
            return
        

    
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

        print("    RATIO: forward ({0:.2f}".format(platform1ToPlatform2Ratio) + "), " + \
              "reverse ({0:.2f}".format(platform2ToPlatform1Ratio) + ")")

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



    def __buyAndSellAssetIfPossible(self) -> bool:
        platform1ToPlatform2Ratio = self.__getRatio(self.__platform1State, self.__platform2State)
        platform2ToPlatform1Ratio = self.__getRatio(self.__platform2State, self.__platform1State)

        deal = None

        minBuySellRatio = self.__storage.getMinForwardRatio()

        if minBuySellRatio is None:
            print("!!! WARNING: Min buy/sell ratio is not specified in configuration.")
            return False

        if platform1ToPlatform2Ratio is not None and platform1ToPlatform2Ratio > minBuySellRatio:
            deal = self.__performBuySell(self.__platform1, \
                                         self.__platform1State, \
                                         self.__platform2, \
                                         self.__platform2State)
            if deal is not None:
                deal.fromPlatform1ToPlatform2 = True           
        elif platform2ToPlatform1Ratio is not None and platform2ToPlatform1Ratio > minBuySellRatio:
            deal = self.__performBuySell(self.__platform2, \
                                         self.__platform2State, \
                                         self.__platform1, \
                                         self.__platform1State) 
            if deal is not None:
                deal.fromPlatform1ToPlatform2 = False 
            
        if deal is not None:
            self.__storeDeal(deal, True)
            return True

        return False



    def __storeDeal(self, deal, isForward):
        self.__storage.storeDeal(isForward, \
                                 deal.fromPlatform1ToPlatform2, \
                                 deal.initialCryptoAmount, \
                                 deal.buyPrice, \
                                 deal.sellPrice)



    def __shouldPerformReverseOperation(self, reverseRatio) -> bool:
        maxLoss = self.__storage.getMaxLossRatio()

        if maxLoss is None:
            print("!!! ATTENTION: Max loss is not specified in configuration")
            return False

        result = reverseRatio > maxLoss
        return result

        

    def __performReverseDealIfPossible(self, isFromPlatform1) -> bool:
        amountToReturn = self.__storage.getAmountToReturn(isFromPlatform1)

        if amountToReturn is None:
            return False

        if amountToReturn < self.__platform1.minOrderCryptoAmount \
           or amountToReturn < self.__platform2.minOrderCryptoAmount:
            return False

        sourcePlatformState = self.__platform1State
        sourcePlatform = self.__platform1
        destinationPlatformState = self.__platform2State
        destinationPlatform = self.__platform2

        if isFromPlatform1 == False:
            sourcePlatformState = self.__platform2State
            sourcePlatform = self.__platform2
            destinationPlatformState = self.__platform1State
            destinationPlatform = self.__platform1

        ratio = self.__getRatio(sourcePlatformState, destinationPlatformState)

        if self.__shouldPerformReverseOperation(ratio):
            reverseDeal = self.__performBuySell(sourcePlatform, \
                                                sourcePlatformState, \
                                                destinationPlatform, \
                                                destinationPlatformState, \
                                                amountToReturn)

            if reverseDeal is not None:
                reverseDeal.fromPlatform1ToPlatform2 = isFromPlatform1

                self.__storeDeal(reverseDeal, False)

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

        print("!!! NOT ENOUGH FUNDS TO PERFORM OPERATION " + platformToBuy.getName() + " <-> " + platformToSell.getName())

        return None



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