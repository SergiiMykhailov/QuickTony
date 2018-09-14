from .. import PlatformState



class BTCTradeUAPlatformState(PlatformState.PlatformState):


    def __init__(self, \
                 buyOrders, \
                 sellOrders, \
                 balanceItems, \
                 fiatCurrencyRate):
        self.__buyOrders = buyOrders
        self.__sellOrders = sellOrders
        self.__balanceItems = balanceItems
        self.fiatCurrencyRate = fiatCurrencyRate

        

    def getTopBuyOrder(self) -> PlatformState.Order:
        return self.__getOrderFromItems(self.__buyOrders)



    def getTopSellOrder(self) -> PlatformState.Order:
        return self.__getOrderFromItems(self.__sellOrders)
        


    def getAvailableFiatAmount(self) -> float:
        return self.__getAvailableAmount('UAH')



    def getAvailableCryptoAmount(self) -> float:
        return self.__getAvailableAmount('BTC')



    def __getOrderFromItems(self, items):
        if len(items) > 0 and len(items['list']) > 0:
            price = float(items['list'][0]['price'])
            cryptoAmount = float(items['list'][0]['currency_trade'])

            return PlatformState.Order(cryptoAmount, price)

        return None



    def __getAvailableAmount(self, asset):
        accounts = self.__balanceItems['accounts']
        for balanceItem in accounts:
            if balanceItem['currency'] == asset:
                result = float(balanceItem['balance'])
                return result

        return None