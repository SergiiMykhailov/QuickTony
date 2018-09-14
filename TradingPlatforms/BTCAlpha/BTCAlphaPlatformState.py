from .. import PlatformState


class BTCAlphaPlatformState(PlatformState.PlatformState):


    def __init__(self, \
                 orderbook, \
                 balanceItems):
        self.__orderbook = orderbook
        self.__balanceItems = balanceItems

        

    def getTopBuyOrder(self) -> PlatformState.Order:
        return self.__getOrderFromItems(self.__orderbook["buy"])



    def getTopSellOrder(self) -> PlatformState.Order:
        return self.__getOrderFromItems(self.__orderbook["sell"])
        


    def getAvailableFiatAmount(self) -> float:
        return self.__getAvailableAmount('USD')



    def getAvailableCryptoAmount(self) -> float:
        return self.__getAvailableAmount('BTC')



    def __getOrderFromItems(self, items):
        if len(items) > 0:
            price = float(items[0]['price'])
            cryptoAmount = float(items[0]['amount'])

            return PlatformState.Order(cryptoAmount, price)

        return None



    def __getAvailableAmount(self, asset):
        for balanceItem in self.__balanceItems:
            if balanceItem['currency'] == asset:
                result = float(balanceItem['balance'])
                return result

        return None