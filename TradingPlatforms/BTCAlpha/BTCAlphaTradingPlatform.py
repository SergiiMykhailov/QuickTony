from .. import TradingPlatform
from .. import PlatformState
from . import BTCAlpha3
from . import BTCAlphaPlatformState



class BTCAlphaTradingPlatform(TradingPlatform.TradingPlatform):

    def __init__(self, \
                 publicKey, \
                 privateKey):
        self.__apiObject = BTCAlpha3.Client(publicKey, privateKey)



    def getState(self) -> PlatformState.PlatformState:
        orderbook = self.__apiObject.get_orderbook("BTC_USD")
        balanceItems = self.__apiObject.get_wallets()

        return BTCAlphaPlatformState.BTCAlphaPlatformState(orderbook, balanceItems)



    def buy(self, price, cryptoAmount):
        self.__apiObject.create_buy_order("BTC_USD", cryptoAmount, price)   



    def sell(self, price, cryptoAmount):
        self.__apiObject.create_sell_order("BTC_USD", cryptoAmount, price)   