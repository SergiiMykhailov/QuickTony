from .. import TradingPlatform
from .. import PlatformState
from . import KunaPlatformState
from kuna import kuna

import requests


class KunaTradingPlatform(TradingPlatform.TradingPlatform):

    def __init__(self, \
                 publicKey, \
                 privateKey):
        self.__apiObject = kuna.KunaAPI(publicKey, privateKey)



    def getState(self) -> PlatformState.PlatformState:
        ordersBook = self.__apiObject.get_order_book('btcuah')
        accountInfo = self.__apiObject.get_user_account_info()
        currencyRate = self.__getCurrencyRate()

        return KunaPlatformState.KunaPlatformState(ordersBook, accountInfo, currencyRate)



    def buy(self, price, cryptoAmount):
        self.__apiObject.put_order('buy', cryptoAmount, 'btcuah', price) 



    def sell(self, price, cryptoAmount):
        self.__apiObject.put_order('sell', cryptoAmount, 'btcuah', price) 



    def __getCurrencyRate(self):
        currencyInfo = requests.get(KunaTradingPlatform.CURRENCY_RATE_URL).json()
        
        for currencyRecord in currencyInfo:
            if currencyRecord["ccy"] == "USD":
                currencyRate = float(currencyRecord["sale"])
                return currencyRate

        return None



    # Internal fields and constants

    CURRENCY_RATE_URL = "https://api.privatbank.ua/p24api/pubinfo?exchange&json&coursid=11"