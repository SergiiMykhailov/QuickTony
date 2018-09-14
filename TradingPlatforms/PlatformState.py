from abc import ABC, abstractmethod


class Order(object):
    
    cryptoAmount = 0.0
    price = 0.0

    def __init__(self, cryptoAmount, price):
        self.cryptoAmount = cryptoAmount
        self.price = price

    def getFiatAmount(self):
        return self.cryptoAmount * self.price



class PlatformState(ABC):

    fiatCurrencyRate = 1.0

    @abstractmethod
    def getTopBuyOrder(self) -> Order:
        pass

    @abstractmethod
    def getTopSellOrder(self) -> Order:
        pass

    @abstractmethod
    def getAvailableFiatAmount(self) -> float:
        pass

    @abstractmethod
    def getAvailableCryptoAmount(self) -> float:
        pass