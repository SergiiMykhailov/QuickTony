from abc import ABC, abstractmethod
from . import PlatformState


class TradingPlatform(ABC):

    minOrderCryptoAmount = 0.0001

    @abstractmethod
    def getState(self) -> PlatformState.PlatformState:
        pass

    @abstractmethod
    def buy(self, price, cryptoAmount):
        pass

    @abstractmethod
    def sell(self, price, cryptoAmount):
        pass