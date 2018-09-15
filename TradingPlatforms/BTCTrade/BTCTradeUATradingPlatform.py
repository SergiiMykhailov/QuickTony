from .. import TradingPlatform
from .. import PlatformState
from . import BTCTradeUA
from . import BTCTradeUAPlatformState


class BTCTradeUATradingPlatform(TradingPlatform.TradingPlatform):

    def __init__(self, \
                 publicKey, \
                 privateKey):
        self.__apiObject = BTCTradeUA.BtcTradeUA(public_key = publicKey, private_key = privateKey)
        self.minOrderCryptoAmount = 0.001



    def getState(self) -> PlatformState.PlatformState:
        balanceItems = self.__apiObject.balance()
        buyOrders = self.__apiObject.buy_list()
        sellOrders = self.__apiObject.sell_list()
        tickerInfo = self.__apiObject.ticker()
        currencyRate = float(tickerInfo["btc_uah"]["usd_rate"])

        return BTCTradeUAPlatformState.BTCTradeUAPlatformState(buyOrders, sellOrders, balanceItems, currencyRate)



    def buy(self, price, cryptoAmount):
        self.__apiObject.buy(price, cryptoAmount)   



    def sell(self, price, cryptoAmount):
        self.__apiObject.sell(price, cryptoAmount) 