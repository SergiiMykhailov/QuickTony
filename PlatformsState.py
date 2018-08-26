class PlatformsState(object):
      
    
    kunaBuyOrders = []
    kunaSellOrders = []
    kunaAccountInfo = []

    btcTradeBuyOrders = []
    btcTradeSellOrders = []
    btcTradeBalanceItems = []
    
    
    def __init__(self, \
                 btcTradeUABuyOrders, \
                 btcTradeUASellOrders, \
                 btcTradeBalanceItems, \
                 kunaBuyOrders, \
                 kunaSellOrders, \
                 kunaAccountInfo):
        self.kunaBuyOrders = kunaBuyOrders
        self.kunaSellOrders = kunaSellOrders
        self.kunaAccountInfo = kunaAccountInfo
        self.btcTradeBuyOrders = btcTradeUABuyOrders
        self.btcTradeSellOrders = btcTradeUASellOrders
        self.btcTradeBalanceItems = btcTradeBalanceItems

    
    
    def topBtcTradeBuyPrice(self):
        if len(self.btcTradeBuyOrders) > 0:
            return float(self.btcTradeBuyOrders['list'][0]['price'])

        return None

    
    
    def topBtcTradeSellPrice(self):
        if len(self.btcTradeSellOrders) > 0:
            return float(self.btcTradeSellOrders['list'][0]['price'])

        return None



    def btcTradeTopSellOrderFiatAmount(self):
        if len(self.btcTradeSellOrders) > 0:
            return float(self.btcTradeSellOrders['list'][0]['currency_base'])

        return None



    def btcTradeTopBuyOrderCryptoAmount(self):
        if len(self.btcTradeBuyOrders) > 0:
            return float(self.btcTradeBuyOrders['list'][0]['currency_trade'])

        return None



    def btcTradeAvailableFiatAmount(self):
        return self.__btcTradeAvailableAmount('UAH')



    def btcTradeAvailableCryptoAmount(self):
        return self.__btcTradeAvailableAmount('BTC')



    def __btcTradeAvailableAmount(self, asset):
        accounts = self.btcTradeBalanceItems['accounts']
        for balanceItem in accounts:
            if balanceItem['currency'] == asset:
                result = float(balanceItem['balance'])
                return result

        return None

    
    
    def topKunaBuyPrice(self):
        if len(self.kunaBuyOrders) > 0:
            return float(self.kunaBuyOrders[0]['price'])

        return None



    def topKunaSellPrice(self):
        if len(self.kunaSellOrders) > 0:
            return float(self.kunaSellOrders[0]['price'])

        return None


    
    def kunaTopSellOrderFiatAmount(self):
        if len(self.kunaSellOrders) > 0:
            price = self.topKunaSellPrice()
            remainingVolume = float(self.kunaSellOrders[0]['remaining_volume'])
            result = price * remainingVolume
            return result

        return None



    def kunaTopBuyOrderCryptoAmount(self):
        if len(self.kunaBuyOrders) > 0:
            result = float(self.kunaBuyOrders[0]['remaining_volume'])
            return result

        return None



    def kunaAvailableFiatAmount(self):
        return self.__kunaAvailableAmount('uah')



    def kunaAvailableCryptoAmount(self):
        return self.__kunaAvailableAmount('btc')
        


    def __kunaAvailableAmount(self, asset):
        accounts = self.kunaAccountInfo['accounts']
        for balanceItem in accounts:
            if balanceItem['currency'] == asset:
                result = float(balanceItem['balance'])
                return result

        return 0.0



    # Profit ratio (in percents) in case when
    # asset was bought at BTCTrade and sold at KUNA
    def btcTradeToKunaBuySellRatio(self):
        sellPrice = self.topBtcTradeSellPrice()
        buyPrice = self.topKunaBuyPrice()

        return self.__getRatio(sellPrice, buyPrice)


    # Profit ratio (in percents) in case when
    # asset was bought at KUNA and sold at BTCTrade
    def kunaToBtcTradeBuySellRatio(self):
        sellPrice = self.topKunaSellPrice()
        buyPrice = self.topBtcTradeBuyPrice()

        return self.__getRatio(sellPrice, buyPrice)


    def __getRatio(self, sellPrice, buyPrice):
        if buyPrice is None or sellPrice is None:
            return None

        result = (buyPrice - sellPrice) / buyPrice * 100

        return result