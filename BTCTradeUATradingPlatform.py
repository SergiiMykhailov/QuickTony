import TradingPlatform
import PlatformState
import BTCTradeUA
import BTCTradeUAPlatformState


class BTCTradeUATradingPlatform(TradingPlatform.TradingPlatform):

    def __init__(self, \
                 publicKey, \
                 privateKey):
        self.__apiObject = BTCTradeUA.BtcTradeUA(public_key = publicKey, private_key = privateKey)



    def getState(self) -> PlatformState.PlatformState:
        balanceItems = self.__apiObject.balance()
        buyOrders = self.__apiObject.buy_list()
        sellOrders = self.__apiObject.sell_list()

        return BTCTradeUAPlatformState.BTCTradeUAPlatformState(buyOrders, sellOrders, balanceItems)



    def buy(self, price, cryptoAmount):
        self.__apiObject.buy(price, cryptoAmount)   



    def sell(self, price, cryptoAmount):
        self.__apiObject.sell(price, cryptoAmount) 