from .. import TradingPlatform
from .. import PlatformState
from . import KunaPlatformState
from kuna import kuna



class KunaTradingPlatform(TradingPlatform.TradingPlatform):

    def __init__(self, \
                 publicKey, \
                 privateKey):
        self.__apiObject = kuna.KunaAPI(publicKey, privateKey)



    def getState(self) -> PlatformState.PlatformState:
        ordersBook = self.__apiObject.get_order_book('btcuah')
        accountInfo = self.__apiObject.get_user_account_info()

        return KunaPlatformState.KunaPlatformState(ordersBook, accountInfo)



    def buy(self, price, cryptoAmount):
        self.__apiObject.put_order('buy', cryptoAmount, 'btcuah', price) 



    def sell(self, price, cryptoAmount):
        self.__apiObject.put_order('sell', cryptoAmount, 'btcuah', price) 